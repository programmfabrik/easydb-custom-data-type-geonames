Session::getCustomDataTypes = ->
	@getDefaults().server.custom_data_types or {}

class CustomDataTypeGEONAMES extends CustomDataType

	# the eventually running xhrs
	geonames_xhr = undefined
	entityfacts_xhr = undefined
	# suggestMenu
	suggest_Menu = new Menu
	# short info panel
	entityfacts_Panel = new Pane
	# locked geonames-URI
	geonamesResultURI = ''
	# locked geonames-Name
	geonamesResultName = ''
	# mapquest api-key
	mapquest_api_key = '';

	#######################################################################
	# return name of plugin
	getCustomDataTypeName: ->
		"custom:base.custom-data-type-geonames.geonames"


	#######################################################################
	# return name (l10n) of plugin
	getCustomDataTypeNameLocalized: ->
		$$("custom.data.type.geonames.name")

	#######################################################################
	# handle editorinput
	renderEditorInput: (data, top_level_data, opts) ->
		# console.error @, data, top_level_data, opts, @name(), @fullName()
		if not data[@name()]
			cdata = {
				    geonamesResultName : ''
				    geonamesResultURI : ''
				}
			data[@name()] = cdata
			geonamesResultURI = ''
			geonamesResultName = ''
		else
			cdata = data[@name()]
			geonamesResultName = cdata.geonamesResultName
			geonamesResultURI = cdata.geonamesResultURI

		@__renderEditorInputPopover(data, cdata)


	#######################################################################
	# buttons, which open and close the popover
	__renderEditorInputPopover: (data, cdata) ->
		# read mapquest-api-key from schema
		if @getCustomSchemaSettings().mapquest_api_key?.value
		    mapquest_api_key = @getCustomSchemaSettings().mapquest_api_key?.value
		# render buttons
		@__layout = new HorizontalLayout
			left:
				content:
						loca_key: "custom.data.type.geonames.edit.button"
						onClick: (ev, btn) =>
							@showEditPopover(btn, cdata, data)
			center:
				content:
						loca_key: "custom.data.type.geonames.remove.button"
						onClick: (ev, btn) =>
							# delete data
							cdata = {
								    geonamesResultName : ''
								    geonamesResultURI : ''
							}
							data.geonames = cdata
							geonamesResultURI = ''
							geonamesResultName = ''
							# trigger form change
							Events.trigger
								node: @__layout
								type: "editor-changed"
							@__updateGEONAMESResult(cdata)
			right: {}
		@__updateGEONAMESResult(cdata)
		@__layout


	#######################################################################
	# update result in Masterform
	__updateGEONAMESResult: (cdata) ->
		btn = @__renderButtonByData(cdata)
		@__layout.replace(btn, "right")


	#######################################################################
	# read info from geonames-terminology
	__getInfoForGeonamesEntry: (uri, tooltip) ->
		# extract geonamesID from uri
		geonamesID = uri
		geonamesID = geonamesID.split "/"
		geonamesID = geonamesID.pop()
		# download infos from entityfacts
		if entityfacts_xhr != undefined
			# abort eventually running request
			entityfacts_xhr.abort()
		# start new request
		entityfacts_xhr = new (CUI.XHR)(url: 'http://uri.gbv.de/terminology/geonames/' + geonamesID + '?format=json')
		entityfacts_xhr.start()
		.done((data, status, statusText) ->
			htmlContent = '<span style="font-weight: bold">Informationen über den Eintrag</span>'
			coord1 = 0
			coord1 = 0
			if data.lat
			    coord1 = data.lat
			if data.lat
			    coord2 = data.lng
			if mapquest_api_key
				if coord1 != 0 & coord2 != 0
					url = 'http://open.mapquestapi.com/staticmap/v4/getmap?key=' + mapquest_api_key + '&size=400,200&zoom=12&center=' + coord1 + ',' + coord2;
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

			tooltip.getPane().replace(htmlContent, "center")
			tooltip.autoSize()
		)
		.fail (data, status, statusText) ->
		    CUI.debug 'FAIL', entityfacts_xhr.getXHR(), entityfacts_xhr.getResponseHeaders()

		return


	#######################################################################
	# handle suggestions-menu
	__updateSuggestionsMenu: (cdata, cdata_form) ->
		that = @

		geonames_searchterm = cdata_form.getFieldsByName("geonamesSearchBar")[0].getValue()
		geonames_featureclass = cdata_form.getFieldsByName("geonamesSelectFeatureClasses")[0].getValue()
		geonames_countSuggestions = cdata_form.getFieldsByName("geonamesSelectCountOfSuggestions")[0].getValue()

		if geonames_searchterm.length == 0
		    return

		# run autocomplete-search via xhr
		if geonames_xhr != undefined
		    # abort eventually running request
		    geonames_xhr.abort()
		# start new request
		geonames_xhr = new (CUI.XHR)(url: 'http://ws.gbv.de/suggest/geonames/?searchterm=' + geonames_searchterm + '&featureclass=' + geonames_featureclass + '&count=' + geonames_countSuggestions)
		geonames_xhr.start().done((data, status, statusText) ->

		    CUI.debug 'OK', geonames_xhr.getXHR(), geonames_xhr.getResponseHeaders()

		    # create new menu with suggestions
		    menu_items = []
		    # the actual Featureclass
		    actualFclass = ''
		    for suggestion, key in data[1]
			    do(key) ->
				    if (actualFclass = '' || actualFclass != data[2][key])
					    actualFclass = data[2][key]
					    item =
						    divider: true
					    menu_items.push item
					    item =
						    label: actualFclass
					    menu_items.push item
					    item =
						    divider: true
					    menu_items.push item
				    item =
					    text: suggestion
					    value: data[3][key]
					    tooltip:
						    markdown: true
						    auto_size: true
						    placement: "e"
						    content: (tooltip) ->
							    # if enabled in mask-config
							    if that.getCustomMaskSettings().show_infopopup?.value
								    that.__getInfoForGeonamesEntry(data[3][key], tooltip)
								    new Label(icon: "spinner", text: "lade Informationen")
				    menu_items.push item

		    # set new items to menu
		    itemList =
			    onClick: (ev2, btn) ->

				    # lock result in variables
				    geonamesResultName = btn.getText()
				    geonamesResultURI = btn.getOpt("value")

				    # lock in save data
				    cdata.geonamesResultURI = geonamesResultURI
				    cdata.geonamesResultName = geonamesResultName
				    # lock in form
				    cdata_form.getFieldsByName("geonamesResultName")[0].storeValue(geonamesResultName).displayValue()
				    # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
				    cdata_form.getFieldsByName("geonamesResultURI")[0].__checkbox.setText(geonamesResultURI)
				    cdata_form.getFieldsByName("geonamesResultURI")[0].show()

				    # clear searchbar
				    cdata_form.getFieldsByName("geonamesSearchBar")[0].setValue('')
			    items: menu_items

		    # if no hits set "empty" message to menu
		    if itemList.items.length == 0
			    itemList =
				    items: [
					    text: "kein Treffer"
					    value: undefined
				    ]

		    suggest_Menu.setItemList(itemList)

		    suggest_Menu.show(
			    new Positioner(
				    top: 60
				    left: 400
				    width: 0
				    height: 0
			    )
		    )

		)
		#.fail (data, status, statusText) ->
		    #CUI.debug 'FAIL', geonames_xhr.getXHR(), geonames_xhr.getResponseHeaders()


	#######################################################################
	# reset form
	__resetGEONAMESForm: (cdata, cdata_form) ->
		# clear variables
		geonamesResultName = ''
		geonamesResultURI = ''
		cdata.geonamesResultName = ''
		cdata.geonamesResultURI = ''

		# reset type-select
		cdata_form.getFieldsByName("geonamesSelectFeatureClasses")[0].setValue("DifferentiatedPerson")

		# reset count of suggestions
		cdata_form.getFieldsByName("geonamesSelectCountOfSuggestions")[0].setValue(20)

		# reset searchbar
		cdata_form.getFieldsByName("geonamesSearchBar")[0].setValue("")

		# reset result name
		cdata_form.getFieldsByName("geonamesResultName")[0].storeValue("").displayValue()

		# reset and hide result-uri-button
		cdata_form.getFieldsByName("geonamesResultURI")[0].__checkbox.setText("")
		cdata_form.getFieldsByName("geonamesResultURI")[0].hide()


	#######################################################################
	# if something in form is in/valid, set this status to masterform
	__setEditorFieldStatus: (cdata, element) ->
		switch @getDataStatus(cdata)
			when "invalid"
				element.addClass("cui-input-invalid")
			else
				element.removeClass("cui-input-invalid")

		Events.trigger
			node: element
			type: "editor-changed"

		@

	#######################################################################
	# show popover and fill it with the form-elements
	showEditPopover: (btn, cdata, data) ->
		# set default value for count of suggestions
		cdata.geonamesSelectCountOfSuggestions = 20
		cdata_form = new Form
			data: cdata
			fields: @__getEditorFields()
			onDataChanged: =>
				@__updateGEONAMESResult(cdata)
				@__setEditorFieldStatus(cdata, @__layout)
				@__updateSuggestionsMenu(cdata, cdata_form)
		.start()
		xpane = new SimplePane
			class: "cui-demo-pane-pane"
			header_left:
				new Label
					text: "Header left shortcut"
			content:
				new Label
					text: "Center content shortcut"
			footer_right:
				new Label
					text: "Footer right shortcut"
		@popover = new Popover
			element: btn
			fill_space: "both"
			placement: "c"
			pane:
				# titel of popovers
				header_left: new LocaLabel(loca_key: "custom.data.type.geonames.edit.modal.title")
				# "save"-button
				footer_left: new Button
				    text: "Ok, Popup schließen"
				    onClick: =>
					    # put data to savedata
					    data.geonames = {
						    geonamesResultName : cdata.geonamesResultName
						    geonamesResultURI : cdata.geonamesResultURI
					    }
					    # close popup
					    @popover.destroy()
				# "reset"-button
				footer_right: new Button
				    text: "Zurücksetzen"
				    onClick: =>
					    @__resetGEONAMESForm(cdata, cdata_form)
					    @__updateGEONAMESResult(cdata)
				content: cdata_form
		.show()


	#######################################################################
	# create form
	__getEditorFields: ->
		fields = [
			{
				type: Select
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
				name: 'geonamesSelectCountOfSuggestions'
			}
			{
				type: Input
				undo_and_changed_support: false
				form:
				    label: $$("custom.data.type.geonames.modal.form.text.searchbar")
				placeholder: $$("custom.data.type.geonames.modal.form.text.searchbar.placeholder")
				name: "geonamesSearchBar"
			}
			{
				form:
					label: "Gewählter Eintrag"
				type: Output
				name: "geonamesResultName"
				data: {geonamesResultName: geonamesResultName}
			}
			{
				form:
					label: "Verknüpfte URI"
				type: FormButton
				name: "geonamesResultURI"
				icon: new Icon(class: "fa-lightbulb-o")
				text: geonamesResultURI
				onClick: (evt,button) =>
					window.open geonamesResultURI, "_blank"
				onRender : (_this) =>
					if geonamesResultURI == ''
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
				type: Select
				undo_and_changed_support: false
				form:
				    label: $$('custom.data.type.geonames.modal.form.text.featureclasses')
				options: featureclassesOptions
				name: 'geonamesSelectFeatureClasses'
			}

			fields.unshift(field)

		fields

	#######################################################################
	# renders details-output of record
	renderDetailOutput: (data, top_level_data, opts) ->
		@__renderButtonByData(data[@name()])


	#######################################################################
	# checks the form and returns status
	getDataStatus: (cdata) ->
		if cdata.geonamesResultURI and cdata.geonamesResultName
			# check url for valididy
			uriCheck = CUI.parseLocation(cdata.geonamesResultURI)

			# /^(https?|ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(value);

			# uri-check patch!?!? returns always a result

			nameCheck = if cdata.geonamesResultName then cdata.geonamesResultName.trim() else undefined

			if uriCheck and nameCheck
				console.debug "getDataStatus: OK "
				return "ok"

			if cdata.geonamesResultURI.trim() == '' and cdata.geonamesResultName.trim() == ''
				console.debug "getDataStatus: empty"
				return "empty"

			console.debug "getDataStatus returns invalid"
			return "invalid"
		else
			cdata = {
				    geonamesResultName : ''
				    geonamesResultURI : ''
				}
			console.debug "getDataStatus: empty"
			return "empty"


	#######################################################################
	# renders the "result" in original form (outside popover)
	__renderButtonByData: (cdata) ->
		# when status is empty or invalid --> message
		switch @getDataStatus(cdata)
			when "empty"
				return new EmptyLabel(text: $$("custom.data.type.geonames.edit.no_geonames")).DOM
			when "invalid"
				return new EmptyLabel(text: $$("custom.data.type.geonames.edit.no_valid_geonames")).DOM

		# if status is ok
		geonamesResultURI = CUI.parseLocation(cdata.geonamesResultURI).url

		# if geonamesResultURI .... ... patch abwarten

		# output Button with Name of picked GEONAMES-Entry and Url to the "Deutsche Nationalbibliothek"
		new ButtonHref
			appearance: "link"
			href: cdata.geonamesResultURI
			target: "_blank"
			tooltip:
				markdown: true
				auto_size: true
				placement: 'n'
				content: () ->
					uri = cdata.geonamesResultURI
					geonamesID = uri.split('/')
					geonamesID = geonamesID.pop()
					htmlContent = ''
					# wenn mapquest-api-key
					if mapquest_api_key
					    htmlContent += '<div style="width:400px; height: 250px; background-image: url(http://ws.gbv.de/suggest/mapfromgeonamesid/?id=' + geonamesID + '&zoom=12&width=400&height=250&mapquestapikey=' + mapquest_api_key + '); background-repeat: no-repeat; background-position: center center;"></div>'
					    htmlContent
			text: cdata.geonamesResultName + '\n( ' + cdata.geonamesResultURI + ')'
		.DOM


	#######################################################################
	# is called, when record is being saved by user
	getSaveData: (data, save_data, opts) ->
		cdata = data[@name()] or data._template?[@name()]
		switch @getDataStatus(cdata)
			when "invalid"
				throw InvalidSaveDataException
			when "empty"
				save_data[@name()] = null
			when "ok"
				save_data[@name()] =
					geonamesResultName: cdata.geonamesResultName.trim()
					geonamesResultURI: cdata.geonamesResultURI.trim()



	renderCustomDataOptionsInDatamodel: (custom_settings) ->
		@


CustomDataType.register(CustomDataTypeGEONAMES)
