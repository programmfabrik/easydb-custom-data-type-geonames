> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-geonames
Custom Data Type "GEONAMES" for easydb

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGeonames` for references to entities of the [GeoNames geographical database)](<http://www.geonames.org/>).

The Plugins uses <http://ws.gbv.de/suggest/geonames/> for the autocomplete-suggestions and [GeoNames database](<http://www.geonames.org/export/JSON-webservices.html>) for additional informations about GeoNames entities. Maps are displayed via the [mapbox-API](https://docs.mapbox.com/api/).

## configuration

In `manifest.yml` you can configure:

* `schema-options`:
    * which [featureclasses] (<http://www.geonames.org/source-code/javadoc/org/geonames/FeatureClass.html>)  are offered for search.
    *  if a mapbox-token is added, the plugin shows geonames-places in a static map.
    *  if a valid geonames-username is given, fulltext will be available

* `mask-options`:
    * wether to show a dropdown with available featureclasses (place-categorie) or not
    * wether to show a dropdown with available featurecodes (place-type) or not
    * default country for the country-dropdown (2 digits-code)
    * default value for search expansion (Records of the lowest administrative level ("admin4") are also found via the higher-level administrative unit ("admin3"))
    * wether the ancestors are shown in hitlist

* `base-config`:
    * "days"
    * "default_language"
    * "geonames_username"

## saved data

* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptFulltext
    * fulltext-string which contains: geonameId, adminName1, adminName2, adminName3, adminName4, adminName5, countryName, toponymName, alternateNames
* conceptAncestors
    * the parent hierarchy of the selected record
* frontendLanguage
    * the frontendlanguage of the entering user
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-geonames>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-geonames/issues) for bug reports and feature requests!
