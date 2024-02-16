extends Node3D


@export var _stationary_zoom_amount: float = 0.5

@onready var _camera_3d = $Camera3D


func _unhandled_input(input_event) -> void:
	if input_event is InputEventMouseMotion:
		if Input.is_action_pressed(&"build_mode_camera_orbit"):
			clamped_camera_rotation(Vector2(input_event.relative.y, input_event.relative.x) *
				GameplaySettings.camera_mouse_sensitivity)
			get_viewport().set_input_as_handled()
	elif input_event is InputEventMouseButton:
		_process_mouse_scroll(input_event)

func clamped_camera_rotation(rot: Vector2) -> void:
	var euler_angles: Vector3 = basis.get_euler()
	euler_angles.x = clampf(euler_angles.x - rot.x, -1.57, 1.57)
	euler_angles.y = fposmod(euler_angles.y - rot.y, TAU)
	euler_angles.z = 0.0
	basis = Basis.from_euler(euler_angles)


func _process_mouse_scroll(input_event: InputEvent) -> void:
	if not input_event.is_pressed():
		return
	if input_event.is_action_pressed(&"build_mode_camera_zoom_in"):
		_add_stationary_zoom(-_stationary_zoom_amount)
	elif input_event.is_action_pressed(&"build_mode_camera_zoom_out"):
		_add_stationary_zoom(_stationary_zoom_amount)


func _add_stationary_zoom(value: float) -> void:
	_camera_3d.position += _camera_3d.transform.basis.z * value
