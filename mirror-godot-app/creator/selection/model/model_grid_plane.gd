class_name ModelGridPlane
extends Node


@onready var _raycast_position_indicator: MeshInstance3D = $RaycastPositionIndicator
@onready var _plane_mesh: MeshInstance3D = $PlaneMesh


func update_position(position: Vector3) -> void:
	_raycast_position_indicator.position = position
	_plane_mesh.position = position


func update_rotation() -> void:
	var local_player = PlayerData.get_local_player()
	if not local_player:
		return
	var camera = local_player.camera_get_viewport().get_camera_3d()
	_plane_mesh.look_at(camera.global_position)
	_plane_mesh.rotation.x += deg_to_rad(90)
	_plane_mesh.rotation = _plane_mesh.rotation.snapped(Vector3.ONE * deg_to_rad(90))


func update_grid_scale(grid_size: float) -> void:
	_plane_mesh.scale = Vector3.ONE * grid_size * 4
	_plane_mesh.material_override.set_shader_parameter("scale", grid_size * 4)
	_plane_mesh.material_override.set_shader_parameter("grid_size", grid_size)


func get_up_axis() -> Vector3:
	return _plane_mesh.transform.basis.y


func hide() -> void:
	_raycast_position_indicator.hide()
	_plane_mesh.hide()


func show() -> void:
	_raycast_position_indicator.show()
	_plane_mesh.show()
