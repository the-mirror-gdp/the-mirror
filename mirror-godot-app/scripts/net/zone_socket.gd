class_name ZoneSocketClient
extends Node


signal ws_connected()
signal asset_received(asset: Dictionary)
signal space_received(space: Dictionary)
signal space_version_received(spaceversion: Dictionary)
signal environment_updated(environment: Dictionary)
signal terrain_received(terrain: Dictionary)
signal terrain_updated(terrain: Dictionary)
signal space_published()
signal space_updated(space: Dictionary)
signal space_variables_updated(space: Dictionary)
signal space_update_received(space_partial_update: Dictionary)

signal space_object_created(space_object: Dictionary, receipt: Dictionary)
signal space_object_received(space_object: Dictionary)
signal space_object_updated(space_object: Dictionary)
signal space_object_deleted(space_object: Dictionary)
signal space_objects_deleted(space_object_ids: Array)
signal space_objects_updated(space_objects: Array)
signal space_objects_received(space_objects: Array)
signal space_objects_page_received(space_objects_page: Dictionary)

signal request_completed(payload)
signal request_errored(request)
signal zone_status_updated()

signal script_entity_create(script: Dictionary)
signal script_entity_get(script: Dictionary)
signal script_entity_update(script: Dictionary)
signal script_entity_delete(script: Dictionary)

signal material_instance_created(material: Dictionary)
signal material_instance_received(material: Dictionary)
signal material_instance_updated(material: Dictionary)
signal material_instance_deleted(material: Dictionary)

const ZONE_GET_ASSET = "zone_get_asset"
const ZONE_GET_SPACE = "zone_get_space"
const ZONE_GET_SPACE_VERSION = "zone_get_space_version"
const ZONE_GET_TERRAIN = "zone_get_terrain"
const ZONE_UPDATE_SPACE = "zone_update_space"
const ZONE_UPDATE_SPACE_VARIABLES = "zone_update_space_variables"
const ZONE_UPDATE_STATUS = "zone_update_status"
const ZONE_UPDATE_ENVIRONMENT = "zone_update_environment"
const ZONE_UPDATE_TERRAIN = "zone_update_terrain"
const ZONE_GET_SPACE_OBJECT = "zone_get_space_object"
const ZONE_UPDATE_SPACE_OBJECT = "zone_update_space_object"
const ZONE_UPDATE_BATCH_SPACE_OBJECTS = "zone_update_batch_space_objects"
const ZONE_DELETE_BATCH_SPACE_OBJECTS = "zone_delete_batch_space_objects"
const ZONE_DELETE_SPACE_OBJECT = "zone_delete_space_object"
const ZONE_CREATE_SPACE_OBJECT = "zone_create_space_object"
const ZONE_GET_SPACE_OBJECTS_PAGE = "zone_get_space_objects_page"
const ZONE_PUBLISH_SPACE = "zone_publish_space"

const ZONE_CREATE_SCRIPT_ENTITY = "zone_create_script_entity"
const ZONE_GET_SCRIPT_ENTITY = "zone_get_script_entity"
const ZONE_UPDATE_SCRIPT_ENTITY = "zone_update_script_entity"
const ZONE_DELETE_SCRIPT_ENTITY = "zone_delete_script_entity"

const ZONE_CREATE_MATERIAL_INSTANCE = "zone_create_material_instance"
const ZONE_GET_MATERIAL_INSTANCE = "zone_get_material_instance"
const ZONE_UPDATE_MATERIAL_INSTANCE = "zone_update_material_instance"
const ZONE_DELETE_MATERIAL_INSTANCE = "zone_delete_material_instance"

const PUBSUB_SPACE_OBJECT_CREATE = "space_object_create"
const PUBSUB_SPACE_OBJECT_UPDATE = "space_object_update"
const PUBSUB_SPACE_OBJECT_DELETE = "space_object_delete"
const PUBSUB_SPACE_UPDATED = "space_updated"

# static peer id for any websocket connection to its server is 1
const _WS_SERVER_PEER_ID: int = 1
const _CONNECT_RETRY_MS: int = 1000

