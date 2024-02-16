extends ScriptBlockPhysicsSequenced


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return ERR_UNAUTHORIZED
	var physics_body: JBody3D = get_physics_body_node()
	if physics_body == null:
		log_error.emit("Unable to find the physics body node.")
		return ERR_INVALID_PARAMETER
	if physics_body.is_static():
		log_error.emit("Tried to move a Static body, but this is not allowed. Try using Kinematic instead.")
		return ERR_INVALID_DATA
	var movement_amount: Vector3 = inputs[1].value
	var collide_with_layers: Array = [
		&"STATIC",
		&"KINEMATIC",
		&"CHARACTER",
		&"DYNAMIC",
	]
	physics_body.move_and_collide(movement_amount, collide_with_layers)
	return OK


func get_script_block_type() -> String:
	return "move_and_collide"
