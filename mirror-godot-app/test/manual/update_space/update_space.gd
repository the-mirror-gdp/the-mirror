extends LoginIntegrationTest


const SPACE_ID = "62ec0ec7bdd116f9f040c0bb"


func _init() -> void:
	_test_queue.append_array([
		"login_firebase",
		"test_update_space",
	])


func test_update_space() -> void:
	var updated_space_data: Dictionary = {
		# Place the new data you wish to apply here.
	}
	var promise = Net.space_client.update_space(SPACE_ID, updated_space_data)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Space update failed: %s" % [promise.get_error_message()])
		return
	print("Space successfully updated %s" % space_data["_id"])
