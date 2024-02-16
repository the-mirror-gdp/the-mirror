extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	assert(outputs.size() == 1) # Should be Unix time float output.
	outputs[0].value = Time.get_unix_time_from_system()


func get_script_block_type() -> String:
	return "get_unix_time_utc"
