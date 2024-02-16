extends DropdownFilterMenu


signal input_value_changed()

var _edited_graph_node: ScriptBlockGraphNode
var _edited_input_port: ScriptBlock.ScriptBlockInputPort


func _ready() -> void:
	search_field.text_changed_delay = 0.0


func edit_input_value(graph_node: ScriptBlockGraphNode, input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	delete_filter_menu_items()
	_edited_graph_node = graph_node
	_edited_input_port = input_port
	var enum_values: Array = graph_node.get_enum_values(input_port)
	for value in enum_values:
		add_filter_menu_item(value, value)
	show_menu_at_mouse_position()
	GameUI.grab_input_lock(self)


func show_menu_at_mouse_position() -> void:
	show()
	var viewport_size: Vector2 = get_tree().get_root().get_visible_rect().size
	var global_pos: Vector2 = get_global_mouse_position()
	global_pos.x -= size.x * 0.5
	global_pos.y += 20.0
	global_position = _fit_rect_in_size(Rect2(global_pos, size), viewport_size)
	focus_filter_menu_search()


func _fit_rect_in_size(child_rect: Rect2, parent_size: Vector2) -> Vector2:
	var pos: Vector2 = child_rect.position
	var end: Vector2 = child_rect.end
	if end.x > parent_size.x:
		pos.x += parent_size.x - end.x
	if end.y > parent_size.y:
		pos.y += parent_size.y - end.y
	if pos.x < 0.0:
		pos.x = 0.0
	if pos.y < 0.0:
		pos.y = 0.0
	return pos


func _on_enum_value_selected(title: String, _metadata: Variant) -> void:
	hide()
	GameUI.release_input_lock(self)
	if not is_instance_valid(_edited_input_port):
		return
	_edited_input_port.value = title
	if is_instance_valid(_edited_graph_node):
		if _edited_graph_node.script_block.has_method(&"update_block_signature"):
			_edited_graph_node.script_block.update_block_signature(_edited_input_port)
			_edited_graph_node.reset_ports()
		else:
			_edited_graph_node.update_variable_ports()
	input_value_changed.emit()
