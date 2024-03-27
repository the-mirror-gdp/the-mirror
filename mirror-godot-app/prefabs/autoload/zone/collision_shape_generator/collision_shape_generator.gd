## Responsible for asynchronous collision mesh generation,
## `async_generate_shape_for_meshes()` is returning Promise object
## which will eventually have collision mesh as a result.
class_name CollisionShapeGenerator
extends Node


var _mesh_rid_to_concave_shape_map = {
	#mesh.get_rid() : ConcavePolygonShape3D
}
var _mesh_rid_to_convex_shape_map = {
	#mesh.get_rid() : ConvexPolygonShape3D
}
var _meshes_to_generate_queue = [
	#MeshPromisePair, (...)
]
# var _generate_thread: Thread = Thread.new()
var cumulative_collision_shape_generation_time = 0.0
func async_generate_shape_for_meshes(body: JBody3D, in_meshes: Array[MeshInstance3D], is_concave: bool) -> Promise:
	var promise = Promise.new()

	# Queue up this promise for generation.
	var pair = MeshPromisePair.new()
	pair.body = body
	pair.meshes = in_meshes
	pair.promise = promise
	pair.is_concave = is_concave
	pair.rid_map = _mesh_rid_to_concave_shape_map if is_concave else _mesh_rid_to_convex_shape_map
	_thread_generate_collision(pair)
	#_meshes_to_generate_queue.append(pair)
	return promise


func _thread_generate_collision(mesh_promise_pair: MeshPromisePair):
	var res = generate_shape_for_meshes(mesh_promise_pair.body, mesh_promise_pair.meshes, mesh_promise_pair.is_concave)
	if res.is_empty():
		push_error("Critical generator failed to run successfully for ", mesh_promise_pair)
		return
	var shape = res[0]
	var generated_shapes: Array[JShape3D] = res[1]
	var generated_shapes_rid: Array[RID] = res[2]
	_collision_generated(mesh_promise_pair, shape, generated_shapes, generated_shapes_rid)


func generate_shape_for_meshes(body: JBody3D, in_meshes: Array[MeshInstance3D], is_concave: bool) -> Array:
	var start_time = Time.get_unix_time_from_system()
	var generated_shapes: Array[JShape3D]
	var generated_shapes_rid: Array[RID]
	var shapes: Array[JShape3D]
	var transforms: Array[Transform3D]
	var rid_map = _mesh_rid_to_concave_shape_map if is_concave else _mesh_rid_to_convex_shape_map

	for mesh in in_meshes:
		# error here 1:4 times of loading the space
		if not is_instance_valid(mesh):
			push_error("failed to find valid mesh during collision generation - critical")
			assert(false)
			return []

	for mesh in in_meshes:
		# error here 1:4 times of loading the space
		if not is_instance_valid(mesh):
			push_error("failed to find valid mesh during collision generation - critical")
			continue
		if not is_instance_valid(mesh.mesh):
			continue
		var rid = mesh.mesh.get_rid()
		var shape: JShape3D = null
		var transform := Transform3D.IDENTITY

		if rid_map.has(rid):
			shape = rid_map[rid]

		if shape == null:
			# Generate the shape
			if is_concave:
				var tms: ConcavePolygonShape3D = mesh.mesh.create_trimesh_shape()
				shape = JMeshShape3D.new()
				shape.faces = tms.get_faces()
			else:
				var cps: ConvexPolygonShape3D = mesh.mesh.create_convex_shape(false, false)
				shape = JConvexHullShape3D.new()
				shape.points = cps.points
			if shape:
				generated_shapes.push_back(shape)
				generated_shapes_rid.push_back(rid)

		# The shape is 100% expected at this point.
		assert(shape)

		# Fetch the transform now
		transform = TMNodeUtil.get_relative_transform(body.interpolated_node, mesh)

		shapes.push_back(shape)
		transforms.push_back(transform)

	assert(in_meshes.size() == shapes.size())
	assert(in_meshes.size() == transforms.size())

	var result_shape: JShape3D = null
	# OK, create the compound shape.
	var cs := JCompoundShape3D.new()
	cs.shapes = shapes
	cs.transforms = transforms
	result_shape = cs

	# The shape is 100% expected at this point.
	assert(result_shape)
	var cumulative_time = Time.get_unix_time_from_system() - start_time
	print("Import time for shape: ", cumulative_time)
	cumulative_collision_shape_generation_time += cumulative_time
	print("[", Zone.get_instance_type(), "] Cumulative import time ", cumulative_collision_shape_generation_time)
	return [result_shape, generated_shapes, generated_shapes_rid]


func _collision_generated(mesh_promise_pair: MeshPromisePair, generated_collision: JShape3D, generated_shapes: Array[JShape3D], generated_shapes_rid: Array[RID]):
	for i in range(generated_shapes.size()):
		mesh_promise_pair.rid_map[generated_shapes_rid[i]] = generated_shapes[i]
	mesh_promise_pair.promise.set_result(generated_collision)


class MeshPromisePair:
	extends RefCounted

	var body: JBody3D = null
	var meshes: Array[MeshInstance3D]
	var promise: Promise
	var is_concave: bool
	var rid_map