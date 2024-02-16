@tool
class_name GLTFDocumentExtensionMirrorEquipable
extends GLTFDocumentExtension


func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("MIRROR_equipable"):
		return OK
	return ERR_SKIP


func _import_post(state: GLTFState, root: Node) -> Error:
	# This is to prevent a crash when sometimes the root was null,
	# but the actual cause should be investigated in the future.
	if not root:
		return ERR_SKIP
	var extensions = state.json.get("extensions")
	if not extensions is Dictionary:
		printerr("Error: GLTF file is invalid, extensions should be a Dictionary.")
		return ERR_FILE_CORRUPT
	var equipable = extensions.get("MIRROR_equipable")
	if not equipable is Dictionary:
		printerr("Error: MIRROR_equipable extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if equipable.has("gun"):
		_convert_vector(equipable["gun"], "muzzle_flash")
	root.set_meta(&"MIRROR_equipable", equipable)
	return OK


func _convert_vector(dict: Dictionary, vector_name) -> void:
	if not dict.has(vector_name):
		return
	var value = dict[vector_name]
	if value is Array and value.size() == 3 and value[0] is float \
	and value[1] is float and value[2] is float:
		dict[vector_name] = Vector3(value[0], value[1], value[2])
