extends Button


func _ready():
	pressed.connect(_on_end_preview_button_pressed)
	Zone.mode_changed.connect(_on_zone_mode_changed)


func _on_zone_mode_changed(new_zone_mode) -> void:
	visible = new_zone_mode == Zone.ZONE_MODE.PLAY and Zone.space.get("play_server") != true


func _on_end_preview_button_pressed() -> void:
	Zone.client_send_mode_change(Zone.ZONE_MODE.EDIT)
	GameUI.main_menu_ui.hide()
