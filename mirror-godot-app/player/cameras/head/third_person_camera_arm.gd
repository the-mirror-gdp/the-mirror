extends Node3D


const ADDITIONAL_ZOOM_LIMIT: float = 0.5

@export var _default_offset_angle: float = 10.0
@export var _shoulder_offset: float = 0.2
@export var _min_zoom: float = 1
@export var _max_zoom: float = 7.0
@export var _zoom_increment: float = 0.8
@export var _zoom_speed: float = 8.0

var is_second_person: bool = false:
	set(value):
		is_second_person = value
		basis = _second_person_basis if value else _third_person_basis
		position.x = -_shoulder_offset if value else _shoulder_offset

var _second_person_basis: Basis
var _third_person_basis: Basis
var _additional_zoom: float = 0.0
var _zoom_scale: float = 1.0
var _zoom_amount: float = 3.0
var _target_length: float = 0.0
var _shape: JShape3D = null

@onready var _camera = $ThirdPersonCamera


func _ready() -> void:
	_shape = JSphereShape3D.new()
	_shape.radius = 0.2
	_set_offset_angle(_default_offset_angle)


func _process(delta) -> void:
	var local_player = PlayerData.get_local_player()
	if not local_player:
		return
	_target_length = lerpf(_target_length, _zoom_amount + _additional_zoom, _zoom_speed * delta)
	var collide_with_layers: Array = [
		&"STATIC",
		&"KINEMATIC",
		&"CHARACTER",
		&"DYNAMIC",
	]
	var res = Jolt.cast_shape(0, _shape, global_transform, global_transform.basis.z * _target_length, collide_with_layers, [local_player])
	_target_length *= res[0].get("fraction", 1.0) if not res.is_empty() else 1.0
	var hit_position: Vector3 = global_position + global_transform.basis.z * _target_length
	_camera.global_position = hit_position


func handle_input(input_event: InputEvent, local_player: Player) -> void:
	if input_event.is_action_pressed(&"player_camera_second_person"):
		is_second_person = not is_second_person
	elif input_event is InputEventMouseButton and local_player.is_player_input_enabled():
		if input_event.is_pressed():
			if input_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_amount -= _zoom_increment
				_zoom_amount = clampf(_zoom_amount, _min_zoom, _max_zoom)
			elif input_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_amount += _zoom_increment
				_zoom_amount = clampf(_zoom_amount, _min_zoom, _max_zoom)


func set_camera_zoom_scale(camera_zoom_scale: float) -> void:
	_zoom_scale = camera_zoom_scale
	_camera.set_camera_zoom_scale(camera_zoom_scale)
	position.y = 0.04 * camera_zoom_scale


func update_camera_arm_run_zoom(player: Player) -> void:
	if player.is_intent_to_run():
		var velocity_sq: float = player.linear_velocity.length_squared()
		_additional_zoom = minf(velocity_sq * 0.02, ADDITIONAL_ZOOM_LIMIT)
	else:
		_additional_zoom = 0.0


func _set_offset_angle(angle: float) -> void:
	angle = deg_to_rad(angle)
	_third_person_basis = Basis.from_euler(Vector3(0.0, angle, 0.0))
	_second_person_basis = _third_person_basis.scaled(Vector3(-1.0, 1.0, -1.0))
	basis = _third_person_basis
	_camera.rotation.y = -angle
