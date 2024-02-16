extends ScriptBlockSequenced


var capsule: JCapsuleShape3D = null


func _execute_callback(_stack_count: int) -> Error:
	if len(inputs) != 9:
		log_error.emit("The script node damage_using_capsule` should receive 9 inputs.")
		return ERR_INVALID_PARAMETER

	var so: SpaceObject = inputs[0].value
	var damage: float = inputs[1].value
	var impulse: float = inputs[2].value
	var can_damage_teams: Array = inputs[3].value
	var can_damage_self: bool = inputs[4].value
	var ignore: Array = inputs[5].value
	var collider_offset: Vector3 = inputs[6].value
	var height: float = inputs[7].value
	var radius: float = inputs[8].value

	if not is_instance_valid(so):
		log_error.emit("The `damage_using_capsule` must be called on a valid SpaceObject.")
		return ERR_INVALID_PARAMETER

	# Prepare the capsule first
	if not is_instance_valid(capsule):
		capsule = JCapsuleShape3D.new()

	capsule.height = height
	capsule.radius = radius

	# Cast the shape
	var res = Jolt.collide_shape(0, capsule, Transform3D(Basis.IDENTITY, so.global_transform * collider_offset), [], ignore)

	# Damage the object
	var damaged: Array = []
	for hit_info in res:
		var other_body = hit_info["body2"]
		if other_body == so and not can_damage_self:
			continue

		if other_body is SpaceObject:
			if not other_body.is_dead():
				other_body.damage(damage, so.name)
				damaged.push_back(other_body)
				var impulse_dir: Vector3 = (other_body.global_position - so.global_position).normalized()
				other_body.add_impulse(impulse_dir * impulse)

		elif other_body is Player:
			if not other_body.is_dead():
				other_body.damage(damage, so.name)
				damaged.push_back(other_body)
				var impulse_dir: Vector3 = (other_body.global_position - so.global_position).normalized()
				other_body.add_impulse(impulse_dir * impulse)

	outputs[0].value = damaged

	return OK


func get_script_block_type() -> String:
	return "damage_using_capsule"
