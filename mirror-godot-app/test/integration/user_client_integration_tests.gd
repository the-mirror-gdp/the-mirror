extends LoginIntegrationTest



## Initializes the UserClient integration test queue.
func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_get_current_user_info",
		&"test_get_current_user_name",
	])


func test_update_current_user_avatar() -> void:
	var url: String = "themirror://avatar/astronaut-male"
	var promise := Net.user_client.update_user_avatar(url)
	var profile = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
	elif profile["readyPlayerMeUrlGlb"] == "really test url":
		test_passed(profile["_id"])
	else:
		test_failed("profile did not update to expected data %s" % str(profile))



## Gets the current user's info
func test_get_current_user_info() -> void:
	var promise := Net.user_client.get_user_profile(Net.user_id)
	var user_info = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
	else:
		test_passed(user_info["_id"])



## Tries to get the current user name
func test_get_current_user_name() -> void:
	var user_name: String = Net.user_client.try_get_user_name(Net.user_id)
	if user_name.is_empty():
		test_failed("No username found for user id: %s" % Net.user_id)
	else:
		test_passed("Username %s found" % user_name)

