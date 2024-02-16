extends BaseIntegrationTest

const _FAKE_SPACE_ID: String = "62f688a9bae4akingrichard"

@onready var _test_ids: Dictionary = ProjectSettings.get_setting("mirror/integration_test_ids")
@onready var _TEST_SPACE_ID: String = _test_ids.get("space_id", "")
@onready var _TEST_ASSET_ID: String = _test_ids.get("asset_id", "")
@onready var _TEST_TERRAIN_ID: String = _test_ids.get("terrain_id", "")

var _test_space: Dictionary
var _test_terrain: Dictionary
var _test_space_object: Dictionary
var _script_entity_id: String
var _space_object_id: String
var _test_group_space_object: Dictionary
var _group_space_object_id: String
var _test_space_objects: Array = []

var _test_obj = {
	"massKg": 5,
	"name": "Test Space Object",
	"position": [0.0, 0.0, 0.0],
	"rotation": [0.0, 0.0, 0.0],
	"scale": [1.0, 1.0, 1.0],
	"offset": [0.0, 0.0, 0.0],
}


func _init() -> void:
	_test_queue = [
		&"test_setup_ws_connection",
		&"test_get_invalid_space_object",
		&"test_create_group_space_object",
		&"test_create_space_object",
		&"test_get_space_object",
		&"test_update_space_object",
		&"test_delete_space_object",
		&"test_delete_group_space_object",
		&"test_create_batch_space_object",
		&"test_create_batch_space_object",
		&"test_create_batch_space_object",
		&"test_update_batch_space_objects",
		&"test_get_batched_space_object",
		&"test_delete_batch_space_objects",
		&"test_get_asset",
		&"test_get_space",
		&"test_get_terrain",
		&"test_update_terrain",
		&"test_update_space",
		&"test_get_updated_space",
		&"test_get_space_not_found",
		&"test_update_zone_status",
		&"test_get_space_objects_page",
		&"test_publish_space",
		&"test_zone_create_script_entity",
		&"test_zone_get_script_entity",
		&"test_zone_update_script_entity",
		&"test_zone_delete_script_entity"
	]


func test_setup_ws_connection() -> void:
	Net.zone_socket.init_ws_client()
	Net.zone_socket.ws_connected.connect(_test_setup_ws_passed)


func _test_setup_ws_passed() -> void:
	Net.zone_socket.ws_connected.disconnect(_test_setup_ws_passed)
	test_passed("Successfully connected to WSS")


