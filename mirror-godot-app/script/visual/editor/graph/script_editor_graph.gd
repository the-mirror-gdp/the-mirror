extends GraphEdit


signal request_block_creation_for_data_drop(block_position: Vector2, data: Dictionary)
signal request_comment_creation(where: Vector2)
signal request_comment_color_edit(comment_graph_node: GraphNode, color: Color)
signal request_save_script_as_asset()
signal request_toggle_variable_editor()
signal request_close_script_editor()

## Emitted when dragging a line to nowhere to request a block for that line.
signal request_block_creation(constraint: int, data_type: int, index: int, from_block: ScriptBlock, where: Vector2)
## Emitted when clicking the toolbar button for a new entry.
signal request_entry_creation(where: Vector2)
## Emitted when clicking on an unconnected input's editable value.
signal request_input_value_edit(graph_node: ScriptBlockGraphNode, input_port: ScriptBlock.ScriptBlockInputPort)
## Emitted when clicking on the open code editor button on a GDScript block.
signal request_gdscript_code_edit(script_block: ScriptBlockGDScriptCode)

signal request_track_recently_used_space_script(script_instance: VisualScriptInstance)

const _TOOLBAR_BUTTONS_SCENE = preload("res://script/visual/editor/graph/visual_script_toolbar_buttons.tscn")
const _SCRIPT_BLOCK_GRAPH_NODE_SCENE = preload("res://script/visual/editor/graph/script_block_graph_node.tscn")
const _SCRIPT_COMMENT_GRAPH_NODE_SCENE = preload("res://script/visual/editor/graph/script_comment_graph_node.tscn")

var comment_graph_nodes: Array[ScriptCommentGraphNode]
var block_graph_nodes: Array[ScriptBlockGraphNode] = []
var script_builder: VisualScriptBuilder
var script_instance: VisualScriptInstance

var clipboard_script_blocks: Array[ScriptBlock] = []
var clipboard_script_comments: Array[VisualScriptComment] = []
var clipboard_copy_position := Vector2.ZERO
var pre_delete_pan_scroll_offset := Vector2.ZERO

var _toolbar_buttons: Control
var _read_only_blocker: Control
var _is_panning: bool = false
var _pan_from: Vector2 = Vector2.ZERO
var _pan_start: Vector2 = Vector2.ZERO
var _pan_amount: Vector2 = Vector2.ZERO
var _mouse_position: Vector2 = Vector2.ZERO
var _queue_update_network_script_frames: int = -1
var _script_block_signatures: Array[Dictionary]


func _ready() -> void:
	for i in ScriptBlock.PortType.values():
		add_valid_connection_type(i, i) # Yup. This needs to be explicit...
		if i < ScriptBlock.PortType.SEQUENCE:
			# Everything below SEQUENCE is data. See the comment above enum PortType.
			add_valid_connection_type(i, ScriptBlock.PortType.ANY_DATA)
			add_valid_connection_type(ScriptBlock.PortType.ANY_DATA, i)
			# Allow any data port type to connect to a String input.
			add_valid_connection_type(i, ScriptBlock.PortType.STRING)
			# Allow any data port type to connect to a dataless connection input.
			add_valid_connection_type(i, ScriptBlock.PortType.CONNECTION)
	add_valid_connection_type(ScriptBlock.PortType.INT, ScriptBlock.PortType.FLOAT)
	add_valid_connection_type(ScriptBlock.PortType.FLOAT, ScriptBlock.PortType.INT)
	# Set up a read-only blocker.
	_read_only_blocker = Control.new()
	_read_only_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_read_only_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	var graphedit_menu_panel: Control = get_menu_hbox().get_parent()
	var graphedit_top_layer: Control = graphedit_menu_panel.get_parent()
	graphedit_top_layer.add_child(_read_only_blocker)
	# Set up toolbar buttons on the GraphEdit Zoom HBox.
	_toolbar_buttons = _TOOLBAR_BUTTONS_SCENE.instantiate()
	graphedit_top_layer.add_child(_toolbar_buttons)
	graphedit_menu_panel.hide()
	_toolbar_buttons.connect_script_graph_edit_signals(self)


