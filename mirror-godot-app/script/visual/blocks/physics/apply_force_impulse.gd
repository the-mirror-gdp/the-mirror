extends ScriptBlockPhysicsSequenced


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return ERR_UNAUTHORIZED
	var physics_body: JBody3D = get_physics_body_node()
	if physics_body == null:
		log_error.emit("Unable to find the physics body node.")
		return ERR_INVALID_PARAMETER
	var impulse_amount: Vector3 = inputs[1].value
	physics_body.add_impulse(impulse_amount * 100.0)
	return OK


func get_script_block_type() -> String:
	return "apply_force_impulse"
