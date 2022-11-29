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
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5.loca.getLanguage()
    desiredLanguage = desiredLanguage.split('-')
    desiredLanguage = desiredLanguage[0]

    desiredLanguage

  #######################################################################
  # returns markup to display in expert search
  #   use same uix as in plugin itself
  #######################################################################
  renderSearchInput: (data) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form

      form.DOM

  #######################################################################
  # make searchfilter for expert-search
  #######################################################################
  getSearchFilter: (data, key=@name()) ->
      that = @

      # search for empty values
      if data[key+":unset"]
          filter =
              type: "in"
              fields: [ @fullName()+".conceptName" ]
              in: [ null ]
          filter._unnest = true
          filter._unset_filter = true
          return filter

      # find all records which
      #   - have the uri as conceptURI
      #   OR
      #   - have the given uri in their ancestors

      filter =
          type: "complex"
          search: [
              type: "in"
              bool: "must"
              fields: [ "_objecttype" ]
              in: [ @path() ]
            ,
              type: "match"
              mode: "token"
              bool: "must",
              phrase: false
              fields: [@path() + '.' + @name() + ".conceptAncestors" ]
          ]

      if ! data[@name()]
          filter.search[1].string = null
      else if data[@name()]?.conceptURI
          givenURI = data[@name()].conceptURI
          givenURIParts = givenURI.split('/')
          givenGeonamesID = givenURIParts.pop()
          uri = 'http://geonames.org/' + givenGeonamesID

          filter.search[1].string = uri
      else
          filter = null

      filter

  #######################################################################
  # make tag for expert-search
  #######################################################################
  getQueryFieldBadge: (data) ->
      if ! data[@name()]
          value = $$("field.search.badge.without")
      else if ! data[@name()]?.conceptURI
          value = $$("field.search.badge.without")
      else
          value = data[@name()].conceptName

      name: @nameLocalized()
      value: value

  #######################################################################
  # read info from geonames-terminology
  __getAdditionalTooltipInfo: (uri, tooltip,extendedInfo_xhr) ->
    that = @
    # extract geonamesID from uri
    geonamesURI = uri
    geonamesID = decodeURIComponent(uri)
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
      htmlContent = '<span style="padding: 10px 10px 0px 10px; font-weight: bold">' + $$('custom.data.type.geonames.config.parameter.mask.infopop.info.label') + '</span>'
      coord1 = 0
      coord1 = 0
      if data.lat
          coord1 = data.lat
      if data.lat
          coord2 = data.lng
      # if mapbox_api_key --> read mapbox_api_key from schema
      if that.getCustomSchemaSettings().mapbox_api_key?.value
          mapbox_api_key = that.getCustomSchemaSettings().mapbox_api_key?.value
          if coord1 != 0 & coord2 != 0
            #url = location.protocol + '//api.mapbox.com/styles/v1/mapbox/streets-v11/static/' + coord2 + ',' + coord1 + ',11/400x200@2x?access_token=' + mapbox_api_key
            #htmlContent += '<div style="width:400px; height: 250px; background-size: contain; background-image: url(' + url + '); background-repeat: no-repeat; background-position: center center;"></div>'
            # show point on static-map
            value = JSON.parse('{"geometry": {"type": "Point","coordinates": [' + coord2 + ',' + coord1 + ']}}')

            # generates static mapbox-map via geojson
            # compare to https://www.mapbox.com/mapbox.js/example/v1.0.0/static-map-from-geojson-with-geo-viewport/
            jsonStr = '{"type": "FeatureCollection","features": []}'
            json = JSON.parse(jsonStr)

            json.features.push value

            bounds = geojsonExtent(json)
            if bounds
              size = [
                500
                300
              ]
              vp = geoViewport.viewport(bounds, size)
              encodedGeoJSON = value
              encodedGeoJSON.properties = {}
              encodedGeoJSON.type = "Feature"
              encodedGeoJSON.properties['stroke-width'] = 4
              encodedGeoJSON.properties['stroke'] = '#C20000'
              encodedGeoJSON = JSON.stringify(encodedGeoJSON)
              encodedGeoJSON = encodeURIComponent(encodedGeoJSON)
              if vp.zoom > 16
                vp.zoom = 12;
              imageSrc = 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v9/static/geojson(' + encodedGeoJSON + ')/' +  vp.center.join(',') + ',' + vp.zoom + '/' + size.join('x') + '@2x?access_token=' + mapbox_api_key
              htmlContent += '<div style="width:400px; height: 250px; background-size: contain; background-image: url(\'' + imageSrc + '\'); background-repeat: no-repeat; background-position: center center;"></div>'

      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

      if data.name
        if typeof data.name != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.name.label') + ':</td><td>' + data.name + '</td></tr>'

      if data.adminName4
        if typeof data.adminName4 != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.einteilung4.label') + ':</td><td>' + data.adminName4 + '</td></tr>'

      if data.adminName3
        if typeof data.adminName3 != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.einteilung3.label') + ':</td><td>' + data.adminName3 + '</td></tr>'

      if data.adminName2
        if typeof data.adminName2 != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.einteilung2.label') + ':</td><td>' + data.adminName2 + '</td></tr>'

      if data.adminName1
        if typeof data.adminName1 != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.einteilung1.label') + ':</td><td>' + data.adminName1 + '</td></tr>'

      if data.countryName
        if typeof data.countryName != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.land.label') + ':</td><td>' + data.countryName + '</td></tr>'

      if data.continentCode
        if typeof data.continentCode != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.kontinent.label') + ':</td><td>' + data.continentCode + '</td></tr>'

      if data.population
        if typeof data.population != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.einwohner.label') + ':</td><td>' + data.population + '</td></tr>'

      if data.fclName
        if typeof data.fclName != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.typ.label') + ':</td><td>' + data.fclName + '</td></tr>'

      if data.timezone
        if typeof data.timezone != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.geonames.config.parameter.mask.infopop.zeitzone.label') + ':</td><td>' + data.timezone + '</td></tr>'

      #tooltip.getPane().replace(htmlContent, "center")
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return

  __getFeaturecodesFromDANTE: (thisSelect, featureclassCode) ->
      dfr = new CUI.Deferred()
      values = []

      # start new request
      searchsuggest_xhr = new (CUI.XHR)(url: 'https://api.dante.gbv.de/suggest?search=&voc=place_type_geonames&language=' + @getFrontendLanguage() + '&limit=1000&cache=1')
      searchsuggest_xhr.start().done((data, status, statusText) ->
          # read options for select
          select_items = []
          item = (
            text: $$('custom.data.type.geonames.config.parameter.mask.config_featurecodes.all.label')
            value: null
          )
          select_items.push item
          for suggestion, key in data[1]
              uriParts = data[3][key]
              uriParts = uriParts.split('.')
              codeNotation = uriParts.pop()
              featureClassCodeExtraction = uriParts[2].split('#')
              featureClassCodeExtraction = featureClassCodeExtraction[1]
              if (featureClassCodeExtraction == featureclassCode) || featureclassCode == '' || ! featureclassCode || featureclassCode == null
                item = (
                  text: suggestion
                  value: codeNotation
                )
                select_items.push item
          thisSelect.enable()
          dfr.resolve(select_items)
      )
      dfr.promise()


  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    suggest_Menu

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }

    # set default value for count of suggestions
    cdata.countOfSuggestions = 50
    cdata_form = new CUI.Form
      class: 'cdtFormWithPadding'
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        # if featureclass- & featurecodes-dropdown are visible
        if @getCustomMaskSettings().config_featureclasses?.value && @getCustomMaskSettings().config_featurecodes?.value
          # if featureclass changed, update featurecodes-dropdown
          if elem.opts.name == 'geonamesSelectFeatureClasses'
            # if featureclass is '', show all featurecodes
            featureclassParameter = ''
            if data?.geonamesSelectFeatureClasses != '' && data?.geonamesSelectFeatureClasses != null
              featureclassParameter = data.geonamesSelectFeatureClasses
            # reset the featurecode-element-value (in data + cdata)
            data.geonamesSelectFeatureCodes = null
            cdata.geonamesSelectFeatureCodes = null
            cdata_form.getFieldsByName("geonamesSelectFeatureCodes")[0]?.setValue(null)
            defaultText = cdata_form.getFieldsByName("geonamesSelectFeatureCodes")[0].default_opt.text

            cdata_form.getFieldsByName("geonamesSelectFeatureCodes")[0].reload()
            cdata_form.getFieldsByName("geonamesSelectFeatureCodes")[0]?.setText('test')
        @__updateResult(cdata, layout, opts)
        @__setEditorFieldStatus(cdata, layout)
        @__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout, opts)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element: cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true
        class: "customDataTypeCommonsMenu"

    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        # titel of popovers
        header_left: new CUI.Label(text: $$('custom.data.type.commons.popover.choose.label'))
        content: cdata_form
    .show()

  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        geonames_searchterm = searchstring
        geonames_countSuggestions = 50
        geonames_featureclass = ''
        geonames_featurecode = ''
        geonames_country = ''

        expandQuery = ''

        if (cdata_form)
          geonames_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
          geonames_featureclass = cdata_form.getFieldsByName("geonamesSelectFeatureClasses")[0]?.getValue()
          if geonames_featureclass == undefined || geonames_featureclass == null
              geonames_featureclass = ''

          geonames_featurecode = cdata_form.getFieldsByName("geonamesSelectFeatureCodes")[0]?.getValue()
          if geonames_featurecode == undefined || geonames_featurecode == null
              geonames_featurecode = ''

          geonames_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

          expandStatus = cdata_form.getFieldsByName("expandSearchCheckbox")[0].getValue()
          expandQuery = '&expand=' + expandStatus

        if geonames_searchterm.length == 0
            return

        countryQuery = ''
        if cdata?.geonamesSelectCountry
          countryQuery = '&country=' + cdata.geonamesSelectCountry

        ancestorsQuery = '&ancestors=false'
        if that.getCustomMaskSettings().use_ancestors?.value
          ancestorsQuery = '&ancestors=true'

        extendedInfo_xhr = { "xhr" : undefined }

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()
        # start new request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/geonames2/?searchterm=' + geonames_searchterm + '&language=' + that.getFrontendLanguage() + '&featureclass=' + geonames_featureclass + '&featurecode=' + geonames_featurecode + '&count=' + geonames_countSuggestions + countryQuery + expandQuery + ancestorsQuery)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

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
                      that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: "lade Informationen")
                menu_items.push item

            # set new items to menu
            itemList =
              keyboardControl: true
              onClick: (ev2, btn) ->
                  # lock in save data
                  cdata.conceptURI = btn.getOpt("value")
                  cdata.conceptName = btn.getText()
                  cdata._fulltext = {}
                  cdata._standard = {}
                  cdata._fulltext.text = cdata.conceptName
                  cdata._standard.text = cdata.conceptName

                  # if a geonames-username is given get data from geonames for fulltext
                  geonamesUsername = ''
                  if that.getCustomSchemaSettings().geonames_username?.value
                    geonamesUsername = that.getCustomSchemaSettings().geonames_username.value
                    # extract geonames-id from URI
                    geonamesID = cdata.conceptURI
                    geonamesID = geonamesID.replace('http://www.geonames.org/', '')
                    # build url for geonames-api
                    encodedURL = encodeURIComponent('http://api.geonames.org/getJSON?formatted=true&geonameId=' + geonamesID + '&username=' + geonamesUsername + '&style=full')
                    dataEntry_xhr = new (CUI.XHR)(url: location.protocol + '//jsontojsonp.gbv.de/?url=' + encodedURL)
                    dataEntry_xhr.start().done((data, status, statusText) ->

                      cdata.conceptName = ez5.GeonamesUtil.getConceptNameFromObject data
                      cdata.conceptURI = ez5.GeonamesUtil.getConceptURIFromObject data

                      # _standard & _fulltext
                      cdata._fulltext = ez5.GeonamesUtil.getFullTextFromObject data, false
                      cdata._standard = ez5.GeonamesUtil.getStandardTextFromObject that, data, cdata, false

                      # get ancestors from data
                      cdata.conceptAncestors = ez5.GeonamesUtil.getConceptAncestorsFromObject data

                      # update the layout in form
                      that.__updateResult(cdata, layout, opts)
                      # hide suggest-menu
                      suggest_Menu.hide()
                      # close popover
                      if that.popover
                        that.popover.hide()
                    )
                  else
                    # update the layout in form
                    that.__updateResult(cdata, layout, opts)
                    # hide suggest-menu
                    suggest_Menu.hide()
                    # close popover
                    if that.popover
                      that.popover.hide()
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
    that = @
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
              text: '10 ' + $$('custom.data.type.geonames.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.geonames.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.geonames.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.geonames.modal.form.text.count_short')
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Checkbox
        class: "commonPlugin_Checkbox"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.geonames.modal.form.text.expand')
        name: 'expandSearchCheckbox'
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
      ]

    # country-dropdown

    # geonamesCountryCodes in file "CountryCodes.coffee", translations in l10n "world_names.csv"
    countryCodeOptions = [
      (
        value: ''
        text: $$('custom.data.type.geonames.country.name.all')
      )
    ]

    # default value for expansion
    if that.getCustomMaskSettings().default_expand?.value
      cdata.expandSearchCheckbox = that.getCustomMaskSettings().default_expand.value

    # default country code?
    if @getCustomMaskSettings().default_country_code?.value
      defaultCountryCode = @getCustomMaskSettings().default_country_code?.value
      defaultCountryCode = defaultCountryCode.toLowerCase()
      cdata.geonamesSelectCountry = defaultCountryCode
    else
      # else "all countrys"
      cdata.geonamesSelectCountry = ''

    for countrycode in geonamesCountryCodes
      countryCodeOption =
        value: countrycode
        text: $$('custom.data.type.geonames.country.name.' + countrycode)
      countryCodeOptions.push countryCodeOption

    field = {
      type: CUI.Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.geonames.modal.form.text.countrys')
      options: countryCodeOptions
      name: 'geonamesSelectCountry'
      class: 'commonPlugin_Select'
    }

    fields.unshift(field)

    # offer Featurecodes? (see config)
    if @getCustomMaskSettings().config_featurecodes?.value

      field = {
        type: CUI.Select
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.geonames.modal.form.text.featurecodes')
        name: 'geonamesSelectFeatureCodes'
        class: 'commonPlugin_Select'
        options: (thisSelect) =>
          featureclassParameter = ''
          if cdata?.geonamesSelectFeatureClasses != '' && cdata?.geonamesSelectFeatureClasses != null
            featureclassParameter = cdata.geonamesSelectFeatureClasses
          that.__getFeaturecodesFromDANTE(thisSelect, featureclassParameter)
      }

      fields.unshift(field)

    # offer Featureclasses? (see config)
    if @getCustomMaskSettings().config_featureclasses?.value
      # featureclasses
      featureclassesOptions = [
        (
          value: ''
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.all.label')
        )
        (
          value: 'A'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.a.label')
        )
        (
          value: 'H'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.h.label')
        )
        (
          value: 'L'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.l.label')
        )
        (
          value: 'P'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.p.label')
        )
        (
          value: 'R'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.r.label')
        )
        (
          value: 'S'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.s.label')
        )
        (
          value: 'T'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.t.label')
        )
        (
          value: 'U'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.u.label')
        )
        (
          value: 'V'
          text: $$('custom.data.type.geonames.config.parameter.mask.config_featureclasses.v.label')
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

    extendedInfo_xhr = { "xhr" : undefined }

    # output Button with Name of picked entry and URI
    new CUI.HorizontalLayout
      maximize: false
      left:
        content:
          new CUI.Label
            centered: false
            multiline: true
            text: cdata.conceptName
      center:
        content:
          # output Button with Name of picked Entry and Url to the Source
          new CUI.ButtonHref
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) ->
                that.__getAdditionalTooltipInfo(cdata.conceptURI, tooltip, extendedInfo_xhr)
                new CUI.Label(icon: "spinner", text: "lade Informationen")
            text: ' '
      right: null
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.mapbox_api_key?.value
      tags.push "✓ mapbox-token"
    else
      tags.push "✘ mapbox-token"

    if custom_settings.geonames_username?.value
      tags.push "✓ geonames-Username"
    else
      tags.push "✘ geonames-Username"

    tags


CustomDataType.register(CustomDataTypeGeonames)