func _process(_delta: float) -> void:
	_process_queue_update_network_script()


func setup(script_block_signatures: Array[Dictionary]) -> void:
	_script_block_signatures = script_block_signatures


## Detects and executes if the network object needs updating the next frame.
func _process_queue_update_network_script() -> void:
	if _queue_update_network_script_frames > 0:
		_queue_update_network_script_frames -= 1
		if _queue_update_network_script_frames == 0:
			script_instance.script_data_contents_changed()


func _gui_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		_mouse_position = input_event.position
		if _is_panning:
			_pan_amount = _pan_start - _mouse_position
			scroll_offset = _pan_from + _pan_amount
	elif input_event.is_action(&"script_editor_pan"):
		_is_panning = input_event.pressed
		if input_event.pressed:
			_pan_from = scroll_offset
			_pan_start = _mouse_position
			_pan_amount = Vector2.ZERO
		elif input_event.is_action(&"script_editor_create"):
			if _pan_amount.length_squared() < 10.0:
				var where: Vector2 = (_pan_from + _mouse_position) / zoom
				create_new_script_block_dialog(where)
		get_viewport().set_input_as_handled()
	elif input_event.is_action(&"script_editor_create") and input_event.double_click:
		var where: Vector2 = (_pan_from + _mouse_position) / zoom
		create_new_script_block_dialog(where)
		get_viewport().set_input_as_handled()
	elif input_event.is_action_pressed(&"script_editor_add_comment"):
		var where: Vector2 = (scroll_offset + _mouse_position) / zoom
		request_comment_creation.emit(where)


func _can_drop_data(_drop_position: Vector2, data) -> bool:
	if not data is Dictionary:
		return false
	var drag_type: String = data.get("drag_type", "")
	if drag_type == "dragged_asset":
		return data["asset_type"] in ["AUDIO", "MESH"]
	return drag_type in [
		"dragged_model_node",
		"dragged_space_object",
		"dragged_global_variable",
		"dragged_node_variable",
	]


func _drop_data(drop_position: Vector2, data) -> void:
	var block_position: Vector2 = (scroll_offset + drop_position) / zoom
	request_block_creation_for_data_drop.emit(block_position, data)


# Error-showing methods.
func hide_all_errors() -> void:
	for graph_node in block_graph_nodes:
		graph_node.hide_error()


func reset_graph_error_and_connections() -> void:
	hide_all_errors()
	clear_connections()
	setup_graph_node_connections()


func reset_all_blocks_evaluation_state() -> void:
	for graph_node in block_graph_nodes:
		graph_node.script_block.evaluated = false


# Graph node creation methods.
func create_graph_nodes(from_script_instance: ScriptInstance, rezoom: bool = true) -> void:
	_queue_update_network_script_frames = -1
	script_instance = from_script_instance
	script_builder = script_instance.script_builder
	# Regression in GraphEdit: https://github.com/godotengine/godot/issues/91857
	# We need to manually filter out the internal _connection_layer using the node name.
	var graph_edit_children: Array[Node] = get_children()
	for child in graph_edit_children:
		assert(child.name.begins_with("_"), "Expected all children to be cleaned up before `create_graph_nodes` was called (expected `cleanup_and_delete_nodes` to be called first).")
	#assert(get_children().is_empty())
	for comment in script_instance.comments:
		create_comment_graph_node(comment)
	var script_blocks: Array[ScriptBlock] = script_builder.all_blocks
	for block in script_blocks:
		create_block_graph_node(block)
	Util.safe_signal_connect(script_instance.script_contents_changed, _on_script_entity_data_changed)
	Util.safe_signal_connect(script_instance.script_entity_data_updated_from_network, _on_script_entity_data_changed)
	Util.safe_signal_connect(script_instance.script_contents_deleted, _delete_all_graph_nodes)
	_toolbar_buttons.setup_for_script_instance(script_instance)
	_read_only_blocker.visible = not (Util.can_local_user_edit_scripts() or from_script_instance.is_script_asset)
	# If we set up the connections immediately after setting up the graph nodes,
	# there can be weird artifacts, since the Control nodes need time to update.
	# If we wait 1 frame, the user may see a 1 frame long flicker.
	# If we set up immediately, then do it again on the next frame,
	# there are *different* graphical artifacts. Least evil: Set up once, immediately.
	setup_graph_node_connections()
	if not rezoom:
		return
	# Wait 1 more frame and rezoom. Control nodes take time to update.
	await get_tree().process_frame
	rezoom_to_show_all_graph_nodes()


