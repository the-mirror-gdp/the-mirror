extends Control


var _target_position := Vector3.ZERO
var _fade_speed: float = 1.2


func _process(delta) -> void:
	if Zone.is_host() or not PlayerData.has_local_player() or modulate.a <= 0.0:
		queue_free()
		return
	modulate.a = lerpf(modulate.a, 0.0, delta * _fade_speed)
	var player: Player = PlayerData.get_local_player()
	var direction: Vector3 = player.global_transform.origin - _target_position
	var camera: Camera3D = player.camera_get_active_player_head_camera()
	var angle: float = rad_to_deg(atan2(direction.z, direction.x))
	rotation_degrees = angle + camera.global_rotation_degrees.y


func set_target(attacker_position: Vector3) -> void:
	_target_position = attacker_position
