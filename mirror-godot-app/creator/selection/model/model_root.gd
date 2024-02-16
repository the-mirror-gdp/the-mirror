class_name ModelRoot
extends StaticBody3D


signal deletion_requested()
signal node_property_changed(object_node: ModelPrimitive, property_name: StringName, old_value: Variant, new_value: Variant)


func _init() -> void:
	set_collision_layer_value(Constants.PHYSICS_LAYER_PLAYER, false)
	set_collision_layer_value(Constants.PHYSICS_LAYER_SPACE_OBJECT, true)
	set_collision_layer_value(Constants.PHYSICS_LAYER_INPUT_RAY, true)
	set_collision_mask_value(Constants.PHYSICS_LAYER_VOXEL, true)
	set_collision_mask_value(Constants.PHYSICS_LAYER_SPACE_OBJECT, true)
	set_collision_mask_value(Constants.PHYSICS_LAYER_STATIC_SPACE_OBJECT, true)


## Used when loading a model from a GLTF file (skipping the file part).
func load_from_node_tree(parent_node: Node3D) -> void:
	var model_primitives = TMNodeUtil.recursive_find_nodes_by_meta(parent_node, &"MIRROR_model_primitive")
	for model_prim in model_primitives:
		var mi_model_meta: Dictionary = model_prim.get_meta(&"MIRROR_model_primitive")
		var gltf_shape: GLTFPhysicsShape = model_prim.get_meta(&"GLTFPhysicsColliderShape")
		var model_primitive := ModelPrimitive.new()
		model_primitive.setup_primitive_shape_from_gltf_shape_and_mi_model_meta(gltf_shape, mi_model_meta)
		model_primitive.transform = model_prim.transform
		model_primitive.name = model_prim.name
		add_child(model_primitive)


func save_to_gltf_file() -> String:
	# Export the model primitive nodes to GLTFState. We want the root to be not transformed.
	set_origin_point()
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var original_transform: Transform3D = transform
	transform = Transform3D.IDENTITY
	gltf_doc.append_from_scene(self, gltf_state)
	transform = original_transform
	# Save the GLTFState data to a file.
	var file_name = Util.clean_string_for_model_file_path(String(name))
	var file_path_base: String = Util.get_primitive_models_directory_path() + file_name
	var file_path_glb: String = file_path_base + ".glb"
	gltf_doc.write_to_filesystem(gltf_state, file_path_glb)
	gltf_doc.write_to_filesystem(gltf_state, file_path_base + ".gltf")
	return file_path_glb


func scene_hierarchy_delete() -> void:
	deletion_requested.emit()


func record_property_changed(property_name: StringName, old_value: Variant, new_value: Variant) -> void:
	node_property_changed.emit(self, property_name, old_value, new_value)


func set_origin_point() -> void:
	var child_transforms = []
	for child in get_children():
		child_transforms.append(child.global_transform)
	position = transform * TMNodeUtil.get_local_bottom_point(self)
	for i in range(get_child_count()):
		get_child(i).global_transform = child_transforms[i]