func create_comment_graph_node(script_comment: VisualScriptComment) -> ScriptCommentGraphNode:
	var graph_node: ScriptCommentGraphNode = _SCRIPT_COMMENT_GRAPH_NODE_SCENE.instantiate()
	graph_node.name = "ScriptComment" + str(comment_graph_nodes.size()) + "_" + script_comment.title
	comment_graph_nodes.append(graph_node)
	add_child(graph_node)
	graph_node.setup(script_comment)
	graph_node.delete_request.connect(_on_script_comment_close_request.bind(graph_node))
	graph_node.comment_changed.connect(script_contents_changed_by_editor)
	graph_node.request_comment_color_edit.connect(_on_request_comment_color_edit)
	return graph_node


func create_block_graph_node(script_block: ScriptBlock) -> ScriptBlockGraphNode:
	var graph_node: ScriptBlockGraphNode = _SCRIPT_BLOCK_GRAPH_NODE_SCENE.instantiate()
	graph_node.name = "ScriptBlock" + str(block_graph_nodes.size()) + "_" + script_block.graph_name
	block_graph_nodes.append(graph_node)
	add_child(graph_node)
	graph_node.description = _get_script_block_description(script_block)
	graph_node.setup(script_block, self)
	graph_node.delete_request.connect(_on_script_block_close_request.bind(graph_node))
	return graph_node


func _get_script_block_description(script_block: ScriptBlock) -> String:
	if script_block.get_script_block_type() == "broken":
		return "This block is broken. Please delete it. This may happen when a block type is deleted from The Mirror.\nIf this appears repeatedly on new blocks, that is an urgent bug, please report it."
	if script_block is ScriptBlockEntryBase:
		return ScriptSignalRegistration.get_builtin_signal_description(script_block.entry_signal)
	if script_block is ScriptBlockSequencedMethod or script_block is ScriptBlockUnsequencedMethod:
		return ScriptMethodRegistration.get_method_description(script_block.method_name)
	if script_block is ScriptBlockOperationProperty or script_block is ScriptBlockGetProperty:
		return ScriptPropertyRegistration.get_property_description(script_block.property_name)
	for script_block_signature in _script_block_signatures:
		if script_block_signature["name"] == script_block.graph_name:
			return script_block_signature.get("description", "No description.")
	for script_block_signature in _script_block_signatures:
		if script_block_signature["type"] == script_block.get_script_block_type():
			return script_block_signature.get("description", "No description.")
	return "No description."


# Inter-block connection methods.
func setup_graph_node_connections() -> void:
	for graph_node in block_graph_nodes:
		if graph_node.script_block is ScriptBlockSequenced:
			_setup_graph_node_flow_connections(graph_node)
		_setup_graph_node_input_connections(graph_node)


func _setup_graph_node_flow_connections(graph_node: ScriptBlockGraphNode) -> void:
	var script_block: ScriptBlock = graph_node.script_block
	for i in script_block.flows.size():
		var flow = script_block.flows[i]
		var connected_block = flow.connected_block
		if connected_block != null:
			var connected_graph_node = connected_block.graph_node
			connect_node(graph_node.name, i, connected_graph_node.name, 0)


