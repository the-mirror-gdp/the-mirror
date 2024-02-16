# Should be used with Debug -> VisibleCollisionShapes to visually confirm that proper shapes were generated
extends Node


@onready var _mesh_instances = [$MeshInstance3D, $rock_02/rock_022, $rock/rock2, $rock_03/rock_022]
@onready var _bodies = [$MeshInstance3D/StaticBody3D, $rock/StaticBody3D, $rock_02/StaticBody3D, $rock_03/StaticBody3D]


func _ready() -> void:
	for mesh_idx in range(_mesh_instances.size()):
		var meshinstance = _mesh_instances[mesh_idx]
		var promisse = Zone.shapes_generator.async_generate_convex_shape_for_mesh(meshinstance.mesh)
		await promisse.wait_till_fulfilled()
		_on_shape_generated(promisse.get_result(), mesh_idx)


func _on_shape_generated(in_collision_shape, in_mesh_idx: int):
	assert(is_instance_valid(in_collision_shape))
	var body = _bodies[in_mesh_idx]
	var meshinstance = _mesh_instances[in_mesh_idx]
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = in_collision_shape

	body.add_child(collision_shape)
	collision_shape.global_transform.origin = meshinstance.global_transform.origin
	collision_shape.global_transform = meshinstance.global_transform
