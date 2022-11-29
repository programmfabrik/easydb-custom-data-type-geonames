class ez5.GeonamesUtil

  @getConceptNameFromObject: (object) ->
    conceptName = ''
    if object?.asciiName
      conceptName = object.asciiName
    return conceptName


  @getConceptURIFromObject: (object) ->
    conceptURI = ''
    if object?.geonameId
      conceptURI = 'http://geonames.org/' + object.geonameId
    return conceptURI


  @getConceptAncestorsFromObject: (object) ->
    conceptAncestors = []
    if object?.countryId
      conceptAncestors.push 'http://geonames.org/' + object.countryId
    if object?.adminId1
      conceptAncestors.push 'http://geonames.org/' + object.adminId1
    if object?.adminId2
      conceptAncestors.push 'http://geonames.org/' + object.adminId2
    if object?.adminId3
      conceptAncestors.push 'http://geonames.org/' + object.adminId3
    if object?.adminId4
      conceptAncestors.push 'http://geonames.org/' + object.adminId4
    # push itself to ancestors
    conceptAncestors.push 'http://geonames.org/' + object.geonameId
    # join array to string
    conceptAncestors = conceptAncestors.join(' ')
    return conceptAncestors


  @getStandardTextFromObject: (context, object, cdata, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()
    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )
    activeFrontendLanguage = null
    if context
      activeFrontendLanguage = context.getFrontendLanguage()

    if cdata?.frontendLanguage
        if cdata?.frontendLanguage?.length == 2
          activeFrontendLanguage = cdata.frontendLanguage

    if Array.isArray(object)
      object = object[0]

    _standard = {}
    standardTextString = ''
    l10nObject = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    # 1. L10N
    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # add to l10n
      l10nObject[l10nObjectKey] = object.asciiName

    _standard.l10ntext = l10nObject

    return _standard


  @getFullTextFromObject: (object, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(object)
      object = object[0]

    _fulltext = {}
    fullTextString = ''
    l10nObject = {}
    l10nObjectWithShortenedLanguages = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    for language in shortenedDatabaseLanguages
      l10nObjectWithShortenedLanguages[language] = ''

    objectKeys = ["asciiName", "alternateNames", "toponymName", "geonameId", "countryName"]

    # parse all object-keys and add all values to fulltext
    for key, value of object
      if objectKeys.includes(key)
        propertyType = typeof value

        # string
        if propertyType == 'string' || propertyType == 'number'
          fullTextString += value + ' '
          # add to each language in l10n
          for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
            l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + value + ' '

        # object / array
        if propertyType == 'object'
          # array?
          if Array.isArray(object[key])
            if Array.isArray(object[key])
              for arrayValue in object[key]
                # no language: add to every l10n-fulltext
                if typeof arrayValue == 'string'
                  fullTextString += arrayValue + ' '
                  for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
                    l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + arrayValue + ' '
            if typeof object[key] == 'object'
              for altnamekey, altnameVal of object[key]
                if altnameVal.name
                  fullTextString += altnameVal.name + ' '
                  for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
                    l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + altnameVal.name + ' '
          else
            # object?
            for objectKey, objectValue of object[key]
              if Array.isArray(objectValue)
                for arrayValueOfObject in objectValue
                  fullTextString += arrayValueOfObject + ' '
                  # check key and also add to l10n
                  if l10nObjectWithShortenedLanguages.hasOwnProperty objectKey
                    l10nObjectWithShortenedLanguages[objectKey] += arrayValueOfObject + ' '
              if typeof objectValue == 'string'
                fullTextString += objectValue + ' '
                # check key and also add to l10n
                if l10nObjectWithShortenedLanguages.hasOwnProperty objectKey
                  l10nObjectWithShortenedLanguages[objectKey] += objectValue + ' '
    # finally give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if l10nObjectWithShortenedLanguages[shortenedLanguage]
        l10nObject[l10nObjectKey] = l10nObjectWithShortenedLanguages[shortenedLanguage]

    _fulltext.text = fullTextString
    _fulltext.l10ntext = l10nObject

    return _fulltext
