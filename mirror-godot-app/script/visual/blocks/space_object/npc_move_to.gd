extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if len(inputs) != 17:
		log_error.emit("The script node `npc_move_to` should receive 17 inputs.")
		return ERR_INVALID_PARAMETER

	var so: SpaceObject = inputs[0].value

	var target_location: Vector3 = inputs[1].value
	var acceleration: float = inputs[2].value
	var deceleration: float = inputs[3].value
	var max_speed: float = inputs[4].value
	var step_height: float = inputs[5].value
	var max_push_force: float = inputs[6].value
	var supporting_volume: float = inputs[7].value
	var gravity: float = inputs[8].value
	var min_target_distance: float = inputs[9].value
	var max_target_distance: float = inputs[10].value
	var base_location: Vector3 = inputs[11].value
	var steering_ray_offset: Vector3 = inputs[12].value
	var steering_ray_length: float = inputs[13].value
	var steering_ray_radius: float = inputs[14].value
	var steering_ignore: Array = inputs[15].value
	var rotation_offset: float = inputs[16].value

	if not is_instance_valid(so):
		log_error.emit("The `npc_move_to` must be called on a valid SpaceObject.")
		return ERR_INVALID_PARAMETER

	if not so.is_kinematic():
		log_error.emit("The `npc_move_to` can't move a SpaceObject of which body_mode is NOT kinematic.")
		return ERR_INVALID_PARAMETER

	outputs[0].value = so.npc_move_to(target_location, acceleration, deceleration, max_speed, step_height, max_push_force, supporting_volume, gravity, min_target_distance, max_target_distance, base_location, steering_ray_offset, steering_ray_length, steering_ray_radius, steering_ignore, rotation_offset)

	return OK


func get_script_block_type() -> String:
	return "npc_move_to"
