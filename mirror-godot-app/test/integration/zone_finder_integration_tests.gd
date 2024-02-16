extends LoginIntegrationTest

var _created_test_space_id: String = ""
var _created_test_spaceversion_id: String = ""

var _test_created_zone: Dictionary
var _test_space_zone: Dictionary
var _user_zones: Array = []
var _ready_zones: Array = []


## Initializes the UserClient integration test queue.
func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_create_space",
		&"test_create_space_version",
		&"test_delete_space",
	])


## Test: Creates a space for testing
func test_create_space() -> void:
	var new_space_data: Dictionary = {
		"name": "Test Space",
		"type": "OPEN_WORLD",
		"template": "space_template",
	}
	var promise = Net.space_client.create_space(new_space_data)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_created_test_space_id = space_data["_id"]
	test_passed(space_data["_id"])


func test_create_space_version() -> void:
	var promise = Net.space_client.publish_space(_created_test_space_id)
	var space_published = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_created_test_spaceversion_id = space_published["_id"]
	test_passed(space_published)


## Test: Deletes the test space
func test_delete_space() -> void:
	var promise = Net.space_client.delete_space(_created_test_space_id)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Deleted space %s" % space_data["_id"])
