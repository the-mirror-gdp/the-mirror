# This scene can be used to manually test the ScenePacker class functionality.
# It's currently not possible to easily support automatic tests for ScenePacker since to avoid
# false positive results, the resources which are packed into pck cannot be imported by the editor at the time of the test
#
# Testing steps:
#	1. Run this scene
#	2. Check for output for SUCCESS message, if FAIL message present something went wrong during pck generation
#	3. Create new Godot project 'Import Test Project', copy "res://test/ScenePackerTest/pck_import_test/" directory into it
#	4. Run 'pck_import_test.tscn' inside of 'Import Test Project' and look for SUCCESS or FAIL msgs
extends Node


const TARGET_PCK_DIRECTORY: String = "res://test/scene_packer_test/pck_import_test/pcks/"

const TEST_SCENES_FILEPATHS: Array = [
	"res://test/scene_packer_test/scene_packer_samples/scene_packer_multi_hierarchy_nodes/scene_packer_multi_hierarchy_nodes.tscn",
	"res://test/scene_packer_test/scene_packer_samples/scene_packer_gltf/scene_packer_gltf.tscn",
	# it's a bit special case, worth to check but keep in mind 'import' result will be FAIL by default due to parse errors
	# in related scripts (in our 'Import Test Project' we dont have the same singletons and class names).
	# Potentially in the future while creating pck we could parse content of the scripts which we are packing in order to
	# find all script/class dependencies but it's an overkill for our initial needs
	#
	# To fix this for testing we can either add singletons with the same API, or just comment bodies of troublesome scripts
#	"res://test/gizmo/test_gizmos.tscn"
]


func _ready():
	if not DirAccess.dir_exists_absolute(TARGET_PCK_DIRECTORY):
		DirAccess.make_dir_absolute(TARGET_PCK_DIRECTORY)

	for scene_filepath in TEST_SCENES_FILEPATHS:
		var pck_filepath = TARGET_PCK_DIRECTORY + scene_filepath.get_file() + ".pck"
		ScenePacker.pack_scene_to_pck_file(scene_filepath, pck_filepath)
		if FileAccess.file_exists(pck_filepath):
			print("SUCCESS: PCK created successfully: ", pck_filepath)
		else:
			printerr("FAIL: PCK has not been created: ", pck_filepath)

	get_tree().quit()