var _ws_client: WebSocketClient
var _ws_connection_failed: bool
var _next_reconnect_time: int
var _zone_server_uuid: String
var _requests: Array = Array()
var _asset_ids_queued: Array = Array()
var _requests_dict: Dictionary = Dictionary()
var _request_promise_list: Dictionary = {}

func _get_ws_url() -> String:
	return str(ProjectSettings.get_setting("mirror/connection_server_ws")).trim_suffix("/")


## Initializes the websocket connection to the Mirror API.
func init_ws_client() -> void:
	assert(Zone.is_host())
	_next_reconnect_time = 0
	_zone_server_uuid = Util.get_commandline_id_val("uuid")
	_ws_client = WebSocketClient.new()
	add_child(_ws_client)
	var _err = 0
	_err = _ws_client.connection_closed.connect(_ws_connection_closed)
	_err = _ws_client.connected_to_server.connect(_ws_connected)
	_err = _ws_client.message_received.connect(_on_ws_data_received)
	var url: String = _get_ws_url()
	var secret = Util.get_server_token()
	var headers = [
		"Authorization: %s" % secret,
		"space: %s" % Zone.server.space_id,
		"zone: %s" % _zone_server_uuid
	]
	print("connecting ws to %s" % url)
	_ws_client.handshake_headers = headers
	_ws_client.tls_verify = false
	var error = _ws_client.connect_to_url(url)
	if error != OK:
		print("Unable to connect to WS Server: %s. (%s)" % [url, error])
		push_error("Unable to connect to WS Server: %s" % url)
		_ws_connection_failed = true
		return


func _ws_connection_closed() -> void:
	_next_reconnect_time = Time.get_ticks_msec() + _CONNECT_RETRY_MS
	print("WS Connection closed.")


func _ws_connected() -> void:
	print("WS Connected")
	ws_connected.emit()


func _send_ws_data(payload: Dictionary) -> void:
	var event_id: String = payload.get("data", {}).get("eventId", "")
	if event_id.is_empty():
		event_id = UUID.generate_guid()
		payload["data"]["eventId"] = event_id
	var packet_str: String = JSON.stringify(payload)
	_requests_dict[event_id] = payload
	var _err = _ws_client.send(packet_str)
	if _err != OK:
		push_error("Failed to send WS packet: ", packet_str)
		return
	print_ws_pending_requests(packet_str, true)


func print_ws_pending_requests(packet_sent: String, send_context: bool = false):
	if not ProjectSettings.get_setting("debug_flags/show_web_socket_debug", false):
		return
	# used for debugging only
	var context = "[WSS recv]\n" + packet_sent + "\n"
	if send_context:
		context = "[WSS sent]\n" + packet_sent + "\n"
	print(context, "Pending Request's ", _requests_dict)


func _on_ws_data_received(message: Variant) -> void:
	var string_data = message
	var json_result = TMFileUtil.parse_json_from_string(string_data)
	var event_id: String = json_result["eventId"]

	# pub sub message before requests_dict since those events are not requested by Godot
	if event_id == "sub":
		_handle_pubsub_message(json_result)
		return


	var request: Dictionary = _requests_dict.get(event_id)

	if _requests_dict.has(event_id):
		var erased = _requests_dict.erase(event_id)
		if not erased:
			push_error("Failed to delete request by id", event_id)
	else:
		push_error("No request corresponder found for event id %s" % event_id)
		push_error("Request info", json_result)
		return

	print_ws_pending_requests(message, false)


	# if it is a paginated result, pass all of the page data as a dictionary to the signal
	if json_result.has("page"):
		request["json_result"] = json_result
	# otherwise, return the simple result as expected
	else:
		request["json_result"] = json_result.get("result", "")
	if json_result.has("status"):
		var status: int = json_result["status"]
		if status >= 300:
			push_error("WS: Status code ", status, " result: ", json_result)
			if _request_promise_list.has(event_id):
				_request_promise_list[event_id].set_error(str(json_result))
				_request_promise_list.erase(event_id)
			request_errored.emit(request)
			return
	_handle_websocket_message(request)


