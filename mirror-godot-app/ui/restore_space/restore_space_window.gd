extends Control


@onready var _version_option_button: OptionButton = %VersionOptionButton
@onready var _loading_spinner: Control = %LoadingSpinner
@onready var _loading_spinner_button = %LoadingSpinnerButton
@onready var _restore_button: Button = %RestoreButton

var space_id: String = ""


func _populate_space_versions() -> void:
	_version_option_button.clear()
	var promise: Promise = Net.space_client.get_published_space_versions(space_id)
	var space_versions = await promise.wait_till_fulfilled()
	_version_option_button.disabled = false
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


func populate(space: Dictionary) -> void:
	Util.safe_signal_connect(Zone.space_restore.space_restored, _on_space_restored)
	Util.safe_signal_connect(Zone.space_restore.space_restore_failed, _on_space_restore_failed)
	space_id = space.get("_id", "")
	_version_option_button.disabled = true
	_loading_spinner_button.visible = false
	_restore_button.disabled = true
	_loading_spinner.visible = true

	await _populate_space_versions()
	_restore_button.disabled = false


func _on_close_button_pressed() -> void:
	hide()


func _on_restore_button_pressed() -> void:
	if space_id.is_empty():
		Notify.error("Error trying restoring space", "Incorrect space id.")
		return
	_restore_button.disabled = true
	var space_version = _version_option_button.get_selected_metadata()
	var space_version_id: String = space_version.get("_id", "")
	if space_version_id.is_empty():
		Notify.error("Error trying restoring space", "Incorrect space version was selected.")
		_restore_button.disabled = false
		return
	_loading_spinner_button.visible = true
	GameUI.instance.creator_ui.clear_selection()
	Zone.space_restore.restore_from_space_version.rpc_id(Zone.SERVER_PEER_ID, space_version_id)


func _on_space_restored(save_name: String) -> void:
	_loading_spinner_button.visible = false
	hide()


func _on_space_restore_failed(save_name: String) -> void:
	_loading_spinner_button.visible = false
	_restore_button.disabled = false
