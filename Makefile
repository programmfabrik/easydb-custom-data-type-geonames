PLUGIN_NAME = custom-data-type-geonames
PLUGIN_PATH = easydb-custom-data-type-geonames

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
    manifest.yml \
    build/updater/geonames-update.js

MAPBOX1 = src/external/geojson-extent.js
MAPBOX2 = src/external/geo-viewport.js

COFFEE_FILES = easydb-library/src/commons.coffee \
		src/webfrontend/geonamesUtil.coffee \
    src/webfrontend/CustomDataTypeGeonames.coffee \
    src/webfrontend/Countrycodes.coffee

CSS_FILE = src/webfrontend/css/main.css

UPDATE_SCRIPT_COFFEE_FILES = \
	src/webfrontend/Countrycodes.coffee \
	src/webfrontend/geonamesUtil.coffee \
	src/updater/geonamesUpdate.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code buildinfojson buildupdater

code: $(JS) $(L10N)
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-geonames.css
	cat $(MAPBOX1) $(MAPBOX2) >> build/webfrontend/custom-data-type-geonames.js

buildupdater: $(subst .coffee,.coffee.js,${UPDATE_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/geonames-update.js

clean: clean-base
