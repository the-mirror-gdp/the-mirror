class_name EquipableViewModel
extends EquipableModel


var _sway_amplitude: float = 0.2
var _interpolate_time: float = 10.0


func setup(equipable_controller: EquipableController) -> void:
	super.setup(equipable_controller)
	_player.damage_handler.health_changed.connect(_on_player_health_changed)


func _process(delta) -> void:
	if not _model:
		return
	var raycast_dict: Dictionary = _equipable_controller.get_raycast()
	var hit_pos = raycast_dict.get("position") # Vector3?
	if hit_pos != null:
		# Interpolate our transform towards one that is rotated at the target.
		var global_trans = _model.global_transform
		var target_pos: Vector3 = hit_pos - global_trans.origin
		var target := Transform3D(Basis.looking_at(target_pos), global_trans.origin)
		_model.global_transform = global_trans.interpolate_with(target, 0.1)
	var target_transform := Transform3D.IDENTITY
	var player_velocity: Vector3 = _player.get_local_movement_velocity()
	var mouse_sway: Vector2 = _player.get_intended_camera_rotation_change()
	if _equipable_controller.is_current_equipable_aiming() and not GameUI.instance.is_mouse_needed_for_ui():
		target_transform.origin = Vector3(-0.025, 0.02, 0.0)
	target_transform.origin += Vector3(mouse_sway.y, mouse_sway.x, 0.0) * _sway_amplitude
	target_transform.basis *= Basis.from_euler(Vector3(0.0, 0.0, (player_velocity.x * -0.3) + -mouse_sway.y))
	_model.transform = _model.transform.interpolate_with(target_transform, delta * _interpolate_time)


func _on_current_equipable_interacted(_equipable: Node) -> void:
	super._on_current_equipable_interacted(_equipable)
	if is_instance_valid(_model) and "recoil_distance" in _equipable and "recoil_rotation" in _equipable:
		_model.position += Vector3(0.0, 0.0, _equipable.recoil_distance)
		_model.basis *= Basis.from_euler(Vector3(_equipable.recoil_rotation, 0.0, 0.0))


func _on_player_health_changed(_target_object: Node, new_health: float, old_health: float, _event_origin: String) -> void:
	if new_health > 0.0 and old_health <= 0.0:
		_set_model_visibility(true)
		return
	if new_health <= 0.0:
		_set_model_visibility(false)
