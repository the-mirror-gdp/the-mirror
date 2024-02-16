@tool
extends MeshInstance3D

var _map_half_size = 512
var _map_center_xz: Vector2

func update_visiblity() -> void:
	if is_inside_tree():
		var x_distance = abs(_map_center_xz.x - global_position.x)
		var y_distance = abs(_map_center_xz.y - global_position.z)
		visible = max(x_distance, y_distance)  <= _map_half_size * 4.0


func on_camera_viewer_chunk_switched(camera_viewer_position: Vector3) -> void:
	update_visiblity()


func on_map_transform_changed(map_size: int, map_position: Vector3) -> void:
	_map_half_size = map_size / 2
	_map_center_xz = Vector2(map_position.x, map_position.z)
	update_visiblity()


func on_map_material_changed(new_material: Material) -> void:
	pass
