class_name ScriptBlockGraphNode
extends GraphNode


const _SCRIPT_BLOCK_GRAPH_SLOT_SCENE = preload("res://script/visual/editor/graph/script_block_graph_slot.tscn")
const _GDSCRIPT_CODE_GRAPH_SLOT_SCENE = preload("res://script/visual/editor/graph/gdscript_code_graph_slot.tscn")
const _ADD_REMOVE_GRAPH_SLOT_SCENE = preload("res://script/visual/editor/graph/add_remove_graph_slot.tscn")
const _TYPE_SELECTION_ALL_SCENE = preload("res://script/visual/editor/type_selection_button_all.tscn")
const _TYPE_SELECTION_MATH_SCENE = preload("res://script/visual/editor/type_selection_button_math.tscn")
const _TYPE_SELECTION_VEC_OBJ_SCENE = preload("res://script/visual/editor/type_selection_button_vec_obj.tscn")

var description: String
var script_block: ScriptBlock
var script_editor_graph: GraphEdit
var graph_slots: Array[HBoxContainer] = []
var special_graph_slot: HBoxContainer = null
var primary_type_selection: OptionButton
var secondary_type_selection: OptionButton

var hover_tooltip_text: String


func setup(block: ScriptBlock, graph_edit: GraphEdit) -> void:
	script_block = block
	script_editor_graph = graph_edit
	block.graph_node = self
	position_offset = block.graph_position
	title = block.graph_name
	if title.ends_with("(Async)") or title.contains("Every Frame"):
		add_theme_color_override("title_color", Color(1.0, 0.9, 0.5))
	_set_overlay_and_tooltip()
	_setup_ports()


func reset_ports() -> void:
	_delete_all_existing_ports()
	_setup_ports()
	# Reset the size to the minimum to avoid graphical artifacts.
	size = Vector2.ZERO
	await get_tree().process_frame
	size = Vector2.ZERO


func cleanup_and_delete() -> void:
	_delete_all_existing_ports()
	if is_instance_valid(script_block):
		script_block.graph_node = null
	script_block = null
	get_parent().remove_child(self)
	queue_free()


