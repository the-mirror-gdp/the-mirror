class_name VRControllerMenu
extends Node

signal vr_started
signal vr_ended

const _ROTATION_SPEED: float = 4.0

@onready var _root: Node3D = $Root
@onready var _origin: XROrigin3D = $Root/XROrigin3D
@onready var _camera: XRCamera3D = $Root/XROrigin3D/XRCamera3D
@onready var _camera_neck: Node3D = $Root/XROrigin3D/XRCamera3D/Neck
@onready var _left_hand: XRController3D = $Root/XROrigin3D/LeftHand
@onready var _left_hand_laser: Node3D = $Root/XROrigin3D/LeftHand/Laser
@onready var _right_hand: XRController3D = $Root/XROrigin3D/RightHand
@onready var _right_hand_laser: Node3D = $Root/XROrigin3D/RightHand/Laser

var _movement_direction := Vector3.ZERO
var _camera_rotation_change := Vector2.ZERO
var _running: bool = false
var _jumping: bool = false

var _left_hand_interacting: bool = false
var _right_hand_interacting: bool = false


func setup(player: TMCharacter3D) -> void:
	VRManager.vr_started.connect(_on_vr_enter)
	VRManager.vr_ended.connect(_on_vr_exit)
	# If the player is already wearing VR, we just activate the VR camera.
	if VRManager.vr_is_active:
		_on_vr_enter()


func _process(_delta: float) -> void:
	# TODO: ?
	# _root.global_position = _local_player.model.global_position
	pass

func _on_vr_enter() -> void:
	vr_started.emit()


func _on_vr_exit() -> void:
	vr_ended.emit()


func get_camera() -> XRCamera3D:
	return _camera


func camera_get_look_target() -> Vector3:
	var head = _camera.get_global_transform()
	return head.origin + head.basis.z * 10


func get_camera_rotation() -> Vector3:
	if is_instance_valid(_camera):
		return _camera.global_rotation
	return Vector3.ZERO


func get_body_position() -> Vector3:
	return _origin.transform * _camera.transform * _camera_neck.position


func get_intended_movement_direction() -> Vector3:
	return _movement_direction


func get_intended_camera_rotation_change() -> Vector2:
	return _camera_rotation_change


func is_intent_to_run() -> bool:
	return _running


func is_intent_to_jump() -> bool:
	if _jumping:
		_jumping = false
		return true
	return false


func is_left_hand_intent_to_interact() -> bool:
	if _left_hand_interacting:
		_left_hand_interacting = false
		return true
	return false


func is_right_hand_intent_to_interact() -> bool:
	if _right_hand_interacting:
		_right_hand_interacting = false
		return true
	return false


func origin_set_rotation_y(rotation: float) -> void:
	_origin.global_rotation.y = rotation - _camera.rotation.y


func _get_ray_cast(hand: Node3D) -> Dictionary:
	var ray_layers: Array = [
		&"STATIC",
		&"KINEMATIC",
		&"CHARACTER",
		&"DYNAMIC",
	]
	return Util.get_raycast(_camera, hand.global_position, hand.global_position - hand.global_transform.basis.z * 100, ray_layers)


func _on_left_hand_input_vector_2_changed(_action: String, value: Vector2):
	_movement_direction = Vector3(value.x, 0, -value.y) if value.length() > 0.1 else Vector3.ZERO


func _on_left_hand_button_pressed(action: String):
	if action == "primary_click":
		_running = true


func _on_left_hand_button_released(action: String):
	if action == "primary_click":
		_running = false
	elif action == "trigger_click" and not _left_hand_interacting:
		_left_hand_interacting = true


func _on_right_hand_button_pressed(action: String):
	if action == "primary_click" and not _jumping:
		_jumping = true
	elif action == "trigger_click" and not _right_hand_interacting:
		_right_hand_interacting = true


func _on_right_hand_input_vector_2_changed(_action: String, value: Vector2):
	# Rotate the XROrigin around a pivot, which is the player.
	var amount: float = deg_to_rad(-value.x * _ROTATION_SPEED)
	var pivot_point: Vector3 = Vector3() # TODO: player global pos
	var offset: Vector3 = _origin.global_position - pivot_point
	var rotated_offset: Vector3 = offset.rotated(Vector3.UP, amount)
	_origin.global_position = pivot_point + rotated_offset
	_origin.rotate(Vector3.UP, amount)