func _setup_graph_node_input_connections(graph_node: ScriptBlockGraphNode) -> void:
	var script_block: ScriptBlock = graph_node.script_block
	for i in script_block.inputs.size():
		var input: ScriptBlock.ScriptBlockInputPort = script_block.inputs[i]
		var connected_block: ScriptBlock = input.connected_block
		if connected_block != null:
			var connected_output: int = input.connected_output
			if connected_block is ScriptBlockSequenced:
				connected_output += connected_block.flows.size()
			var port_index: int = i
			if script_block is ScriptBlockSequenced and not script_block is ScriptBlockEntryBase:
				port_index += 1
			var connected_graph_node: ScriptBlockGraphNode = connected_block.graph_node
			if is_instance_valid(connected_graph_node):
				assert(connected_output < connected_graph_node.get_output_port_count())
				connect_node(connected_graph_node.name, connected_output, graph_node.name, port_index)


func _on_connection_request(from_node: StringName, from_port_index: int, to_node: StringName, to_port_index: int) -> void:
	if from_node == to_node:
		return
	var from_graph_node: ScriptBlockGraphNode
	var to_graph_node: ScriptBlockGraphNode
	for graph_node in block_graph_nodes:
		if graph_node.name == from_node:
			from_graph_node = graph_node
		elif graph_node.name == to_node:
			to_graph_node = graph_node
	assert(is_instance_valid(from_graph_node) and is_instance_valid(to_graph_node))
	var from_type = from_graph_node.get_output_port_type(from_port_index)
	var from_script_block = from_graph_node.script_block
	if from_type == ScriptBlock.PortType.SEQUENCE:
		from_script_block.flows[from_port_index].connected_block = to_graph_node.script_block
		reset_graph_error_and_connections()
		script_contents_changed_by_editor()
		return
	# Else, this is a variable port, not a sequence port.
	var to_script_block = to_graph_node.script_block
	var from_output_index = from_port_index
	var to_input_index = to_port_index
	if from_script_block is ScriptBlockSequenced:
		from_output_index -= from_script_block.flows.size()
	if to_script_block is ScriptBlockSequenced:
		to_input_index -= 1
	var to_block_input: ScriptBlock.ScriptBlockInputPort = to_script_block.inputs[to_input_index]
	to_block_input.connected_block = from_script_block
	to_block_input.connected_output = from_output_index
	if to_script_block.has_method(&"update_block_signature"):
		to_script_block.update_block_signature(to_block_input)
	await to_graph_node.reset_ports()
	reset_graph_error_and_connections()
	script_contents_changed_by_editor()


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2):
	var to_graph_node: ScriptBlockGraphNode
	for graph_node in block_graph_nodes:
		if graph_node.name == to_node:
			to_graph_node = graph_node
			break
	var to_script_block: ScriptBlock = to_graph_node.script_block
	var to_type: int = to_graph_node.get_input_port_type(to_port)
	if to_type == ScriptBlock.PortType.SEQUENCE:
		var was_connected: bool = false
		for graph_node in block_graph_nodes:
			var script_block: ScriptBlock = graph_node.script_block
			if not script_block is ScriptBlockSequenced:
				continue
			for flow in script_block.flows:
				if flow.connected_block == to_script_block:
					flow.connected_block = null
					was_connected = true
		if was_connected:
			script_contents_changed_by_editor()
		else:
			# Bring up a dialog for selecting a sequenced/run block.
			var where: Vector2 = (release_position + scroll_offset) / zoom
			var constraint := ScriptBlockCreationMenu.ConstraintType.SEQUENCED_RUN
			request_block_creation.emit(constraint, 0, -1, to_script_block, where)
		reset_graph_error_and_connections()
		return
	# Else, this is a variable port, not a sequence port.
	var to_input = to_port
	if to_script_block is ScriptBlockSequenced:
		to_input -= 1
	var input = to_script_block.inputs[to_input]
	if input.connected_block == null:
		# Bring up a dialog for selecting an unsequenced/data block.
		var where: Vector2 = (release_position + scroll_offset) / zoom
		request_block_creation.emit(ScriptBlockCreationMenu.ConstraintType.OUTPUT, \
				input.port_type, to_input, to_script_block, where)
	else:
		await to_graph_node.disconnect_input(input)
		script_contents_changed_by_editor()
	reset_graph_error_and_connections()


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2):
	var from_graph_node: ScriptBlockGraphNode
	for graph_node in block_graph_nodes:
		if graph_node.name == from_node:
			from_graph_node = graph_node
			break
	var from_script_block: ScriptBlock = from_graph_node.script_block
	var from_type: int = from_graph_node.get_output_port_type(from_port)
	if from_type == ScriptBlock.PortType.SEQUENCE:
		assert(from_script_block is ScriptBlockSequenced)
		var flow = from_script_block.flows[from_port]
		if flow.connected_block == null:
			# Bring up a dialog for selecting a sequenced/run block.
			var where: Vector2 = (release_position + scroll_offset) / zoom
			request_block_creation.emit(ScriptBlockCreationMenu.ConstraintType.SEQUENCED_RUN, \
					0, from_port, from_script_block, where)
		else:
			flow.connected_block = null
			script_contents_changed_by_editor()
		reset_graph_error_and_connections()
		return
	# Else, this is a variable port, not a sequence port.
	var from_output = from_port
	if from_script_block is ScriptBlockSequenced:
		from_output -= from_script_block.flows.size()
	var was_connected: bool = false
	for graph_node in block_graph_nodes:
		var script_block: ScriptBlock = graph_node.script_block
		for input in script_block.inputs:
			if input.connected_block == from_script_block and input.connected_output == from_output:
				graph_node.disconnect_input(input)
				was_connected = true
	if was_connected:
		script_contents_changed_by_editor()
	else:
		# Bring up a dialog for selecting an unsequenced/data block.
		var where: Vector2 = (release_position + scroll_offset) / zoom
		request_block_creation.emit(ScriptBlockCreationMenu.ConstraintType.INPUT, \
				from_type, from_output, from_script_block, where)
	reset_graph_error_and_connections()


