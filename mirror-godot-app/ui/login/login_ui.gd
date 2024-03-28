class_name LoginUI
extends Control

# The design should follow this paradigm:
# 1. Login to firebase.
# 2. On success get or create the mirror profile for the user.
# 3. Now you can go to the main menu and use authed requests safely.

signal login_succeeded()

var _test_accts: Array = []
var busy: bool = false

@onready var _connect_popup: Panel = $VBoxContainer/ConnectPopup
@onready var _sign_in_menu: Panel = $VBoxContainer/SignInMenu
@onready var _sign_in_vbox: VBoxContainer = %LoginContainer
@onready var _email_field: LineEdit = %LoginContainer/Username
@onready var _password_field: LineEdit = %LoginContainer/Password

@onready var _register_vbox: VBoxContainer = %RegisterContainer
@onready var _register_display_name: LineEdit = %RegisterContainer/DisplayName
@onready var _register_email: LineEdit = %RegisterContainer/Email
@onready var _register_password: LineEdit = %RegisterContainer/Password
@onready var _register_confirm_password: LineEdit = %RegisterContainer/ConfirmPassword
@onready var _register_tos_checkbox: CheckBox = %RegisterContainer/ToS/ToSCheckbox



# For dev login help. Dev build only
@onready var _dev_login_options: OptionButton = _sign_in_vbox.get_node(^"DevLoginOptions")
@onready var _remember_me_checkbox: CheckBox = %RememberMe


## Called when the game is started
## You should call this once, and also only on booting the app but not when the
## Server is booted.
func start_login_ui() -> void:
	assert(not Zone.is_host())
	_email_field.grab_focus()
	_email_field.text = ""
	_password_field.text = ""
	_remember_me_checkbox.button_pressed = GameplaySettings.login_remember_me
	_populate_dev_options_button()
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_UI_READY)
	Firebase.Auth.login_succeeded.connect(_on_login_succeeded)
	Firebase.Auth.login_failed.connect(_on_login_failed)
	Firebase.Auth.signup_succeeded.connect(_guest_signup_succeeded)
	Firebase.Auth.userdata_received.connect(Net.user_client._firebase_auth_userdata_received)
	Firebase.Auth.logged_out.connect(_logged_out)
	Deeplinking.join_authed_space.connect(_deeplink_login_as_user)
	if Firebase.Auth.check_auth_file() and not Deeplinking.has_join_command_with_auth():
		var mirror_profile: Dictionary = await get_latest_mirror_profile_or_create_it()
		if mirror_profile.has("error"):
			Notify.error(tr("Login Failed"), mirror_profile.error)
			Firebase.Auth.remove_auth()
			Firebase.Auth.logout()
			return
		_fully_log_in_user(mirror_profile, Firebase.Auth.auth)


func login_game_server_to_backend(access_token: String, refresh_token: String, space_id: String):
	await _deeplink_login_as_user(access_token, refresh_token, space_id)


func _deeplink_login_as_user(access_token: String, refresh_token: String, space_id: String):
	var custom_auth_dict = {
		"refresh_token" = refresh_token
	}
	Firebase.Auth.manual_token_refresh(custom_auth_dict)
	var token = await Firebase.Auth.token_refresh_succeeded
	var mirror_profile: Dictionary = await get_latest_mirror_profile_or_create_it()
	if mirror_profile.has("error"):
		Notify.error(tr("Login Failed"), mirror_profile.error)
		Firebase.Auth.remove_auth()
		Firebase.Auth.logout()
		return
	_fully_log_in_user(mirror_profile, Firebase.Auth.auth)
	print("Waiting for login to complete before joining space")
	await LoginUI.wait_till_login(get_tree())
	print("Login completed with deeplink now proceding to join space!")
	Zone.client._on_deeplink_join_space_requested(space_id)


func _logged_out():
	_connect_popup.hide()
	_sign_in_menu.show()
	# don't call remove_auth here; that's handled by the Firebase addon when logout() is called. Otherwise, Remember Me will fail


