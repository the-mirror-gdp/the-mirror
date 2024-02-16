@tool
class_name GLTFDocumentExtensionOMISpawnPoint
extends GLTFDocumentExtension


func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("OMI_spawn_point"):
		return OK
	return ERR_SKIP


func _import_node(_state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions is Dictionary:
		printerr("Error: GLTF file is invalid, extensions should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not extensions.has("OMI_spawn_point"):
		return OK
	var spawn_point = extensions.get("OMI_spawn_point")
	if not spawn_point is Dictionary:
		printerr("Error: OMI_spawn_point extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	node.set_meta(&"OMI_spawn_point", spawn_point)
	return OK


func _import_post(state: GLTFState, root: Node) -> Error:
	# The true doesn't actually matter, we later just check if the key exists.
	root.set_meta(&"has_omi_spawn_points", true)
	return OK
