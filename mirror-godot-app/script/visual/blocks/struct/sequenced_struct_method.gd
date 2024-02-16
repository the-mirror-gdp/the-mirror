## Block used for calling sequenced methods on other objects.
## For security reasons, valid methods are whitelisted via registration.
class_name ScriptBlockSequencedStructMethod
extends ScriptBlockSequenced


var method_name: StringName


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("method"):
		printerr("Tried to create a method block but there was no method name.")
		return
	method_name = StringName(String(block_json["method"]))


func _execute_callback(stack_count: int) -> Error:
	var target_variant = inputs[0].value
	outputs[0].value = target_variant # Pass
	match method_name:
		&"duplicate":
			outputs[0].value = target_variant.duplicate(inputs[1].value)
		&"sort":
			target_variant.sort()
		&"shuffle":
			target_variant.shuffle()
		_:
			assert(false, "Registered sequenced struct methods need to be defined here too.")
	return OK


func get_script_block_type() -> String:
	return "sequenced_struct_method"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "sequenced_struct_method"
	ret["method"] = String(method_name)
	return ret
