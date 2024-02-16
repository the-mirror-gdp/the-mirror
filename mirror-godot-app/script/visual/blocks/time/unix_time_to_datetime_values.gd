extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 1) # Should be Unix timestamp int.
	assert(outputs.size() == 6) # Should be datetime values: YMDhms.
	var input_time: int = type_convert(inputs[0].value, ScriptBlock.PortType.INT)
	var datetime_dict: Dictionary = Time.get_datetime_dict_from_unix_time(input_time)
	outputs[0].value = datetime_dict["year"]
	outputs[1].value = datetime_dict["month"]
	outputs[2].value = datetime_dict["day"]
	outputs[3].value = datetime_dict["hour"]
	outputs[4].value = datetime_dict["minute"]
	outputs[5].value = datetime_dict["second"]


func get_script_block_type() -> String:
	return "unix_time_to_datetime_values"
