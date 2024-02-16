extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var variable_name = inputs[0].value
	outputs[0].value = Zone.script_network_sync.has_global_variable(variable_name)


func get_script_block_type() -> String:
	return "has_global_variable"
