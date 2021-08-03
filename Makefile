PLUGIN_NAME = custom-data-type-geonames

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv \
    l10n/world_names.csv
L10N_GOOGLE_KEY = 1Z3UPJ6XqLBp-P8SUf-ewq4osNJ3iZWKJB83tc6Wrfn0
L10N_GOOGLE_GID = 1663005148

INSTALL_FILES = \
    $(WEB)/l10n/cultures.json \
    $(WEB)/l10n/de-DE.json \
    $(WEB)/l10n/en-US.json \
    $(JS) \
    $(CSS) \
    manifest.yml

MAPBOX1 = src/external/geojson-extent.js
MAPBOX2 = src/external/geo-viewport.js

COFFEE_FILES = easydb-library/src/commons.coffee \
    src/webfrontend/CustomDataTypeGeonames.coffee \
    src/webfrontend/Countrycodes.coffee

CSS_FILE = src/webfrontend/css/main.css

all: build

include easydb-library/tools/base-plugins.make

build: code buildinfojson

code: $(JS) $(L10N)
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-geonames.css
	cat $(MAPBOX1) $(MAPBOX2) >> build/webfrontend/custom-data-type-geonames.js

clean: clean-base
