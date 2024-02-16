extends GutTest


const PCK_FILE_PATH = "res://test/test_files/test-packed-scene-file-2.pck"


func test_load_pck_from_disk_as_node() -> void:
	var node = ScenePacker.get_unpacked_pck_as_node(PCK_FILE_PATH)
	assert_not_null(node)
	if node:
		node.free()
	return
