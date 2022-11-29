class geonamesUpdate

  __start_update: ({server_config, plugin_config}) ->
      # only if geonames-username is given
      geonames_username = false
      if server_config.base.system.update_interval_geonames.geonames_username != ''
        geonames_username = server_config.base.system.update_interval_geonames.geonames_username
      if geonames_username
        # Check if geonames-API is available.
        testURL = 'https://ws.gbv.de/suggest/geonames2/?searchterm=G%C3%B6ttingen&featureclass=P&country=DE&count=50&ancestors=true&language=de&expand=false'
        availabilityCheck_xhr = new (CUI.XHR)(url: testURL)
        availabilityCheck_xhr.start()
        .done((data, status, statusText) ->
          dataStr = JSON.stringify data
          if dataStr.includes('Göttingen')
            ez5.respondSuccess({
              state: {
                  "start_update": new Date().toUTCString()
                  "databaseLanguages" : server_config.base.system.languages.database
                  "geonames_username" : geonames_username
                  "default_language" : server_config.base.system.update_interval_geonames.default_language
              }
            })
          else
            ez5.respondError("custom.data.type.geonames.update.error.generic", {error: "Test on geonames-API was not successfull!"})
        )
      else
        ez5.respondError("custom.data.type.geonames.update.error.generic", {error: "No geonames-username for API given!"})


  __updateData: ({objects, plugin_config, state}) ->
    that = @
    objectsMap = {}
    geonamesURIs = []
    databaseLanguages = state.databaseLanguages
    default_language = state.default_language
    geonames_username = state.geonames_username

    # check and set default-language
    defaultLanguage = false
    if default_language
      if (typeof default_language == 'string' || default_language instanceof String)
        if default_language.length == 2
          defaultLanguage = default_language

    for object in objects
      if not (object.identifier and object.data)
        continue
      geonamesURI = object.data.conceptURI
      if CUI.util.isEmpty(geonamesURI)
        continue
      if not objectsMap[geonamesURI]
        objectsMap[geonamesURI] = [] # It is possible to have more than one object with the same ID in different objects.
      objectsMap[geonamesURI].push(object)
      geonamesURIs.push(geonamesURI)

    if geonamesURIs.length == 0
      return ez5.respondSuccess({payload: []})

    timeout = plugin_config.update?.timeout or 0
    timeout *= 1000 # The configuration is in seconds, so it is multiplied by 1000 to get milliseconds.

    # unique geonames-uris
    geonamesURIs = geonamesURIs.filter((x, i, a) => a.indexOf(x) == i)

    objectsToUpdate = []

    # update the uri's one after the other
    chunkWorkPromise = CUI.chunkWork.call(@,
      items: geonamesURIs
      chunk_size: 1
      call: (items) =>
        #for uri in items
        uri = items[0]
        console.error "uri", uri
        originalUri = items[0]
        geonamesID = uri.replace('http://www.geonames.org/', '')
        geonamesID = geonamesID.replace('https://www.geonames.org/', '')
        geonamesID = geonamesID.replace('http://geonames.org/', '')
        geonamesID = geonamesID.replace('https://geonames.org/', '')
        console.error "geonamesID", geonamesID
        # build url for geonames-api
        encodedURL = encodeURIComponent('http://api.geonames.org/getJSON?formatted=true&geonameId=' + geonamesID + '&username=' + geonames_username + '&style=full')
        callUrl = 'https://jsontojsonp.gbv.de/?url=' + encodedURL
        console.error "callUrl", callUrl
        deferred = new CUI.Deferred()
        extendedInfo_xhr = new (CUI.XHR)(url: callUrl)
        extendedInfo_xhr.start().done((data, status, statusText) ->
          console.error "data", data
          # validation-test on data.geonameId (obligatory)
          if data?.geonameId
            # validation-test on data.asciiName (obligatory)
            if data?.asciiName
              resultsUri = 'http://geonames.org/' + data.geonameId
              # parse every record of this URI
              for cdataFromObjectsMap, objectsMapKey in objectsMap[originalUri]
                cdataFromObjectsMap = cdataFromObjectsMap.data

                # init updated cdata
                updatedcdata = {}
                updatedcdata.conceptName = ez5.GeonamesUtil.getConceptNameFromObject data
                #updatedcdata.conceptName = "TOBIAS"

                updatedcdata.conceptURI = ez5.GeonamesUtil.getConceptURIFromObject data

                # _standard & _fulltext
                updatedcdata._fulltext = ez5.GeonamesUtil.getFullTextFromObject data, databaseLanguages
                updatedcdata._standard = ez5.GeonamesUtil.getStandardTextFromObject null, data, cdataFromObjectsMap, databaseLanguages

                # get ancestors from data
                updatedcdata.conceptAncestors = ez5.GeonamesUtil.getConceptAncestorsFromObject data

                console.error "updatedcdata", updatedcdata
                # aggregate in objectsMap
                if that.__hasChanges(objectsMap[originalUri][objectsMapKey].data, updatedcdata)
                  objectsMap[originalUri][objectsMapKey].data = updatedcdata
                  objectsToUpdate.push(objectsMap[originalUri][objectsMapKey])
          deferred.resolve()
        ).fail( =>
         deferred.reject()
        )
        return deferred.promise()
    )

    chunkWorkPromise.done(=>
     ez5.respondSuccess({payload: objectsToUpdate})
    ).fail(=>
     ez5.respondError("custom.data.type.geonames.update.error.generic", {error: "Error connecting to geonames"})
    )

  __hasChanges: (objectOne, objectTwo) ->
    for key in ["conceptName", "conceptURI", "_standard", "_fulltext", "conceptAncestors", "frontendLanguage"]
      if not CUI.util.isEqual(objectOne[key], objectTwo[key])
        return true
    return false

  main: (data) ->
    if not data
      ez5.respondError("custom.data.type.geonames.update.error.payload-missing")
      return

    for key in ["action", "server_config", "plugin_config"]
      if (!data[key])
        ez5.respondError("custom.data.type.geonames.update.error.payload-key-missing", {key: key})
        return

    if (data.action == "start_update")
      @__start_update(data)
      return
    else if (data.action == "update")
      if (!data.objects)
        ez5.respondError("custom.data.type.geonames.update.error.objects-missing")
        return

      if (!(data.objects instanceof Array))
        ez5.respondError("custom.data.type.geonames.update.error.objects-not-array")
        return

      if (!data.state)
        ez5.respondError("custom.data.type.geonames.update.error.state-missing")
        return

      if (!data.batch_info)
        ez5.respondError("custom.data.type.geonames.update.error.batch_info-missing")
        return

      @__updateData(data)
      return
    else
      ez5.respondError("custom.data.type.geonames.update.error.invalid-action", {action: data.action})

module.exports = new geonamesUpdate()
