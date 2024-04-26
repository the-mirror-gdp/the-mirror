class_name MirrorHttpClient
extends Node

var _base_url: String
var _requests: Array = Array()
var _requesting_count: int = 0


## Process runs every frame.
func _process(_delta: float) -> void:
	_process_request_queue()


## Process method makes requests one at a time from the request stack.
func _process_request_queue() -> void:
	if is_request_queue_full() or _requests.is_empty():
		return
	_make_request(_requests.pop_front())


## Used to check if queue for requests is fully used
func is_request_queue_full():
	return _requesting_count >= GameplaySettings.concurrent_http_requests


## Used to make a GET request against the Mirror RESTful API.
func get_request(key: int, url: String, aux: Dictionary={}) -> Promise:
	return _queue_request(HTTPClient.METHOD_GET, key, url, {}, true, aux)


## Used to make a GET request against an external resource.
## Initial use case is against GCStorage which doesn't like our headers.
func get_request_ext(key: int, url: String, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_GET, key, url, {}, false, aux)


## Used to make a POST request against the Mirror RESTful API.
func post_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_POST, key, url, body, true, aux)


## Used to make a POST request against an external resource
func post_request_ext(key: int, url: String, body: Variant, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_POST, key, url, body, false, aux)


## Used to make a PUT request against the Mirror RESTful API.
func put_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_PUT, key, url, body, true, aux)


## Used to make a PATCH request against the Mirror RESTful API.
func patch_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_PATCH, key, url, body, true, aux)


## Used to make a DELETE request against the Mirror RESTful API.
func delete_request(key: int, url: String, aux: Dictionary = {}) -> Promise:
	return _queue_request(HTTPClient.METHOD_DELETE, key, url, {}, true, aux)


## Used to make a GET request against an external resource.
## Initial use case is against GCStorage which doesn't like our headers.
## Returns HTTPRequest which can be quered for progress
func get_request_ext_with_http(key: int, url: String, aux: Dictionary={}) -> HTTPRequest:
	var request_dict: Dictionary = {
		"key": key,
		"url": url,
		"method": HTTPClient.METHOD_GET,
		"request_body": {},
		"use_base": false
	}
	if not aux.is_empty():
		request_dict.merge(aux)
	return _make_request(request_dict)


## Queues a request dict onto the request stack.
func _queue_request(method: int, key: int, url: String, body, use_base_url: bool = true, aux: Dictionary = {}) -> Promise:
	var request_dict: Dictionary = {
		"key": key,
		"url": url,
		"method": method,
		"request_body": body,
		"use_base": use_base_url
	}
	if not aux.is_empty():
		request_dict.merge(aux)
	var request_hash = request_dict.hash()
	request_dict["hash"] = request_hash
	var previously_queued = _requests.filter(func(x): return x["hash"] == request_hash)
	if not previously_queued.is_empty():
		request_dict = previously_queued[0]
	else:
		request_dict["promise"] = Promise.new()
		_requests.push_back(request_dict)
	return request_dict["promise"]


## Gets the base URL for the Mirror REST API.
func _get_base_url() -> String:
	if _base_url.is_empty():
		_base_url = ProjectSettings.get_setting("mirror/connection_server").trim_suffix("/")
	return _base_url



## Makes an HTTP Request to the Mirror REST API with a request dict.
func _make_request(request_data: Dictionary) -> HTTPRequest:
	if not request_data.has("url"):
		return
	var is_external = not request_data["use_base"]
	var base_url: String = _get_base_url() if not is_external else ""
	var url: String = base_url + request_data["url"]
	var http: HTTPRequest = HTTPRequest.new()
	http.use_threads = not GameplaySettings.force_single_threaded_mode
	add_child(http)
	var body = request_data["request_body"]
	var method: int = request_data["method"]
	var headers : Array = []
	var is_mixpanel = "api.mixpanel" in url
	# If the server is running and the url has not got a download present
	# We should throw a warning, because this should not happen!
	# Web socket should be used for the data.
	if Zone.is_host() and not url.contains("https://storage.googleapis.com/"):
		print("Legacy Code is using HTTP rather than WebSocket for Server Communication: ", request_data)
		push_error("Legacy Code is using HTTP rather than WebSocket for Server Communication: ", request_data)
		var token = Util.get_server_token()
		if token.is_empty():
			push_error("WSS Token is empty, required in server context for http requests")
		headers = _get_headers(token)
	else:
		headers = _get_headers(Firebase.Auth.get_jwt())
	var raw_request = false

	# HTTP requires we send an empty body length when there is no body
	if body.is_empty() and (method == HTTPClient.METHOD_PUT or method == HTTPClient.METHOD_POST):
		headers.append('Content-Length:0')

	if body is Dictionary:
		body = "" if body.is_empty() else JSON.stringify(body)
		headers.append("Content-Type: application/json")
	elif body is PackedByteArray:
		raw_request = true
		headers.append('Content-Type: multipart/form-data;boundary="WebKitFormBoundaryePkpFF7tjBAqx29L"')

	if is_external:
		headers = []
		body = "" 	
		# Manual override modification for external Mixpanel requests
		# the above "if is_external" code is bad because it strips the body and headers from all external requests
		# However, I'm unsure what already uses it so I'm extending instead of modifying
		# We really shouldn't be modifying resource-specific requests in this method though - Jared Apr 25 2024
		if is_mixpanel:
			headers = _get_mixpanel_headers(url)
			#headers = ["accept: */*", "content-type: application/x-www-form-urlencoded"]
			# format for application/x-www-form-urlencoded
			body = _get_mixpanel_body(url, request_data["request_body"])
		

	http.set_download_file(request_data.get("download_path", ""))
	var error = http.request_completed.connect(_request_completed.bind(request_data, http))
	if raw_request:
		error = http.request_raw(url, headers, method, body)
	else:
		if url.contains("https://api.mixpanel.com/engage#profile-set"):
			print('temp')
		error = http.request(url, headers, method, body)
	if error:
		push_error(str(error))
		# Request failed to be created, but we still need to fullfil Promise
		request_data["promise"].set_error("Request {0} failed REASON = {1}" % [request_data.get("url"), str(error)])
		return http
	_requesting_count += 1
	return http


