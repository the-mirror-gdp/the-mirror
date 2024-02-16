class_name KeyboardGrabbingConfirmationDialog
extends ConfirmationDialog


func _on_focus_entered() -> void:
	GameUI.grab_input_lock(self)


func _on_focus_exited() -> void:
	if not get_parent().get_viewport() is AcceptDialog:
		GameUI.release_input_lock(self)
