extends ScriptBlockPhysicsSequenced


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return ERR_UNAUTHORIZED
	var physics_body: JBody3D = get_physics_body_node()
	if physics_body == null:
		log_error.emit("Unable to find the physics body node.")
		return ERR_INVALID_PARAMETER
	var force_amount: Vector3 = inputs[1].value * 100.0
	var duration: float = inputs[2].value
	MirrorScriptServer.add_force_to_body_over_time(physics_body, force_amount, duration)
	Zone.script_network_sync.server_add_force_to_body_over_time(physics_body, force_amount, duration)
	return OK


func get_script_block_type() -> String:
	return "apply_force_over_time"
