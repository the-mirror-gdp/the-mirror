@tool
class_name GLTFDocumentExtensionOMISeat
extends GLTFDocumentExtension


func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("OMI_seat"):
		return OK
	return ERR_SKIP


func _import_node(_state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions is Dictionary:
		printerr("Error: GLTF file is invalid, extensions should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not extensions.has("OMI_seat"):
		return OK
	var seat_dict = extensions.get("OMI_seat")
	if not seat_dict is Dictionary:
		printerr("Error: OMI_seat extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if convert_seat(seat_dict):
		node.set_meta(&"OMI_seat", seat_dict)
	else:
		return ERR_FILE_CORRUPT
	return OK


static func convert_seat(seat_dict: Dictionary) -> bool:
	if not _convert_seat_vector(seat_dict, "foot"):
		return false
	if not _convert_seat_vector(seat_dict, "knee"):
		return false
	if not _convert_seat_vector(seat_dict, "back"):
		return false
	if not seat_dict.has("angle") or not seat_dict["angle"] is float:
		seat_dict["angle"] = TAU * 0.25
	_calculate_helper_vectors(seat_dict)
	return true


static func _convert_seat_vector(seat_dict: Dictionary, vector_name: String) -> bool:
	if not seat_dict.has(vector_name):
		printerr("Error: OMI_seat extension is missing required field '" + vector_name + "', contents: '" + str(seat_dict) + "'.")
		return false
	var vector_array = seat_dict[vector_name]
	if vector_array is Vector3:
		return true
	if not vector_array is Array or vector_array.size() != 3 or not vector_array[0] is float \
			or not vector_array[1] is float or not vector_array[2] is float:
		printerr("Error: OMI_seat extension field '" + vector_name + "' is invalid, expected an array of 3 numbers but was '" + str(vector_array) + "'.")
		return false
	seat_dict[vector_name] = Vector3(vector_array[0], vector_array[1], vector_array[2])
	return true


static func _calculate_helper_vectors(seat_dict: Dictionary) -> void:
	var back: Vector3 = seat_dict["back"]
	var foot: Vector3 = seat_dict["foot"]
	var knee: Vector3 = seat_dict["knee"]
	var upper_leg_dir: Vector3 = back.direction_to(knee)
	var lower_leg_dir: Vector3 = knee.direction_to(foot)
	var right: Vector3 = lower_leg_dir.cross(upper_leg_dir).normalized()
	var spine_dir: Vector3 = upper_leg_dir.rotated(right, seat_dict["angle"])
	var spine_norm: Vector3 = spine_dir.cross(right)
	var upper_leg_norm: Vector3 = right.cross(upper_leg_dir)
	var lower_leg_norm: Vector3 = right.cross(lower_leg_dir)
	# Write to the dictionary.
	seat_dict["upper_leg_dir"] = upper_leg_dir
	seat_dict["lower_leg_dir"] = lower_leg_dir
	seat_dict["right"] = right
	seat_dict["spine_dir"] = spine_dir
	seat_dict["spine_norm"] = spine_norm
	seat_dict["upper_leg_norm"] = upper_leg_norm
	seat_dict["lower_leg_norm"] = lower_leg_norm


func _export_node(state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if node.has_meta(&"OMI_seat"):
		var omi_seat_ext: Dictionary = _export_omi_seat(node.get_meta(&"OMI_seat"))
		# Write to the GLTF node JSON.
		var extensions: Dictionary = json.get_or_add("extensions", {})
		extensions["OMI_seat"] = omi_seat_ext
		state.add_used_extension("OMI_seat", false)
	return OK


func _export_omi_seat(omi_seat_meta: Dictionary) -> Dictionary:
	var back: Vector3 = omi_seat_meta["back"]
	var foot: Vector3 = omi_seat_meta["foot"]
	var knee: Vector3 = omi_seat_meta["knee"]
	var omi_seat_ext: Dictionary = {}
	omi_seat_ext["back"] = [back.x, back.y, back.z]
	omi_seat_ext["foot"] = [foot.x, foot.y, foot.z]
	omi_seat_ext["knee"] = [knee.x, knee.y, knee.z]
	if not is_equal_approx(omi_seat_meta["angle"], TAU * 0.25):
		omi_seat_ext["angle"] = omi_seat_meta["angle"]
	return omi_seat_ext
