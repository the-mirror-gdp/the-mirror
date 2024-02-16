@tool
extends "inspector_deletable_base.gd"


signal value_submitted()


func emit_value_submitted(_new_text = null) -> void:
	GameUI.release_input_lock(self)
	value_submitted.emit()


func _on_focus_entered() -> void:
	GameUI.grab_input_lock(self)


func _on_focus_exited() -> void:
	if not get_viewport() is AcceptDialog:
		GameUI.release_input_lock(self)
