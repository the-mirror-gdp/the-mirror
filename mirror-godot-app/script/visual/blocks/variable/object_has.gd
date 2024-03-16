extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var variable_object = inputs[0].value
	var variable_name = inputs[1].value
	if variable_object == null:
		variable_object = attached_object
	outputs[0].value = Mirror.has_object_variable(variable_object, variable_name)


func get_script_block_type() -> String:
	return "has_object_variable"
