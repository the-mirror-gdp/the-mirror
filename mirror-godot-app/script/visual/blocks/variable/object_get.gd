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
		log_error.emit("No variables have been set on this object.")
		outputs[0].value = type_convert(null, type)
		return
	var object_variables = variable_object.get_meta(&"MirrorScriptObjectVariables")
	var value = TMDataUtil.get_variable_by_json_path_string(object_variables, variable_name)
	if type != ScriptBlock.PortType.ANY_DATA:
		value = type_convert(value, type)
	outputs[0].value = value


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if edited_input_port.port_name != "Variable Name":
		return
	var variable_object = inputs[0].value
	if variable_object == null:
		variable_object = attached_object
	if not variable_object.has_meta(&"MirrorScriptObjectVariables"):
		return
	var object_variables = variable_object.get_meta(&"MirrorScriptObjectVariables")
	var variable_name: String = edited_input_port.value
	var variable_value = TMDataUtil.get_variable_by_json_path_string(object_variables, variable_name)
	outputs[0].port_type = typeof(variable_value)
	outputs[0].value = variable_value


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[0].port_type = type
	outputs[0].value = type_convert(outputs[0].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	outputs[0].port_type = typeof(value)
	outputs[0].value = value


func get_script_block_type() -> String:
	return "get_object_variable"
