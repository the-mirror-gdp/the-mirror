## Can be used to create pck file for a given scene.
## Provided scene needs to be correct at pck creation time, which means it should be possible to
## instance it, it's needed in order to find all dependent resources and pack them automatically.
## It will not parse contents of a script in order to find all script dependencies that exists in the
## code of a given scene, which means given scene might not be successfully unpacked for some client
## if for some reason some referenced script does not exist locally.
class_name ScenePacker


const CURRENT_METADATA_FORMAT_VERSION: int = 2
const METADATA_PROPERTY_VERSION: String = "metadata_format_version"
const METADATA_PROPERTY_FILE: String = "packed_file"
const METADATA_PROPERTY_GLTF_FILE_LIST: String = "gltf_files"
const METADATA_FILE: String = "res://scene_packer_metadata.dat"
const IMPORT_DIRECTORY_PATH: String = "res://.godot/imported/"
const IMPORT_FILE_PROPERTY_DEST_FILES = "dest_files="


## Unpacks pck file from a given file path
## returns ScenePackerMetaData object with additional information about pack which has been loaded
static func unpack_pck_file(in_pck_filepath: String) -> ScenePackerMetaData:
	var _success = ProjectSettings.load_resource_pack(in_pck_filepath)
	if not _success:
		printerr("ScenePacker: Something went wrong during unpacking: ", in_pck_filepath)
		return ScenePackerMetaData.new({})

	var metadata_dict: Dictionary = _load_metadata_dictionary()
	var post_process = null
	if metadata_dict[METADATA_PROPERTY_VERSION] == 1:
		post_process = PCKUnpackPostProcessV1.new()
	elif metadata_dict[METADATA_PROPERTY_VERSION] == 2:
		post_process = PCKUnpackPostProcessV2.new()
	else:
		printerr("ScenePacker: I'm trying to unpack pck which was packed in newer version of The Mirror, unknown format version")
		return ScenePackerMetaData.new({})

	return post_process.finalize(in_pck_filepath)


## Unpacks a PCK file and returns a node instance that may be duplicated.
static func get_unpacked_pck_as_node(path_to_pck_file: String) -> Node:
	var node: Node
	var unpack_info: ScenePackerMetaData = unpack_pck_file(path_to_pck_file)
	if unpack_info.has_error():
		printerr("ScenePacker: can't determine filepath for object unpacked from:", path_to_pck_file)
		return node
	var unpacked_scene_filepath = unpack_info.get_loaded_filepath()
	var unpacked_scene = load(unpacked_scene_filepath)
	if not is_instance_valid(unpacked_scene):
		printerr("ScenePacker: encountered an error while loading file from unpacked pck:", unpacked_scene_filepath)
		return node
	var instance = unpacked_scene.instantiate()
	if not is_instance_valid(instance):
		printerr("ScenePacker: cannot create instance:", unpacked_scene_filepath)
		return node
	node = instance
	return node


static func _load_metadata_dictionary() -> Dictionary:
	var metadata = {}
	if FileAccess.file_exists(METADATA_FILE):
		var file_explorer = FileAccess.open(METADATA_FILE, FileAccess.READ)
		var raw_string = file_explorer.get_line()
		if raw_string.is_empty():
			return metadata
		var json = JSON.new()
		json.parse(raw_string)
		metadata = json.get_data()
	return metadata


static func pack_scene_to_pck_file(in_scene_filepath: String, in_target_pck_filepath: String) -> void:
	assert(in_target_pck_filepath.ends_with(".pck"))
	assert(in_scene_filepath.ends_with(".tscn") or in_scene_filepath.ends_with(".scn"))

	var scene = load(in_scene_filepath)
	var packer = PCKPacker.new()
	var instance = scene.instantiate()
	var all_gltf_files = {
		#some_file.gltf : some_file.gltf-12a0c89316e48b5bad2d99eb30232a04.scn
	}
	assert(is_instance_valid(instance))

	packer.pck_start(in_target_pck_filepath)
	packer.add_file(in_scene_filepath, in_scene_filepath)
	_add_all_node_resources(instance, packer, all_gltf_files)
	_add_all_children_nodes(instance, instance, packer, all_gltf_files)
	_add_metadata(in_scene_filepath, packer, all_gltf_files)
	packer.flush()

	_pack_cleanup(instance)


