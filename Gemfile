source "https://rubygems.org"

gem "metanorma-cli", github: "metanorma/metanorma-cli", branch: "main"

# ogcapi-openapi sample (metanorma-ogc#153): the plugin + its model gem,
# riding main until the first releases train
gem "metanorma-plugin-openapi", github: "metanorma/metanorma-plugin-openapi", branch: "main"
gem "lutaml-openapi", github: "lutaml/lutaml-openapi", branch: "main"
# main carries the openapi preprocessor registration (#1026) and
# the plugin prerelease floor (#1027)
gem "metanorma-ogc", github: "metanorma/metanorma-ogc", branch: "main"
gem "moxml", github: "lutaml/moxml", branch: "main"

# released standoc caps relaton-cli ~> 2.1; main carries the widened floors
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "main"
# SvgmapElement (needed by metanorma-standoc main) is unreleased
# and blocked by metanorma-iso 3.5.0 (~> 0.2.0) on rubygems
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"
# released flavor gems subclass relaton-render classes that moved in
# the 3.0.0.pre train; all flavors ride main until they release against it
gem "metanorma-bipm", github: "metanorma/metanorma-bipm", branch: "main"
gem "metanorma-cc", github: "metanorma/metanorma-cc", branch: "main"
gem "metanorma-generic", github: "metanorma/metanorma-generic", branch: "main"
gem "metanorma-iec", github: "metanorma/metanorma-iec", branch: "main"
gem "metanorma-ieee", github: "metanorma/metanorma-ieee", branch: "main"
gem "metanorma-ietf", github: "metanorma/metanorma-ietf", branch: "main"
gem "metanorma-iho", github: "metanorma/metanorma-iho", branch: "main"
gem "metanorma-itu", github: "metanorma/metanorma-itu", branch: "main"
gem "metanorma-jis", github: "metanorma/metanorma-jis", branch: "main"
gem "metanorma-plateau", github: "metanorma/metanorma-plateau", branch: "main"
gem "metanorma-ribose", github: "metanorma/metanorma-ribose", branch: "main"
# released suma pins svg_conform ~> 0.1.0 vs standoc main (suma#127)
gem "suma", github: "metanorma/suma", branch: "main"

# pre-release line pins (see metanorma release wave)
gem "isodoc", github: "metanorma/isodoc", branch: "main"
# isodoc main requires sassc-embedded without declaring it
gem "sassc-embedded"
gem "relaton-cli", "~> 3.0"
