extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 6) # Should be datetime values: YMDhms.
	assert(outputs.size() == 1) # Should be Unix timestamp int.
	var date_dict: Dictionary = {
		"year": type_convert(inputs[0].value, ScriptBlock.PortType.INT),
		"month": type_convert(inputs[1].value, ScriptBlock.PortType.INT),
		"day": type_convert(inputs[2].value, ScriptBlock.PortType.INT),
		"hour": type_convert(inputs[3].value, ScriptBlock.PortType.INT),
		"minute": type_convert(inputs[4].value, ScriptBlock.PortType.INT),
		"second": type_convert(inputs[5].value, ScriptBlock.PortType.INT),
	}
	outputs[0].value = Time.get_unix_time_from_datetime_dict(date_dict)


func get_script_block_type() -> String:
	return "datetime_values_to_unix_time"