static func _add_all_children_nodes(in_owner: Node, in_start_node:Node, in_packer: PCKPacker,
		out_gltf_files: Dictionary) -> void:
	for child in in_start_node.get_children():
		var child_filepath = child.get_scene_file_path()
		if not child_filepath.is_empty():
			var _err = in_packer.add_file(child.get_scene_file_path(), child.get_scene_file_path())
			# Will have entry only if child is GLTF.
			var imported_child_files = _find_all_imported_files_4_object(child_filepath)
			if imported_child_files.size() == 1:
				# GLTF should have exactly one imported SCN.
				var imported_gltf_path: String = imported_child_files.front()
				out_gltf_files[child_filepath] = imported_gltf_path

			_add_all_node_resources(child, in_packer, out_gltf_files)
			_add_all_children_nodes(child, child, in_packer, out_gltf_files)
			continue
		if child.get_owner() == in_owner:
			_add_all_node_resources(child, in_packer, out_gltf_files)
			_add_all_children_nodes(in_owner, child, in_packer, out_gltf_files)


static func _add_all_node_resources(in_node: Node, out_packer: PCKPacker, in_gltf_data_to_ignore: Dictionary) -> void:
	_fetch_and_add_all_imports_4_node(in_node, out_packer, in_gltf_data_to_ignore)
	var node_resources := {}
	_fetch_all_object_dependencies(in_node, node_resources, in_gltf_data_to_ignore)
	for resource_key in node_resources:
		var resource = node_resources[resource_key]
		var resource_filepath = resource.resource_path
		var resource_pck_filepath = resource_filepath
		if not _has_any_imported_counterparts(resource_filepath):
			var _err = out_packer.add_file(resource_pck_filepath, resource_filepath)
		_fetch_and_add_all_imports_4_object(resource_filepath, out_packer, in_gltf_data_to_ignore)