func _process(_delta) -> void:
	_process_ws_client()
	_process_request_queue()


func _process_ws_client() -> void:
	if not _ws_client:
		return
	if _should_try_reconnect():
		init_ws_client()


## Process method makes requests one at a time from the request stack.
func _process_request_queue() -> void:
	if _requests.is_empty():
		return
	var current_request = _requests.pop_front()
	_send_ws_data(current_request)


func _should_try_reconnect() -> bool:
	return _next_reconnect_time > 0 and Time.get_ticks_msec() > _next_reconnect_time


func get_space(space_id: String) -> Promise:
	var promise: Promise = Promise.new()
	var event_id: String = UUID.generate_guid()
	var request = {
		"event": ZONE_GET_SPACE,
		"data": {
			"id": space_id,
			"eventId": event_id
		}
	}
	_requests.push_back(request)
	_request_promise_list[event_id] = promise
	return promise


func get_space_version(space_version_id: String) -> Promise:
	var promise: Promise = Promise.new()
	var event_id: String = UUID.generate_guid()
	var request = {
		"event": ZONE_GET_SPACE_VERSION,
		"data": {
			"spaceVersionId": space_version_id,
			"eventId": event_id
		}
	}
	_requests.push_back(request)
	_request_promise_list[event_id] = promise
	return promise


func publish_space(space_id: String) -> void:
	var request = {
		"event": ZONE_PUBLISH_SPACE,
		"data": { "id": space_id }
	}
	_requests.push_back(request)


func update_environment(environment: Dictionary) -> void:
	var environment_id = str(environment.get("_id", ""))
	if environment_id.is_empty():
		return
	var request = {
		"event": ZONE_UPDATE_ENVIRONMENT,
		"data": {
			"id": environment_id,
			"dto": environment
		}
	}
	_requests.push_back(request)


func get_terrain(terrain_id: String) -> void:
	var request = {
		"event": ZONE_GET_TERRAIN,
		"data": { "id": terrain_id }
	}
	_requests.push_back(request)


func update_terrain(terrain: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_TERRAIN,
		"data": {
			"id": terrain["_id"],
			"dto": terrain
		}
	}
	_requests.push_back(request)


func update_status(status: Dictionary) -> void:
	status["uuid"] = _zone_server_uuid
	var request = {
		"event": ZONE_UPDATE_STATUS,
		"data": status
	}
	_requests.push_back(request)


func get_space_objects_page(space_id: String, page: int=1) -> void:
	var request = {
		"event": ZONE_GET_SPACE_OBJECTS_PAGE,
		"data": { "id": space_id, "page": page, "perPage": 40 }
	}
	_requests.push_back(request)


func queue_download_asset(asset_id: String) -> Promise:
	var promise: Promise = Promise.new()
	var event_id: String = UUID.generate_guid()
	var request = {
		"event": ZONE_GET_ASSET,
		"data": {
			"id": asset_id,
			"eventId": event_id
		}
	}
	_asset_ids_queued.append(asset_id)
	_requests.push_back(request)
	_request_promise_list[event_id] = promise
	return promise


func update_space(space: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_SPACE,
		"data": {
			"id": space["_id"],
			"dto": space
		}
	}
	_requests.push_back(request)


func update_space_variables(space: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_SPACE,
		"data": {
			"id": space["_id"],
			"dto": space
		}
	}
	_requests.push_back(request)


func create_space_object(space_object: Dictionary, receipt: Dictionary) -> void:
	if not space_object.has("spaceId"):
		space_object["spaceId"] = Zone.server.space_id
	assert(space_object.spaceId == Zone.server.space_id)
	var request: Dictionary = {
		"event": ZONE_CREATE_SPACE_OBJECT,
		"data": {
			"dto": space_object
		}
	}
	assert(not space_object.has("receipt"), "The SpaceObject itself should not have the receipt in it.")
	if not receipt.is_empty():
		request["receipt"] = receipt
	_requests.push_back(request)


