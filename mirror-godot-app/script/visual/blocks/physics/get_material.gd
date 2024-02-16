extends ScriptBlockPhysicsUnsequenced


func evaluate() -> void:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return
	evaluate_inputs()
	var physics_body: JBody3D = get_physics_body_node()
	if physics_body == null:
		log_error.emit("Unable to find the physics body node.")
		return
	outputs[0].value = physics_body.friction
	outputs[1].value = physics_body.bounciness


func get_script_block_type() -> String:
	return "get_physics_material_properties"
