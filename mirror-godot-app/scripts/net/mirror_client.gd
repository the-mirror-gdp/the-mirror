## Deprecated, use MirrorHttpClient instead.
class_name MirrorClient
extends Node


signal request_completed(request: Dictionary)
signal request_errored(request: Dictionary)

var _base_url: String
var _requests: Array = Array()
var _requesting_count: int = 0
var _requests_completed: Array = Array()


## Initializes the client. Automatically called.
func _init() -> void:
	_setup_client()


## Sets up the client to listen to signals handling requests completing.
# TODO: replace that String parameter with a Callable instead directly
func _setup_client() -> void:
	request_completed.connect(Callable(self, "_handle_request_completed"))


## Process runs every frame.
func _process(_delta: float) -> void:
	_process_request_queue()
	_process_request_signals()


## Process method makes requests one at a time from the request stack.
func _process_request_queue() -> void:
	if is_request_queue_full() or _requests.is_empty():
		return
	_make_request(_requests.pop_front())


## Process method emits signals of completed requests.
func _process_request_signals() -> void:
	if _requests_completed.is_empty():
		return
	var request = _requests_completed.pop_front()
	if request["code"] >= 300 or request["code"] == 0: # zero uninitialized?
		request_errored.emit(request)
		return
	request_completed.emit(request)


## Used to check if queue for requests is fully used
func is_request_queue_full():
	return _requesting_count >= GameplaySettings.concurrent_http_requests


## Used to make a GET request against the Mirror RESTful API.
func get_request(key: int, url: String, aux: Dictionary={}) -> void:
	_queue_request(HTTPClient.METHOD_GET, key, url, {}, true, aux)


## Used to make a GET request against an external resource.
## Initial use case is against GCStorage which doesn't like our headers.
func get_request_ext(key: int, url: String, aux: Dictionary = {}) -> void:
	_queue_request(HTTPClient.METHOD_GET, key, url, {}, false, aux)


## Used to make a POST request against the Mirror RESTful API.
func post_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> void:
	_queue_request(HTTPClient.METHOD_POST, key, url, body, true, aux)


## Used to make a PUT request against the Mirror RESTful API.
func put_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> void:
	_queue_request(HTTPClient.METHOD_PUT, key, url, body, true, aux)


## Used to make a PATCH request against the Mirror RESTful API.
func patch_request(key: int, url: String, body: Variant, aux: Dictionary = {}) -> void:
	_queue_request(HTTPClient.METHOD_PATCH, key, url, body, true, aux)


## Used to make a DELETE request against the Mirror RESTful API.
func delete_request(key: int, url: String, aux: Dictionary = {}) -> void:
	_queue_request(HTTPClient.METHOD_DELETE, key, url, {}, true, aux)


## Used to make a GET request against an external resource.
## Initial use case is against GCStorage which doesn't like our headers.
## Returns HTTPRequest which can be quered for progress
func get_request_ext_with_http(key: int, url: String, aux: Dictionary={}) -> HTTPRequest:
	var request_dict: Dictionary = {
		"key": key,
		"url": url,
		"method": HTTPClient.METHOD_GET,
		"request_body": {},
		"use_base": false,
	}
	if not aux.is_empty():
		request_dict.merge(aux)
	return _make_request(request_dict)

## Queues a request dict onto the request stack.
func _queue_request(method: int, key: int, url: String, body, use_base_url: bool = true, aux: Dictionary = {}) -> void:
	var request_dict: Dictionary = {
		"key": key,
		"url": url,
		"method": method,
		"request_body": body,
		"use_base": use_base_url,
	}
	if not aux.is_empty():
		request_dict.merge(aux)
	_requests.push_back(request_dict)


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
	if Zone.is_host():
		var token = Util.get_server_token()
		if token.is_empty():
			push_error("WSS Token is empty, required in server context for http requests")
		headers = _get_headers(token)
	else:
		headers = _get_headers(Firebase.Auth.get_jwt())
	var raw_request = false
	if body is Dictionary:
		body = "" if body.is_empty() else JSON.stringify(body)
		headers.append("Content-Type: application/json")
	elif body is PackedByteArray:
		raw_request = true
		headers.append('Content-Type: multipart/form-data;boundary="WebKitFormBoundaryePkpFF7tjBAqx29L"')

	var ssl = true
	if is_external:
		ssl = false
		headers = []
		body = ""

	http.set_download_file(request_data.get("download_path", ""))
	var error = http.request_completed.connect(_request_completed.bind(request_data, http))
	if raw_request:
		error = http.request_raw(url, headers, method, body)
	else:
		error = http.request(url, headers, method, body)
	if error:
		push_error(str(error))
		return http
	_requesting_count += 1
	return http


## Signal for when a request is completed.
func _request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, request_data: Dictionary, http: HTTPRequest) -> void:
	request_data["result"] = result
	request_data["code"] = code
	request_data["body"] = body
	request_data["json_result"] = null
	request_data["json_parse_success"] = false
	request_data["response_text"] = ""
	if code >= 300:
		var prefix = "[client] "
		if Zone.is_host():
			prefix = "[server] "
		print(prefix + "Error in http request: ", request_data.get("url"), " code: ", code)
		push_error(prefix + "Error in http request: ", request_data.get("url"), " code: ", code)
		if request_data["body"] is PackedByteArray:
			request_data["response_text"] = request_data["body"].get_string_from_ascii()
			print(prefix + "Error response: ", request_data["response_text"])
	#else: this is useful for debugging but off by default (adds much more cycles)
		#print(prefix + "Success http request: ", request_data.get("url"), " code: ", code)
	if not Util.filetype_supported(request_data["url"]) and code < 300:
		request_data["json_result"] = TMFileUtil.parse_json_from_string(body.get_string_from_ascii())
		request_data["json_parse_success"] = request_data["json_result"] != null
	_requests_completed.push_back(request_data)
	http.request_completed.disconnect(_request_completed)
	_requesting_count = max(0, _requesting_count - 1)
	http.queue_free()


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