func get_space_object(object_id: String) -> void:
	var request = {
		"event": ZONE_GET_SPACE_OBJECT,
		"data": { "id": object_id }
	}
	_requests.push_back(request)


func delete_space_object(object_id: String) -> void:
	var request = {
		"event": ZONE_DELETE_SPACE_OBJECT,
		"data": { "id": object_id }
	}
	_requests.push_back(request)


func delete_space_objects(object_ids: Array) -> void:
	var request = {
		"event": ZONE_DELETE_BATCH_SPACE_OBJECTS,
		"data": { "batch": object_ids }
	}
	_requests.push_back(request)


func update_space_object(space_object: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_SPACE_OBJECT,
		"data": {
			"id": space_object["_id"],
			"dto": space_object,
		}
	}
	_requests.push_back(request)


func create_script_entity(script_entity: Dictionary, from_user: String) -> void:
	var request = {
		"event": ZONE_CREATE_SCRIPT_ENTITY,
		"data": {
			"dto": script_entity,
			"fromUser": from_user,
		}
	}
	_requests.push_back(request)


func get_script_entity(id: String) -> void:
	var request = {
		"event": ZONE_GET_SCRIPT_ENTITY,
		"data": {
			"id": id,
		}
	}
	_requests.push_back(request)


func update_script_entity(id: String, script_entity: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_SCRIPT_ENTITY,
		"data": {
			"id": id,
			"dto": script_entity,
		}
	}
	_requests.push_back(request)


func delete_script_entity(id: String) -> void:
	var request = {
		"event": ZONE_DELETE_SCRIPT_ENTITY,
		"data": {
			"id": id,
		}
	}
	_requests.push_back(request)


func create_material_instance(space_id: String, material: Dictionary) -> void:
	material["spaceId"] = space_id
	var request = {
		"event": ZONE_CREATE_MATERIAL_INSTANCE,
		"data": {
			"dto": material,
		}
	}
	_requests.push_back(request)


func get_material_instance(space_id: String, id: String) -> void:
	var request = {
		"event": ZONE_GET_MATERIAL_INSTANCE,
		"data": {
			"spaceId": space_id,
			"materialInstanceId": id,
		}
	}
	_requests.push_back(request)


func update_material_instance(space_id: String, id: String, material: Dictionary) -> void:
	var request = {
		"event": ZONE_UPDATE_MATERIAL_INSTANCE,
		"data": {
			"spaceId": space_id,
			"materialInstanceId": id,
			"dto": material,
		}
	}
	_requests.push_back(request)


func delete_material_instance(space_id: String, id: String) -> void:
	var request = {
		"event": ZONE_DELETE_MATERIAL_INSTANCE,
		"data": {
			"space_id": space_id,
			"materialInstanceId": id,
		}
	}
	_requests.push_back(request)


func update_space_objects(space_objects: Array) -> void:
	var max_slice_size: int = 50
	for i in range(0, space_objects.size(), max_slice_size):
		var sliced = space_objects.slice(i, mini(i + max_slice_size, space_objects.size()), 1)
		var request = {
			"event": ZONE_UPDATE_BATCH_SPACE_OBJECTS,
			"data": { "batch": sliced }
		}
		_requests.push_back(request)


func _handle_pubsub_space_updated(message: Dictionary) -> void:
	var update = {
		"space_id": message.get("id", ""),
		"partial_data": message.get("eventData", {})
	}
	space_update_received.emit(update)


func _handle_pubsub_message(message: Dictionary) -> void:
	var event: String = message.get("event", "")
	var object_id: String = message.get("id", "")
	if object_id.is_empty():
		push_error("missing parameter `object_id` in pubsub message: %s" % str(message))
		return
	match event:
		PUBSUB_SPACE_OBJECT_CREATE: get_space_object(object_id)
		PUBSUB_SPACE_OBJECT_UPDATE: get_space_object(object_id)
		PUBSUB_SPACE_OBJECT_DELETE: space_object_deleted.emit({"_id": object_id})
		PUBSUB_SPACE_UPDATED: _handle_pubsub_space_updated(message)


