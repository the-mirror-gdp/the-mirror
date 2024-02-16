extends PopupPanel


func _on_focus_entered() -> void:
	GameUI.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.release_input_lock(self)
