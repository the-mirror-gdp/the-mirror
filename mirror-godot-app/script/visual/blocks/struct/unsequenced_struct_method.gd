class_name ScriptBlockUnsequencedStructMethod
extends ScriptBlock


var method_name: StringName


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not block_json.has("method"):
		printerr("Tried to create a method block but there was no method name.")
		return
	method_name = StringName(String(block_json["method"]))


func evaluate() -> void:
	evaluate_inputs()
	var target_variant = inputs[0].value
	outputs[0].value = target_variant # Pass
	# If we use output 0, we aren't passing the target variant through.
	# If we use output 1, the method's return value is placed after the target variant.
	match method_name:
		&"angle_to":
			outputs[0].value = rad_to_deg(target_variant.angle_to(inputs[1].value))
		&"clamp":
			outputs[0].value = target_variant.clamp(inputs[1].value, inputs[2].value)
		&"distance_to":
			outputs[0].value = target_variant.distance_to(inputs[1].value)
		&"is_empty":
			outputs[1].value = target_variant.is_empty()
		&"length":
			outputs[1].value = target_variant.length()
		&"move_toward":
			outputs[0].value = target_variant.move_toward(inputs[1].value, inputs[2].value)
		&"project":
			outputs[0].value = target_variant.project(inputs[1].value)
		&"size":
			outputs[1].value = target_variant.size()
		_:
			assert(false, "Registered unsequenced struct methods need to be defined here too.")


func get_script_block_type() -> String:
	return "unsequenced_struct_method"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "unsequenced_struct_method"
	ret["method"] = String(method_name)
	return ret
