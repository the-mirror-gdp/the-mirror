extends LoginIntegrationTest


var _test_group_data: Dictionary


func _init() -> void:
	_test_queue.append_array([
		# TODO: Re-enable group creation and deletion when Group deletion on API is fixed.
		#"test_create_group",
		&"test_create_group_invalid_data",
		&"test_user_groups_received",
		#"test_delete_group",
	])


## Creates a group with valid data
func test_create_group() -> void:
	var new_group_data = {
		"name": "Test Group"
	}
	Net.group_client.group_created.connect(_group_created_pass)
	Net.group_client.request_errored.connect(test_failed)
	Net.group_client.create_group(new_group_data)


## Pass: Creates a group successfully
func _group_created_pass(group_data: Dictionary) -> void:
	_test_group_data = group_data
	Net.group_client.group_created.disconnect(_group_created_pass)
	Net.group_client.request_errored.disconnect(test_failed)
	test_passed("Group created successfully %s" % str(group_data["_id"]))


## Test deleting a group.
func test_delete_group() -> void:
	Net.group_client.group_deleted.connect(_group_deleted_pass)
	Net.group_client.request_errored.connect(test_failed)
	Net.group_client.delete_group(_test_group_data["_id"])


## Pass: deleted a group successfully
func _group_deleted_pass(group_data: Dictionary) -> void:
	_test_group_data = group_data
	Net.group_client.group_created.disconnect(_group_deleted_pass)
	Net.group_client.request_errored.disconnect(test_failed)
	test_passed("Group deleted successfully %s" % str(group_data["_id"]))


## Attempts to create a group with invalid data. Should get a request error.
func test_create_group_invalid_data() -> void:
	Net.group_client.group_created.connect(_create_group_invalid_data_fail)
	Net.group_client.request_errored.connect(_create_group_invalid_data_pass)
	Net.group_client.create_group({})


## Pass: Group did not create with invalid data.
func _create_group_invalid_data_pass(_group_data: Dictionary) -> void:
	Net.group_client.group_created.disconnect(_create_group_invalid_data_fail)
	Net.group_client.request_errored.disconnect(_create_group_invalid_data_pass)
	test_passed("Group did not create with invalid data.")


## Fail: A group was created even though data was invalid data.
## The API should have thrown an error.
func _create_group_invalid_data_fail(group_data: Dictionary) -> void:
	Net.group_client.group_created.disconnect(_create_group_invalid_data_fail)
	Net.group_client.request_errored.disconnect(_create_group_invalid_data_pass)
	test_failed("Group was created with invalid data! id: %s" % str(group_data["_id"]))


## Gets the groups from the current user
func test_user_groups_received() -> void:
	Net.group_client.user_groups_received.connect(_user_groups_received_pass)
	Net.group_client.request_errored.connect(test_failed)
	Net.group_client.get_current_user_groups()


## Pass: Gets the groups that the current logged in user is a part of
func _user_groups_received_pass(groups: Array) -> void:
	Net.group_client.user_groups_received.disconnect(_user_groups_received_pass)
	Net.group_client.request_errored.disconnect(test_failed)
	test_passed("Current user groups: %s" % str(groups.size()))
