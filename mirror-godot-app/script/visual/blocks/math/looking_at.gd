class_name ScriptBlockRotationLookingAt
extends ScriptBlock


const _RAD_TO_DEG = 57.295779513082320876798154814

var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var positive: Vector3
	var negative: Vector3
	if inputs[0].port_type == ScriptBlock.PortType.VECTOR3:
		positive = inputs[0].value
		negative = inputs[1].value
	else: # if inputs[0].port_type == ScriptBlock.PortType.OBJECT:
		var positive_node = inputs[0].value
		if not positive_node is Node3D:
			positive_node = attached_object
		positive = positive_node.global_position
		var negative_node = inputs[1].value
		if not negative_node is Node3D:
			negative_node = attached_object
		negative = negative_node.global_position
	# By this point we have the positive/negative vectors and can do math on them.
	if positive.is_equal_approx(negative):
		return
	var up: Vector3 = inputs[2].value
	var direction: Vector3 = negative - positive
	if up.cross(direction).is_zero_approx():
		return
	outputs[0].value = Basis.looking_at(direction, up).get_euler() * _RAD_TO_DEG


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	inputs[0].port_type = type
	inputs[0].value = type_convert(inputs[0].value, type)
	inputs[1].port_type = type
	inputs[1].value = type_convert(inputs[1].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[0].port_type


func get_script_block_type() -> String:
	return "looking_at"
