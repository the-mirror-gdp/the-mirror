class_name LoginService
extends Control


static func setup_deeplink_login(tree: SceneTree):
	Deeplinking.join_authed_space.connect(login_as_user_deeplink.bind(tree))


static func server_login_if_required(tree: SceneTree):
	var server_login_token = Util.get_commandline_id_val("server_login")
	if not server_login_token.is_empty():
		await login_as_user("", server_login_token, tree)
		print("Server successfully has logged into the backend for web socket authentication")


## Retrieves a profile for this firebase UID
## If one doesn't exist it will create it for you
## Returns an "error" dictionary on failure
static func get_latest_mirror_profile_or_create_it() -> Dictionary:
	var account_promise = Net.mirror_auth_client.create_account_if_missing()
	var mirror_profile = await account_promise.wait_till_fulfilled()
	if account_promise.is_error():
		return { "error: " : account_promise.get_error_message() }
	return mirror_profile


## wait until the user has logged in asyncronously
## I recommend you call it exactly like this:
## await LoginUI.wait_till_login(get_tree())
static func wait_till_login(scene_tree: SceneTree):
	# it is possible you use the code in this UI in a place where it may not be fully loaded
	# we ensure we have all the autoloads, and instances configured
	if not Firebase or not Firebase.Auth or not GameUI.login_ui:
		await scene_tree.process_frame
	# now we check are we fully logged into the app
	if Net.is_fully_logged_in() and Firebase.Auth.is_logged_in():
		return
	# we wait until this is the case since we weren't logged in
	await GameUI.login_ui.login_succeeded


static func login_as_user_deeplink(
	access_token: String,
	refresh_token: String,
	space_id: String,
	tree: SceneTree):
	await login_as_user(access_token, refresh_token, tree)
	print("Login completed with deeplink now proceding to join space!")
	Zone.client._on_deeplink_join_space_requested(space_id)


static func login_as_user(
	access_token: String,
	refresh_token: String,
	tree: SceneTree):
	var custom_auth_dict = {
		"refresh_token" = refresh_token
	}
	Firebase.Auth.manual_token_refresh(custom_auth_dict)
	var token = await Firebase.Auth.token_refresh_succeeded
	var mirror_profile: Dictionary = await get_latest_mirror_profile_or_create_it()
	if mirror_profile.has("error"):
		# Notify.error(tr("Login Failed"), mirror_profile.error)
		Firebase.Auth.remove_auth()
		Firebase.Auth.logout()
		return
	fully_log_in_user(mirror_profile, Firebase.Auth.auth)
	print("Waiting for login to complete before joining space")
	await LoginService.wait_till_login(tree)


static func fully_log_in_user(mirror_profile: Dictionary, auth_result: Dictionary) -> bool:
	if not auth_result.has("idtoken") or not auth_result.has("localid"):
		push_error("Invalid login data passed to fully logged in check")
		return false

	if mirror_profile.is_empty():
		push_error("Invalid profile")
		return false

	if not mirror_profile.has("displayName"):
		push_error("Invalid profile missing name")
		return false
	Firebase.Auth.get_user_data()
	Net.fully_log_in_user_with_profile(mirror_profile, auth_result)
	return true
