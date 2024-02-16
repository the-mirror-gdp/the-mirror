@tool
## @meta-authors Nicolò 'fenix' Santilio,
## @meta-version 2.5
##
## (source: [url=https://firebase.google.com/docs/functions]Functions[/url])
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki/Functions

class_name FirebaseFunctions extends Node

## Emitted when a  [code]query()[/code] request is successfully completed. [code]error()[/code] signal will be emitted otherwise.
## @arg-types Array
## Emitted when a [code]list()[/code] or [code]query()[/code] request is [b]not[/b] successfully completed.
signal task_error(code,status,message)

# TODO: Implement cache size limit
const CACHE_SIZE_UNLIMITED = -1

const _CACHE_EXTENSION : String = ".fscache"
const _CACHE_RECORD_FILE : String = "RmlyZXN0b3JlIGNhY2hlLXJlY29yZHMu.fscache"

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _MAX_POOLED_REQUEST_AGE = 30

## The code indicating the request Firestore is processing.
## See @[enum FirebaseFirestore.Requests] to get a full list of codes identifiers.
## @enum Requests
var request : int = -1

## Whether cache files can be used and generated.
## @default true
var persistence_enabled : bool = true

## Whether an internet connection can be used.
## @default true
var networking: bool = true :
	set = set_networking


## A Dictionary containing all authentication fields for the current logged user.
## @type Dictionary
var auth : Dictionary

var _config : Dictionary = {}
var _cache_loc: String
var _encrypt_key: String = "" if OS.get_name() in ["HTML5", "UWP"] else OS.get_unique_id()

var _base_url : String =  ""

var _http_request_pool : Array = []

var _offline: bool = false :
	set = _set_offline


func _ready() -> void:
	pass

func _process(delta : float) -> void:
	for i in range(_http_request_pool.size() - 1, -1, -1):
		var request = _http_request_pool[i]
		if not request.get_meta("requesting"):
			var lifetime: float = request.get_meta("lifetime") + delta
			if lifetime > _MAX_POOLED_REQUEST_AGE:
				request.queue_free()
				_http_request_pool.remove_at(i)
			request.set_meta("lifetime", lifetime)


## @args
## @return FunctionTask
func execute(function: String, method: int, params: Dictionary = {}, body: Dictionary = {}) -> FunctionTask:
	var function_task : FunctionTask = FunctionTask.new()
	function_task.connect("task_error", self._on_task_error)
	function_task.connect("task_finished", self._on_task_finished)
	function_task.connect("function_executed", self._on_function_executed)

	function_task._method = method

	var url : String = _base_url + ("/" if not _base_url.ends_with("/") else "") + function
	function_task._url = url

	if not params.is_empty():
		url += "?"
		for key in params.keys():
			url += key + "=" + params[key] + "&"

	if not body.is_empty():
		function_task._headers = PackedStringArray(["Content-Type: application/json"])
		function_task._fields = JSON.stringify(body)

	_pooled_request(function_task)
	return function_task


func set_networking(value: bool) -> void:
	if value:
		enable_networking()
	else:
		disable_networking()


func enable_networking() -> void:
	if networking:
		return
	networking = true
	_base_url = _base_url.replace("storeoffline", "functions")


func disable_networking() -> void:
	if not networking:
		return
	networking = false
	# Pointing to an invalid url should do the trick.
	_base_url = _base_url.replace("functions", "storeoffline")


func _set_offline(value: bool) -> void:
	if value == _offline:
		return

	_offline = value
	if not persistence_enabled:
		return

	return


func _set_config(config_json : Dictionary) -> void:
	_config = config_json
	_cache_loc = _config.cacheLocation if _config.cacheLocation else ""

	if _encrypt_key == "": _encrypt_key = _config.apiKey
	_check_emulating()


func _check_emulating() -> void :
	## Check emulating
	if not Firebase.emulating:
		_base_url = "https://{zone}-{projectId}.cloudfunctions.net/".format({ zone = _config.functionsGeoZone, projectId = _config.projectId })
	else:
		var port : String = _config.emulators.ports.functions
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Cloud Functions has not been configured.")
		else:
			_base_url = "http://localhost:{port}/{projectId}/{zone}/".format({ port = port, zone = _config.functionsGeoZone, projectId = _config.projectId })


func _pooled_request(task : FunctionTask) -> void:
	if _offline:
		task._on_request_completed(HTTPRequest.RESULT_CANT_CONNECT, 404, PackedStringArray(), PackedByteArray())
		return

	if not auth.is_empty():
		Firebase._print("Unauthenticated request issued...")
		Firebase.Auth.login_anonymous()
		var result: Array = await Firebase.Auth.auth_request
		if result[0] != 1:
			_check_auth_error(result[0], result[1])
		Firebase._print("Client connected as Anonymous")


	task._headers = Array(task._headers) + [_AUTHORIZATION_HEADER + auth.idtoken]

	var http_request : HTTPRequest
	for request in _http_request_pool:
		if not request.get_meta("requesting"):
			http_request = request
			break

	if not http_request:
		http_request = HTTPRequest.new()
		_http_request_pool.append(http_request)
		add_child(http_request)
		http_request.request_completed.connect(_on_pooled_request_completed.bind(http_request))

	http_request.set_meta("requesting", true)
	http_request.set_meta("lifetime", 0.0)
	http_request.set_meta("task", task)
	http_request.request(task._url, task._headers, task._method, task._fields)


# -------------

func _on_task_finished(data : Dictionary) :
	pass

func _on_function_executed(result : int, data : Dictionary) :
	pass

func _on_task_error(code : int, status : int, message : String):
	emit_signal("task_error", code, status, message)
	Firebase._printerr(message)

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
	auth = auth_result


func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
	auth = auth_result


func _on_pooled_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, request : HTTPRequest) -> void:
	request.get_meta("task")._on_request_completed(result, response_code, headers, body)
	request.set_meta("requesting", false)


func _on_connect_check_request_completed(result : int, _response_code, _headers, _body) -> void:
	_set_offline(result != HTTPRequest.RESULT_SUCCESS)
	#_connect_check_node.request(_base_url)


func _on_FirebaseAuth_logout() -> void:
	auth = {}

func _check_auth_error(code : int, message : String) -> void:
	var err : String
	match code:
		400: err = "Please, enable Anonymous Sign-in method or Authenticate the Client before issuing a request (best option)"
	Firebase._printerr(err)
