extends Control


signal request_change_page(subpage_name: StringName)

@onready var _download_popup: Control = $Popup
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _download_avatar_url: LineEdit = $Popup/Panel/MarginContainer/VBoxContainer/Url
@onready var _connect_btn: Button = $Popup/Panel/MarginContainer/VBoxContainer/Connect
@onready var _avatar_preview: Node3D = $HBoxContainer/AvatarPreview/SubViewport/AvatarPreview
@onready var _save_button: Button = $HBoxContainer/VBoxContainer/ContinueWithAvatar

var _target_avatar_url: String = "":
	set(new_value):
		_target_avatar_url = new_value
		_save_button.disabled = _target_avatar_url.is_empty()
var _avatar_download_url: String = ""


func _ready():
	Net.user_client.user_profile_data_loaded.connect(_load_current_profile_preview)
	_download_popup.hide()
	_connect_btn.text = "Connect"
	var main_menu = get_parent().get_parent()


func _on_popup_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_animation_player.play("FadeOut")


func _on_animation_player_animation_finished(anim_name) -> void:
	if anim_name == "FadeOut":
		_download_popup.hide()


func _load_current_profile_preview(profile_data: Dictionary) -> void:
	# get the current user profile's avatar url
	var avatar_url: String = profile_data.get("avatarUrl", "")

	# No avatar url specified.
	if avatar_url.is_empty():
		# select default preset
		_on_preset_1_pressed()
		return

	# if the avatar is stored in resources, load the avatar from resources.
	if Net.file_client.resource_avatars.has(avatar_url):
		var resource_path = Net.file_client.resource_avatars[avatar_url]
		_save_button.grab_focus()
		_avatar_preview.set_avatar_with_resource_path(resource_path)
		return

	# if the avatar is stored in the files, load a unique instance of it and set to the model
	if Net.file_client.files.has(avatar_url):
		_promise_set_preview_model(avatar_url)
		return

	# Otherwise we may need to download it. Ensure it is an HTTP location.
	if not avatar_url.to_lower().begins_with("http"):
		# something is wrong so select default preset
		_on_preset_1_pressed()
		return

	_avatar_preview.show_loading()
	_avatar_download_url = avatar_url
	# Download file avatar url and listen for a file download.
	var promise = Net.file_client.get_file(avatar_url, Enums.DownloadPriority.AVATAR_DEFAULT)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error loading avatar: %s" % promise.get_error_message())
		return
	_on_avatar_downloaded()


func _on_import_avatar_pressed() -> void:
	_download_popup.modulate = Color(255, 255, 255, 0)
	_download_popup.show()
	_animation_player.play("FadeIn")


func _on_preset_1_pressed() -> void:
	_preview_resource_avatar("themirror://avatar/astronaut-male")


func _on_preset_2_pressed() -> void:
	_preview_resource_avatar("themirror://avatar/astronaut-female")


func _preview_resource_avatar(resource_avatar_url: String) -> void:
	if not Net.file_client.resource_avatars.has(resource_avatar_url):
		return
	_target_avatar_url = resource_avatar_url
	_save_button.grab_focus()
	_avatar_preview.set_avatar_with_resource_path(Net.file_client.resource_avatars[resource_avatar_url])


func _on_connect_pressed() -> void:
	var download_avatar_url: String = _download_avatar_url.text.strip_edges()
	if download_avatar_url.is_empty():
		Notify.error("Avatar Error", "No URL provided.")
		return
	if Net.file_client.files.has(download_avatar_url):
		_download_popup.hide()
		_promise_set_preview_model(download_avatar_url)
		return
	_avatar_preview.show_loading()
	_avatar_download_url = download_avatar_url
	_connect_btn.text = "Downloading..."

	_animation_player.play("FadeOut")
	var promise = Net.file_client.get_file(_avatar_download_url, Enums.DownloadPriority.AVATAR_DEFAULT)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error loading avatar: %s" % promise.get_error_message())
		return
	_on_avatar_downloaded()


func _promise_set_preview_model(avatar_url: String) -> void:
	if _target_avatar_url == avatar_url:
		return # Already loaded.
	_target_avatar_url = avatar_url
	var promise = Net.file_client.get_model_instance_promise(avatar_url)
	_avatar_preview.show_loading()
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Avatar Error", "Could not load avatar.")
		return
	_save_button.grab_focus()
	_avatar_preview.set_avatar_with_node(promise.get_result())


func _on_avatar_downloaded() -> void:
	_connect_btn.text = "Connect"
	_promise_set_preview_model(_avatar_download_url)


func _on_continue_with_avatar_pressed() -> void:
	if _target_avatar_url.is_empty():
		Notify.warning("No avatar selected", "Please select an avatar first")
		return
	# Apply the avatar to the currently joined server, if any.
	if PlayerData.has_local_player():
		var local_player: Player = PlayerData.get_local_player()
		local_player.set_player_avatar_from_user(_target_avatar_url)
	# Save selected Avatar to profile
	var user_id = Net.user_id
	var old_profile = null
	if user_id:
		old_profile = Net.user_client.user_profiles.get(user_id, null)
	var promise = Net.user_client.update_user_avatar(_target_avatar_url)
	var result = await promise.wait_till_fulfilled()
	if promise.is_error():
		var click_callable = func ():
			OS.shell_open(ProjectSettings.get_setting("mirror/bug_report_url", "https://themirror.space/discord"))
		Notify.error(
			tr("No changes to your avatar"),
			tr("Try to retry once or twice, then tell us about it by clicking HERE\nError: \"%s\""%promise.get_error_message()),
			click_callable
		)
	else:
		var user_profile = result
		var uid = user_profile["_id"]
		if not old_profile:
			# Worse case, when you retry to set the avatar, you get a better and more correct message.
			Notify.info(tr("Can't confirm changes\n to your avatar"), tr("Your avatar might have been successfully changed. Retry to make sure."))
		elif user_profile["avatarUrl"] != old_profile["avatarUrl"]:
			Notify.success(tr("Your avatar successfully changed"), tr("This change will be applied on your next connection to any server"))
			if GameUI.should_display_space_listings:
				request_change_page.emit(&"Home")
		else:
			Notify.info(tr("No changes to your avatar"), tr("Your avatar was already set to that same avatar"))
