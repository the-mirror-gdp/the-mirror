extends LoginIntegrationTest


var _created_test_asset_id: String = ""

var _test_space_data: Dictionary
var _test_space_object_data: Dictionary

var _test_duplicated_space_data: Dictionary
var _test_duplicated_space_object: Dictionary


func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_create_space",
		&"test_create_fake_space",
		&"test_get_current_user_spaces",
		&"test_get_space",
		&"test_get_fake_space",
		&"test_clear_voxels",
		&"test_update_space",
		&"test_get_updated_space",
		&"test_update_fake_space",
		&"test_create_asset",
		&"test_create_space_object",
		&"test_get_space_object",
		&"test_update_space_object",
		&"test_get_space_objects",
		&"test_publish_space",
		&"test_get_published_spaces",
		&"test_duplicate_space",
		&"test_get_duplicated_space_objects",
		# cleanup
		&"test_delete_space_object",
		&"test_delete_space",
		&"test_delete_duplicated_space_object",
		&"test_delete_duplicated_space",
		&"test_delete_asset",
	])


func _fail_on_promise_error(promise: Promise) -> void:
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


## Test: Creates a space with valid data
func test_create_space() -> void:
	var new_space_data: Dictionary = {
		"name": "Test Space",
		"type": "OPEN_WORLD",
		"template": "space_template",
	}
	var promise = Net.space_client.create_space(new_space_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_space_data = promise.get_result()
	test_passed(_test_space_data["_id"])


func test_publish_space() -> void:
	var space_id = _test_space_data["_id"]
	var promise = Net.space_client.publish_space(space_id)
	var space = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(space.get("_id"))


func test_get_published_spaces() -> void:
	var space_id = _test_space_data["_id"]
	var promise = Net.space_client.get_published_space_versions(space_id)
	var versions = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	if versions.size() > 0:
		test_passed("Received Published Space Versions: %s" % str(versions.size()))
	else:
		test_failed("Expected at least 1 published version.")


func test_duplicate_space() -> void:
	var space_id = _test_space_data["_id"]
	var promise = Net.space_client.duplicate_space(space_id)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_duplicated_space_data = space_data
	if _test_space_data["name"] == space_data["name"]:
		test_passed(space_data["_id"])
	else:
		test_failed("Space name was not the same: %s != %s" % [_test_space_data["name"], space_data["name"]])


## Test: Attempts to create a space with invalid data
func test_create_fake_space() -> void:
	var invalid_space_data: Dictionary = {
		"fake_name": "Fake Name Space",
	}
	var promise = Net.space_client.create_space(invalid_space_data)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_passed("Invalid space was not created")
		return
	test_failed("Created space with missing data %s" % str(space_data))



## Test: Creates an asset with the minimum requirements.
func test_create_asset() -> void:
	var asset_data: Dictionary = {
		"name": "Test Asset",
		"assetType": Enums.ASSET_TYPE.MESH,
	}
	Net.asset_client.asset_created.connect(_asset_created_success, CONNECT_ONE_SHOT)
	_fail_on_promise_error(Net.asset_client.create_asset(asset_data))


## Pass: Sets the new asset as test_asset_data
func _asset_created_success(asset_data: Dictionary) -> void:
	_created_test_asset_id = asset_data["_id"]
	test_passed("Created test asset: %s" % _created_test_asset_id)


## Test: Deletes the test asset
func test_delete_asset() -> void:
	Net.asset_client.asset_deleted.connect(_asset_deleted_success, CONNECT_ONE_SHOT)
	_fail_on_promise_error(Net.asset_client.delete_asset(_created_test_asset_id))


## Pass: Deleted the asset
func _asset_deleted_success(asset: Dictionary) -> void:
	test_passed("Deleted space %s" % asset["_id"])


## Test to create a space object
func test_create_space_object() -> void:
	var space_id = _test_space_data["_id"]
	var asset_id = _created_test_asset_id
	var promise = Net.space_client.create_space_object(space_id, asset_id)
	var payload = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_space_object_data = payload
	test_passed(payload["_id"])


## Test to get a space object.
func test_get_space_object() -> void:
	var promise = Net.space_client.get_space_object(_test_space_object_data["_id"])
	var payload = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(payload["_id"])


## Test updating a space object.
func test_update_space_object() -> void:
	_test_space_object_data["name"] = "its a test"
	_test_space_object_data["position"] = [100.0, 50.0, 0.0]
	var promise = Net.space_client.update_space_object(_test_space_object_data)
	var payload = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	var passed = payload["name"] == "its a test"
	if passed:
		test_passed(payload["_id"])
	else:
		test_failed("Space object update did not change name value: %s" % str(payload))


## Test to get all space objects belonging to a Space.
func test_get_duplicated_space_objects() -> void:
	var space_id = _test_duplicated_space_data["_id"]
	var promise = Net.space_client.get_space_objects(space_id)
	var space_objects = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	var size = space_objects.size()
	var passed = size > 0
	if passed:
		_test_duplicated_space_object = space_objects[0]
		test_passed("Received %s space objects " % str(size))
	else:
		test_failed("Did not receive any space objects: %s" % str(size))


## Test to get all space objects belonging to a Space.
func test_get_space_objects() -> void:
	var space_id = _test_space_data["_id"]
	var promise = Net.space_client.get_space_objects(space_id)
	var space_objects = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	var size = space_objects.size()
	var passed = size > 0
	if passed:
		test_passed("Received %s space objects " % str(size))
	else:
		test_failed("Did not receive any space objects: %s" % str(size))


## Test: Deletes the test space object
func test_delete_space_object() -> void:
	var promise = Net.space_client.delete_space_object(_test_space_object_data["_id"])
	var space_object_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Deleted space object %s" % space_object_data["_id"])


## Test: Gets the current user's spaces
func test_get_current_user_spaces() -> void:
	var parameters = SpaceClient.SpaceListRequestParameters.new()
	var promise = Net.space_client.get_current_user_spaces(parameters)
	var spaces = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	if spaces.size() > 0:
		test_passed("Received User Spaces (Count: %s)" % str(spaces.size()))
	else:
		test_failed("Received current user spaces, but list is is_empty. Expected at LEAST 1 space.")


## Test: Gets a valid space with the provided id
func test_get_space() -> void:
	var promise = Net.space_client.get_space(_test_space_data["_id"])
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(space_data["_id"])


func test_clear_voxels() -> void:
	var promise = Net.space_client.clear_voxels(_test_space_data["_id"])
	var id = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(id)


## Test: Gets a non-existant space with the provided id
func test_get_fake_space() -> void:
	var promise = Net.space_client.get_space("fake_space_id")
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_passed("Fake space was not returned: %s" % promise.get_error_message())
		return
	test_failed("Invalid space received %s" % str(space_data))


## Test: Updates an existing space with valid data
func test_update_space() -> void:
	var updated_space_data: Dictionary = {
		"name": "Updated Space Name",
		"lowerLimitY": randi_range(-300, -100),
	}
	var promise = Net.space_client.update_space(_test_space_data["_id"], updated_space_data)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_space_data = space_data
	test_passed("Space successfully updated %s" % space_data["_id"])


## Test: Gets the updated space with the provided id
func test_get_updated_space() -> void:
	var promise = Net.space_client.get_space(_test_space_data["_id"])
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	if _test_space_data["lowerLimitY"] != space_data["lowerLimitY"]:
		test_failed(space_data)
	test_passed(space_data["_id"])


## Test: Attempts to update a space that doesn't exist
func test_update_fake_space() -> void:
	var fake_space_data: Dictionary = {
		"fake_id": "12345",
		"name": "Fake Updated Space Name",
	}
	var promise = Net.space_client.update_space(fake_space_data["fake_id"], fake_space_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_passed("Fake space was not updated: %s" % [promise.get_error_message()])
		return
	test_failed("Update to non-existant space returned as success")


## Test: Deletes the test space
func test_delete_space() -> void:
	var promise = Net.space_client.delete_space(_test_space_data["_id"])
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Deleted space %s" % space_data["_id"])


## Test: Deletes the test space
func test_delete_duplicated_space() -> void:
	var promise = Net.space_client.delete_space(_test_duplicated_space_data["_id"])
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Deleted space %s" % space_data["_id"])


## Test: Deletes the test space object
func test_delete_duplicated_space_object() -> void:
	var promise = Net.space_client.delete_space_object(_test_duplicated_space_object["_id"])
	var space_object_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Deleted space object %s" % space_object_data["_id"])
