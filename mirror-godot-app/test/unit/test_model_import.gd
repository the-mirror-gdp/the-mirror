extends GutTest


const TEST_GLB_DISK_WRITE_FORMAT = "user://__test%s.glb"
const TEST_GLTF_DISK_WRITE_FORMAT = "user://__test%s.gltf"
const GLB_FILE_PATH = "res://test/test_files/bench.glb"
const OBJ_FILE_PATH = "res://test/test_files/ramp1.not_obj"
const MTL_FILE_PATH = "res://test/test_files/ramp1.not_mtl"
const GLTF_FILE_PATH = "res://test/test_files/medieval.gltf"


func test_load_gltf_from_disk_as_node():
	# proof we can load a GLTF from the disk as a node
	var node: Node = TMFileUtil.load_gltf_file_as_node(GLTF_FILE_PATH, false)
	assert_not_null(node)
	assert_true(node is Node)

	# proof we can duplicate the node for instancing
	var duped_node: Node = node.duplicate()
	assert_not_null(duped_node)
	assert_true(duped_node is Node)

	var found_node: Node = null
	for child in duped_node.get_children():
		if child.name == "torture_device_001":
			found_node = child
	assert_not_null(found_node)

	node.free()
	duped_node.free()


func test_save_bytes_to_disk_and_load_gltf_as_node():
	# proof we can load the byte data of a GLTF from the disk into memory
	var bytes = TMFileUtil.load_file_bytes(GLTF_FILE_PATH)
	assert_true(bytes.size() > 0)

	var test_path = TEST_GLTF_DISK_WRITE_FORMAT % str(Time.get_ticks_msec())

	# proof we can save the raw byte data of the GLTF to the disk
	var new_file = FileAccess.open(test_path, FileAccess.WRITE)
	new_file.store_buffer(bytes)
	new_file.flush()

	assert_true(FileAccess.file_exists(test_path))

	# proof we can load the byte data that was in memory as GLTF
	var node: Node = TMFileUtil.load_gltf_file_as_node(test_path, false)
	assert_not_null(node)
	assert_true(node is Node)

	# proof we can duplicate the node for instancing
	var duped_node: Node = node.duplicate()
	assert_not_null(duped_node)
	assert_true(duped_node is Node)

	var found_node: Node = null
	for child in duped_node.get_children():
		if child.name == "torture_device_001":
			found_node = child
	assert_not_null(found_node)

	node.free()
	duped_node.free()

	# TODO: Delete test asset from disk


func test_load_glb_from_disk_as_node():
	# proof we can load a GLTF from the disk as a node
	var node: Node = TMFileUtil.load_gltf_file_as_node(GLB_FILE_PATH, false)
	assert_not_null(node)
	assert_true(node is Node)

	# proof we can duplicate the node for instancing
	var duped_node: Node = node.duplicate()
	assert_not_null(duped_node)
	assert_true(duped_node is Node)

	var found_node: Node = null
	for child in duped_node.get_children():
		if str(child.name).to_lower().begins_with("bench"):
			found_node = child
	assert_not_null(found_node)

	node.free()
	duped_node.free()


func test_save_bytes_to_disk_and_load_glb_as_node():
	# proof we can load the byte data of a GLTF from the disk into memory
	var bytes = TMFileUtil.load_file_bytes(GLB_FILE_PATH)
	assert_true(bytes.size() > 0)

	var test_path = TEST_GLB_DISK_WRITE_FORMAT % str(Time.get_ticks_msec())

	# proof we can save the raw byte data of the GLB to the disk
	var new_file = FileAccess.open(test_path, FileAccess.WRITE)
	new_file.store_buffer(bytes)
	new_file.flush()

	assert_true(FileAccess.file_exists(test_path))

	# proof we can load the byte data that was in memory as GLB
	var node: Node = TMFileUtil.load_gltf_file_as_node(test_path, false)

	assert_not_null(node)
	assert_true(node is Node)

	# proof we can duplicate the node for instancing
	var duped_node: Node = node.duplicate()
	assert_not_null(duped_node)
	assert_true(duped_node is Node)

	var found_node: Node = null
	for child in duped_node.get_children():
		if str(child.name).to_lower().begins_with("bench"):
			found_node = child
	assert_not_null(found_node)

	node.free()
	duped_node.free()

	# TODO: Delete test asset from disk


func test_load_obj_from_disk_as_node():
	## TODO Remove this test or replace with better one (public side of utils_funcs instead)
	const ObjParse = preload("res://scripts/autoload/util_funcs/obj_parse.gd")
	var mesh = ObjParse.load_obj(OBJ_FILE_PATH, MTL_FILE_PATH)
	assert_not_null(mesh)


func test_convert_obj_to_glb():
	var glb_data: PackedByteArray = Util.convert_obj_to_glb_data(OBJ_FILE_PATH, MTL_FILE_PATH)
	assert_false(glb_data.is_empty())


func test_convert_gltf_to_glb():
	var glb_data: PackedByteArray = Util.convert_gltf_to_glb_data(GLTF_FILE_PATH)
	assert_false(glb_data.is_empty())
