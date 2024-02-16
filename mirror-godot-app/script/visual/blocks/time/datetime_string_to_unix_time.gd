extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 1) # Should be ISO 8601 datetime string.
	assert(outputs.size() == 1) # Should be Unix timestamp int.
	var iso_8601_date: String = type_convert(inputs[0].value, ScriptBlock.PortType.STRING)
	outputs[0].value = Time.get_unix_time_from_datetime_string(iso_8601_date)


func get_script_block_type() -> String:
	return "datetime_string_to_unix_time"