# Checks if given resource has been actually imported (if Godot is actually using counterpart from
# .import directory instead of original resource)
static func _has_any_imported_counterparts(in_filepath: String) -> bool:
	var import_file_filepath = in_filepath + ".import"
	if FileAccess.file_exists(import_file_filepath):
		var file := FileAccess.open(import_file_filepath, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line()
			if line.begins_with(IMPORT_FILE_PROPERTY_DEST_FILES):
				return true
	return false


static func _fetch_and_add_all_imports_4_node(in_node: Node, out_packer: PCKPacker, in_gltf_data_to_ignore: Dictionary) -> void:
	if in_node.get_scene_file_path().is_empty():
		return
	var filepath = in_node.get_scene_file_path()
	_fetch_and_add_all_imports_4_object(filepath, out_packer, in_gltf_data_to_ignore)


static func _fetch_all_object_dependencies(in_resource: Object, out_resources: Dictionary, in_gltf_data_to_ignore: Dictionary) -> void:
	var node_properties = in_resource.get_property_list()
	for property_info in node_properties:
		var property_name = property_info.name
		if property_info.type != TYPE_OBJECT:
			#not a resource
			continue
		var property = in_resource.get(property_name)
		if property is Resource:
			var subresource = property as Resource
			if not out_resources.has(subresource.resource_path):
				out_resources[subresource.resource_path] = subresource
				_fetch_all_object_dependencies(subresource, out_resources, in_gltf_data_to_ignore)


static func _fetch_and_add_all_imports_4_object(in_obj_filepath: String, out_packer: PCKPacker,
		in_gltf_data_to_ignore: Dictionary) -> void:
	var resource_import_config_path = in_obj_filepath + ".import"
	if FileAccess.file_exists(resource_import_config_path):
		var _err = out_packer.add_file(resource_import_config_path, resource_import_config_path)

	var resource_imports := _find_all_imported_files_4_object(in_obj_filepath)
	for resource_import in resource_imports:
		var add_file := true
		for imported_scn_file_to_ignore in in_gltf_data_to_ignore.values():
			if resource_import == imported_scn_file_to_ignore:
				add_file = false
				break

		if add_file:
			var _err = out_packer.add_file(resource_import, resource_import)


static func _find_all_imported_files_4_object(in_resource_filepath: String) -> Array:
	var in_import_file_path = in_resource_filepath + ".import"
	var imported_files = []
	if not FileAccess.file_exists(in_import_file_path):
		return []

	var import_file = FileAccess.open(in_import_file_path, FileAccess.READ)
	while not import_file.eof_reached():
		var line = import_file.get_line()
		if line.begins_with(IMPORT_FILE_PROPERTY_DEST_FILES):
			var files = line.right(-IMPORT_FILE_PROPERTY_DEST_FILES.length())
			var json = JSON.new()
			var error := json.parse(files)
			if error != OK:
				printerr("ScenePacker: can't add imported counterpart for: ", in_import_file_path,
					" due to: ", json.get_error_message())
			imported_files = json.get_data()
	return imported_files


# might be worth to cache it
static func _get_all_filenames_in_directory(path) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				files.append(path + file_name)
			file_name = dir.get_next()
	return files


static func _add_metadata(in_scene_filepath: String, out_packer: PCKPacker, in_gltf_files: Dictionary) -> void:
	var metadata = {
		METADATA_PROPERTY_VERSION: CURRENT_METADATA_FORMAT_VERSION,
		METADATA_PROPERTY_FILE: in_scene_filepath,
		METADATA_PROPERTY_GLTF_FILE_LIST: in_gltf_files
	}
	var file_explorer = FileAccess.open(METADATA_FILE, FileAccess.WRITE)
	file_explorer.store_line(JSON.stringify(metadata))
	file_explorer.flush()
	file_explorer.close()

	var _err = out_packer.add_file(METADATA_FILE, METADATA_FILE)


static func _pack_cleanup(in_scn_instance: Node) -> void:
	in_scn_instance.queue_free()
	if FileAccess.file_exists(METADATA_FILE):
		var err = DirAccess.remove_absolute(METADATA_FILE)
		if err != OK:
			printerr("ScenePacker: Can't remove temporary metadata file, error while removing the file")


##########
### Additional classes

## Instance of this class is returned by ScenePacker.unpack_pck_file(...)
## Allows to obtain additional information about pck which just has been loaded
class ScenePackerMetaData:
	extends RefCounted


	var _metadata: Dictionary = {}


	func _init(in_metadata: Dictionary):
		_metadata = in_metadata


	func get_loaded_filepath() -> String:
		var filepath := ""
		if _metadata.has(METADATA_PROPERTY_FILE):
			filepath = _metadata[METADATA_PROPERTY_FILE]
		return filepath


	func has_error() -> bool:
		return not _metadata.has(METADATA_PROPERTY_FILE)


class PCKUnpackPostProcessV1:
	func finalize(_in_pck_filepath: String) -> ScenePackerMetaData:
		var metadata_dict: Dictionary = ScenePacker._load_metadata_dictionary()
		return ScenePackerMetaData.new(metadata_dict)


class PCKUnpackPostProcessV2:
	func finalize(_in_pck_filepath: String) -> ScenePackerMetaData:
		var metadata_dict: Dictionary = ScenePacker._load_metadata_dictionary()
		if metadata_dict.has(METADATA_PROPERTY_GLTF_FILE_LIST):
			var files_to_import = metadata_dict[METADATA_PROPERTY_GLTF_FILE_LIST]
			for source_filename in files_to_import:
				if source_filename.find(".gltf") < 0:
					continue
				var target_filename = files_to_import[source_filename]
				var sourceScn = TMFileUtil.load_gltf_file_as_node(source_filename, false)
				var packedGltf = PackedScene.new()
				packedGltf.pack(sourceScn)
				ResourceSaver.save(packedGltf, target_filename)
		return ScenePackerMetaData.new(metadata_dict)
