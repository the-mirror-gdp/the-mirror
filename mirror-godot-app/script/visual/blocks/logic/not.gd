extends ScriptBlock


func setup(block_json: Dictionary) -> void:
	_setup_base(block_json)
	if inputs.size() == 0:
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Input"
		inputs.append(input_port)
	if outputs.size() == 0:
		var output_port = ScriptBlockDataPort.new()
		output_port.port_name = "Result"
		outputs.append(output_port)


func evaluate() -> void:
	super()
	var input: bool = type_convert(inputs[0].value, ScriptBlock.PortType.BOOL)
	outputs[0].value = not input


func get_script_block_type() -> String:
	return "not"