func on_slot_port_removed(from_script_block: ScriptBlock) -> void:
	script_builder.validate_inputs_connected_to_block(from_script_block)
	reset_graph_error_and_connections()


func create_new_comment_pressed() -> void:
	var where: Vector2 = (scroll_offset + size * 0.5) / zoom
	request_comment_creation.emit(where)


func save_script_as_asset() -> void:
	request_save_script_as_asset.emit()


func toggle_variable_editor_pressed() -> void:
	request_toggle_variable_editor.emit()


func close_script_editor_pressed() -> void:
	request_close_script_editor.emit()


func script_name_text_changed(new_text: String) -> void:
	if not script_instance:
		return
	script_instance.script_name = new_text
	script_instance.script_contents_changed.emit()
	_queue_update_network_script_frames = 50 # Update slower for the name field.


func create_new_script_block_dialog(where := Vector2.INF) -> void:
	if where.x == INF:
		where = (scroll_offset + size * 0.5) / zoom
	request_block_creation.emit(ScriptBlockCreationMenu.ConstraintType.NONE, \
			ScriptBlock.PortType.ANY_DATA, -1, null, where)


func create_new_script_entry_dialog(where := Vector2.INF) -> void:
	if where.x == INF:
		where = (scroll_offset + size * 0.5) / zoom
	request_entry_creation.emit(where)


# Copy and paste methods.
func copy_selected_script_blocks(set_os_clipboard: bool = true) -> void:
	clipboard_copy_position = (scroll_offset + _mouse_position) / zoom
	clipboard_script_blocks.clear()
	for graph_node in block_graph_nodes:
		if graph_node.selected and not graph_node.script_block is ScriptBlockEntryBase:
			clipboard_script_blocks.append(graph_node.script_block)
	clipboard_script_comments.clear()
	for graph_node in comment_graph_nodes:
		if graph_node.selected:
			clipboard_script_comments.append(graph_node.script_comment)
	if not set_os_clipboard:
		return
	var clipboard_json: Dictionary = {
		"blocks": script_builder.serialize_some_blocks_to_json(clipboard_script_blocks),
		"copy_position": Serialization.vector2_to_array(clipboard_copy_position),
		"comments": script_instance.serialize_some_comments_to_json(clipboard_script_comments),
		"name": "Copied snippet from " + script_instance.script_name,
		"type": "MirrorVisualScript",
	}
	DisplayServer.clipboard_set(JSON.stringify(clipboard_json))


