class_name KeyboardGrabbingLineEdit
extends LineEdit


func _on_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)


func _on_focus_exited() -> void:
	if not get_viewport() is AcceptDialog:
		GameUI.instance.release_input_lock(self)