## Signal routes a successful request to the appropriate complete method.
func _handle_websocket_message(request: Dictionary) -> void:
	var json_result = request["json_result"]
	if json_result == null:
		request_errored.emit(request)
		if request["event"] in [ZONE_GET_ASSET, ZONE_GET_SPACE, ZONE_GET_SPACE_VERSION]:
			var event_id = request["data"]["eventId"]
			_request_promise_list[event_id].set_error(request)
			_request_promise_list.erase(event_id)
		return
	match request["event"]:
		ZONE_GET_ASSET:
			if _asset_ids_queued.has(request["data"]["id"]):
				_asset_ids_queued.erase(request["data"]["id"])
			var event_id = request["data"]["eventId"]
			_request_promise_list[event_id].set_result(json_result)
			_request_promise_list.erase(event_id)
			asset_received.emit(json_result)
		ZONE_GET_SPACE:
			var event_id = request["data"]["eventId"]
			_request_promise_list[event_id].set_result(json_result)
			_request_promise_list.erase(event_id)
			space_received.emit(json_result)
		ZONE_GET_SPACE_VERSION:
			var event_id = request["data"]["eventId"]
			_request_promise_list[event_id].set_result(json_result)
			_request_promise_list.erase(event_id)
			space_version_received.emit(json_result)
		ZONE_GET_TERRAIN:
			terrain_received.emit(json_result)
		ZONE_UPDATE_SPACE:
			space_updated.emit(json_result)
		ZONE_UPDATE_SPACE_VARIABLES:
			space_variables_updated.emit(json_result)
		ZONE_UPDATE_ENVIRONMENT:
			environment_updated.emit(json_result)
		ZONE_UPDATE_TERRAIN:
			terrain_updated.emit(json_result)
		ZONE_GET_SPACE_OBJECT:
			space_object_received.emit(json_result)
		ZONE_GET_SPACE_OBJECTS_PAGE:
			space_objects_page_received.emit(json_result)
		ZONE_UPDATE_SPACE_OBJECT:
			space_object_updated.emit(json_result)
		ZONE_UPDATE_BATCH_SPACE_OBJECTS:
			space_objects_updated.emit(request["data"]["batch"])
		ZONE_DELETE_BATCH_SPACE_OBJECTS:
			space_objects_deleted.emit(request["data"]["batch"])
		ZONE_DELETE_SPACE_OBJECT:
			space_object_deleted.emit(json_result)
		ZONE_CREATE_SPACE_OBJECT:
			_handle_create_space_object_success(request)
		ZONE_UPDATE_STATUS:
			zone_status_updated.emit()
		ZONE_PUBLISH_SPACE:
			space_published.emit()
		ZONE_CREATE_SCRIPT_ENTITY:
			script_entity_create.emit(json_result)
		ZONE_GET_SCRIPT_ENTITY:
			script_entity_get.emit(json_result)
		ZONE_UPDATE_SCRIPT_ENTITY:
			script_entity_update.emit(json_result)
		ZONE_DELETE_SCRIPT_ENTITY:
			script_entity_delete.emit(json_result)
		ZONE_CREATE_MATERIAL_INSTANCE:
			json_result.merge(request.get("data", {}).get("dto", {}))
			material_instance_created.emit(json_result)
		ZONE_GET_MATERIAL_INSTANCE:
			material_instance_received.emit(json_result)
		ZONE_UPDATE_MATERIAL_INSTANCE:
			material_instance_updated.emit(json_result)
		ZONE_DELETE_MATERIAL_INSTANCE:
			material_instance_deleted.emit(json_result)


func _handle_create_space_object_success(request_dictionary: Dictionary) -> void:
	var new_space_object = request_dictionary["json_result"]
	assert(not new_space_object.has("receipt"), "The SpaceObject itself should not have the receipt in it.")
	space_object_created.emit(new_space_object, request_dictionary.get("receipt", {}))
