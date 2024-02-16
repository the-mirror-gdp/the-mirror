extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 1) # Should be Unix timestamp int.
	assert(outputs.size() == 1) # Should be ISO 8601 datetime string.
	var input_time: int = type_convert(inputs[0].value, ScriptBlock.PortType.INT)
	outputs[0].value = Time.get_datetime_string_from_unix_time(input_time)


func get_script_block_type() -> String:
	return "unix_time_to_datetime_string"
