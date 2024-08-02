extends Control

@onready var login_code = $VBoxContainer/SignInMenu/MarginContainer/LoginContainer/LoginCode

func _on_sign_in_pressed() -> void:
	if login_code.text.is_empty():
		return
	var session_promise = Net.mirror_auth_client.check_login_code(login_code.text)
	var data = await session_promise.wait_till_fulfilled()
	
	if session_promise.is_error():
		Notify.error("Failed to login with code", session_promise.get_error_message())
		return
	assert(data.userId)
	assert(data.refreshToken)
	assert(data.spaceId)
	assert(data.loginCode)

func _ready():
	var login_code: bool = ProjectSettings.get_setting("feature_flags/force_enable_login_code", false)
	if login_code:
		show()
		await get_tree().process_frame
		GameUI.instance.login_ui.hide()
	else:
		hide()
