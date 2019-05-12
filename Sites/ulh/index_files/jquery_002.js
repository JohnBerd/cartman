
/*****************************************************************************/
/***** This file contains all functions to dialog with the portal api    *****/
/*****************************************************************************/

// We declare the jQuery Plugin
(function($) {

	var _controllerHostName = "";
	var _inAutoConnect = false;

	$.settings = "";
	$.translations = "";

	// Here are defined all the methods
	var methods = {
		getControllerHostname : // Gather controller name the initialize Ajax
			function () {
				if (_controllerHostName == "") {
					// Get controller hostname from URL
					var searchString = document.location.search.substring(1);
					var pairs = searchString.split('&');
					var controllerHostnameFound = false;
					for (i = 0; i < pairs.length; i++) {
						var pair = pairs[i].split('=');
						if (pair[0] == 'controllerHostname') {
							_controllerHostName = pair[1];
							controllerHostnameFound = true;
							break;
						}
					}
					if (controllerHostnameFound == false) {
						_controllerHostName = window.location.host;
					}

					delete searchString;
					delete pairs;
					delete controllerHostnameFound;

					// We initialize the future Ajax Requests
					$.ajaxSetup({
						async : true,
						cache : false,
						type : "POST",
						url : "https://" + _controllerHostName + "/portal_api.php",
						dataType : "json"
						});
				}
			},
		getCnaId: function() {
			var url_search_string = window.location.search.substring(1);
			if (url_search_string != '') {
				var url_search_pairs = url_search_string.split('&');
				for (var i = 0; i < url_search_pairs.length; ++i) {
					var url_search_pair = url_search_pairs[i].split('=');
					if (url_search_pair[0] == 'cna_id') {
						return url_search_pair[1];
						break;
					}
				}
			}
			return null;
		},
		setInAutoConnect: function(tmp_bool) {
			if (tmp_bool !== true && tmp_bool !== false) {
				$.error('setInAutoConnect in jQuery.portal_api detected an invalid input: ' + tmp_bool);
			}
			else {
				_inAutoConnect = tmp_bool;
			}
		},
		isInAutoConnect: function() {
			return _inAutoConnect;
		},
		init : // Gather portal settings then launch callbacks methods
			function (successCallback, startCallback, stopCallback, additionalRequest) {
				$.portal_api('getControllerHostname');

				var init_request = new Object();
				init_request.action = "init";
				init_request.free_urls = new Array();
				$('a').each(function() {
					if ($(this).attr('href') != "#") {
						init_request.free_urls.push($(this).attr('href'));
					}
				});

				if (typeof(additionalRequest) != 'undefined')
				{
					init_request.additional_request = additionalRequest;
				}

				// send also cna_id if we have it
				var cna_id = $.portal_api('getCnaId');
				if (cna_id != null) {
					init_request.cna_id = cna_id;
				}

				$.ajax({
					data : init_request,
					success : function (data, textStatus, xhr) {
							$.settings = data;
							if (successCallback != undefined) {
								successCallback(data, textStatus, xhr);
							}
						},
					start : function () {
							if (startCallback != undefined) {
								startCallback();
							}
						},
					stop : function () {
							if (stopCallback != undefined) {
								stopCallback();
							}
						}
					});
			},
		getTranslations : // Gather portal translation file then launch callbacks methods
			function (portalType, successCallback, startCallback, stopCallback) {
				$.portal_api('getControllerHostname');
				$.ajax({
					type: "GET",
					url: portalType + ".lang.xml",
					dataType: "xml",
					cache : true,
					success : function (xml) {
							$.translations = xml;
							if (successCallback != undefined) {
								successCallback();
							}
						},
					start : function () {
							if (startCallback != undefined) {
								startCallback();
							}
						},
					stop : function () {
							if (stopCallback != undefined) {
								stopCallback();
							}
						}
					});
			},
		action : // Execute Ajax action with callbacks methods / Callback method must have this definition method(data, textStatus, xhr)
			function (request, callbacks) {
				$.ajax({
					data : request,
					beforeSend : function() {
							if (callbacks != undefined && callbacks.beforeSend != undefined) {
								callbacks.beforeSend();
							}
						},
					success : function(data, textStatus, xhr) {
							// We extend the existing settings with the new results
							delete $.settings.error;
							delete $.settings.info;
							$.extend(true, $.settings, data);
							if (callbacks != undefined && callbacks.success != undefined) {
								callbacks.success(data, textStatus, xhr);
							}
						},
					complete : function () {
							if (callbacks != undefined && callbacks.complete != undefined) {
								callbacks.complete();
							}
						}
					});
			}
	};

	$.portal_api = function ( method ) {
		// Try to find if method is defined
		if ( method && method != '_initCallback' && methods[method] ) {
			return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
		//}
		//else if ( typeof method === 'object' || ! method ) {
		//	return methods.init.apply( this, arguments );
		}
		else {
			$.error( 'Method ' +  method + ' does not exist on jQuery.portal_api' );
		}
	};

})(jQuery);
