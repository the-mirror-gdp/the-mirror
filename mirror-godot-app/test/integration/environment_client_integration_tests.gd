extends LoginIntegrationTest


var _test_environment: Dictionary


func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_create_environment",
		&"test_get_environment",
		&"test_update_environment",
		&"test_delete_environment",
	])


## Test: Creates environment
func test_create_environment() -> void:
	var new_environment: Dictionary = {
		"fogEnabled": false,
		"sunCount": 1
	}
	Net.environment_client.environment_created.connect(_environment_created_pass, CONNECT_ONE_SHOT)
	Net.environment_client.request_errored.connect(test_failed)
	Net.environment_client.create_environment(new_environment)


## Pass: created a new environment
func _environment_created_pass(environment: Dictionary) -> void:
	Net.environment_client.request_errored.disconnect(test_failed)
	_test_environment = environment
	test_passed(environment["_id"])


## Test: Gets a environment entity
func test_get_environment() -> void:
	Net.environment_client.environment_received.connect(_environment_received_pass, CONNECT_ONE_SHOT)
	Net.environment_client.request_errored.connect(test_failed)
	Net.environment_client.get_environment(_test_environment["_id"])


## Pass: created a new environment
func _environment_received_pass(environment: Dictionary) -> void:
	Net.environment_client.request_errored.disconnect(test_failed)
	test_passed(environment["_id"])


## Test: update environment
func test_update_environment() -> void:
	_test_environment["name"] = "updated environment"
	_test_environment["fogEnabled"] = true
	_test_environment["sunCount"] = 3
	Net.environment_client.environment_updated.connect(_environment_updated_pass, CONNECT_ONE_SHOT)
	Net.environment_client.request_errored.connect(test_failed)
	Net.environment_client.update_environment(_test_environment)


## Pass: updated a environment
func _environment_updated_pass(environment: Dictionary) -> void:
	Net.environment_client.request_errored.disconnect(test_failed)
	if environment["fogEnabled"] != true:
		test_failed("Environment updated failed, expected fogEnabled to be true.")
		return
	if environment["sunCount"] != 3:
		test_failed("Environment updated failed, expected sunCount to be 3.")
		return
	test_passed(environment["_id"])


## Test: Delete a environment
func test_delete_environment() -> void:
	Net.environment_client.environment_deleted.connect(_environment_deleted_pass, CONNECT_ONE_SHOT)
	Net.environment_client.request_errored.connect(test_failed)
	Net.environment_client.delete_environment(_test_environment["_id"])


## Pass: deleted a environment
func _environment_deleted_pass(environment: Dictionary) -> void:
	Net.environment_client.request_errored.disconnect(test_failed)
	test_passed(environment["_id"])
