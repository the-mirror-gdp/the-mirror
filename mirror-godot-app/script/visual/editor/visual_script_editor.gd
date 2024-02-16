extends Control


signal request_save_script_as_asset(script_instance: ScriptInstance)
signal request_show_entry_creation_dialog(target_node: Node)
signal request_toggle_variable_editor()
signal request_visual_script_editor_visibility(is_visible: bool)

signal request_track_recently_used_space_script(script_instance: VisualScriptInstance)

var _creation_constraint: int
var _creation_data_type: int
var _creation_from_index: int
var _creation_from_block: ScriptBlock
var _creation_position: Vector2

var _script_instance: VisualScriptInstance
var _script_builder: VisualScriptBuilder

var _comment_being_color_edited: GraphNode
@onready var _comment_color_picker_popup: Popup = $ScriptCommentColorPickerPopup
@onready var _comment_color_picker_picker: ColorPicker = $ScriptCommentColorPickerPopup/ScriptCommentColorPicker

@onready var _script_block_creation_dialog: ConfirmationDialog = $ScriptBlockCreationDialog
@onready var _script_block_creation_menu: ScriptBlockCreationMenu = $ScriptBlockCreationDialog/ScriptBlockCreationMenu
@onready var _script_block_input_value_dialog: ConfirmationDialog = $ScriptBlockInputValueDialog
@onready var _script_block_input_enum_menu: Control = $ScriptBlockInputEnumMenu
@onready var _script_graph_edit: GraphEdit = $ScriptGraphEdit
@onready var _gdscript_code_edit: Window = $GDScriptCodeEditor


func _process(_delta: float) -> void:
	if _script_instance:
		_validate_script_instance()


func setup(signal_tree_populator: ScriptEntrySignalTreePopulator) -> void:
	var script_block_signatures: Array[Dictionary] = VisualScriptBlockRegistration.get_all_registered_script_blocks()
	_script_block_creation_menu.setup(signal_tree_populator, script_block_signatures)
	_script_graph_edit.setup(script_block_signatures)


func load_from_script_instance(script_instance: ScriptInstance, rezoom: bool = true) -> void:
	# Clean up old data.
	if is_instance_valid(_script_instance):
		_script_instance.script_about_to_run_from_signal.disconnect(_script_graph_edit.hide_all_errors)
		_script_instance.script_entity_data_updated_from_network.disconnect(refresh_script_graph_and_builder)
	_script_graph_edit.cleanup_and_delete_nodes()
	# Setup new data.
	_script_instance = script_instance
	_script_builder = script_instance.script_builder
	_script_graph_edit.create_graph_nodes(script_instance, rezoom)
	_script_block_creation_dialog.setup_for_script_instance(script_instance)
	_script_instance.script_about_to_run_from_signal.connect(_script_graph_edit.hide_all_errors)
	_script_instance.script_entity_data_updated_from_network.connect(refresh_script_graph_and_builder)
	if script_instance.script_builder.entry_blocks.is_empty() and Util.can_local_user_edit_scripts():
		request_show_entry_creation_dialog.emit(_script_instance.target_node)


func refresh_script_graph_and_builder() -> void:
	_script_graph_edit.cleanup_and_delete_nodes()
	_script_builder = _script_instance.script_builder
	_script_graph_edit.create_graph_nodes(_script_instance, false)
	_script_graph_edit.scroll_offset = _script_graph_edit.pre_delete_pan_scroll_offset


func focus_block_in_visual_script(script_instance: ScriptInstance, script_block: ScriptBlock, error_text: String) -> void:
	if _script_instance != script_instance:
		load_from_script_instance(script_instance)
	if script_block:
		_script_graph_edit.focus_script_block(script_block, error_text)


func copy_selected_script_blocks() -> void:
	_script_graph_edit.copy_selected_script_blocks()


func paste_copied_script_blocks() -> void:
	_script_graph_edit.paste_copied_script_blocks()


func duplicate_selected_script_blocks() -> void:
	_script_graph_edit.duplicate_selected_script_blocks()


func delete_selected_script_blocks() -> void:
	_script_graph_edit.delete_selected_script_blocks()


func request_close() -> bool:
	# In order of which dialogs should be the first to close when pressing Esc.
	if _comment_color_picker_popup.visible:
		_comment_color_picker_popup.hide()
	elif _script_block_input_value_dialog.visible:
		_script_block_input_value_dialog.hide()
	elif _script_block_creation_dialog.visible:
		_script_block_creation_dialog.hide()
	elif _gdscript_code_edit.visible:
		_gdscript_code_edit.hide()
	else:
		# If none of the dialogs are open, Esc closes the whole script editor.
		_cleanup_and_close_script_editor()
		return true
	return false


func cleanup_and_clear_script_editor() -> void:
	if is_instance_valid(_script_instance):
		_script_instance.script_about_to_run_from_signal.disconnect(_script_graph_edit.hide_all_errors)
	_script_instance = null
	_script_builder = null
	_script_graph_edit.cleanup_and_delete_nodes()


func _cleanup_and_close_script_editor() -> void:
	cleanup_and_clear_script_editor()
	request_visual_script_editor_visibility.emit(false)


## This is not a block that the builder knows about, just a comment.
func create_comment(where: Vector2) -> void:
	var center_pos: Vector2 = (where / 20).round() * 20
	var script_comment := VisualScriptComment.new()
	script_comment.position = center_pos - Vector2(80, 40)
	_script_instance.comments.append(script_comment)
	_script_graph_edit.create_comment_graph_node(script_comment)
	_script_instance.script_data_contents_changed()


