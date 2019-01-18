#!make
SHELL := /bin/bash

include metanorma.env
export $(shell sed 's/=.*//' metanorma.env)

RELATON_COLLECTION_ORG  := "OGC: The Open Geospatial Consortium"
RELATON_COLLECTION_NAME := "OGC Publications in Metanorma"

comma := ,
empty :=
space := $(empty) $(empty)

SRC  := $(wildcard repos/*)
REPO_XML    := $(addsuffix .xml,$(SRC))
INPUT_XML   := $(patsubst repos/%,sources/%,$(REPO_XML))
OUTPUT_XML  := $(patsubst sources/%,documents/%,$(INPUT_XML))
OUTPUT_HTML := $(patsubst %.xml,%.html,$(OUTPUT_XML))
FORMATS := xml html

COMPILE_CMD_LOCAL := bundle exec metanorma -t ogc -R $${FILENAME//xml/rxl} $$FILENAME
COMPILE_CMD_DOCKER := docker run -v "$$(pwd)":/metanorma/ ribose/metanorma "metanorma $${FILENAME//xml/rxl}  $$FILENAME"

ifdef METANORMA_DOCKER
  COMPILE_CMD := echo "Compiling via docker..."; $(COMPILE_CMD_DOCKER)
else
  COMPILE_CMD := echo "Compiling locally..."; $(COMPILE_CMD_LOCAL)
endif

_OUT_FILES := $(foreach FORMAT,$(FORMATS),$(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))
OUT_FILES  := $(foreach F,$(_OUT_FILES),$($F))

all: documents.html

documents:
	mkdir -p $@

documents/%.xml: documents sources/%.xml
	cp sources/$*.xml documents && \
	mv sources/$*.{html,doc,rxl,pdf} documents

sources:
	mkdir -p $@

sources/%.xml: sources | bundle
	cp repos/$*/*.xml sources/$*.xml
	FILENAME=$@; \
	${COMPILE_CMD}

documents.rxl: $(OUTPUT_XML)
	bundle exec relaton concatenate \
	  -t $(RELATON_COLLECTION_NAME) \
		-g $(RELATON_COLLECTION_ORG) \
		documents $@

documents.html: documents.rxl
	bundle exec relaton xml2html documents.rxl

%.xml:

clean:
	rm -rf documents published *_images sources/*.{rxl,xml,html,pdf,doc}

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

serve: $(NODE_BIN_DIR)/live-server revealjs-css reveal.js images
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
	mkdir -p published && \
	cp -a documents $@/ && \
	cp $< published/index.html; \
	if [ -d "images" ]; then cp -a images published; fi

deploy_key:
	openssl aes-256-cbc -K $(encrypted_$(ENCRYPTION_LABEL)_key) \
		-iv $(encrypted_$(ENCRYPTION_LABEL)_iv) -in $@.enc -out $@ -d && \
	chmod 600 $@

deploy: deploy_key
	export COMMIT_AUTHOR_EMAIL=$(COMMIT_AUTHOR_EMAIL); \
	./deploy.sh

.PHONY: publish deploy
