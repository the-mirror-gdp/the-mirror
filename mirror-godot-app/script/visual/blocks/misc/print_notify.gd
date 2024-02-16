extends ScriptBlockPrintBase


signal print_notify(title: String, message: String, notify_status: Enums.NotifyStatus)


func setup(block_json: Dictionary) -> void:
	super(block_json)
	# Compatibility with old print blocks.
	if inputs.size() == 1:
		# Add a title input.
		var title_input := ScriptBlockInputPort.new()
		title_input.port_name = "Title"
		title_input.port_type = ScriptBlock.PortType.STRING
		title_input.value = "Script Notification"
		inputs.push_front(title_input)
		# Add a notify status input.
		var notify_status_input := ScriptBlockInputPort.new()
		notify_status_input.port_name = "Notify Status"
		notify_status_input.port_type = ScriptBlock.PortType.STRING
		notify_status_input.value = "Info"
		inputs.append(notify_status_input)


func _execute_callback(_stack_count: int) -> Error:
	var title: String = inputs[0].value
	var message: String = ScriptBlockPrintBase.value_to_friendly_string(inputs[1].value)
	var notify_status: Enums.NotifyStatus = _get_notify_status(inputs[2])
	# Note: Our notifications UI is very slow! This takes about 1 millisecond.
	print_notify.emit(title, message, notify_status)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[2]


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return ["Info", "Success", "Warning", "Error"]


func _get_notify_status(notify_status_port: ScriptBlockInputPort) -> Enums.NotifyStatus:
	var notify_status_string: String = notify_status_port.value
	match notify_status_string:
		"Success":
			return Enums.NotifyStatus.SUCCESS
		"Warning":
			return Enums.NotifyStatus.WARNING
		"Error":
			return Enums.NotifyStatus.ERROR
	# "Info" or fallback to info if not recognized.
	return Enums.NotifyStatus.INFO


func get_script_block_type() -> String:
	return "print_notify"
