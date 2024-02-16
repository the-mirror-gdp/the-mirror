## Block used for reading properties of objects.
## For security reasons, valid properties are whitelisted via registration.
class_name ScriptBlockGetProperty
extends ScriptBlock


var attached_object: Object
var property_name: StringName


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("property"):
		printerr("Tried to create a get property block but there was no property name.")
		return
	var property = StringName(block_json["property"])
	if ScriptPropertyRegistration.has_registered_property(property):
		property_name = property
	else:
		printerr("Tried to create a get property block for " + String(property) + " but it is not registered. This is unsecure, skipping.")


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 1) # Should be exactly one input for the target object.
	var target_object: Object
	if inputs[0].connected_block == null:
		target_object = attached_object
	else:
		target_object = type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return
	get_property_on_target(target_object)
	if outputs.size() > 1:
		outputs[0].value = target_object


func get_property_on_target(target_object: Object) -> void:
	if not property_name in target_object:
		log_error.emit("The target object does not have the requested property (" + String(property_name) + ").")
		return
	var ret = target_object.get(property_name)
	if outputs.size() == 1:
		outputs[0].value = ret
	else:
		outputs[1].value = ret


func get_script_block_type() -> String:
	return "get_property"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "get_property"
	ret["property"] = String(property_name)
	return ret
