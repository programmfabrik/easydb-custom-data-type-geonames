###
 * easydb-custom-data-type-geonames
 * Copyright (c) 2016 Programmfabrik GmbH, Verbundzentrale des GBV (VZG)
 * MIT Licence
 * https://github.com/programmfabrik/easydb-custom-data-type-gnd
###

describe 'CustomDataTypeGeonames', () ->

  # create a new instance
  gndtype = new CustomDataTypeGeonames

  it 'should have a custom data type name', () ->
    expect(gndtype.getCustomDataTypeName()).toBe 'custom:base.custom-data-type-geonames.geonames'

  it 'should define editor fields', () ->
    fields = gndtype.__getEditorFields()
    for field in fields
      expect(field.type).toBeTruthy()

