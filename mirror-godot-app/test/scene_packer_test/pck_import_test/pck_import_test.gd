# Purpose of this scene is to be used in 'Import PCK test' project as described in scene_packer_test.gd
extends Node


const PCK_DIRECTORY = "res://pck_import_test/pcks/"

const TEST_SCENES_FILEPATHS = [
	"res://test/scene_packer_test/scene_packer_samples/scene_packer_multi_hierarchy_nodes/scene_packer_multi_hierarchy_nodes.tscn",
	"res://test/scene_packer_test/scene_packer_samples/scene_packer_gltf/scene_packer_gltf.tscn",
#	"res://test/gizmo/test_gizmos.tscn", #uncomment only if related pck has been created
]


func _ready():
	for scene_filepath in TEST_SCENES_FILEPATHS:
		var pck_filename = scene_filepath.right(scene_filepath.rfind("/")) + ".pck"
		var pck_filepath = PCK_DIRECTORY + pck_filename
		var load_success = ProjectSettings.load_resource_pack(pck_filepath)
		if not load_success:
			printerr("unpack FAIL: ", pck_filepath)
			continue
		print("unpack SUCCESS: ", pck_filepath)
		var instance = load(scene_filepath).instantiate()
		if not is_instance_valid(instance):
			printerr("FAIL when instancing: ", scene_filepath, " most likely pck is incorrect")
