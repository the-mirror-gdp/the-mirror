## Base class for operations on properties (like set, add, multiply).
class_name ScriptBlockOperationProperty
extends ScriptBlockOperationBase


var property_name: StringName


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("property"):
		printerr("Tried to create a property block but there was no property name.")
		return
	var property = StringName(block_json["property"])
	var registered_properties: Dictionary = ScriptPropertyRegistration.get_registered_properties()
	if property in registered_properties:
		property_name = property
	else:
		printerr("Tried to create a property block for " + String(property) + " but it is not registered. This is unsecure, skipping.")


func set_property_on_target(target_object: Object, value: Variant):
	if target_object is Node:
		# This will also set it locally immediately.
		Zone.script_network_sync.set_property_on_node(target_object, property_name, value)
	else:
		target_object.set(property_name, value)


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["property"] = String(property_name)
	return ret
