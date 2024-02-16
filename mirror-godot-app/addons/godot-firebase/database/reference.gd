@tool
## @meta-authors TODO
## @meta-version 2.3
## A reference to a location in the Realtime Database.
## Documentation TODO.

class_name FirebaseDatabaseReference extends Node

signal new_data_update(data)
signal patch_data_update(data)
signal delete_data_update(data)

signal push_successful()
signal push_failed()

const ORDER_BY : String = "orderBy"
const LIMIT_TO_FIRST : String = "limitToFirst"
const LIMIT_TO_LAST : String = "limitToLast"
const START_AT : String = "startAt"
const END_AT : String = "endAt"
const EQUAL_TO : String = "equalTo"

var _pusher : HTTPRequest
var _listener : Node
var _store : FirebaseDatabaseStore
var _auth : Dictionary
var _config : Dictionary
var _filter_query : Dictionary
var _db_path : String
var _cached_filter : String
var _push_queue : Array = []
var _update_queue : Array = []
var _delete_queue : Array = []
var _can_connect_to_host : bool = false

const _put_tag : String = "put"
const _patch_tag : String = "patch"
const _delete_tag : String = "delete"
const _separator : String = "/"
const _json_list_tag : String = ".json"
const _query_tag : String = "?"
const _auth_tag : String = "auth="
const _accept_header : String = "accept: text/event-stream"
const _auth_variable_begin : String = "["
const _auth_variable_end : String = "]"
const _filter_tag : String = "&"
const _escaped_quote : String = '"'
const _equal_tag : String = "="
const _key_filter_tag : String = "$key"

var _headers : PackedStringArray = []

func set_db_path(path : String, filter_query_dict : Dictionary) -> void:
	_db_path = path
	_filter_query = filter_query_dict

func set_auth_and_config(auth_ref : Dictionary, config_ref : Dictionary) -> void:
	_auth = auth_ref
	_config = config_ref

func set_pusher(pusher_ref : HTTPRequest) -> void:
	if !_pusher:
		_pusher = pusher_ref
		add_child(_pusher)
		_pusher.connect("request_completed", self.on_push_request_complete)

func set_listener(listener_ref : Node) -> void:
	if !_listener:
		_listener = listener_ref
		add_child(_listener)
		_listener.connect("new_sse_event", self.on_new_sse_event)
		var base_url = _get_list_url(false).trim_suffix(_separator)
		var extended_url = _separator + _db_path + _get_remaining_path(false)
		var port = -1
		if Firebase.emulating:
			port = int(_config.emulators.ports.realtimeDatabase)
		_listener.connect_to_host(base_url, extended_url, port)

func on_new_sse_event(headers : Dictionary, event : String, data : Dictionary) -> void:
	if data:
		var command = event
		if command and command != "keep-alive":
			_route_data(command, data.path, data.data)
			if command == _put_tag:
				if data.path == _separator and data.data and data.data.keys().size() > 0:
					for key in data.data.keys():
						emit_signal("new_data_update", FirebaseResource.new(_separator + key, data.data[key]))
				elif data.path != _separator:
					emit_signal("new_data_update", FirebaseResource.new(data.path, data.data))
			elif command == _patch_tag:
				emit_signal("patch_data_update", FirebaseResource.new(data.path, data.data))
			elif command == _delete_tag:
				emit_signal("delete_data_update", FirebaseResource.new(data.path, data.data))
	pass

func set_store(store_ref : FirebaseDatabaseStore) -> void:
	if !_store:
		_store = store_ref
		add_child(_store)

func update(path : String, data : Dictionary) -> void:
	path = path.strip_edges(true, true)

	if path == _separator:
		path = ""

	var to_update = JSON.stringify(data)
	var status = _pusher.get_http_client_status()
	if status == HTTPClient.STATUS_DISCONNECTED || status != HTTPClient.STATUS_REQUESTING:
		var resolved_path = (_get_list_url() + _db_path + "/" + path + _get_remaining_path())

		_pusher.request(resolved_path, _headers, HTTPClient.METHOD_PATCH, to_update)
	else:
		_update_queue.append({"path": path, "data": data})

func push(data : Dictionary) -> void:
	var to_push = JSON.stringify(data)
	if _pusher.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_pusher.request(_get_list_url() + _db_path + _get_remaining_path(), _headers, HTTPClient.METHOD_POST, to_push)
	else:
		_push_queue.append(data)

func delete(reference : String) -> void:
	if _pusher.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_pusher.request(_get_list_url() + _db_path + _separator + reference + _get_remaining_path(), _headers, HTTPClient.METHOD_DELETE, "")
	else:
		_delete_queue.append(reference)

#
# Returns a deep copy of the current local copy of the data stored at this reference in the Firebase
# Realtime Database.
#
func get_data() -> Dictionary:
	if _store == null:
		return { }

	return _store.get_data()

func _get_remaining_path(is_push : bool = true) -> String:
	var remaining_path = ""
	if !_filter_query.is_empty() or is_push:
		remaining_path = _json_list_tag + _query_tag + _auth_tag + Firebase.Auth.auth.idtoken
	else:
		remaining_path = _json_list_tag + _query_tag + _get_filter() + _filter_tag + _auth_tag + Firebase.Auth.auth.idtoken

	if Firebase.emulating:
		remaining_path += "&ns="+_config.projectId+"-default-rtdb"

	return remaining_path

func _get_list_url(with_port:bool = true) -> String:
	var url = Firebase.Database._base_url.trim_suffix(_separator)
	if with_port and Firebase.emulating:
		url += ":" + _config.emulators.ports.realtimeDatabase
	return url + _separator


func _get_filter():
	if !_filter_query.is_empty():
		return ""
	# At the moment, this means you can't dynamically change your filter; I think it's okay to specify that in the rules.
	if !_cached_filter.is_empty():
		_cached_filter = ""
		if _filter_query.has(ORDER_BY):
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _filter_query[ORDER_BY] + _escaped_quote
			_filter_query.erase(ORDER_BY)
		else:
			_cached_filter += ORDER_BY + _equal_tag + _escaped_quote + _key_filter_tag + _escaped_quote # Presumptuous, but to get it to work at all...
		for key in _filter_query.keys():
			_cached_filter += _filter_tag + key + _equal_tag + _filter_query[key]

	return _cached_filter

#
# Appropriately updates the current local copy of the data stored at this reference in the Firebase
# Realtime Database.
#
func _route_data(command : String, path : String, data) -> void:
	if command == _put_tag:
		_store.put(path, data)
	elif command == _patch_tag:
		_store.patch(path, data)
	elif command == _delete_tag:
		_store.delete(path, data)

func on_push_request_complete(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		emit_signal("push_successful")
	else:
		emit_signal("push_failed")

	if _push_queue.size() > 0:
		push(_push_queue.pop_front())
		return
	if _update_queue.size() > 0:
		var e = _update_queue.pop_front()
		update(e['path'], e['data'])
		return
	if _delete_queue.size() > 0:
		delete(_delete_queue.pop_front())
