extends ScriptBlockPhysicsSequenced


const _RAYCASTABLE_LAYERS_NO_TRIGGER: Array[StringName] = [
	&"STATIC",
	&"KINEMATIC",
	&"CHARACTER",
	&"DYNAMIC",
]

const _RAYCASTABLE_LAYERS_WITH_TRIGGER: Array[StringName] = [
	&"STATIC",
	&"KINEMATIC",
	&"CHARACTER",
	&"DYNAMIC",
	&"TRIGGER",
]


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_client():
		log_error.emit("Physics blocks can only run on the server, not the client.")
		return ERR_UNAUTHORIZED
	var from: Vector3 = inputs[0].value
	var direction: Vector3 = inputs[1].value
	var length: float = inputs[2].value
	var sphere_radius: float = inputs[3].value
	var hit_triggers: bool = inputs[4].value
	var ignore_self: bool = inputs[5].value
	var ignore_objects: Array = inputs[6].value.duplicate(false)
	# Ensure all objects in the ignore objects array are physics objects.
	# In case a subnode was passed, find the parent physics object.
	for i in range(ignore_objects.size()):
		var obj = ignore_objects[i]
		if not obj is JBody3D:
			var jbody_maybe = Util.recursive_get_node_from_type(obj, JBody3D)
			if not jbody_maybe is JBody3D:
				log_error.emit("Ignore Objects array contains a non-physics object: " + obj)
				return ERR_INVALID_PARAMETER
			ignore_objects[i] = jbody_maybe
	# If ignore self is true, add the attached object to the ignore objects array.
	if ignore_self:
		if attached_object is JBody3D:
			ignore_objects.append(attached_object)
	var layers: Array[StringName] = _RAYCASTABLE_LAYERS_WITH_TRIGGER if hit_triggers else _RAYCASTABLE_LAYERS_NO_TRIGGER
	var sorted_hits: Array[Dictionary] = Jolt.high_level_ray_or_shape_cast(from, direction, length, sphere_radius, layers, ignore_objects)
	# If there was no hit, write "empty" values to the outputs.
	if sorted_hits.is_empty():
		outputs[0].value = false
		outputs[1].value = null
		outputs[2].value = -1.0
		outputs[3].value = -1.0
		outputs[4].value = Vector3()
		outputs[5].value = Vector3()
		outputs[6].value = []
		return OK
	# Write the best hit to the outputs.
	var best_hit = sorted_hits[0]
	outputs[0].value = true
	outputs[1].value = best_hit["body"]
	outputs[2].value = best_hit["depth"]
	outputs[3].value = best_hit["fraction"]
	outputs[4].value = best_hit["normal"]
	outputs[5].value = best_hit["position"]
	outputs[6].value = sorted_hits
	return OK


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if edited_input_port.port_name != "Sphere Radius":
		return
	if edited_input_port.connected_block != null:
		graph_name = "Physics Raycast or Sphere Shape Cast"
	elif edited_input_port.value > 0.0:
		graph_name = "Physics Sphere Shape Cast"
	else:
		graph_name = "Physics Raycast"
	if graph_node:
		graph_node.title = graph_name


func get_script_block_type() -> String:
	return "physics_raycast"
