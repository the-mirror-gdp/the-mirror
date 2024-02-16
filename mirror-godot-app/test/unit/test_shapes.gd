extends GutTest


func test_generate_box_shapes():
	var size_1: Vector3 = Vector3.ONE
	var size_2: Vector3 = Vector3(20, 20, 20)
	var size_3: Vector3 = Vector3(0.5, 0.5, 0.5)
	var box_1 = Util.get_bounding_box(size_1)
	var box_2 = Util.get_bounding_box(size_2)
	var box_3 = Util.get_bounding_box(size_3)
	assert_not_null(box_1)
	assert_not_null(box_2)
	assert_not_null(box_3)
	assert_true(box_1 is BoxShape3D)
	assert_true(box_2 is BoxShape3D)
	assert_true(box_3 is BoxShape3D)
	assert_eq(box_1.extents, size_1 / 2)
	assert_eq(box_2.extents, size_2 / 2)
	assert_eq(box_3.extents, size_3 / 2)


func test_generate_sphere_shapes():
	var sphere_1 = Util.get_bounding_sphere(1)
	var sphere_2 = Util.get_bounding_sphere(25)
	var sphere_3: SphereShape3D = Util.get_bounding_sphere(0.5)
	assert_not_null(sphere_1)
	assert_not_null(sphere_2)
	assert_not_null(sphere_3)
	assert_true(sphere_1 is SphereShape3D)
	assert_true(sphere_2 is SphereShape3D)
	assert_true(sphere_3 is SphereShape3D)
	assert_eq(sphere_1.radius, 1.0)
	assert_eq(sphere_2.radius, 25.0)
	assert_eq(sphere_3.radius, 0.5)
