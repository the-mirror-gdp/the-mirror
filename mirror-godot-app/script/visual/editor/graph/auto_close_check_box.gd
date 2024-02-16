extends CheckBox


func _ready() -> void:
	await GameplaySettings.ready
	button_pressed = GameplaySettings.auto_close_script_editor


func _on_toggled(is_button_pressed: bool) -> void:
	GameplaySettings.auto_close_script_editor = is_button_pressed
