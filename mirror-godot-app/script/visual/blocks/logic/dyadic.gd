## Ensures that the block has at least two inputs and at least one output.
class_name ScriptBlockDyadic
extends ScriptBlock


func setup(block_json: Dictionary) -> void:
	_setup_base(block_json)
	if inputs.size() == 0:
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Left"
		inputs.append(input_port)
	if inputs.size() == 1:
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Right"
		inputs.append(input_port)
	if outputs.size() == 0:
		var output_port = ScriptBlockDataPort.new()
		output_port.port_name = "Result"
		outputs.append(output_port)
