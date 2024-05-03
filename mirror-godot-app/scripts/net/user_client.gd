class_name UserClient
extends MirrorHttpClient

enum {
	GET_USER,
	GET_USER_RECENTS,
	UPDATE_USER_PROFILE,
	UPDATE_USER_AVATAR,
	UPDATE_USER_TUTORIAL,
	GET_PRIVATE_PROFILE,
	SEARCH,
	GET_ENTITY_ACTION_STATS,
	GET_ENTITY_ACTION,
	UPSERT_ENTITY_ACTION,
	DELETE_ENTITY_ACTION,
	CREATE_ACCOUNT,
}

var _current_user_profile: Dictionary = {}
var current_user_auth_user_data: Dictionary
var user_profiles: Dictionary = {}

signal user_first_login()
signal user_profile_data_loaded(profile_data: Dictionary)


func _firebase_auth_userdata_received(userdata: FirebaseUserData) -> void:
	current_user_auth_user_data = userdata._to_dictionary()
	if current_user_auth_user_data["last_login_at"] == 0:
		user_first_login.emit()


func create_account(data: Dictionary) -> Promise:
	return self.post_request(CREATE_ACCOUNT, "/auth/email-password", data)


func get_current_user_profile() -> Dictionary:
	return _current_user_profile


## This is only intended to be called when logging in or refreshing.
func set_current_user_profile(profile: Dictionary) -> void:
	assert(profile["_id"] == Net.user_id, "The user profile ID doesn't match the current user ID.")
	_current_user_profile = profile
	user_profiles[Net.user_id] = profile
	user_profile_data_loaded.emit(profile)


## This is only intended to be called when logging out.
func logout_reset_current_user_profile() -> void:
	_current_user_profile = {}


## Gets the user profile of the provided user id.
## If the user profile is already in memory,
## the success signal is called automatically.
func get_user_profile(uid: String) -> Promise:
	# cache causes avatar loading issues so we disabled the cache
	# the user profile cannot be cached unless we can expire it on all clients and the server
	# in the meantime its better to leave a comment
	#if user_profiles.has(uid):
	#	var promise_fulfilled = Promise.new()
	#	promise_fulfilled.set_result(user_profiles[uid])
	#	return promise_fulfilled
	return self.get_request(GET_USER, "/user/id/%s" % uid)


## Get the user's private profile
func get_user_private_profile() -> Promise:
	return self.get_request(GET_PRIVATE_PROFILE, "/user/me")


## Search for users that fits the query
func search_users(query: String) -> Promise:
	return self.get_request(SEARCH, "/user/search?query=%s" % query)


func get_user_recents() -> Promise:
	return self.get_request(GET_USER_RECENTS, "/user/recents/me")


## updates the current user's profile
func update_user_profile(profile_data: Dictionary) -> Promise:
	return self.patch_request(UPDATE_USER_PROFILE, "/user/profile", profile_data)


## updates the current user's avatar
func update_user_avatar(avatar_url: String) -> Promise:
	var request_body: Dictionary = {
		"avatarUrl": avatar_url,
	}
	return self.patch_request(UPDATE_USER_AVATAR, "/user/avatar", request_body)


## updates the current user's tutorial state
func update_user_tutorial(tutorial_data: Dictionary) -> Promise:
	return self.patch_request(UPDATE_USER_TUTORIAL, "/user/tutorial", tutorial_data)


## gets the entity actions stats for a given ID
func get_entity_action_stats(entity_id: String) -> Promise:
	return self.get_request(GET_ENTITY_ACTION_STATS, "/user/entity-action/for-entity/%s" % entity_id)


## gets the entity actions for an user for a given ID
func get_entity_action(entity_id: String) -> Promise:
	return self.get_request(GET_ENTITY_ACTION, "/user/entity-action/me/for-entity/%s" % entity_id)


## create/update the entity action for an user
func upsert_entity_action(enitity_action: Dictionary) -> Promise:
	return self.patch_request(UPSERT_ENTITY_ACTION, "/user/entity-action", enitity_action)


## delete the entity action for an user
func delete_entity_action(enitity_action_id: String) -> Promise:
	return self.delete_request(DELETE_ENTITY_ACTION, "/user/entity-action/%s" % enitity_action_id)


## Tries to get the user name with the user id. Returns is_empty string if name doesn't exist in memory.
func try_get_user_name(uid: String) -> String:
	if user_profiles.has(uid) and user_profiles[uid].has("displayName"):
		return user_profiles[uid]["displayName"]
	return ""


func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	var parsed_result = request.get("json_result")
	if parsed_result == null:
		push_error("UserClient request succeeded but parsed result is null. %s" % str(request))
		promise.set_error("UserClient request succeeded but parsed result is null. %s" % str(request))
		return
	var key = request.get("key")
	# We cache the user_profile to later compare the old_avatar to the new_avatar
	if key in [GET_USER, UPDATE_USER_PROFILE, UPDATE_USER_AVATAR, GET_PRIVATE_PROFILE]:
		# TODO: backend is changing analytics user to this
		_refresh_profile(parsed_result)
	promise.set_result(parsed_result)


## Success method when a user profile is received.
## Loads user data into memory and emits a signal.
func _refresh_profile(user_profile: Dictionary) -> void:
	var user_id: String = user_profile["_id"]
	user_profiles[user_id] = user_profile
	if user_id == Net.user_id:
		set_current_user_profile(user_profile)
		# If there's an email on the profile, identify it to Analytics
		if user_profile.get("email"):
			Analytics.identify_user_email(user_id, user_profile.email)
