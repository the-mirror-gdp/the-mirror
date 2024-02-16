extends Node


const _CURVE_PRECISION = 32
const _RING_PRECISION = _CURVE_PRECISION * 2
const _OUTLINE_MATERIAL = preload("res://ui/game/outline_material.mat.tres")

@onready var _wireframe_box: ArrayMesh = _create_wireframe_box()


func _process(_delta: float) -> void:
	await get_tree().process_frame
	for child in get_children():
		child.queue_free()


func draw_line(start: Vector3, end: Vector3, color: Color) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	_create_mesh_instance_for_mesh(mesh, color)


func draw_lines(lines: Array, color: Color) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for vertex in lines:
		mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	var mesh_instance: MeshInstance3D = _create_mesh_instance_for_mesh(mesh, color)
	return mesh_instance


func draw_wireframe_box_aabb(aabb: AABB, color: Color) -> void:
	var mesh_instance: MeshInstance3D = _create_mesh_instance_for_mesh(_wireframe_box, color)
	mesh_instance.position = aabb.position
	mesh_instance.scale = aabb.size


func draw_wireframe_box_transform(transform: Transform3D, color: Color) -> void:
	var mesh_instance: MeshInstance3D = _create_mesh_instance_for_mesh(_wireframe_box, color)
	mesh_instance.transform = transform


func draw_wireframe_box_object(object: Node, color: Color) -> void:
	if not object is Node3D:
		return
	var aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(object)
	draw_wireframe_box_aabb(object.global_transform * aabb, color)


func draw_wireframe_sphere(t: Transform3D, color: Color) -> void:
	var b: Basis = t.basis
	var pos: Vector3 = t.origin
	var points := PackedVector3Array()
	var indices := PackedInt32Array()
	# Draw the three circles.
	_add_wireframe_curve_points(points, pos, b.x, b.y)
	_add_wireframe_curve_points(points, pos, -b.x, -b.y)
	_add_loop_indices(indices, 0, _RING_PRECISION)
	_add_wireframe_curve_points(points, pos, b.y, b.z)
	_add_wireframe_curve_points(points, pos, -b.y, -b.z)
	_add_loop_indices(indices, _RING_PRECISION, _RING_PRECISION * 2)
	_add_wireframe_curve_points(points, pos, b.z, b.x)
	_add_wireframe_curve_points(points, pos, -b.z, -b.x)
	_add_loop_indices(indices, _RING_PRECISION * 2, _RING_PRECISION * 3)
	# Create the mesh.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_create_mesh_instance_for_mesh(mesh, color)


func draw_wireframe_capsule(t: Transform3D, half_mid_height: float, color: Color) -> void:
	var b: Basis = t.basis
	var pos_top: Vector3 = t.origin + b.y * half_mid_height
	var pos_bottom: Vector3 = t.origin - b.y * half_mid_height
	var points := PackedVector3Array()
	var indices := PackedInt32Array()
	# Draw top and bottom circles.
	_add_wireframe_curve_points(points, pos_top, b.z, b.x)
	_add_wireframe_curve_points(points, pos_top, -b.z, -b.x)
	_add_loop_indices(indices, 0, _RING_PRECISION)
	_add_wireframe_curve_points(points, pos_bottom, b.z, b.x)
	_add_wireframe_curve_points(points, pos_bottom, -b.z, -b.x)
	_add_loop_indices(indices, _RING_PRECISION, _RING_PRECISION * 2)
	# Draw the lines spanning the height of the capsule.
	_add_wireframe_curve_points(points, pos_top, b.x, b.y)
	_add_wireframe_curve_points(points, pos_bottom, -b.x, -b.y)
	_add_loop_indices(indices, _RING_PRECISION * 2, _RING_PRECISION * 3)
	_add_wireframe_curve_points(points, pos_top, b.z, b.y)
	_add_wireframe_curve_points(points, pos_bottom, -b.z, -b.y)
	_add_loop_indices(indices, _RING_PRECISION * 3, _RING_PRECISION * 4)
	# Create the mesh.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_create_mesh_instance_for_mesh(mesh, color)


func draw_wireframe_cylinder(t: Transform3D, half_height: float, color: Color) -> void:
	var b: Basis = t.basis
	var pos_top: Vector3 = t.origin + b.y * half_height
	var pos_bottom: Vector3 = t.origin - b.y * half_height
	var points := PackedVector3Array()
	var indices := PackedInt32Array()
	# Draw top and bottom circles.
	_add_wireframe_curve_points(points, pos_top, b.z, b.x)
	_add_wireframe_curve_points(points, pos_top, -b.z, -b.x)
	_add_loop_indices(indices, 0, _RING_PRECISION)
	_add_wireframe_curve_points(points, pos_bottom, b.z, b.x)
	_add_wireframe_curve_points(points, pos_bottom, -b.z, -b.x)
	_add_loop_indices(indices, _RING_PRECISION, _RING_PRECISION * 2)
	# Draw the lines spanning the height of the cylinder.
	points.append_array([
		pos_top + b.x, pos_bottom + b.x,
		pos_top - b.x, pos_bottom - b.x,
		pos_top + b.z, pos_bottom + b.z,
		pos_top - b.z, pos_bottom - b.z
	])
	indices.append_array([
		_RING_PRECISION * 2, _RING_PRECISION * 2 + 1,
		_RING_PRECISION * 2 + 2, _RING_PRECISION * 2 + 3,
		_RING_PRECISION * 2 + 4, _RING_PRECISION * 2 + 5,
		_RING_PRECISION * 2 + 6, _RING_PRECISION * 2 + 7
	])
	# Create the mesh.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_create_mesh_instance_for_mesh(mesh, color)


func _add_wireframe_curve_points(points: PackedVector3Array, pos: Vector3, x: Vector3, y: Vector3) -> void:
	for i in range(_CURVE_PRECISION):
		var radians: float = PI * float(i) / float(_CURVE_PRECISION)
		var new_point: Vector3 = pos + x * cos(radians) + y * sin(radians)
		points.append(new_point)


func _add_loop_indices(indices: PackedInt32Array, start: int, end: int) -> void:
	for i in range(start, end):
		indices.append(i)
		if i != start:
			indices.append(i)
	indices.append(start)


func _create_mesh_instance_for_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _OUTLINE_MATERIAL
	mesh_instance.set_instance_shader_parameter("albedo", color)
	mesh_instance.set_instance_shader_parameter("albedo_depth", Color.from_hsv(color.h + 0.25, color.s - 0.1, color.v - 0.5))
	add_child(mesh_instance)
	return mesh_instance


func _create_wireframe_box() -> ArrayMesh:
	var positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var indices := PackedInt32Array([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var colors := PackedColorArray([
		Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
		Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