## Retrieves a profile for this firebase UID
## If one doesn't exist it will create it for you
## Returns an "error" dictionary on failure
func get_latest_mirror_profile_or_create_it() -> Dictionary:
	var account_promise = Net.mirror_auth_client.create_account_if_missing()
	var mirror_profile = await account_promise.wait_till_fulfilled()
	if account_promise.is_error():
		return { "error: " : account_promise.get_error_message() }
	return mirror_profile


func _guest_signup_succeeded(acc: Dictionary) -> void:
	var mirror_profile: Dictionary = await get_latest_mirror_profile_or_create_it()
	if mirror_profile.has("error"):
		Notify.error(tr("Guest Login Failed"), mirror_profile.error)
		Firebase.Auth.remove_auth()
		Firebase.Auth.logout()
		return
	_fully_log_in_user(mirror_profile, Firebase.Auth.auth)


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


## hide the login ui pane
func hide_login_ui():
	busy = false
	hide()
	_sign_in_menu.hide()
	_connect_popup.show()


func _fully_log_in_user(mirror_profile: Dictionary, auth_result: Dictionary) -> bool:
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
	hide_login_ui()
	login_succeeded.emit()
	Notify.success("Welcome %s" % mirror_profile.get("displayName", ""), "")
	if _remember_me_checkbox.button_pressed:
		Firebase.Auth.save_auth(Firebase.Auth.auth)
	GameplaySettings.login_remember_me = _remember_me_checkbox.button_pressed
	return true


# Triggers when the login is successful
func _on_login_succeeded(auth_result: Dictionary) -> void:
	busy = true
	var account_promise = Net.mirror_auth_client.create_account_if_missing()
	var mirror_profile = await account_promise.wait_till_fulfilled()

	if account_promise.is_error():
		push_error("Failed to get profile from server: ", account_promise.get_error_message())
		Notify.error(tr("Login Failed"), tr(account_promise.get_error_message()))
		Firebase.Auth.remove_auth()
		Firebase.Auth.logout()
		busy = false
		return

	if not _fully_log_in_user(mirror_profile, auth_result):
		Notify.error("Failed to login", "please report this")
	busy = false



# Triggers when the login fails
func _on_login_failed(_code: int, message: String) -> void:
	busy = false
	push_error("Login Failed: %s" % message)
	_connect_popup.hide()
	_sign_in_menu.show()
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_USER_FAIL, {"code": _code, "message": message})
	Notify.error("Login Failed", message)


# Triggers when the Google Login button is pressed
func _on_google_login_pressed() -> void:
	if busy:
		return
	OS.shell_open(ProjectSettings.get_setting("mirror/base_url"))
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_GOOGLE_PRESSED)


# Triggers when the Discord Login button is pressed
func _on_discord_login_pressed() -> void:
	if busy:
		return
	OS.shell_open(ProjectSettings.get_setting("mirror/base_url"))
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_DISCORD_PRESSED)


# Triggers when the Facebook Login button is pressed
func _on_facebook_login_pressed() -> void:
	if busy:
		return
	OS.shell_open(ProjectSettings.get_setting("mirror/base_url"))
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_FACEBOOK_PRESSED)


# Triggers when the user presses enter while email or password fields are focused
func _on_text_submitted(_new_text: String) -> void:
	if _sign_in_vbox.is_visible_in_tree():
		_on_sign_in_pressed()
	else:
		_on_sign_up_pressed()


# Triggers when the Sign In button is pressed
func _on_sign_in_pressed() -> void:
	if busy or _email_field.text.is_empty() or _password_field.text.is_empty():
		return
	busy = true
	_sign_in_menu.hide()
	_connect_popup.show()
	Firebase.Auth.login_with_email_and_password(_email_field.text, _password_field.text)
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_UI_SIGN_IN_PRESSED, {"email_field": _email_field.text})


