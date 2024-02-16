extends PanelContainer


signal actions_updated(actions_to_undo, actions_to_redo)

func _on_undo_redo_system_actions_updated(actions_to_undo, actions_to_redo) -> void:
	actions_updated.emit(actions_to_undo, actions_to_redo)
