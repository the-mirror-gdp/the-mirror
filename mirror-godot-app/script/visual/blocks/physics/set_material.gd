extends ScriptBlockPhysicsSequenced


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return ERR_UNAUTHORIZED
	var physics_body: JBody3D = get_physics_body_node()
	if physics_body == null:
		log_error.emit("Unable to find the physics body node.")
		return ERR_INVALID_PARAMETER
	# Input 0 is the body, so properties start from 1.
	physics_body.friction = inputs[1].value
	physics_body.bounciness = inputs[2].value
	return OK


func get_script_block_type() -> String:
	return "set_physics_material_properties"
