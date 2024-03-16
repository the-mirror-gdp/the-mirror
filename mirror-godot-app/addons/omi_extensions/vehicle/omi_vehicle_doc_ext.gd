@tool
class_name GLTFDocumentExtensionOMIVehicle
extends GLTFDocumentExtension


# Import process.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_vehicle_body") and not extensions.has("OMI_vehicle_wheel"):
		return ERR_SKIP
	var state_json: Dictionary = state.get_json()
	if state_json.has("extensions"):
		var state_extensions: Dictionary = state_json["extensions"]
		if state_extensions.has("OMI_vehicle_wheel"):
			var omi_vehicle_wheel_ext: Dictionary = state_extensions["OMI_vehicle_wheel"]
			if omi_vehicle_wheel_ext.has("wheels"):
				var state_wheel_dicts: Array = omi_vehicle_wheel_ext["wheels"]
				if state_wheel_dicts.size() > 0:
					var state_wheels: Array[GLTFVehicleWheel] = []
					for i in range(state_wheel_dicts.size()):
						state_wheels.append(GLTFVehicleWheel.from_dictionary(state_wheel_dicts[i]))
					state.set_additional_data(&"GLTFVehicleWheels", state_wheels)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_vehicle_body", "OMI_vehicle_wheel"])


func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if extensions.has("OMI_vehicle_body"):
		gltf_node.set_additional_data(&"GLTFVehicleBody", GLTFVehicleBody.from_dictionary(extensions["OMI_vehicle_body"]))
	if extensions.has("OMI_vehicle_wheel"):
		var node_wheel_ext: Dictionary = extensions["OMI_vehicle_wheel"]
		if node_wheel_ext.has("wheel"):
			# "wheel" is the index of the wheel parameters in the state wheels array.
			var node_wheel_index: int = node_wheel_ext["wheel"]
			var state_wheels: Array[GLTFVehicleWheel] = state.get_additional_data(&"GLTFVehicleWheels")
			if node_wheel_index < 0 or node_wheel_index >= state_wheels.size():
				printerr("GLTF Physics: On node " + gltf_node.get_name() + ", the wheel index " + str(node_wheel_index) + " is not in the state wheels (size: " + str(state_wheels.size()) + ").")
				return ERR_FILE_CORRUPT
			gltf_node.set_additional_data(&"GLTFVehicleWheel", state_wheels[node_wheel_index])
		else:
			gltf_node.set_additional_data(&"GLTFVehicleWheel", GLTFVehicleWheel.from_dictionary(extensions["OMI_vehicle_wheel"]))
	return OK


func _generate_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var gltf_vehicle_wheel: GLTFVehicleWheel = gltf_node.get_additional_data(&"GLTFVehicleWheel")
	if gltf_vehicle_wheel != null:
		return gltf_vehicle_wheel.to_node()
	return null


func _import_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var gltf_vehicle_body: GLTFVehicleBody = gltf_node.get_additional_data(&"GLTFVehicleBody")
	if gltf_vehicle_body != null:
		if node is RigidBody3D:
			gltf_vehicle_body.apply_to_godot_rigid_body(state, node)
		else:
			gltf_vehicle_body.apply_to_node(state, node)
	return OK


# Export process.
func _convert_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if scene_node is VehicleBody3D:
		var gltf_vehicle_body := GLTFVehicleBody.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleBody", gltf_vehicle_body)
	elif scene_node is VehicleWheel3D:
		var gltf_vehicle_wheel := GLTFVehicleWheel.from_node(scene_node)
		gltf_node.set_additional_data(&"GLTFVehicleWheel", gltf_vehicle_wheel)


func _get_or_create_state_wheels_in_state(gltf_state: GLTFState) -> Array:
	var state_json: Dictionary = gltf_state.get_json()
	var state_extensions: Dictionary = state_json.get_or_add("extensions", {})
	var omi_vehicle_wheel_ext: Dictionary = state_extensions.get_or_add("OMI_vehicle_wheel", {})
	gltf_state.add_used_extension("OMI_vehicle_wheel", false)
	var state_wheels: Array = omi_vehicle_wheel_ext.get_or_add("wheels", [])
	return state_wheels


func _node_index_from_scene_node(state: GLTFState, scene_node: Node) -> int:
	var index: int = 0
	var node: Node = state.get_scene_node(index)
	while node != null:
		if node == scene_node:
			return index
		index = index + 1
		node = state.get_scene_node(index)
	return -1


func _export_node(state: GLTFState, gltf_node: GLTFNode, node_json: Dictionary, _node: Node) -> Error:
	var gltf_vehicle_body: GLTFVehicleBody = gltf_node.get_additional_data(&"GLTFVehicleBody")
	if gltf_vehicle_body != null:
		gltf_vehicle_body.pilot_seat_index = _node_index_from_scene_node(state, gltf_vehicle_body.pilot_seat_node)
		var node_extensions = node_json.get_or_add("extensions", {})
		state.add_used_extension("OMI_vehicle_body", false)
		node_extensions["OMI_vehicle_body"] = gltf_vehicle_body.to_dictionary()
	var gltf_vehicle_wheel: GLTFVehicleWheel = gltf_node.get_additional_data(&"GLTFVehicleWheel")
	if gltf_vehicle_wheel != null:
		var node_extensions = node_json.get_or_add("extensions", {})
		var state_wheels = _get_or_create_state_wheels_in_state(state)
		var size = state_wheels.size()
		var omi_vehicle_wheel_ext: Dictionary = {}
		node_extensions["OMI_vehicle_wheel"] = omi_vehicle_wheel_ext
		var wheel_dict: Dictionary = gltf_vehicle_wheel.to_dictionary()
		for i in range(size):
			var other: Dictionary = state_wheels[i]
			if other == wheel_dict:
				# De-duplication: If we already have an identical wheel,
				# set the wheel index to the existing one and return.
				omi_vehicle_wheel_ext["wheel"] = i
				return OK
		# If we don't have an identical wheel, add it to the array.
		state_wheels.append(wheel_dict)
		omi_vehicle_wheel_ext["wheel"] = size
	return OK