func disconnect_input(input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	assert(input_port in script_block.inputs)
	input_port.connected_block = null
	input_port.connected_output = -1
	if script_block.has_method(&"update_block_signature"):
		script_block.update_block_signature(input_port)
	reset_ports()


func execute() -> void:
	assert(script_block is ScriptBlockSequenced)
	script_editor_graph.hide_all_errors()
	script_editor_graph.reset_all_blocks_evaluation_state()
	MirrorScriptServer.is_execution_override_enabled = true
	script_block.execute()
	MirrorScriptServer.is_execution_override_enabled = false


func show_error(error_text: String) -> void:
	#overlay = GraphNode.OVERLAY_BREAKPOINT
	assert(not graph_slots.is_empty())
	graph_slots[0].show_error(error_text)


func hide_error() -> void:
	_set_overlay_and_tooltip()
	if not graph_slots.is_empty():
		graph_slots[0].hide_error()


func _set_overlay_and_tooltip() -> void:
	assert(is_instance_valid(script_block), "If the script block is deleted, the graph node should be deleted too.")
	if is_instance_valid(script_block) and script_block is ScriptBlockEntryBase and not script_block.entry_connection_valid:
		#overlay = GraphNode.OVERLAY_POSITION
		var attached_object: Object = script_editor_graph.script_builder.attached_object
		if attached_object == null:
			hover_tooltip_text = "Script is an asset, not in the space. Attach the script to an object so that it can run."
		elif attached_object is SpaceGlobalScripts:
			hover_tooltip_text = "Script is global, not attached to an object. Attach the script to an object to enable this entry block."
		elif script_block.entry_node == null:
			hover_tooltip_text = "Script entry is looking for a specific subnode, but none was found. This entry won't run attached to this object."
		else:
			hover_tooltip_text = "Script entry is looking for a specific subnode with this signal, but the subnode found does not have this signal. This entry won't run attached to this object."
	else:
		#overlay = GraphNode.OVERLAY_DISABLED
		hover_tooltip_text = description


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	if script_block.has_method(&"is_port_enumerated"):
		return script_block.is_port_enumerated(input_port)
	return false


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	assert(script_block.has_method(&"get_enum_values"), "Check is_port_enumerated() before calling get_enum_values()")
	return script_block.get_enum_values(input_port)


func get_input_limits(input_port: ScriptBlock.ScriptBlockInputPort) -> Vector2:
	if script_block.has_method(&"get_input_limits"):
		return script_block.get_input_limits(input_port)
	return Vector2.ZERO


func _setup_ports() -> void:
	_setup_port_slots()
	if script_block is ScriptBlockSequenced:
		_setup_sequence_flow_ports()
	_setup_variable_ports()
	var primary_on_left: bool = _is_primary_type_selection_on_left(script_block)
	# Editor code for specific block types.
	if script_block is ScriptBlockRotationLookingAt:
		_setup_primary_type_selection_button(_TYPE_SELECTION_VEC_OBJ_SCENE, primary_on_left)
	elif script_block is ScriptBlockMath:
		_setup_primary_type_selection_button(_TYPE_SELECTION_MATH_SCENE, primary_on_left)
	elif script_block.has_method(&"change_primary_type_selection"):
		_setup_primary_type_selection_button(_TYPE_SELECTION_ALL_SCENE, primary_on_left)
		if script_block.has_method(&"change_secondary_type_selection"):
			var secondary_on_left: bool = _is_secondary_type_selection_on_left(script_block)
			_setup_secondary_type_selection_button(_TYPE_SELECTION_ALL_SCENE, primary_on_left, secondary_on_left)
	elif script_block is ScriptBlockGDScriptCode:
		_setup_gdscript_code_slot()
	if script_block.has_method(&"add_slot_port"):
		_setup_add_remove_slot_port()


func _setup_port_slots() -> void:
	assert(graph_slots.is_empty())
	var left_ports: int = script_block.inputs.size()
	var right_ports: int = script_block.outputs.size()
	if script_block is ScriptBlockSequenced:
		left_ports += 1
		right_ports += script_block.flows.size()
	if script_block.has_method(&"change_primary_type_selection"):
		if _is_primary_type_selection_on_left(script_block):
			left_ports += 1
		else:
			right_ports += 1
	if script_block.has_method(&"change_secondary_type_selection"):
		if _is_secondary_type_selection_on_left(script_block):
			left_ports += 1
		else:
			right_ports += 1
	for i in maxi(left_ports, right_ports):
		var slot: Node = _SCRIPT_BLOCK_GRAPH_SLOT_SCENE.instantiate()
		graph_slots.append(slot)
		add_child(slot)
	if special_graph_slot != null:
		move_child(special_graph_slot, -1)


func _setup_sequence_flow_ports() -> void:
	if not script_block is ScriptBlockEntryBase:
		set_slot_enabled_left(0, true)
		set_slot_type_left(0, ScriptBlock.PortType.SEQUENCE)
	graph_slots[0].setup_left_sequence()
	for i in script_block.flows.size():
		var flow = script_block.flows[i]
		set_slot_enabled_right(i, true)
		set_slot_type_right(i, ScriptBlock.PortType.SEQUENCE)
		graph_slots[i].setup_right(flow.port_name, ScriptBlock.PortType.SEQUENCE)


func _setup_variable_ports() -> void:
	var left_port_index: int = 0
	var right_port_index: int = 0
	if script_block is ScriptBlockSequenced:
		left_port_index = 1
		for i in script_block.flows.size():
			right_port_index += 1
	# Variable inputs and outputs.
	for i in range(script_block.inputs.size()):
		var input = script_block.inputs[i]
		var slot_index = left_port_index + i
		set_slot_enabled_left(slot_index, true)
		set_slot_type_left(slot_index, input.port_type)
		set_slot_color_left(slot_index, _get_color_of_type(input.port_type))
		graph_slots[slot_index].setup_left_data(input)
		graph_slots[slot_index].request_input_value_edit.connect(_request_input_value_edit)
	for i in range(script_block.outputs.size()):
		var output = script_block.outputs[i]
		var slot_index = right_port_index + i
		set_slot_enabled_right(slot_index, true)
		set_slot_type_right(slot_index, output.port_type)
		set_slot_color_right(slot_index, _get_color_of_type(output.port_type))
		graph_slots[slot_index].setup_right(output.port_name, output.port_type)


func _setup_primary_type_selection_button(button_scene: PackedScene, primary_on_left: bool) -> void:
	var primary_type_slot: Control = graph_slots.back()
	if primary_on_left:
		primary_type_slot.hide_left()
	else:
		primary_type_slot.hide_right()
	primary_type_selection = button_scene.instantiate()
	primary_type_selection.item_selected.connect(_primary_type_selection_changed)
	var port_type: ScriptBlock.PortType = script_block.get_primary_port_type()
	primary_type_selection.selected = primary_type_selection.get_item_index(port_type)
	primary_type_slot.add_child(primary_type_selection)
	if primary_on_left:
		primary_type_slot.move_child(primary_type_selection, 0)


func _setup_secondary_type_selection_button(button_scene: PackedScene, primary_on_left: bool, secondary_on_left: bool) -> void:
	var secondary_type_slot: Control
	if primary_on_left == secondary_on_left:
		secondary_type_slot = graph_slots[graph_slots.size() - 2]
	else:
		secondary_type_slot = graph_slots[graph_slots.size() - 1]
	if secondary_on_left:
		secondary_type_slot.hide_left()
	else:
		secondary_type_slot.hide_right()
	secondary_type_selection = button_scene.instantiate()
	secondary_type_selection.item_selected.connect(_secondary_type_selection_changed)
	var port_type: ScriptBlock.PortType = script_block.get_secondary_port_type()
	secondary_type_selection.selected = secondary_type_selection.get_item_index(port_type)
	secondary_type_slot.add_child(secondary_type_selection)
	if secondary_on_left:
		secondary_type_slot.move_child(secondary_type_selection, 0)


func _primary_type_selection_changed(selected_index: int) -> void:
	var type = primary_type_selection.get_item_id(selected_index)
	script_block.change_primary_type_selection(type)
	update_variable_ports()
	script_editor_graph.script_contents_changed_by_editor()


func _secondary_type_selection_changed(selected_index: int) -> void:
	var type = secondary_type_selection.get_item_id(selected_index)
	script_block.change_secondary_type_selection(type)
	update_variable_ports()
	script_editor_graph.script_contents_changed_by_editor()


# Lightweight alternative to `reset_ports()` that only updates the contents of the
# variable ports in the slots, but not the amount of slots, or any sequence ports.
func update_variable_ports() -> void:
	_setup_variable_ports()
	title = script_block.graph_name
	# Reset the size to the minimum to avoid graphical artifacts.
	size = Vector2.ZERO
	await get_tree().process_frame
	size = Vector2.ZERO


func _setup_add_remove_slot_port() -> void:
	special_graph_slot = _ADD_REMOVE_GRAPH_SLOT_SCENE.instantiate()
	var custom_name: String = ""
	if script_block.has_method(&"get_add_remove_slot_port_custom_name"):
		custom_name = script_block.get_add_remove_slot_port_custom_name()
	special_graph_slot.setup_add_remove_slot(_add_slot_port_pressed, _remove_slot_port_pressed, custom_name)
	add_child(special_graph_slot)


func _add_slot_port_pressed() -> void:
	script_block.add_slot_port()
	reset_ports()
	script_editor_graph.script_contents_changed_by_editor()


func _remove_slot_port_pressed() -> void:
	script_block.remove_slot_port()
	script_editor_graph.on_slot_port_removed(script_block)
	reset_ports()
	script_editor_graph.script_contents_changed_by_editor()


func _setup_gdscript_code_slot() -> void:
	special_graph_slot = _GDSCRIPT_CODE_GRAPH_SLOT_SCENE.instantiate()
	var open_code_editor: Button = special_graph_slot.get_node(^"OpenCodeEditor")
	open_code_editor.pressed.connect(_on_open_gdscript_code_editor_pressed)
	var edit_ports: Button = special_graph_slot.get_node(^"EditPorts")
	add_child(special_graph_slot)


func _delete_all_existing_ports() -> void:
	for i in range(get_child_count()):
		# Before deleting ports, disable the ports visually.
		set_slot_enabled_left(i, false)
		set_slot_enabled_right(i, false)
	for slot in graph_slots:
		remove_child(slot)
		slot.queue_free()
	graph_slots.clear()
	if special_graph_slot:
		special_graph_slot.queue_free()
		special_graph_slot = null


func _on_open_gdscript_code_editor_pressed() -> void:
	script_editor_graph.request_gdscript_code_edit.emit(script_block)


func _request_input_value_edit(input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	script_editor_graph.request_input_value_edit.emit(self, input_port)


func _is_primary_type_selection_on_left(script_block: ScriptBlock) -> bool:
	if script_block is ScriptBlockDictionaryForEach:
		return true
	return script_block is ScriptBlockArrayForEach


func _is_secondary_type_selection_on_left(script_block: ScriptBlock) -> bool:
	if script_block is ScriptBlockDictionaryForEach:
		return true
	return script_block is ScriptBlockDictionaryGet


func _get_color_of_type(port_type: int) -> Color:
	# These colors are copied from Godot's colors.
	match port_type:
		ScriptBlock.PortType.ANY_DATA:
			return Color(0.25, 0.93, 0.68)
		ScriptBlock.PortType.BOOL:
			return Color(0.44, 0.57, 0.94)
		ScriptBlock.PortType.INT:
			return Color(0.35, 0.73, 0.94)
		ScriptBlock.PortType.FLOAT:
			return Color(0.21, 0.83, 0.96)
		ScriptBlock.PortType.STRING:
			return Color(0.27, 0.58, 0.93)
		ScriptBlock.PortType.VECTOR2:
			return Color(0.67, 0.45, 0.95)
		ScriptBlock.PortType.VECTOR3:
			return Color(0.87, 0.40, 0.94)
		ScriptBlock.PortType.COLOR:
			return Color(0.62, 1.00, 0.44)
		ScriptBlock.PortType.OBJECT:
			return Color(0.47, 0.95, 0.91)
		ScriptBlock.PortType.DICTIONARY:
			return Color(0.33, 0.93, 0.62)
		ScriptBlock.PortType.ARRAY:
			return Color(0.66, 0.66, 0.66)
		ScriptBlock.PortType.SEQUENCE:
			return Color.WHITE
		ScriptBlock.PortType.CONNECTION:
			return Color(0.25, 0.93, 0.68)
	return Color.GRAY


func _on_hoverable_script_block_mouse_entered() -> void:
	GameUI.instance.set_hover_tooltip_text(hover_tooltip_text)


func _on_hoverable_script_block_mouse_exited() -> void:
	GameUI.instance.hide_hover_tooltip_text()