func paste_copied_script_blocks() -> void:
	# First, try to load from the user's OS clipboard.
	var clipboard_json = JSON.parse_string(DisplayServer.clipboard_get())
	if clipboard_json is Dictionary:
		if clipboard_json.get("type") == "MirrorVisualScript":
			_paste_copied_script_blocks_from_json(clipboard_json)
			return
	_paste_copied_script_blocks_local_clipboard()


func _paste_copied_script_blocks_from_json(clipboard_json: Dictionary) -> void:
	var offset := Vector2.ZERO
	if clipboard_json.has("copy_position") and clipboard_json["copy_position"] is Array:
		var copy_pos: Array = clipboard_json["copy_position"]
		# Remember, JSON only has floats. So saving (1, 2) will become [1.0, 2.0].
		if copy_pos.size() == 2 and copy_pos[0] is float and copy_pos[1] is float:
			offset = _paste_calculate_offset(Serialization.array_to_vector2(copy_pos))
	if clipboard_json.has("blocks") and clipboard_json["blocks"] is Array:
		var blocks: Array = clipboard_json["blocks"]
		var new_blocks: Array[ScriptBlock] = script_builder.append_more_blocks(blocks)
		for new_block in new_blocks:
			if new_block == null:
				continue
			new_block.graph_position += offset
			var graph_node: ScriptBlockGraphNode = create_block_graph_node(new_block)
			graph_node.selected = true
	if clipboard_json.has("comments") and clipboard_json["comments"] is Array:
		var comments: Array = clipboard_json["comments"]
		for comment_json in comments:
			var new_comment := VisualScriptComment.new()
			new_comment.setup_from_json(comment_json)
			new_comment.position += offset
			script_instance.comments.append(new_comment)
			create_comment_graph_node(new_comment)
	reset_graph_error_and_connections()
	script_contents_changed_by_editor()


func _paste_copied_script_blocks_local_clipboard() -> void:
	for clipboard_block in clipboard_script_blocks:
		# Sanity check: Validate all of our clipboard blocks are valid first.
		if not is_instance_valid(clipboard_block):
			clipboard_script_blocks.clear()
			return
	var offset: Vector2 = _paste_calculate_offset(clipboard_copy_position)
	for graph_node in block_graph_nodes:
		graph_node.selected = false
	var new_blocks = script_builder.duplicate_script_blocks(clipboard_script_blocks, offset)
	for block in new_blocks:
		var graph_node: ScriptBlockGraphNode = create_block_graph_node(block)
		graph_node.selected = true
	for comment in clipboard_script_comments:
		var new_comment: VisualScriptComment = comment.duplicate()
		new_comment.position += offset
		script_instance.comments.append(new_comment)
		create_comment_graph_node(new_comment)
	reset_graph_error_and_connections()
	script_contents_changed_by_editor()


func _paste_calculate_offset(copy_position: Vector2) -> Vector2:
	var offset: Vector2 = (scroll_offset + _mouse_position) / zoom - copy_position
	if offset.length_squared() < 1000.0:
		offset = Vector2(100.0, 100.0)
	return offset


func duplicate_selected_script_blocks() -> void:
	copy_selected_script_blocks(false)
	_paste_copied_script_blocks_local_clipboard()


# Deletion methods.
func cleanup_and_delete_nodes() -> void:
	if is_instance_valid(script_instance):
		script_instance.script_contents_changed.disconnect(_on_script_entity_data_changed)
		script_instance.script_entity_data_updated_from_network.disconnect(_on_script_entity_data_changed)
		script_instance.script_contents_deleted.disconnect(_delete_all_graph_nodes)
	_queue_update_network_script_frames = -1
	script_instance = null
	script_builder = null
	_delete_all_graph_nodes()


