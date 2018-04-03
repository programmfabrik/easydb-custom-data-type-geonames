# easydb-custom-data-type-geonames
Custom Data Type "GEONAMES" for easydb

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGeonames` for references to entities of the [GeoNames geographical database)](<http://www.geonames.org/>).

The Plugins uses <http://ws.gbv.de/suggest/geonames/> for the autocomplete-suggestions and [GeoNames database](<http://www.geonames.org/export/JSON-webservices.html>) for additional informations about GeoNames entities.

## configuration

In `CustomDataTypeGeonames.config.yml` you can configure:

* `schema-options`: which [featureclasses] (<http://www.geonames.org/source-code/javadoc/org/geonames/FeatureClass.html>)  are offered for search. If a Mapquest-Developer-Key is added, the Plugin shows GeoNames-Entries in a static map.

* `mask-options`: whether additional informationen is loaded if the mouse hovers a suggestion in the search result. The results are ordered and categorized by featurecode

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-geonames>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-geonames/issues) for bug reports and feature requests!




