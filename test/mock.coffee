###
 * easydb-custom-data-type-geonames
 * Copyright (c) 2016 Programmfabrik GmbH, Verbundzentrale des GBV (VZG)
 * MIT Licence
 * https://github.com/programmfabrik/easydb-custom-data-type-gnd
###

class Session

class Menu

class Pane

class DataField

class Select extends DataField

class Input extends DataField

class Output extends DataField

class FormButton extends DataField

class Icon

class CUI
  @XHR: () ->

  @parseLocation: () ->
    true

  @debug: () ->

class CustomDataType
  @register: (datatype) -> 

  getCustomSchemaSettings: () ->
    {}

  getCustomMaskSettings: () ->
    {}

$$ = () ->

console = {
  log: () ->
  debug: () ->
}
