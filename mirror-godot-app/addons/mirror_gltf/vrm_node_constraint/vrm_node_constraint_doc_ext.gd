@tool
class_name GLTFDocumentExtensionVRMNodeConstraint
extends GLTFDocumentExtension


func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("VRMC_node_constraint"):
		return OK
	return ERR_SKIP


func _parse_node_extensions(gltf_state: GLTFState, gltf_node: GLTFNode, node_extensions: Dictionary) -> Error:
	if not node_extensions.has("VRMC_node_constraint"):
		return OK
	var constraint_ext: Dictionary = node_extensions["VRMC_node_constraint"]
	var constraint := BoneNodeConstraint.from_dictionary(constraint_ext)
	gltf_node.set_additional_data(&"BoneNodeConstraint", constraint)
	return OK


func _import_post_parse(gltf_state: GLTFState) -> Error:
	var applier := BoneNodeConstraintApplier.new()
	applier.name = &"BoneNodeConstraintApplier"
	gltf_state.set_additional_data(&"BoneNodeConstraintApplier", applier)
	return OK


func _import_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var constraint: BoneNodeConstraint = gltf_node.get_additional_data(&"BoneNodeConstraint")
	if not constraint:
		return OK
	# Set up the source node.
	constraint.source_node = gltf_state.get_scene_node(constraint.source_node_index)
	constraint.source_rest_transform = constraint.source_node.transform
	if constraint.source_node is Skeleton3D:
		var source_bone_name: String = gltf_state.nodes[constraint.source_node_index].resource_name
		constraint.source_bone_index = constraint.source_node.find_bone(source_bone_name)
		# Edge case: Even though we have been given the Skeleton by Godot, and
		# this is almost certainly a bone, it could be the Skeleton node itself.
		if constraint.source_bone_index != -1:
			constraint.source_rest_transform = node.get_bone_rest(constraint.source_bone_index)
	# Set up the target node. NOTE: It seems similar to the source node code,
	# however there are a ton of subtle differences, so it should be duplicated.
	constraint.target_node = node
	constraint.target_rest_transform = node.transform
	if node is Skeleton3D:
		constraint.target_bone_index = node.find_bone(gltf_node.resource_name)
		# Edge case: Even though we have been given the Skeleton by Godot, and
		# this is almost certainly a bone, it could be the Skeleton node itself.
		if constraint.target_bone_index != -1:
			constraint.target_rest_transform = node.get_bone_rest(constraint.target_bone_index)
	# Set node paths relative to the applier and save to the applier.
	var applier: BoneNodeConstraintApplier = gltf_state.get_additional_data(&"BoneNodeConstraintApplier")
	applier.constraints.append(constraint)
	return OK


func _import_post(gltf_state: GLTFState, root: Node) -> Error:
	# Add the constraint applier to the real root, next to the AnimationPlayer.
	var applier: BoneNodeConstraintApplier = gltf_state.get_additional_data(&"BoneNodeConstraintApplier")
	root.add_child(applier)
	applier.owner = root
	# Set node paths relative to the applier.
	for constraint in applier.constraints:
		constraint.set_node_paths_from_references(applier)
	return OK


# Export process.
func _convert_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if not scene_node is BoneNodeConstraintApplier:
		return
	var applier: BoneNodeConstraintApplier = scene_node
	gltf_state.set_additional_data(&"BoneNodeConstraintApplier", scene_node)
	gltf_state.add_used_extension("VRMC_node_constraint", false)
	for constraint in applier.constraints:
		constraint.set_node_references_from_paths(applier)
		if constraint.target_node:
			constraint.target_node.set_meta(&"GLTFBoneNodeConstraint", constraint)


func _export_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not node.has_meta(&"GLTFBoneNodeConstraint"):
		return OK
	var constraint: BoneNodeConstraint = node.get_meta(&"GLTFBoneNodeConstraint")
	if not constraint:
		return ERR_INVALID_DATA
	# TODO: Use get_node_index() once we stop supporting 4.0.x.
	# See https://github.com/godotengine/godot/pull/77534
	for i in range(gltf_state.get_nodes().size()):
		var scene_node: Node = gltf_state.get_scene_node(i)
		if scene_node == constraint.source_node:
			constraint.source_node_index = i
			break
	var extensions: Dictionary = json.get_or_set_default("extensions", {})
	extensions["VRMC_node_constraint"] = constraint.to_dictionary()
	node.remove_meta(&"GLTFBoneNodeConstraint")
	return OK
