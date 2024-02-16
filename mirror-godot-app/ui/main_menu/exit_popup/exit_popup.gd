extends Control


var _game_ui: Node

@onready var animation_player = $AnimationPlayer


# Toggle the fade in and out
func _input(_event) -> void:
	if not self.visible:
		return
	if Input.is_action_just_pressed(&"ui_cancel"):
		fade_out()


func setup(game_ui: Node) -> void:
	_game_ui = game_ui
	hide()


# Fades in the scene
func fade_in() -> void:
	self.show()
	animation_player.play("FadeIn")


# Fades out the scene
func fade_out() -> void:
	animation_player.play("FadeOut")


# Triggered at the end of an animation playing
func _on_animation_player_animation_finished(anim_name) -> void:
	if anim_name == "FadeOut":
		self.hide()


# Triggered when the close button is pressed
func _on_close_button_pressed() -> void:
	fade_out()


# Triggered when the player clicks outside of the panel
func _on_color_rect_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			fade_out()


# Triggered when the leave game button is pressed
func _on_exit_button_pressed() -> void:
	if Zone.client.pid:
		OS.kill(Zone.client.pid)
	get_tree().quit()


# Triggered when the back to game button is pressed
func _on_stay_button_pressed() -> void:
	fade_out()


func _on_logout_button_pressed() -> void:
	if Zone.is_client():
		Zone.client.quit_to_main_menu()
	Net.logout()
	fade_out()
	_game_ui.logout()
