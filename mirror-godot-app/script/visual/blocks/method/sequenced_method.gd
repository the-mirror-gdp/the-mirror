## Block used for calling sequenced methods on other objects.
## For security reasons, valid methods are whitelisted via registration.
class_name ScriptBlockSequencedMethod
extends ScriptBlockSequenced


var attached_object: Object
var method_name: StringName


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("method"):
		printerr("Tried to create a method block but there was no method name.")
		return
	var method = StringName(String(block_json["method"]))
	if ScriptMethodRegistration.has_registered_method(method):
		method_name = method
	else:
		printerr("Tried to create a method block for " + String(method) + " but it is not registered. This is unsecure, skipping.")


func _execute_callback(stack_count: int) -> Error:
	assert(inputs.size() > 0) # Should be at least one input for the target object.
	var target_object: Object
	if inputs[0].connected_block == null:
		target_object = attached_object
	else:
		target_object = type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	var arguments: Array = []
	for i in range(1, inputs.size()):
		arguments.append(inputs[i].value)
	return call_method_on_target(target_object, arguments)


func call_method_on_target(target_object: Object, arguments: Array) -> int:
	if not target_object.has_method(method_name):
		log_error.emit("The target object does not have the requested method (" + String(method_name) + ").")
		return ERR_METHOD_NOT_FOUND
	var ret = target_object.callv(method_name, arguments)
	if outputs.size() == 1:
		var output: ScriptBlockDataPort = outputs[0]
		if output.port_name == "Pass":
			outputs[0].value = target_object
		else:
			outputs[0].value = ret
	elif outputs.size() > 1:
		outputs[0].value = target_object
		outputs[1].value = ret
	return OK


func get_script_block_type() -> String:
	return "sequenced_method"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "sequenced_method"
	ret["method"] = String(method_name)
	return ret
