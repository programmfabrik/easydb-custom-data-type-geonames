class CustomDataTypeGeonames extends CustomDataTypeWithCommons


  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-geonames.geonames"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.geonames.name")


  #######################################################################
  # read info from geonames-terminology
  __getAdditionalTooltipInfo: (uri, tooltip,extendedInfo_xhr) ->
    that = @
    # extract geonamesID from uri
    geonamesID = uri
    geonamesID = geonamesID.split "/"
    geonamesID = geonamesID.pop()
    # download infos from entityfacts
    if extendedInfo_xhr.xhr != undefined
      # abort eventually running request
      extendedInfo_xhr.xhr.abort()
    # start new request
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//uri.gbv.de/terminology/geonames/' + geonamesID + '?format=json')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="font-weight: bold">Informationen über den Eintrag</span>'
      coord1 = 0
      coord1 = 0
      if data.lat
          coord1 = data.lat
      if data.lat
          coord2 = data.lng
      # wenn mapquest-api-key
      # read mapquest-api-key from schema
      if that.getCustomSchemaSettings().mapquest_api_key?.value
          mapquest_api_key = that.getCustomSchemaSettings().mapquest_api_key?.value
      if mapquest_api_key
        if coord1 != 0 & coord2 != 0
          url = location.protocol + '//open.mapquestapi.com/staticmap/v4/getmap?key=' + mapquest_api_key + '&size=400,200&zoom=12&center=' + coord1 + ',' + coord2;
          htmlContent += '<div style="width:400px; height: 250px; background-image: url(' + url + '); background-repeat: no-repeat; background-position: center center;"></div>'
      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

      if data.name
        if typeof data.name != 'object'
            htmlContent += '<tr><td>Name:</td><td>' + data.name + '</td></tr>'

      if data.adminName4
        if typeof data.adminName4 != 'object'
            htmlContent += '<tr><td>Einteilung4:</td><td>' + data.adminName4 + '</td></tr>'

      if data.adminName3
        if typeof data.adminName3 != 'object'
            htmlContent += '<tr><td>Einteilung3:</td><td>' + data.adminName3 + '</td></tr>'

      if data.adminName2
        if typeof data.adminName2 != 'object'
            htmlContent += '<tr><td>Einteilung2:</td><td>' + data.adminName2 + '</td></tr>'

      if data.adminName1
        if typeof data.adminName1 != 'object'
            htmlContent += '<tr><td>Einteilung1:</td><td>' + data.adminName1 + '</td></tr>'

      if data.countryName
        if typeof data.countryName != 'object'
            htmlContent += '<tr><td>Land:</td><td>' + data.countryName + '</td></tr>'

      if data.continentCode
        if typeof data.continentCode != 'object'
            htmlContent += '<tr><td>Kontinent:</td><td>' + data.continentCode + '</td></tr>'

      if data.population
        if typeof data.population != 'object'
            htmlContent += '<tr><td>Einwohner:</td><td>' + data.population + '</td></tr>'

      if data.fclName
        if typeof data.fclName != 'object'
            htmlContent += '<tr><td>Typ:</td><td>' + data.fclName + '</td></tr>'

      if data.timezone
        if typeof data.timezone != 'object'
            htmlContent += '<tr><td>Zeitzone:</td><td>' + data.timezone + '</td></tr>'

      #tooltip.getPane().replace(htmlContent, "center")
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )
    .fail (data, status, statusText) ->
        CUI.debug 'FAIL', extendedInfo_xhr.xhr.getXHR(), extendedInfo_xhr.xhr.getResponseHeaders()

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, searchsuggest_xhr) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        geonames_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
        geonames_featureclass = cdata_form.getFieldsByName("geonamesSelectFeatureClasses")[0]?.getValue()
        if geonames_featureclass == undefined
            geonames_featureclass = ''
        geonames_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

        if geonames_searchterm.length == 0
            return

        extendedInfo_xhr = { "xhr" : undefined }

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()
        # start new request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/geonames/?searchterm=' + geonames_searchterm + '&featureclass=' + geonames_featureclass + '&count=' + geonames_countSuggestions)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            CUI.debug 'OK', searchsuggest_xhr.xhr.getXHR(), searchsuggest_xhr.xhr.getResponseHeaders()

            # create new menu with suggestions
            menu_items = []
            # the actual Featureclass
            for suggestion, key in data[1]
              do(key) ->
                # the actual Featureclass...
                aktType = data[2][key]
                lastType = ''
                if key > 0
                  lastType = data[2][key-1]
                if aktType != lastType
                  item =
                    divider: true
                  menu_items.push item
                  item =
                    label: aktType
                  menu_items.push item
                  item =
                    divider: true
                  menu_items.push item
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "e"
                    content: (tooltip) ->
                      # if enabled in mask-config
                      if that.getCustomMaskSettings().show_infopopup?.value
                        that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                        new CUI.Label(icon: "spinner", text: "lade Informationen")
                menu_items.push item

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->

                # lock in save data
                cdata.conceptURI = btn.getOpt("value")
                cdata.conceptName = btn.getText()
                # lock in form
                cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
                # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
                cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText(cdata.conceptURI)
                cdata_form.getFieldsByName("conceptURI")[0].show()

                # clear searchbar
                cdata_form.getFieldsByName("searchbarInput")[0].setValue('')
              items: menu_items

            # if no hits set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: "kein Treffer"
                  value: undefined
                ]

            suggest_Menu.setItemList(itemList)

            suggest_Menu.show()

        )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    fields = [
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.geonames.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 Vorschläge'
          )
          (
              value: 20
              text: '20 Vorschläge'
          )
          (
              value: 50
              text: '50 Vorschläge'
          )
          (
              value: 100
              text: '100 Vorschläge'
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.geonames.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.geonames.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }
      {
        form:
          label: "Gewählter Eintrag"
        type: CUI.Output
        name: "conceptName"
        data: {conceptName: cdata.conceptName}
      }
      {
        form:
          label: "Verknüpfte URI"
        type: CUI.FormButton
        name: "conceptURI"
        icon: new CUI.Icon(class: "fa-lightbulb-o")
        text: cdata.conceptURI
        onClick: (evt,button) =>
          window.open cdata.conceptURI, "_blank"
        onRender : (_this) =>
          if cdata.conceptURI == ''
            _this.hide()
      }]

    # offer Featureclasses? (see config)
    if @getCustomMaskSettings().config_featureclasses?.value
      # featureclasses
      featureclassesOptions = [
        (
          value: ''
          text: 'Alle Featureklassen'
        )
        (
          value: 'A'
          text: 'Administration'
        )
        (
          value: 'H'
          text: 'Gewässer'
        )
        (
          value: 'L'
          text: 'Gebiete'
        )
        (
          value: 'P'
          text: 'Besiedelte Orte'
        )
        (
          value: 'R'
          text: 'Straßen- und Eisenbahn'
        )
        (
          value: 'S'
          text: 'Punkte'
        )
        (
          value: 'T'
          text: 'Geländeformen'
        )
        (
          value: 'U'
          text: 'Untersee'
        )
        (
          value: 'V'
          text: 'Vegetation'
        )
      ]

      field = {
        type: CUI.Select
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.geonames.modal.form.text.featureclasses')
        options: featureclassesOptions
        name: 'geonamesSelectFeatureClasses'
        class: 'commonPlugin_Select'
      }

      fields.unshift(field)

    fields


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->
    that = @
    # when status is empty or invalid --> message
    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.geonames.edit.no_geonames")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.geonames.edit.no_valid_geonames")).DOM

    # if status is ok
    cdata.conceptURI = CUI.parseLocation(cdata.conceptURI).url

    # output Button with Name of picked GEONAMES-Entry and Url to the "Deutsche Nationalbibliothek"
    new CUI.ButtonHref
      appearance: "link"
      href: cdata.conceptURI
      target: "_blank"
      tooltip:
        markdown: true
        placement: 'n'
        content: (tooltip) ->
          uri = cdata.conceptURI
          geonamesID = uri.split('/')
          geonamesID = geonamesID.pop()
          htmlContent = ''
          # wenn mapquest-api-key
          if that.getCustomSchemaSettings().mapquest_api_key?.value
              mapquest_api_key = that.getCustomSchemaSettings().mapquest_api_key?.value
          if mapquest_api_key
              htmlContent += '<div style="width:400px; height: 250px; background-image: url(' + location.protocol  + '//ws.gbv.de/suggest/mapfromgeonamesid/?id=' + geonamesID + '&zoom=12&width=400&height=250&mapquestapikey=' + mapquest_api_key + '); background-repeat: no-repeat; background-position: center center;"></div>'
          tooltip.DOM.innerHTML = htmlContent
          tooltip.autoSize()
          htmlContent
      text: cdata.conceptName
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.mapquest_api_key?.value
      tags.push "✓ Mapquest-API-Key"
    else
      tags.push "✘ Mapquest-API-Key"

    tags


CustomDataType.register(CustomDataTypeGeonames)
