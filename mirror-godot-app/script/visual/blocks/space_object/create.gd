extends ScriptBlockAsync


const _DEG_TO_RAD = 0.0174532925199432957692369077

var attached_object: Object


func await_correct_so_with_receipt_uuid(receipt_uuid: String) -> SpaceObject:
	var received_receipt_uuid := ""
	while received_receipt_uuid != receipt_uuid:
		var data = await Zone.instance_manager.space_object_created
		if data[1] == receipt_uuid:
			return data[0]
	return null


func _execute_callback(_stack_count: int) -> Error:
	var asset_id: String = inputs[0].value
	if asset_id.length() < 20:
		log_error.emit("Tried to create a SpaceObject, but the Asset ID was not valid.")
		return ERR_INVALID_PARAMETER
	var name: String = inputs[1].value
	var position: Vector3 = inputs[2].value
	var rotation: Vector3 = Vector3(inputs[3].value) * _DEG_TO_RAD
	var relative: bool = inputs[4].value
	var scale: Vector3 = inputs[5].value
	var offset: Vector3 = inputs[6].value
	var collision_enabled: bool = inputs[7].value
	var physics_shape_type: String = inputs[8].value
	if inputs[9].port_type == ScriptBlock.PortType.BOOL:
		log_error.emit("Please delete and re-create the Create Space Object block.")
		return ERR_INVALID_PARAMETER
	var physics_body_type: String = inputs[9].value
	var mass: float = inputs[10].value
	var gravity_scale: float = inputs[11].value
	var damageable: bool = inputs[12].value if inputs.size() >= 13 else false
	if relative:
		var attached_object_transform: Transform3D = attached_object.global_transform
		position = attached_object_transform * position
		rotation = (attached_object_transform.basis * Basis.from_euler(rotation)).get_euler()
	var space_object_data: Dictionary = {
		"asset": asset_id,
		"name": name,
		"position": Serialization.vector3_to_array(position),
		"rotation": Serialization.vector3_to_array(rotation),
		"scale": Serialization.vector3_to_array(scale),
		"offset": Serialization.vector3_to_array(offset),
		"collisionEnabled": collision_enabled,
		"shapeType": physics_shape_type,
		"bodyType": physics_body_type,
		"massKg": mass,
		"gravityScale": gravity_scale,
		"damage_handler_enabled": damageable,
	}
	var receipt_uuid: String = UUID.generate_guid()
	if Zone.is_host():
		var receipt = Zone.receipt_create("", false, receipt_uuid)
		Zone.server_create_space_object(space_object_data, receipt)
	else:
		var receipt = Zone.receipt_create(PlayerData.get_local_user_id(), false, receipt_uuid)
		Zone.client_send_create_space_object(space_object_data, receipt)

	var saved_state = save_execution_state(self)
	var so = await await_correct_so_with_receipt_uuid(receipt_uuid)
	load_execution_state(saved_state)
	if outputs.size() > 0:
		outputs[0].value = so
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[8] or input_port == inputs[9]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[8]:
		return ["Auto", "Convex", "Concave", "Model Shapes", "Multi Bodies", "Capsule"]
	if input_port == inputs[9]:
		return ["Static", "Kinematic", "Dynamic", "Trigger"]
	assert(false, "Should not be reached, the code should never try to get the enum values from a non-enumerated port.")
	return []


func get_script_block_type() -> String:
	return "create_space_object"
