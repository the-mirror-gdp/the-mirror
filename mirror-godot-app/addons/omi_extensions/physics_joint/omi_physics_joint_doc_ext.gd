@tool
class_name GLTFDocumentExtensionOMIPhysicsJoint
extends GLTFDocumentExtension


# Import process.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if not extensions.has("OMI_physics_joint"):
		return ERR_SKIP
	var state_json = state.get_json()
	if not state_json.has("extensions"):
		return ERR_FILE_CORRUPT
	var state_extensions: Dictionary = state_json["extensions"]
	if not state_extensions.has("OMI_physics_joint"):
		return ERR_FILE_CORRUPT
	var omi_physics_joint_doc_ext: Dictionary = state_extensions["OMI_physics_joint"]
	if not omi_physics_joint_doc_ext.has("constraints"):
		return ERR_FILE_CORRUPT
	var state_constraint_dicts: Array = omi_physics_joint_doc_ext["constraints"]
	var state_constraints: Array = []
	for constraint_dict in state_constraint_dicts:
		state_constraints.append(GLTFPhysicsJointConstraint.from_dictionary(constraint_dict))
	state.set_additional_data("GLTFPhysicsJointConstraints", state_constraints)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_physics_joint"])


func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("OMI_physics_joint"):
		return OK
	var joint_dict = extensions.get("OMI_physics_joint")
	if not joint_dict is Dictionary:
		printerr("Error: OMI_physics_joint extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	var constraints = joint_dict.get("constraints")
	if not constraints is Array or constraints.is_empty():
		printerr("Error: OMI_physics_joint extension should have at least one constraint.")
		return ERR_FILE_CORRUPT
	var state_constraints: Array = state.get_additional_data("GLTFPhysicsJointConstraints")
	var joint := GLTFPhysicsJoint.new()
	for constraint in constraints:
		var joint_constraint: GLTFPhysicsJointConstraint
		if constraint is float: # Remember, JSON only stores "number".
			joint_constraint = state_constraints[int(constraint)]
		else:
			joint_constraint = GLTFPhysicsJointConstraint.from_dictionary(constraint)
		joint.apply_constraint(joint_constraint)
	gltf_node.set_additional_data("GLTFPhysicsJoint", joint)
	return OK


func _generate_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var joint: GLTFPhysicsJoint = gltf_node.get_additional_data("GLTFPhysicsJoint")
	if joint == null:
		return null
	return joint.to_node()


func _import_node(state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions.has("OMI_physics_joint"):
		return OK
	var joint_dict = extensions.get("OMI_physics_joint")
	if not joint_dict is Dictionary:
		printerr("Error: OMI_physics_joint extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not joint_dict.has("nodeA") or not joint_dict.has("nodeB"):
		printerr("Error: OMI_physics_joint extension should have nodeA and nodeB.")
		return ERR_FILE_CORRUPT
	var joint_node: Joint3D = node as Joint3D
	var node_a_index: int = int(joint_dict["nodeA"])
	if node_a_index != -1:
		var node_a: Node = state.get_scene_node(node_a_index)
		if not node_a is PhysicsBody3D:
			printerr("Error: OMI_physics_joint nodeA should be a physics body (non-trigger).")
			return ERR_FILE_CORRUPT
		joint_node.node_a = joint_node.get_path_to(node_a)
	var node_b_index: int = int(joint_dict["nodeB"])
	if node_b_index != -1:
		var node_b: Node = state.get_scene_node(node_b_index)
		if not node_b is PhysicsBody3D:
			printerr("Error: OMI_physics_joint nodeB should be a physics body (non-trigger).")
			return ERR_FILE_CORRUPT
		joint_node.node_b = joint_node.get_path_to(node_b)
	return OK


# Export process.
func _convert_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if not scene_node is Joint3D:
		return
	var joint := GLTFPhysicsJoint.from_node(scene_node)
	gltf_node.set_additional_data("GLTFPhysicsJoint", joint)


func _get_or_create_state_constraints_in_state(state: GLTFState) -> Array:
	var state_json: Dictionary = state.get_json()
	var state_extensions: Dictionary = state_json.get_or_set_default("extensions", {})
	var omi_physics_joint_doc_ext: Dictionary = state_extensions.get_or_set_default("OMI_physics_joint", {})
	state.add_used_extension("OMI_physics_joint", false)
	var state_constraints: Array = omi_physics_joint_doc_ext.get_or_set_default("constraints", [])
	return state_constraints


func _get_or_insert_constraint_in_state(state: GLTFState, constraint: GLTFPhysicsJointConstraint) -> int:
	var state_constraints: Array = _get_or_create_state_constraints_in_state(state)
	var size: int = state_constraints.size()
	var constraint_dict: Dictionary = constraint.to_dictionary()
	for i in range(size):
		var other: Dictionary = state_constraints[i]
		if other == constraint_dict:
			# De-duplication: If we already have an identical constraint,
			# return the index of the existing constraint.
			return i
	# If we don't have an identical constraint, add it to the array.
	state_constraints.push_back(constraint_dict)
	return size


func _node_index_from_scene_node(state: GLTFState, scene_node: Node) -> int:
	var index: int = 0
	var node: Node = state.get_scene_node(index)
	while node != null:
		if node == scene_node:
			return index
		index = index + 1
		node = state.get_scene_node(index)
	return -1


func _export_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, _node: Node) -> Error:
	var gltf_physics_joint: GLTFPhysicsJoint = gltf_node.get_additional_data("GLTFPhysicsJoint")
	if gltf_physics_joint == null:
		return OK
	var node_extensions = json.get_or_set_default("extensions", {})
	var omi_physics_joint_node_ext: Dictionary = {}
	# Populate the constraints.
	var constraints: Array = gltf_physics_joint.get_constraints()
	var constraint_indices: Array[int] = []
	for constraint in constraints:
		var index: int = _get_or_insert_constraint_in_state(state, constraint)
		if not index in constraint_indices:
			constraint_indices.append(index)
	omi_physics_joint_node_ext["constraints"] = constraint_indices
	# Populate the node references.
	omi_physics_joint_node_ext["nodeA"] = _node_index_from_scene_node(state, gltf_physics_joint.node_a)
	omi_physics_joint_node_ext["nodeB"] = _node_index_from_scene_node(state, gltf_physics_joint.node_b)
	node_extensions["OMI_physics_joint"] = omi_physics_joint_node_ext
	return OK
