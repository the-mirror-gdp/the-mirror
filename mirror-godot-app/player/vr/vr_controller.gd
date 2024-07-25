class_name VRController
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
@onready var _emoji_menu: JBody3D = $EmojiMenu

var _local_player: TMCharacter3D
var _movement_direction := Vector3.ZERO
var _camera_rotation_change := Vector2.ZERO
var _running: bool = false
var _jumping: bool = false

var _left_hand_interacting: bool = false
var _right_hand_interacting: bool = false


func setup(player: TMCharacter3D) -> void:
	_set_vr_visibility(false)
	_local_player = player
	VRManager.vr_started.connect(_on_vr_enter)
	VRManager.vr_ended.connect(_on_vr_exit)
	_emoji_menu.setup(_local_player, _camera)
	# If the player is already wearing VR, we just activate the VR camera.
	if VRManager.vr_is_active:
		_on_vr_enter()


func _process(_delta: float) -> void:
	if _local_player == null or not _local_player.model or not VRManager.vr_is_active:
		return
	_root.global_position = _local_player.model.global_position
	_process_hand_interaction(_left_hand, _left_hand_laser, is_left_hand_intent_to_interact())
	_process_hand_interaction(_right_hand, _right_hand_laser, is_right_hand_intent_to_interact())
	if _local_player.model.get_player_visible():
		_local_player.model.hide_player()


func _on_vr_enter() -> void:
	_set_vr_visibility(true)
	if is_instance_valid(_local_player):
		origin_set_rotation_y(_local_player.get_model_rotation_euler().y)
	vr_started.emit()


func _on_vr_exit() -> void:
	_set_vr_visibility(false)
	vr_ended.emit()


func _set_vr_visibility(value: bool) -> void:
	_origin.set_visible(value)


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


func _process_hand_interaction(hand: Node3D, laser: Node3D, intent_to_interact: bool) -> void:
	if not intent_to_interact:
		return
	var raycast_dict: Dictionary = _get_ray_cast(hand)
	var hit = _local_player.process_interaction(raycast_dict, intent_to_interact)
	laser.set_visible(hit)
	if hit:
		laser.scale.z = hand.global_position.distance_to(raycast_dict.position) / 2


func _get_ray_cast(hand: Node3D) -> Dictionary:
	var ray_layers: Array = [
		&"STATIC",
		&"KINEMATIC",
		&"CHARACTER",
		&"DYNAMIC",
	]
	return Util.get_raycast(_camera, hand.global_position, hand.global_position - hand.global_transform.basis.z * 100, ray_layers)


func _on_left_hand_input_vector_2_changed(_action: String, value: Vector2):
	if _emoji_menu.is_open():
		_emoji_menu.close()
	_movement_direction = Vector3(value.x, 0, -value.y) if value.length() > 0.1 else Vector3.ZERO


func _on_left_hand_button_pressed(action: String):
	if action == "primary_click":
		_running = true
	elif action == "by_button":
		_emoji_menu.toggle_menu(_left_hand.global_position + _left_hand.global_transform.basis.z * -0.15)


func _on_left_hand_button_released(action: String):
	if action == "primary_click":
		_running = false
	elif action == "trigger_click" and not _left_hand_interacting:
		_left_hand_interacting = false


func _on_right_hand_button_pressed(action: String):
	if action == "primary_click" and not _jumping:
		_jumping = true
	elif action == "trigger_click" and not _right_hand_interacting:
		_right_hand_interacting = true
	elif action == "by_button":
		_emoji_menu.toggle_menu(_right_hand.global_position + _right_hand.global_transform.basis.z * -0.15)


func _on_right_hand_input_vector_2_changed(_action: String, value: Vector2):
	if not is_instance_valid(_local_player) or _local_player.is_sitting():
		return
	if _emoji_menu.is_open():
		_emoji_menu.close()
	# Rotate the XROrigin around a pivot, which is the player.
	var amount: float = deg_to_rad(-value.x * _ROTATION_SPEED)
	var pivot_point: Vector3 = _local_player.global_position
	var offset: Vector3 = _origin.global_position - pivot_point
	var rotated_offset: Vector3 = offset.rotated(Vector3.UP, amount)
	_origin.global_position = pivot_point + rotated_offset
	_origin.rotate(Vector3.UP, amount)