# Refreshes the email and password fields when the dev login options button is pressed
func _on_dev_login_options_item_selected(index) -> void:
	var acct = _test_accts[index]
	_email_field.text = acct["email"]
	_password_field.text = acct["password"]


# Cancels the login
func _on_connect_cancel_button_pressed() -> void:
	busy = false
	Net.logout()
	_connect_popup.hide()
	_sign_in_menu.show()
	Firebase.Auth.cancel_login_request()
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_UI_CANCEL_BUTTON_PRESSED)


# Triggers when the forgot password button is pressed
func _on_forgot_password_pressed() -> void:
	if busy:
		return
	var url = ProjectSettings.get_setting("mirror/base_url") + "/?forgot-password=true"
	Analytics.track_event_client(
		AnalyticsEvent.TYPE.LOGIN_UI_FORGOT_PASSWORD_PRESSED,
		{"base_url": url}
	)
	OS.shell_open(url)


# Triggers when the sign up here password button is pressed
func _on_sign_up_here_pressed() -> void:
	if busy:
		return
	_sign_in_vbox.hide()
	_register_vbox.show()
	var url = ProjectSettings.get_setting("mirror/base_url")
	Analytics.track_event_client(
		AnalyticsEvent.TYPE.LOGIN_UI_SIGN_UP_HERE_PRESSED,
		{"base_url": url}
	)


func _on_login_anonymously_pressed():
	Firebase.Auth.login_anonymous()


# Populates the dev options button with test account info
func _populate_dev_options_button() -> void:
	_test_accts = ProjectSettings.get_setting("mirror/test_accounts", [])
	_dev_login_options.clear()
	_dev_login_options.add_item("")
	if _test_accts.size() == 0:
		_dev_login_options.visible = false
		return
	for acct in _test_accts:
		var email: String = acct["email"]
		_dev_login_options.add_item(email)
	_test_accts.push_front({"email": "", "password": ""})


func _on_sign_up_pressed() -> void:
	var line_edits: Array[LineEdit] = [
			_register_display_name, _register_email,
			_register_password, _register_confirm_password
	]
	for edit in line_edits:
		var error_label = edit.get_node_or_null("ErrorLabel")
		if error_label:
			error_label.visible = edit.text.is_empty()
	_register_tos_checkbox.get_node("ErrorLabel").visible = not _register_tos_checkbox.is_pressed()

	var pasword_match = _register_confirm_password.text == _register_password.text
	_register_confirm_password.get_node("ErrorLabel").visible = not pasword_match

	if busy or line_edits.any(func(a): a.text.is_empty()):
		return
	if  not _register_tos_checkbox.is_pressed() or not pasword_match:
		return

	var data = {
		"displayName": _register_display_name.text,
		"password": _register_password.text,
		"email": _register_email.text,
		"termsAgreedtoGeneralTOSandPP": _register_tos_checkbox.is_pressed()
	}
	busy = true
	var promise: Promise = Net.user_client.create_account(data)
	await promise.wait_till_fulfilled()
	busy = false
	if promise.is_error():
		Notify.error("Create Account Error!", promise.get_error_message())
	else:
		Notify.info("Create Account Success!", "Account was created sucesfully.")
		_on_sign_in_here_pressed() # so after logout we will see Sign In page
		_sign_in_menu.hide()
		_connect_popup.show()
		Firebase.Auth.login_with_email_and_password(_register_email.text, _register_password.text)
		Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_UI_SIGN_IN_PRESSED, {"email_field": _email_field.text})


func _on_sign_in_here_pressed() -> void:
	if busy:
		return
	_sign_in_vbox.show()
	_register_vbox.hide()


func _go_to_webpage(uri: String) -> void:
	if busy:
		return
	var base_url = ProjectSettings.get_setting("mirror/landing_page_url")
	OS.shell_open(base_url + uri)


func _on_tos_link_pressed() -> void:
	_go_to_webpage("/terms")


func _on_privacy_link_pressed() -> void:
	_go_to_webpage("/privacy")
