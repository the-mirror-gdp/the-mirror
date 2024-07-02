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


func setup() -> void:
	VRManager.vr_started.connect(_on_vr_enter)
	VRManager.vr_ended.connect(_on_vr_exit)
	# If the player is already wearing VR, we just activate the VR camera.
	if VRManager.vr_is_active:
		_on_vr_enter()


func set_vr_mouse_input_state(state: bool):
	var quad = get_open_xr_quad()
	quad.set_mouse_state(state)

func _on_vr_enter() -> void:
	vr_started.emit()


func _on_vr_exit() -> void:
	vr_ended.emit()


func get_camera() -> XRCamera3D:
	return _camera


func get_root() -> Node3D:
	return $Root


func get_open_xr_quad() -> OpenXRCompositionLayerQuad:
	return $Root/XROrigin3D/OpenXRCompositionLayerQuad


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
