extends ItemList

func _update_my_content(arr: Array) -> void:
	self.clear()
	for x in arr:
		var action: UndoRedoAction = x
		var text = action.to_string()
		var item_index = self.add_item(text)
		var line_length = 80
		var wrapped_text = wrap_text(text, line_length)
		self.set_item_tooltip(item_index, wrapped_text)

func wrap_text(text, line_length := 80) -> String:
		var wrapped_text = ""
		var i = 0
		for char in text:
			i += 1
			wrapped_text += char
			if i > line_length:
				i = 0
				wrapped_text += "\n"
		return wrapped_text


func _on_undo_redo_system_actions_updated_undo(actions_to_undo, _actions_to_redo):
	_update_my_content(actions_to_undo)


func _on_undo_redo_system_actions_updated_redo(_actions_to_undo, actions_to_redo):
	_update_my_content(actions_to_redo)
