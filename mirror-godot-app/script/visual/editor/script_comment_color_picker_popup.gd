extends PopupPanel


func _on_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.instance.release_input_lock(self)
