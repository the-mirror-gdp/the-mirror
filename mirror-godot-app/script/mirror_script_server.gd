extends Node


# When true, skip the can_execute checks (for visual scripting only).
var is_execution_override_enabled: bool = false


var _bodies_with_forces_over_time: Array[Dictionary] = []


func _physics_process(delta: float) -> void:
	if Zone.is_client():
		return
	_process_bodies_with_forces_over_time(delta)


func add_force_to_body_over_time(body: JBody3D, force: Vector3, duration: float) -> void:
	var body_with_forces: Dictionary = {
		"body": body,
		"duration": duration,
		"force": force,
	}
	_bodies_with_forces_over_time.append(body_with_forces)


func _process_bodies_with_forces_over_time(delta: float) -> void:
	for i in range(_bodies_with_forces_over_time.size() - 1, -1, -1):
		var body_with_forces = _bodies_with_forces_over_time[i]
		var body = body_with_forces["body"]
		if not is_instance_valid(body):
			_bodies_with_forces_over_time.remove_at(i)
			continue
		var force: Vector3 = body_with_forces["force"]
		body.add_force(force)
		var duration: float = body_with_forces["duration"]
		duration -= delta
		if duration <= 0:
			_bodies_with_forces_over_time.remove_at(i)
		else:
			body_with_forces["duration"] = duration
