extends Control


signal space_version_published()

@onready var _version_option_button: OptionButton = %VersionOptionButton
@onready var _loading_spinner: Control = %LoadingSpinner
@onready var _publish_button: Button = %PublishButton
@onready var _current_version_check_box: CheckBox = %CurrentVersionCheckBox
@onready var _custom_version_check_box = %CustomVersionCheckBox

var space_id: String = ""


func _populate_space_versions() -> void:
	_version_option_button.clear()
	var promise: Promise = Net.space_client.get_published_space_versions(space_id)
	var space_versions = await promise.wait_till_fulfilled()
	_version_option_button.disabled = false
	_custom_version_check_box.disabled = false
	_loading_spinner.visible = false
	if promise.is_error():
		Notify.error("Space Version Error", promise.get_error_message())
		return
	var id := 0
	for version in space_versions:
		var display_name: String = version.get("name", "")
		if display_name.is_empty():
			display_name = "%s - %s" % [version.get("createdAt", ""), version.get("mirrorVersion", "")]
		_version_option_button.add_item(display_name, id)
		var index = _version_option_button.get_item_index(id)
		_version_option_button.set_item_metadata(index, version)
		id += 1
	if _version_option_button.item_count <= 0:
		_version_option_button.disabled = true
		_custom_version_check_box.disabled = true
		_current_version_check_box.button_pressed = true


func populate(space: Dictionary) -> void:
	space_id = space.get("_id", "")
	_version_option_button.disabled = true
	_publish_button.disabled = true
	_loading_spinner.visible = true

	await _populate_space_versions()
	_publish_button.disabled = false


func _on_close_button_pressed():
	hide()


func _on_publish_button_pressed():
	if space_id.is_empty():
		Notify.error("Error on Space Publish", "Incorrect space id.")
		return

	var is_current_version = _current_version_check_box.button_pressed
	_publish_button.disabled = true
	if is_current_version:
		var succses = await Util.publish_space(space_id)
		if not succses:
			_publish_button.disabled = false
			return
		space_version_published.emit()
	else:
		var space_version = _version_option_button.get_selected_metadata()
		var space_version_id: String = space_version.get("_id", "")
		if space_version_id.is_empty():
			Notify.error("Error on Space Publish", "Incorrect space version was selected.")
			_publish_button.disabled = false
			return
		var new_space_data = {
			"activeSpaceVersion": space_version_id
		}
		# New play server will be created using the selected space_version
		# But old play servers that are currently running will stay on the old version
		var promise: Promise = Net.space_client.update_space(space_id, new_space_data)
		await promise.wait_till_fulfilled()
		if promise.is_error():
			Notify.error("Error on Space Publish", "Failure during updating space data.")
			_publish_button.disabled = false
			return
		# Show this only when updating. Notification is already handled with new published space
		Notify.success("Space Published", "Publish version was changed succesfully.")
		space_version_published.emit()
	hide()
	_publish_button.disabled = false
	await _populate_space_versions()


func _on_version_option_button_item_selected(index):
	_custom_version_check_box.button_pressed = true


func _on_visibility_changed():
	if _current_version_check_box != null:
		_current_version_check_box.button_pressed = true
