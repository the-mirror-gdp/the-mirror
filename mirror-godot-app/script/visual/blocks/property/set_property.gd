class_name ScriptBlockSetProperty
extends ScriptBlockOperationProperty


var _enum_values = null


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("property"):
		printerr("Tried to create a set property block but there was no property name.")
		return
	var property = StringName(block_json["property"])
	var registered_properties: Dictionary = ScriptPropertyRegistration.get_registered_properties()
	if property in registered_properties:
		property_name = property
		var registered_property_signature: Dictionary = registered_properties[property]
		if registered_property_signature.has("enum_values"):
			_enum_values = registered_property_signature["enum_values"]
	else:
		printerr("Tried to create a set property block for " + String(property) + " but it is not registered. This is unsecure, skipping.")


func _execute_callback(stack_count: int) -> Error:
	assert(inputs.size() == 2) # Should be exactly two inputs for the target object and value.
	var target_object: Object = get_operation_target_object()
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	if not property_name in target_object:
		log_error.emit("The target object does not have the requested property (" + String(property_name) + ").")
		return ERR_METHOD_NOT_FOUND
	var value = inputs[1].value
	if _enum_values is Array and not _enum_values.has(value):
		log_error.emit("The given value (" + String(value) + ") is not in the list of allowed values:\n" + str(_enum_values))
		return ERR_INVALID_PARAMETER
	set_property_on_target(target_object, value)
	if outputs.size() > 0:
		outputs[0].value = target_object
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return _enum_values and input_port == inputs[1]


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return _enum_values


func get_script_block_type() -> String:
	return "set_property"
