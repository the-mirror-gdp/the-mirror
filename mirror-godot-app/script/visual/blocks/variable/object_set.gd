extends ScriptBlockOperationObjectVariable


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object = get_target_object()
	var variable_name: String = inputs[1].value
	var variable_value: Variant = inputs[2].value
	if target_object == null:
		target_object = attached_object
	if target_object is Node:
		# This will also set it locally immediately.
		Zone.script_network_sync.set_variable_on_node(target_object, variable_name, variable_value)
	else:
		# Allow setting on non-Node objects, but only locally, since we don't
		# have a way to keep track of non-Node references over the network.
		if not target_object.has_meta(&"MirrorScriptObjectVariables"):
			target_object.set_meta(&"MirrorScriptObjectVariables", {})
		var object_variables: Dictionary = target_object.get_meta(&"MirrorScriptObjectVariables")
		TMDataUtil.set_variable_by_json_path_string(object_variables, variable_name, variable_value)
		Zone.script_network_sync.object_variable_changed.emit(target_object, variable_name, variable_value)
	return OK


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	inputs[2].port_type = type
	inputs[2].value = type_convert(inputs[2].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[2].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	inputs[2].port_type = typeof(value)
	inputs[2].value = value


func get_script_block_type() -> String:
	return "set_object_variable"