func test_get_space() -> void:
	Net.zone_socket.space_received.connect(_get_space_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.get_space(_TEST_SPACE_ID)


func test_get_space_objects_page() -> void:
	Net.zone_socket.space_objects_page_received.connect(_on_space_objects_page_received)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.get_space_objects_page(_TEST_SPACE_ID, 1)


func _on_space_objects_page_received(page: Dictionary) -> void:
	Net.zone_socket.space_objects_page_received.disconnect(_on_space_objects_page_received)
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed("page: %s" % page["page"])


func test_get_space_not_found() -> void:
	Net.zone_socket.space_received.connect(test_failed)
	Net.zone_socket.request_errored.connect(_get_space_not_found_success)
	Net.zone_socket.get_space(_FAKE_SPACE_ID)


func _get_space_not_found_success(_payload: Dictionary) -> void:
	Net.zone_socket.space_received.disconnect(test_failed)
	Net.zone_socket.request_errored.disconnect(_get_space_not_found_success)
	test_passed("No Space found")


func _get_space_success(payload: Dictionary) -> void:
	Net.zone_socket.space_received.disconnect(_get_space_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space = payload
	test_passed(payload["_id"])


func test_get_terrain() -> void:
	Net.zone_socket.terrain_received.connect(_get_terrain_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.get_terrain(_TEST_TERRAIN_ID)


func _get_terrain_success(payload: Dictionary) -> void:
	Net.zone_socket.terrain_received.disconnect(_get_terrain_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_terrain = payload
	test_passed(payload["_id"])


func test_update_terrain() -> void:
	_test_terrain["seed"] = _test_terrain["seed"] + 1
	Net.zone_socket.terrain_updated.connect(_update_terrain_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.update_terrain(_test_terrain)


func _update_terrain_success(payload: Dictionary) -> void:
	Net.zone_socket.terrain_updated.disconnect(_update_terrain_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload["_id"])


func test_update_space() -> void:
	Net.zone_socket.space_updated.connect(_update_space_success)
	Net.zone_socket.request_errored.connect(test_failed)
	_test_space["lowerLimitY"] = randi_range(-300, -100)
	Net.zone_socket.update_space(_test_space)


func _update_space_success(payload: Dictionary) -> void:
	Net.zone_socket.space_updated.disconnect(_update_space_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space = payload
	test_passed(payload["_id"])


func test_get_updated_space() -> void:
	Net.zone_socket.space_received.connect(_get_updated_space_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.get_space(_TEST_SPACE_ID)


func _get_updated_space_success(payload: Dictionary) -> void:
	Net.zone_socket.space_received.disconnect(_get_updated_space_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	if _test_space["lowerLimitY"] != payload["lowerLimitY"]:
		test_failed(payload)
	_test_space = payload
	test_passed(payload["_id"])


func test_get_asset() -> void:
	Net.zone_socket.asset_received.connect(_get_asset_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.queue_download_asset(_TEST_ASSET_ID)


func _get_asset_success(payload: Dictionary) -> void:
	Net.zone_socket.asset_received.disconnect(_get_asset_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload["_id"])


func test_create_space_object() -> void:
	Net.zone_socket.space_object_created.connect(_create_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	var space_obj = _test_obj.duplicate()
	space_obj["spaceId"] = _TEST_SPACE_ID
	space_obj["asset"] = _TEST_ASSET_ID
	space_obj["parentId"] = _test_group_space_object["_id"]
	var receipt = {}
	Net.zone_socket.create_space_object(space_obj, receipt)


func _create_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space_object = payload
	_space_object_id = payload["_id"]
	test_passed("%s: parentId: %s" % [payload["_id"], payload.get("parentId", "")])


func test_create_group_space_object() -> void:
	Net.zone_socket.space_object_created.connect(_create_group_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	var space_obj = _test_obj.duplicate()
	space_obj["spaceId"] = _TEST_SPACE_ID
	space_obj["asset"] = _TEST_ASSET_ID
	space_obj["isGroup"] = true
	var receipt = {}
	Net.zone_socket.create_space_object(space_obj, receipt)


func _create_group_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_group_space_object = payload
	_group_space_object_id = payload["_id"]
	test_passed("%s: isGroup: %s" % [payload["_id"], payload.get("isGroup", false)])


func test_create_batch_space_object() -> void:
	Net.zone_socket.space_object_created.connect(_create_batch_space_object_success)
	Net.zone_socket.request_errored.connect(test_failed)
	var space_obj = _test_obj.duplicate()
	space_obj["spaceId"] = _TEST_SPACE_ID
	space_obj["asset"] = _TEST_ASSET_ID
	var receipt = {}
	Net.zone_socket.create_space_object(space_obj, receipt)


func test_zone_create_script_entity_success(payload: Dictionary) -> void:
	_script_entity_id = payload["_id"]
	test_passed(payload["_id"])


func test_zone_create_script_entity() -> void:
	Net.zone_socket.script_entity_create.connect(test_zone_create_script_entity_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.create_script_entity({"name": "valid_test_script"}, Net.user_id)


func test_zone_get_script_entity() -> void:
	Net.zone_socket.script_entity_get.connect(test_zone_create_script_entity_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.get_script_entity(_script_entity_id)


func test_zone_update_script_entity_received(payload: Dictionary) -> void:
	_script_entity_id = payload["_id"]
	if payload["name"] != "new_test_script_not_old!":
		test_failed(payload)
	test_passed(payload["_id"])


func test_zone_update_script_entity() -> void:
	Net.zone_socket.script_entity_update.connect(test_zone_update_script_entity_received)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.update_script_entity(_script_entity_id, {"name": "new_test_script_not_old!"})


func test_zone_delete_script_entity() -> void:
	Net.zone_socket.script_entity_delete.connect(test_zone_create_script_entity_success)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.delete_script_entity(_script_entity_id)


func _create_batch_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.space_object_created.disconnect(_create_batch_space_object_success)
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space_objects.append(payload)
	test_passed(payload["_id"])


func test_update_batch_space_objects() -> void:
	Net.zone_socket.space_objects_updated.connect(_update_batch_space_objects_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	for o in _test_space_objects:
		o["position"] = [5.0, 0.0, 0.0]
	Net.zone_socket.update_space_objects(_test_space_objects)


func _update_batch_space_objects_success(payload: Array) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload.size())


func test_get_batched_space_object() -> void:
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.space_object_received.connect(_get_batched_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.get_space_object(_test_space_objects[0]["_id"])


func _get_batched_space_object_success(space_object: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	if space_object["position"][0] == 5:
		test_passed(space_object["_id"])
	else:
		test_failed("position == %s, expected 5." % str(space_object["position"]))


func test_delete_batch_space_objects() -> void:
	var ids = []
	for obj in _test_space_objects:
		ids.append(obj["_id"])
	Net.zone_socket.space_objects_deleted.connect(_delete_batch_space_objects_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.delete_space_objects(ids)


func _delete_batch_space_objects_success(payload: Array) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space_objects.clear()
	test_passed(payload.size())



func test_get_space_object() -> void:
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.space_object_received.connect(_get_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.get_space_object(_space_object_id)


func _get_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload["_id"])


func test_get_invalid_space_object() -> void:
	Net.zone_socket.space_object_received.connect(test_failed, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(_get_invalid_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.get_space_object(_space_object_id)


func _get_invalid_space_object_success(_payload: Variant) -> void:
	Net.zone_socket.space_object_received.disconnect(test_failed)
	test_passed("Invalid space object was not found")


func test_update_space_object() -> void:
	Net.zone_socket.space_object_updated.connect(_update_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	_test_space_object["massKg"] = null
	Net.zone_socket.update_space_object(_test_space_object)


func _update_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload["_id"])


func test_delete_space_object() -> void:
	Net.zone_socket.space_object_deleted.connect(_delete_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.delete_space_object(_test_space_object["_id"])


func _delete_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	_test_space_object = payload
	test_passed(payload["_id"])


func test_delete_group_space_object() -> void:
	Net.zone_socket.space_object_deleted.connect(_delete_group_space_object_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.delete_space_object(_test_group_space_object["_id"])


func _delete_group_space_object_success(payload: Dictionary) -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed(payload["_id"])


func test_update_zone_status() -> void:
	Net.zone_socket.zone_status_updated.connect(_update_zone_status_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.update_status({
		"players": 0,
		"secondsEmpty": 0,
		"mode": 0,
		"version": Util.get_version_string()
	})


func _update_zone_status_success() -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed("status updated")


func test_publish_space() -> void:
	Net.zone_socket.space_published.connect(_test_publish_space_success, CONNECT_ONE_SHOT)
	Net.zone_socket.request_errored.connect(test_failed)
	Net.zone_socket.publish_space(_TEST_SPACE_ID)


func _test_publish_space_success() -> void:
	Net.zone_socket.request_errored.disconnect(test_failed)
	test_passed("Space published")
