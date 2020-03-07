#!make
SHELL := /bin/bash
# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

SRC := $(lastword $(shell yq r metanorma.yml metanorma.source.files))
ifeq ($(SRC),)
BUILT := $(shell yq r metanorma.yml metanorma.source.built_targets | cut -d ':' -f 1 | tr -s '\n' ' ')
ifeq ($(BUILT),)
SRC := $(filter-out README.adoc, $(wildcard sources/*.adoc))
else
XML := $(patsubst sources/%,documents/%,$(BUILT))
endif
endif

FORMATS := $(shell yq r metanorma.yml metanorma.formats | tr -d '[:space:]' | tr -s '-' ' ')
ifeq ($(FORMATS),)
FORMAT_MARKER := mn-output-
FORMATS := $(shell grep "$(FORMAT_MARKER)" $(SRC) | cut -f 2 -d ' ' | tr ',' '\n' | sort | uniq | tr '\n' ' ')
endif

XML  ?= $(patsubst sources/%,documents/%,$(patsubst %.adoc,%.xml,$(SRC)))

METANORMA_DOCKER_IMAGE ?= metanorma/metanorma

ifdef METANORMA_DOCKER
  PREFIX_CMD := echo "Running via docker..."; docker run -v "$$(pwd)":/metanorma/ $(METANORMA_DOCKER)

else
  PREFIX_CMD := echo "Running locally..."; bundle exec
endif

_OUT_FILES := $(foreach FORMAT,$(FORMATS),$(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))
OUT_FILES  := $(foreach F,$(_OUT_FILES),$($F))

all: documents.html

documents:
	mkdir -p $@

documents/%.xml: sources/%.html | documents
	export GLOBIGNORE=sources/$*.adoc; \
	mv sources/$(addsuffix .*,$*) documents; \
	unset GLOBIGNORE

# Build canonical XML output
# If XML file is provided, copy it over
# Otherwise, build it using adoc
sources/%.xml: | bundle
	BUILT_TARGET=$(shell yq r metanorma.yml metanorma.source.built_targets[$@]); \
	if [ "$$BUILT_TARGET" != "null" ]; then \
		if [ -f "$$BUILT_TARGET" ] && [ "$${BUILT_TARGET##*.}" == "xml" ]; then \
			cp "$$BUILT_TARGET" $@; \
		else \
			$(PREFIX_CMD) metanorma $$BUILT_TARGET; \
			cp "$${BUILT_TARGET//adoc/xml}" $@; \
		fi \
	fi

# Build derivative output
sources/%.html sources/%.doc sources/%.pdf:	sources/%.xml
	$(PREFIX_CMD) metanorma $<; \

documents.rxl: $(XML)
	echo "$(FORMATS)"; \
	echo "$(XML)"; \
	$(PREFIX_CMD) relaton concatenate \
	  -t "$(shell yq r metanorma.yml relaton.collection.name)" \
		-g "$(shell yq r metanorma.yml relaton.collection.organization)" \
		documents $@

documents.html: documents.rxl
	$(PREFIX_CMD) relaton xml2html documents.rxl

define FORMAT_TASKS
OUT_FILES-$(FORMAT) := $($(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))

open-$(FORMAT):
	open $$(OUT_FILES-$(FORMAT))

clean-$(FORMAT):
	rm -f $$(OUT_FILES-$(FORMAT))

$(FORMAT): clean-$(FORMAT) $$(OUT_FILES-$(FORMAT))

.PHONY: clean-$(FORMAT)

endef

$(foreach FORMAT,$(FORMATS),$(eval $(FORMAT_TASKS)))

open: open-html

clean:
	rm -rf documents documents.{html,rxl} published *_images $(OUT_FILES)

bundle:
	if [ "x" == "${METANORMA_DOCKER}x" ]; then bundle; fi

.PHONY: bundle all open clean

#
# Watch-related jobs
#

.PHONY: watch serve watch-serve

NODE_BINS          := onchange live-serve run-p
NODE_BIN_DIR       := node_modules/.bin
NODE_PACKAGE_PATHS := $(foreach PACKAGE_NAME,$(NODE_BINS),$(NODE_BIN_DIR)/$(PACKAGE_NAME))

$(NODE_PACKAGE_PATHS): package.json
	npm i

watch: $(NODE_BIN_DIR)/onchange
	make all
	$< $(ALL_SRC) -- make all

define WATCH_TASKS
watch-$(FORMAT): $(NODE_BIN_DIR)/onchange
	make $(FORMAT)
	$$< $$(SRC_$(FORMAT)) -- make $(FORMAT)

.PHONY: watch-$(FORMAT)
endef

$(foreach FORMAT,$(FORMATS),$(eval $(WATCH_TASKS)))

serve: $(NODE_BIN_DIR)/live-server revealjs-css reveal.js
	export PORT=$${PORT:-8123} ; \
	port=$${PORT} ; \
	for html in $(HTML); do \
		$< --entry-file=$$html --port=$${port} --ignore="*.html,*.xml,Makefile,Gemfile.*,package.*.json" --wait=1000 & \
		port=$$(( port++ )) ;\
	done

watch-serve: $(NODE_BIN_DIR)/run-p
	$< watch serve

#
# Deploy jobs
#

publish: published

published: documents.html
	mkdir -p $@ && \
	cp -a documents $@/ && \
	cp $< $@/index.html;
