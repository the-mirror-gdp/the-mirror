extends GutTest


func test_collision_mesh_generation():
	return # TODO: TEST is broken this should be fixed
	var packed_scn = autofree(load("res://test/test_files/bench.glb"))
	var scn_with_mesh = autofree(packed_scn.instantiate())
	var mesh_instance: MeshInstance3D = TMNodeUtil.recursive_get_node_by_type(scn_with_mesh, MeshInstance3D) as MeshInstance3D
	if not is_instance_valid(mesh_instance):
		assert_not_null(mesh_instance, "test_collision_mesh_generation")
		return

	var visual: Mesh = mesh_instance.mesh
	var convex_shape_not_clean_not_simplified = autofree(visual.create_convex_shape(false, false))
	var convex_shape_clean_not_simplified = autofree(visual.create_convex_shape(true, false))
	var convex_shape_clean_simplified = autofree(visual.create_convex_shape(true, true))
	var trimesh_shape = autofree(visual.create_trimesh_shape())

	assert_not_null(convex_shape_not_clean_not_simplified, "test_collision_mesh_generation")
	assert_not_null(convex_shape_clean_not_simplified, "test_collision_mesh_generation")
	assert_not_null(convex_shape_clean_simplified, "test_collision_mesh_generation")
	assert_not_null(trimesh_shape, "test_collision_mesh_generation")