func _validate_script_instance() -> void:
	assert(_script_instance == _script_graph_edit.script_instance)
	if not is_instance_valid(_script_instance):
		# If the script event is no longer valid, clear the script editor.
		_cleanup_and_close_script_editor()
		return
	assert(is_instance_valid(_script_instance.script_builder))
	var attached_object: Object = _script_instance.script_builder.attached_object
	assert(attached_object == null or is_instance_valid(attached_object))
	if _script_builder != _script_instance.script_builder:
		load_from_script_instance(_script_instance, false)
	elif not _script_graph_edit.validate_script_comments():
		load_from_script_instance(_script_instance, false)


func _on_request_block_creation(constraint: int, data_type: int, index: int, from_block: ScriptBlock, where: Vector2) -> void:
	if data_type == ScriptBlock.PortType.CONNECTION:
		data_type = ScriptBlock.PortType.ANY_DATA
	_creation_constraint = constraint
	_creation_data_type = data_type
	_creation_from_index = index
	_creation_from_block = from_block
	_creation_position = where
	_script_block_creation_dialog.request_block_creation(constraint, data_type)


func _on_request_entry_creation(where: Vector2) -> void:
	_creation_position = where
	request_show_entry_creation_dialog.emit(_script_instance.target_node)


func _on_request_input_value_edit(graph_node: ScriptBlockGraphNode, input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	var is_port_enumerated: bool = graph_node.is_port_enumerated(input_port)
	if is_port_enumerated:
		_script_block_input_enum_menu.edit_input_value(graph_node, input_port)
	else:
		_script_block_input_value_dialog.edit_input_value(graph_node, input_port)


func create_new_script_block_from_json(block_json: Dictionary) -> void:
	var script_block: ScriptBlock = _script_instance.script_builder.create_block(block_json)
	if script_block is ScriptBlockEntryBase:
		# For new entries, we need to sync the parameter list and connect the node.
		_script_instance.sync_script_inst_params_with_script_data()
		_script_instance.setup_entry_block_with_node(script_block)
	else:
		if script_block is ScriptBlockMath and \
				_creation_data_type in ScriptBlockMath.MATH_PORT_TYPES:
			# If the block we are creating is a math block, and the port we are coming
			# from is a math port, set the type of that math block to the port's type.
			script_block.change_primary_type_selection(_creation_data_type)
		_connect_port_for_creation_constraint(script_block)
	# Now that the script is set up with the entry, update the script editor.
	if script_block.graph_position == Vector2.ZERO:
		script_block.graph_position = _creation_position
	_script_graph_edit.create_block_graph_node(script_block)
	_script_graph_edit.reset_graph_error_and_connections()
	_script_instance.script_data_contents_changed()


func _connect_port_for_creation_constraint(script_block: ScriptBlock) -> void:
	# Connect the first compatible port of the new block to where we dragged from.
	match _creation_constraint:
		ScriptBlockCreationMenu.ConstraintType.SEQUENCED_RUN:
			if _creation_from_block is ScriptBlockSequenced:
				if _creation_from_index == -1:
					script_block.flows[0].connected_block = _creation_from_block
				else:
					_creation_from_block.flows[_creation_from_index].connected_block = script_block
		ScriptBlockCreationMenu.ConstraintType.INPUT:
			for port in script_block.inputs:
				if _script_graph_edit.is_valid_connection_type(_creation_data_type, port.port_type):
					port.connected_block = _creation_from_block
					port.connected_output = _creation_from_index
					break
		ScriptBlockCreationMenu.ConstraintType.OUTPUT:
			var input = _creation_from_block.inputs[_creation_from_index]
			for i in script_block.outputs.size():
				var output: ScriptBlock.ScriptBlockDataPort = script_block.outputs[i]
				if _script_graph_edit.is_valid_connection_type(output.port_type, _creation_data_type):
					input.connected_block = script_block
					input.connected_output = i
					if _creation_from_block is ScriptBlockEvaluateNow:
						# Special case: Update this block's output to match the connected block's output.
						_creation_from_block.outputs[0].port_type = output.port_type
						_creation_from_block.outputs[0].value = output.value
					_creation_from_block.graph_node.reset_ports()
					break


func _on_input_value_changed() -> void:
	_script_instance.script_data_contents_changed()


func _on_script_comment_color_edit(comment_graph_node: GraphNode, color: Color) -> void:
	_comment_being_color_edited = comment_graph_node
	_comment_color_picker_picker.color = color
	_comment_color_picker_popup.popup(Rect2(get_global_mouse_position(), Vector2()))


func _on_script_comment_color_picker_popup_hide() -> void:
	_script_instance.script_data_contents_changed()


func _on_script_comment_color_picker_changed(color: Color) -> void:
	if is_instance_valid(_comment_being_color_edited):
		_comment_being_color_edited.set_comment_color(color)


func _on_request_reload_script_editor() -> void:
	load_from_script_instance(_script_instance, false)


func _on_request_save_script_as_asset() -> void:
	request_save_script_as_asset.emit(_script_instance)


func _on_request_toggle_variable_editor() -> void:
	request_toggle_variable_editor.emit()


func _on_request_track_recently_used_space_script(script_instance: VisualScriptInstance) -> void:
	request_track_recently_used_space_script.emit(script_instance)
