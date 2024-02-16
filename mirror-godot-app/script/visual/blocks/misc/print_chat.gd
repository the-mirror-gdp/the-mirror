extends ScriptBlockPrintBase


var attached_object: Object


func setup(block_json: Dictionary) -> void:
	super(block_json)
	update_block_signature(inputs[1])


func _execute_callback(_stack_count: int) -> Error:
	var message: String = ScriptBlockPrintBase.value_to_friendly_string(inputs[0].value)
	var range_radius: float = inputs[1].value
	if range_radius <= 0.0:
		range_radius = INF
	GameUI.chat_ui.send_message_from_object(attached_object, message, range_radius)
	return OK


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if edited_input_port.port_name != "Range":
		return
	if edited_input_port.value <= 0.0:
		graph_name = "Print In Chat (Global)"
	elif edited_input_port.value < 2.0:
		graph_name = "Whisper In Chat"
	elif edited_input_port.value < 40.0:
		graph_name = "Say In Chat"
	else:
		graph_name = "Shout In Chat"
	if graph_node:
		graph_node.title = graph_name


func get_script_block_type() -> String:
	return "print_chat"
