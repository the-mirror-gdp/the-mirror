@tool
class_name GLTFDocumentExtensionMirrorModelPrimitive
extends GLTFDocumentExtension


func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("MIRROR_model_primitive"):
		return OK
	return ERR_SKIP


func _parse_node_extensions(_gltf_state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("MIRROR_model_primitive"):
		return OK
	var mi_model_ext = extensions.get("MIRROR_model_primitive")
	if not mi_model_ext is Dictionary:
		printerr("Error: GLTF file is invalid, MIRROR_model_primitive extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	var mi_model_meta: Dictionary = {}
	var color_array = mi_model_ext.get("color")
	if not color_array is Array or color_array.size() < 3:
		mi_model_meta["color"] = Color.WHITE
	else:
		for item in color_array:
			if not item is float:
				printerr("Error: MIRROR_model_primitive extension color property is corrupt (expected only numbers).")
				return ERR_FILE_CORRUPT
		mi_model_meta["color"] = Serialization.array_to_color(color_array)
	if mi_model_ext.has("shape"):
		var size_array = mi_model_ext.get("size")
		if not size_array is Array:
			printerr("Error: MIRROR_model_primitive extension with custom shape should have a size.")
			return ERR_FILE_CORRUPT
		for item in size_array:
			if not item is float:
				printerr("Error: MIRROR_model_primitive extension custom shape size is corrupt.")
				return ERR_FILE_CORRUPT
		# In most cases we want to use the collision shape resource for the
		# shape information, but that only works for standardized shapes.
		# For non-standard shapes like cones and triangles we use our metadata.
		if mi_model_ext["shape"] == "cone":
			mi_model_meta["shape"] = ModelPrimitive.ShapeType.CONE
			if size_array.size() < 2:
				printerr("Error: MIRROR_model_primitive extension with cone shape size does not have enough numbers (expected 2).")
				return ERR_FILE_CORRUPT
			mi_model_meta["size"] = PackedFloat64Array(size_array)
		elif mi_model_ext["shape"] == "triangle":
			mi_model_meta["shape"] = ModelPrimitive.ShapeType.TRIANGLE
			if size_array.size() < 3:
				printerr("Error: MIRROR_model_primitive extension with triangle shape size does not have enough numbers (expected 3).")
				return ERR_FILE_CORRUPT
			mi_model_meta["size"] = PackedFloat64Array(size_array)
		else:
			printerr("Error: MIRROR_model_primitive extension has unrecognized custom shape.")
			return ERR_FILE_CORRUPT
	gltf_node.set_additional_data("MIRROR_model_primitive", mi_model_meta)
	return OK


func _import_node(_state: GLTFState, gltf_node: GLTFNode, _json: Dictionary, node: Node) -> Error:
	var node_collider = gltf_node.get_additional_data("GLTFPhysicsColliderShape")
	var mi_model_meta = gltf_node.get_additional_data("MIRROR_model_primitive")
	node.set_meta(&"GLTFPhysicsColliderShape", node_collider)
	node.set_meta(&"MIRROR_model_primitive", mi_model_meta)
	return OK


func _import_post(state: GLTFState, root: Node) -> Error:
	# The true doesn't actually matter, we later just check if the key exists.
	root.set_meta(&"MIRROR_block_model", true)
	return OK


func _export_preflight(state: GLTFState, root: Node) -> Error:
	if root is ModelRoot:
		return OK
	return ERR_SKIP


func _export_node(state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if node is ModelPrimitive:
		var extensions: Dictionary = json.get_or_set_default("extensions", {})
		var mi_model_ext: Dictionary = node.serialize_to_mi_model_gltf_extension()
		extensions["MIRROR_model_primitive"] = mi_model_ext
		state.add_used_extension("MIRROR_model_primitive", false)
	return OK
