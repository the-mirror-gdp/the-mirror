extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var variable_object = inputs[0].value
	var variable_name = inputs[1].value
	if variable_object == null:
		variable_object = attached_object
	var type = outputs[0].port_type
	if not variable_object.has_meta(&"MirrorScriptObjectVariables"):
		outputs[0].value = false
		return
	var object_variables = variable_object.get_meta(&"MirrorScriptObjectVariables")
	var value = TMDataUtil.has_variable_by_json_path_string(object_variables, variable_name)
	outputs[0].value = value


func get_script_block_type() -> String:
	return "has_object_variable"