func _delete_all_graph_nodes() -> void:
	pre_delete_pan_scroll_offset = scroll_offset
	for block_graph_node in block_graph_nodes:
		block_graph_node.cleanup_and_delete()
	block_graph_nodes.clear()
	for comment_graph_node in comment_graph_nodes:
		comment_graph_node.cleanup_and_delete()
	comment_graph_nodes.clear()
	reset_graph_error_and_connections()


func delete_selected_script_blocks() -> void:
	# We have to iterate backwards over the array.
	var i = block_graph_nodes.size() - 1
	while i >= 0:
		var graph_node = block_graph_nodes[i]
		if graph_node.selected:
			_delete_script_block(graph_node)
		i -= 1
	i = comment_graph_nodes.size() - 1
	while i >= 0:
		var graph_node = comment_graph_nodes[i]
		if graph_node.selected:
			_delete_script_comment(graph_node)
		i -= 1
	script_contents_changed_by_editor()


func _delete_script_block(graph_node: ScriptBlockGraphNode) -> void:
	block_graph_nodes.erase(graph_node)
	remove_child(graph_node)
	script_builder.delete_script_block(graph_node.script_block)
	graph_node.queue_free()
	reset_graph_error_and_connections()


func _delete_script_comment(graph_node: GraphNode) -> void:
	comment_graph_nodes.erase(graph_node)
	remove_child(graph_node)
	script_instance.comments.erase(graph_node.script_comment)
	graph_node.queue_free()


func _on_delete_nodes_request(node_names: Array[StringName]) -> void:
	# We have to iterate backwards over the array.
	var i = block_graph_nodes.size() - 1
	while i >= 0:
		var graph_node = block_graph_nodes[i]
		if graph_node.name in node_names:
			_delete_script_block(graph_node)
		i -= 1
	script_contents_changed_by_editor()


func _on_script_block_close_request(graph_node: ScriptBlockGraphNode) -> void:
	_delete_script_block(graph_node)
	script_contents_changed_by_editor()


func _on_script_comment_close_request(graph_node: GraphNode) -> void:
	_delete_script_comment(graph_node)
	script_contents_changed_by_editor()


# Misc methods.
func focus_script_block(script_block: ScriptBlock, error_text: String) -> void:
	zoom = 1.0
	var graph_node: ScriptBlockGraphNode = script_block.graph_node
	set_selected(graph_node)
	scroll_offset = graph_node.position_offset + (graph_node.size - size) * 0.5
	if not error_text.is_empty():
		graph_node.show_error(error_text)


func rezoom_to_show_all_graph_nodes() -> void:
	# Keep a 500x500 area near the origin in view.
	var rect := Rect2(-100.0, -100.0, 400.0, 400.0)
	for graph_elem in get_children():
		if not graph_elem is GraphElement:
			continue
		var pos: Vector2 = graph_elem.position_offset
		rect = rect.expand(pos)
		rect = rect.expand(pos + graph_elem.size)
	zoom = minf(size.x / rect.size.x, size.y / rect.size.y) * 0.9
	scroll_offset = rect.get_center() * zoom - size * 0.5


func script_contents_changed_by_editor() -> void:
	script_builder.sync_blocks()
	_queue_update_network_script_frames = 5


func validate_script_comments() -> bool:
	if comment_graph_nodes.size() != script_instance.comments.size():
		return false
	if not comment_graph_nodes.is_empty():
		return is_instance_valid(comment_graph_nodes[0].script_comment)
	return true


func _on_script_entity_data_changed() -> void:
	_toolbar_buttons.setup_for_script_instance(script_instance)
	request_track_recently_used_space_script.emit(script_instance) # It might have changed.


func _on_request_comment_color_edit(comment_graph_node: GraphNode, color: Color) -> void:
	request_comment_color_edit.emit(comment_graph_node, color)


func _on_end_node_move() -> void:
	script_contents_changed_by_editor()
