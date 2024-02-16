extends SubViewportContainer


# At 1.0, the object's edge touches the viewport's edge.
# Below 1.0, the object's edge can go past the viewport.
# Above 1.0, the object's edge has some margin.
const _MARGIN_MULTIPLIER = 1.4

signal preview_generated(image)

var camera_center_offset := Vector3.ZERO

#func _ready():
#	# Everything here is only for testing purposes.
#	var mesh_instance = MeshInstance3D.new()
#	mesh_instance.mesh = BoxMesh.new()
#	add_asset(mesh_instance)
#	deferred_save_image("user://asset_preview_test.png")


func render_to_image() -> Image:
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	@warning_ignore("redundant_await")
	await get_tree().process_frame
	var image: Image = $SubViewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


## Save what the Viewport is currently rendering to a file at the given path.
func deferred_save_image(path: String) -> int:
	var image = await render_to_image()
	var result = image.save_webp(path, true)
	preview_generated.emit(image)
	return result


## Set up the asset preview for the given node or scene instance.
func add_asset(node_or_scene_instance: Node) -> void:
	var subviewport = $SubViewport
	var object_pivot = subviewport.get_node(^"ObjectPivot")
	var camera_pivot = subviewport.get_node(^"CameraPivot")
	object_pivot.add_child(node_or_scene_instance)
	# Durinc calculation, we rotate the object pivot the opposite way compared
	# to the camera so that the AABB we calculate is relative to the camera.
	object_pivot.transform.basis = camera_pivot.transform.basis.inverse()
	var aabb = _calculate_aabb_recursive(object_pivot)
	# After calculation, we un-rotate the object pivot.
	object_pivot.transform.basis = Basis()
	_setup_camera_from_aabb(camera_pivot, aabb)


func _calculate_aabb_recursive(node: Node, aabb: AABB = AABB()) -> AABB:
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = node
		var mesh_global_transform = mesh.get_global_transform()
		# The AABB Godot gives us may not be optimal, so let's build our own.
		# This is a complex calculation, we could move this to C++ later.
		if mesh == null or mesh.mesh == null:
			push_error("Mesh was null, could not calculate AABB in asset preview")
			return AABB()
		for surface_index in range(mesh.mesh.get_surface_count()):
			for point in mesh.mesh.surface_get_arrays(surface_index)[0]:
				aabb = aabb.expand(mesh_global_transform * point)
	for child in node.get_children():
		aabb = _calculate_aabb_recursive(child, aabb)
	return aabb


func _setup_camera_from_aabb(camera_pivot: Node3D, aabb: AABB) -> void:
	var camera = camera_pivot.get_child(0)
	camera_pivot.translate(aabb.get_center())
	camera.transform.origin.z = aabb.size.z
	camera.transform.origin += camera_center_offset
	camera.near = aabb.size.z * 0.4
	camera.far = aabb.size.z * 1.6
	camera.size = aabb.size.y * _MARGIN_MULTIPLIER
	# If the width is the part at the edge, expand a bit more.
	var width_mult_ratio = aabb.size.x * size.y / (aabb.size.y * size.x)
	if width_mult_ratio > 1.0:
		camera.size *= width_mult_ratio
