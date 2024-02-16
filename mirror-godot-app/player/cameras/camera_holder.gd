## Not a Camera3D node
class_name CameraHolder
extends Node3D


## The camera may be updated by derived classes, but also must have an
## initial value set in the editor for some early init logic to work.
@export var _camera: Camera3D

var _local_player: TMCharacter3D


func setup(player: TMCharacter3D, camera_manager: CameraManager, gizmo: Gizmo) -> void:
	_local_player = player
	_camera.setup(camera_manager, gizmo)


func get_camera() -> Camera3D:
	return _camera


func get_camera_placement_transform(): # -> Transform3D?:
	return _camera.get_placement_transform_or_null()


func get_camera_raycast_dict(ignored_bodies=[]) -> Dictionary:
	if ignored_bodies.is_empty():
		return _camera.raycast_dict
	else:
		return _camera.get_camera_raycast_dict_but_ignore(ignored_bodies)


func get_next_camera_target_transform() -> Transform3D:
	return _camera.global_transform


## Used by derived classes to rotate the camera holder.
func clamped_camera_rotation(rot: Vector2):
	var euler_angles: Vector3 = basis.get_euler()
	euler_angles.x = clampf(euler_angles.x - rot.x, -1.57, 1.57)
	euler_angles.y = fposmod(euler_angles.y - rot.y, TAU)
	euler_angles.z = 0.0
	basis = Basis.from_euler(euler_angles)


# The below methods can be overridden in derived classes.
func update(_in_delta: float) -> void:
	_camera.update(_in_delta)


func handle_input(_input_event: InputEvent) -> void:
	pass


func handle_asset_placement_input(input_event: InputEvent) -> void:
	_camera.handle_asset_placement_input(input_event)


func enter(target_transform: Transform3D) -> void:
	_camera.make_current()


func exit() -> void:
	pass