## Function to set a Promise value. Can be modifed from inheting classes to
## further Specify the content of successful Promise based on request_data
func _promise_fulfill_successful(request_data: Dictionary, promise: Promise) -> void:
	promise.set_result(request_data)


func _extract_error_message(text_result: String) -> String:
	var json = TMFileUtil.parse_json_from_string(text_result)
	if json != null and json is Dictionary and json.has("message") and json.get("message") is String:
		return json.get("message")
	# return original text when extraction wasn't succesfull
	return text_result


## Signal for when a request is completed.
func _request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, request_data: Dictionary, http: HTTPRequest) -> void:
	request_data["result"] = result
	request_data["code"] = code
	request_data["body"] = body
	request_data["json_result"] = null
	request_data["json_parse_success"] = false
	request_data["response_text"] = ""
	if code >= 300 or code == 0:  # zero uninitialized?
		var prefix = "[server] " if Zone.is_host() else "[client] "
		print(prefix + "Error in http request: ", request_data.get("url"), " code: ", code)
		push_error(prefix + "Error in http request: ", request_data.get("url"), " code: ", code)
		if "mixpanel" in request_data.get("url"):
			print("temp")
		if request_data["body"] is PackedByteArray:
			request_data["response_text"] = request_data["body"].get_string_from_ascii()
			print(prefix + "Error response: ", request_data["response_text"])
		request_data["promise"].set_error(_extract_error_message(request_data["response_text"]))
	else:
		if not Util.filetype_supported(request_data["url"]) and code < 300:
			request_data["json_result"] = TMFileUtil.parse_json_from_string(body.get_string_from_ascii())
			request_data["json_parse_success"] = request_data["json_result"] != null
		_promise_fulfill_successful(request_data, request_data["promise"])
	http.request_completed.disconnect(_request_completed)
	_requesting_count = max(0, _requesting_count - 1)
	http.queue_free()
	# At this point Promise must be fulfilled
	assert(request_data["promise"].has_result() or request_data["promise"].is_error())


## Creates and returns a form data PackedByteArray for sending form data in a request body.
static func get_form_data(data_payload: PackedByteArray, mime_type: String, name := "file") -> PackedByteArray:
	var body: PackedByteArray = PackedByteArray()
	body.append_array("--WebKitFormBoundaryePkpFF7tjBAqx29L\r\n".to_utf8_buffer())
	body.append_array('Content-Disposition: form-data; name="{0}"; filename="filename"\r\n'.format([str(name)]).to_utf8_buffer())
	body.append_array(("Content-Type: %s\r\n\r\n" % mime_type).to_utf8_buffer())
	body.append_array(data_payload)
	body.append_array("\r\n--WebKitFormBoundaryePkpFF7tjBAqx29L--\r\n".to_utf8_buffer())
	return body


## Gets an array of header strings needed to connect to the Mirror REST API
func _get_headers(token: String = "") -> Array:
	var auth_header: String = "Authorization: Bearer %s" % token
	var version := Util.get_version_string()
	var app_type: String = "MirrorGodotServer" if Zone.is_host() else "MirrorGodotClient"
	var user_agent_header: String = "User-Agent: %s/%s" % [app_type, version]
	var accept_header: String = "Accept: */*"
	var headers: Array = [
		auth_header,
		user_agent_header,
		accept_header,
	]
	return headers

func _get_mixpanel_headers(url: String) -> Array:
	var headers: Array = []
	# Mixpanel oddly requires different headers depending on the route. This took hours of debugging to get right.
	if url.contains("api.mixpanel.com/track"):
		headers.append("accept: */*")
		headers.append("content-type: application/x-www-form-urlencoded")
	if url.contains("api.mixpanel.com/engage"):
		#headers.append("Accept: text/plain")
		#headers.append("Content-Type: application/json")
		#headers.append("Host: api.mixpanel.com")
		
		# temp test
		headers.append("accept: */*")
		headers.append("content-type: application/x-www-form-urlencoded")
	return headers
	
func _get_mixpanel_body(url: String, request_body):
	if url.contains("api.mixpanel.com/track"):
		var body_str = JSON.stringify(request_body)
		var body = 'data=%s&verbose=1' % body_str
		print('sending track event %s' % body)
		return body
	#if url.contains("api.mixpanel.com/engage"):
		#var body_str = JSON.stringify(request_body)
		#print('sending identify event %s' % body_str)
		#return body_str
	if url.contains("api.mixpanel.com/engage"):
		var body_str = JSON.stringify(request_body)
		var body = 'data=%s&verbose=1' % body_str
		print('sending identify event %s' % body_str)
		return body
