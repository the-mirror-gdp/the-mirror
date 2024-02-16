extends KeyboardGrabbingConfirmationDialog


signal input_value_changed()

const _INSPECTOR_NUMBER_SLIDER = preload("res://creator/selection/inspector/primitive/inspector_number_slider.tscn")
const _INSPECTOR_TEXT_FIELD = preload("res://creator/selection/inspector/primitive/inspector_text_field.tscn")

var _edited_graph_node: ScriptBlockGraphNode
var _edited_input_port: ScriptBlock.ScriptBlockInputPort
var _primitive_value_editor: Control


func edit_input_value(graph_node: ScriptBlockGraphNode, input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	_edited_graph_node = graph_node
	_edited_input_port = input_port
	assert(input_port.port_type in ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES)
	var primitive_scene = ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES[input_port.port_type]
	var input_limits: Vector2 = graph_node.get_input_limits(input_port)
	if input_port.port_type == ScriptBlock.PortType.STRING:
		# Use a larger editor for regular Strings to allow for newlines.
		primitive_scene = _INSPECTOR_TEXT_FIELD
	elif input_port.port_type == ScriptBlock.PortType.FLOAT and input_limits != Vector2.ZERO:
		# Use a slider for input values that indicate they should be limited.
		primitive_scene = _INSPECTOR_NUMBER_SLIDER
	_primitive_value_editor = primitive_scene.instantiate()
	_primitive_value_editor.label_text = input_port.port_name
	add_child(_primitive_value_editor)
	_primitive_value_editor.value_submitted.connect(_on_confirmed_and_close)
	# Be careful, the order matters here! Properties with setters that use
	# onready vars can only be used after adding as a child.
	var port_value: Variant = _edited_input_port.value
	if input_port.port_type == ScriptBlock.PortType.ANY_DATA:
		# Special case: Allow editing "Any Data" like a String.
		port_value = str(port_value)
	elif input_port.port_type == ScriptBlock.PortType.FLOAT and input_limits != Vector2.ZERO:
		_primitive_value_editor.min_value = input_limits.x
		_primitive_value_editor.max_value = input_limits.y
	_primitive_value_editor.current_value = port_value
	if _primitive_value_editor.has_method(&"refresh"):
		_primitive_value_editor.refresh()
	var rect := Rect2(graph_node.get_global_mouse_position(), Vector2(280, 84))
	rect.position += Vector2(rect.size.x * -0.5, rect.size.y * 0.5)
	popup(rect)


func _on_confirmed_and_close() -> void:
	_on_confirmed()
	hide()


func _on_confirmed() -> void:
	if not is_instance_valid(_edited_input_port) or not is_instance_valid(_edited_graph_node):
		return
	var new_value = _primitive_value_editor.current_value
	if _primitive_value_editor.has_method(&"get_value_at_index"):
		new_value = _primitive_value_editor.get_value_at_index(new_value)
	# Special case: Change the String to another type if this port is "Any Data".
	if _edited_input_port.port_type == ScriptBlock.PortType.ANY_DATA:
		new_value = Serialization.convert_any_data_string_to_value(new_value)
	_edited_input_port.value = new_value
	# Update the edited script block if needed.
	if _edited_graph_node.script_block.has_method(&"update_block_signature"):
		_edited_graph_node.script_block.update_block_signature(_edited_input_port)
	_edited_graph_node.reset_ports()
	_cleanup()
	input_value_changed.emit()


func _on_canceled() -> void:
	_cleanup()


func _cleanup() -> void:
	_edited_graph_node = null
	_edited_input_port = null
	if is_instance_valid(_primitive_value_editor):
		_primitive_value_editor.cleanup_and_delete()
		remove_child(_primitive_value_editor)
		_primitive_value_editor = null
