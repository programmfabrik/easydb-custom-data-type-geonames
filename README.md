# easydb-custom-data-type-geonames
Custom Data Type "GEONAMES" for easydb

Erlaubt die Verknüpfung mit geonames. Über einen Suchschlitz wird der Suggest-Service http://ws.gbv.de/suggest/geonames/ angesteuert. Die Ergebnisse können nach Featureklassen (http://www.geonames.org/source-code/javadoc/org/geonames/FeatureClass.html) gefiltert werden.

Im Vorschlagsmenü werden die Treffervorschläge nach Featurecodes zusammengefasst und entsprechend unterteilt ausgeliefert.

Beim Mausüberfahren eines Treffers in der Vorschlagsliste werden alle weiteren bekannten Informationen zum Datensatz in einem Tooltip dargestellt.

Um die Treffer in einer statischen Kartenvorschau zu sehen, muss ein Mapquest-Developer-Key in der Datenbank-Schema-Konfiguration des Objekttyps hinterlegt werden. Ohne API-Key wird keine Karte angezeigt.
