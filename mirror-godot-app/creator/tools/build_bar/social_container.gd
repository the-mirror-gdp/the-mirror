extends HBoxContainer


signal open_space_settings_pressed()

@onready var _share_button: Button = $ShareButton
@onready var _gear_button: Button = $GearButton


func _on_share_button_pressed() -> void:
	var base_url: String = ProjectSettings.get_setting("mirror/base_url")
	var space_id: String = Zone.space.get("_id", "unknown")
	DisplayServer.clipboard_set(base_url + "/s/" + space_id)
	Notify.info("Space URL Copied", base_url + "/s/ " + space_id)
	_share_button.release_focus()


func _on_gear_button_pressed() -> void:
	open_space_settings_pressed.emit()
	_gear_button.release_focus()
