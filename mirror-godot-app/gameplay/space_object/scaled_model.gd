extends Node3D


# Note: We only need to emit this when something changes in the node structure
# that the scene hierarchy or inspector needs to know about. So, we do emit this
# for changing meshes, but not for changing behind-the-scenes physics shapes.
signal node_structure_changed()

## Can be any huge value significantly less than the engine's MAX_OBJECT_DISTANCE.
const _BIG_OUTLIER_POSITION = Vector3(1e18, 1e18, 1e18)

@export var outline_resource: Resource

var _model_node: Node
var _model_source: Node
var _old_transform: Transform3D
var _space_object: SpaceObject
var _extra_nodes_in_tree: Array = []

# Physics
var _model_provided_bodies: Array
var _model_provided_shapes_require_static: bool = false
var _last_generated_shape_type: String
var _is_shape_generating: bool = true # Block generation until model is set up.
var _try_another_regeneration_later: bool = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		if not transform.is_equal_approx(_old_transform):
			setup_physics_colliders()


func get_model_root_node() -> Node:
	return _model_node


func get_model_node_by_name(node_name: StringName) -> Node:
	return TMNodeUtil.recursive_get_node_by_name(self, node_name)


func get_model_node_by_type(node_type: String) -> Node:
	return TMNodeUtil.recursive_get_node_by_type_string(self, node_type)


## This is a hyper-specific API designed to work with the inspector.
func get_inspector_extra_physics_options() -> int:
	for model_body in _model_provided_bodies:
		if not is_instance_valid(model_body):
			printerr("A model body was invalid! Model nodes should never be freed while the SpaceObject still exists.")
			continue
		var imported_jbody_mode: JBody3D.BodyMode = model_body.get_meta(&"imported_jbody_mode")
		if imported_jbody_mode != JBody3D.BodyMode.STATIC:
			return 2
	return 0 if _model_provided_bodies.size() == 0 else 1


func is_block_model() -> bool:
	return is_instance_valid(_model_source) and _model_source.has_meta(&"MIRROR_block_model")


func setup_initial(space_object: SpaceObject) -> void:
	set_notify_local_transform(true)
	_space_object = space_object


func setup_model(model_source: Node) -> void:
	_model_source = model_source
	_setup_model_and_mesh()
	_setup_extra_nodes()
	refresh_model_materials()
	refresh_model_visibility()
	# Must wait one physics frame for the physics server to
	# be updated with any physics data added by the model.
	var tree = get_tree()
	# BUG: joining server when you leave immediately crashes without this.
	if not tree:
		return
	await tree.physics_frame
	_is_shape_generating = false
	setup_physics_colliders()


func reset_with_space_object_data() -> void:
	refresh_model_materials()
	setup_physics_colliders()


## Sets the instance up to display a mesh/GLTF/GLB node.
func _setup_model_and_mesh() -> void:
	var changed = false
	if _model_node:
		self.remove_child(_model_node)
		_model_node.queue_free()
		changed = true
	if _model_source:
		if _model_source.get_child_count() == 1 and not _model_source.has_meta(&"from_pck"):
			# The GLTF importer creates an extra root node to handle GLTF
			# files with multiple root nodes. If only one, we can skip it.
			_model_node = _model_source.get_child(0).duplicate()
		else:
			_model_node = _model_source.duplicate()
			if _model_node.has_node(^"AnimationPlayer"):
				_space_object.animation_player = _model_node.get_node(^"AnimationPlayer")
		self.add_child(_model_node)
		if _model_source.has_meta(&"has_omi_spawn_points"):
			Zone.Scene.register_spawn_points(_model_node)
		changed = true
	if changed:
		_update_model_provided_physics_vars()
		node_structure_changed.emit()


func setup_extra_nodes() -> void:
	_delete_all_extra_nodes()
	_setup_extra_nodes()


func _setup_extra_nodes() -> void:
	# Add new extra nodes from SpaceObject's data.
	var extra_node_dicts = _space_object.extra_node_dicts
	for extra_node_dict in extra_node_dicts:
		var parent_name: String = extra_node_dict["parent"]
		var parent_node: Node = get_model_node_by_name(StringName(parent_name))
		if not parent_node:
			continue
		var new_node: Node3D = _create_extra_node_from_dict(extra_node_dict)
		_extra_nodes_in_tree.append(new_node)
		parent_node.add_child(new_node)


func _delete_all_extra_nodes() -> void:
	for existing_node in _extra_nodes_in_tree:
		if not is_instance_valid(existing_node):
			continue
		var parent = existing_node.get_parent()
		if parent:
			parent.remove_child(existing_node)
		existing_node.queue_free()
	_extra_nodes_in_tree.clear()


## This code is similar to Godot's GLTFDocument::_generate_scene_node,
## but has a much narrower scope of what it needs to support.
func _create_extra_node_from_dict(extra_node_dict: Dictionary) -> Node3D:
	var extensions: Dictionary = extra_node_dict.get("extensions", {})
	var node: Node3D
	if extensions.has("OMI_physics_shape"):
		var gltf_shape := GLTFPhysicsShape.from_dictionary(extensions["OMI_physics_shape"])
		node = gltf_shape.to_jbody()
	if not node:
		# If not generated yet, no specific Godot node type needed, so generate a Node3D.
		node = Node3D.new()
	# By now, there will be a node generated. Set up the transform.
	if extra_node_dict.has("translation"):
		var a: Array = extra_node_dict["translation"]
		node.position = Serialization.array_to_vector3(a)
	if extra_node_dict.has("rotation"):
		var a: Array = extra_node_dict["rotation"]
		node.quaternion = Quaternion(a[0], a[1], a[2], a[3])
	if extra_node_dict.has("scale"):
		var a: Array = extra_node_dict["scale"]
		node.scale = Serialization.array_to_vector3(a)
	# Set up extensions. We only need to include the ones that The Mirror supports as extra nodes.
	if extensions.has("OMI_seat"):
		var seat = Dictionary(extensions["OMI_seat"]).duplicate(true)
		GLTFDocumentExtensionOMISeat.convert_seat(seat)
		node.set_meta(&"OMI_seat", seat)
	if extensions.has("OMI_spawn_point"):
		node.set_meta(&"OMI_spawn_point", extensions["OMI_spawn_point"])
		Zone.Scene.register_spawn_point(node)
	node.set_meta(&"MirrorExtraNode", extra_node_dict)
	node.name = extra_node_dict["name"]
	return node


## Gets the real desired shape type, such that it's never "Auto".
## This method is named "desired" since it may not be what's currently active
## in cases where the physics shapes are outdated and need regeneration.
func determine_desired_shape_type() -> String:
	var space_object_shape_type: String = _space_object.physics_shape_type
	if space_object_shape_type == "Auto":
		if _model_provided_bodies.size() > 0:
			if _space_object._physics_body_type == "Static":
				# We could default to "Multi Bodies" if _model_provided_bodies.size() > 1,
				# but due to it being buggy for now we will default to "Model Shapes".
				return "Model Shapes"
			elif _model_provided_shapes_require_static:
				return "Convex"
			else:
				return "Model Shapes"
		elif _space_object._physics_body_type != "Static":
			# We want convex for dynamic, kinematic, and trigger bodies.
			return "Convex"
		else:
			return "Concave"
	return space_object_shape_type


func does_desired_shape_type_require_static() -> bool:
	var desired_shape_type = determine_desired_shape_type()
	# If Model Shapes are used, check if the shapes require static.
	if desired_shape_type == "Model Shapes":
		return _model_provided_shapes_require_static
	# Concave shapes must be static. Multi Bodies must have a static base.
	return desired_shape_type == "Concave" or desired_shape_type == "Multi Bodies"


func setup_physics_colliders() -> void:
	if _is_shape_generating or not is_instance_valid(_space_object):
		_try_another_regeneration_later = true
		return
	var desired_shape_type: String = determine_desired_shape_type()
	# Do we need to regenerate? Check what we have.
	if desired_shape_type == _last_generated_shape_type \
			and transform.is_equal_approx(_old_transform):
		return
	_is_shape_generating = true
	_last_generated_shape_type = desired_shape_type
	_old_transform = transform
	# Delete old CollisionShape3D children.
	if is_instance_valid(_space_object.shape):
		_space_object.shape = null
	_setup_new_physics_colliders(desired_shape_type)
	# All promises have been fulfilled.
	_is_shape_generating = false
	if _try_another_regeneration_later:
		setup_physics_colliders()


func _setup_new_physics_colliders(desired_shape_type: String) -> void:
	_space_object.set_ignore_state_sync(true)

	if desired_shape_type == "Multi Bodies":
		_space_object.shape = null
		for model_body in _model_provided_bodies:
			if not is_instance_valid(model_body):
				printerr("A model body was invalid! Model nodes should never be freed while the SpaceObject still exists.")
				continue
			# This value is set at import time, and we ensure all _model_provided_bodies have this set.
			var imported_jbody_mode: JBody3D.BodyMode = model_body.get_meta(&"imported_jbody_mode")
			model_body.body_mode = imported_jbody_mode
			match imported_jbody_mode:
				JBody3D.BodyMode.STATIC:
					model_body.set_layer_name(&"STATIC")
				JBody3D.BodyMode.KINEMATIC:
					model_body.set_layer_name(&"KINEMATIC")
				JBody3D.BodyMode.DYNAMIC:
					model_body.set_layer_name(&"DYNAMIC")
				JBody3D.BodyMode.SENSOR:
					model_body.set_layer_name(&"TRIGGER")
	else:
		for model_body in _model_provided_bodies:
			if not is_instance_valid(model_body):
				printerr("A model body was invalid! Model nodes should never be freed while the SpaceObject still exists.")
				continue
			# Note: Trigger or not doesn't matter because the layer is NO_COLLIDE.
			model_body.body_mode = JBody3D.BodyMode.STATIC
			model_body.set_layer_name(&"NO_COLLIDE")
		var asset_hash = Net.file_client._file_cache.get_hash_for_asset(_space_object.asset_data.file_url)
		var cache_key = asset_hash + "-" + desired_shape_type

		if desired_shape_type == "Model Shapes":
			var promise = await _generate_model_shape_collision(cache_key)
			await promise.wait_till_fulfilled()
			_space_object.shape = promise.get_result()
			_model_provided_shapes_require_static = not _space_object.shape.is_convex()
		elif desired_shape_type == "Capsule":
			_generate_capsule_shape_collision()
		else: # Concave or Convex mesh shape.
			var promise = await _generate_mesh_collision(cache_key, desired_shape_type == "Concave")
			await promise.wait_till_fulfilled()
			_space_object.shape = promise.get_result()

	await get_tree().create_timer(2.0).timeout
	_space_object.set_ignore_state_sync(false)


func _generate_capsule_shape_collision() -> void:
	var aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(self)
	var capsule = JCapsuleShape3D.new()
	capsule.height = max(aabb.size.y, aabb.size.x/2.0)
	capsule.radius = aabb.size.x/2.0
	var body_transform := Transform3D(Basis.IDENTITY, aabb.get_center())
	var compound_shape := JCompoundShape3D.new()
	compound_shape.shapes = [capsule]
	compound_shape.transforms = [body_transform]
	_space_object.shape = compound_shape
	_model_provided_shapes_require_static = false


func _generate_model_shape_collision(cache_key: String) -> Promise:
	if Zone.hash_requests.has(cache_key):
		Zone.hash_requests[cache_key] += 1
		return Zone.physics_hash_promises[cache_key]
	else:
		Zone.hash_requests[cache_key] = 1
		Zone.physics_hash_promises[cache_key] = Promise.new()

	var shapes: Array[JShape3D] = []
	var transforms: Array[Transform3D] = []
	for model_body in _model_provided_bodies:
		if not is_instance_valid(model_body):
			printerr("A model body was invalid! Model nodes should never be freed while the SpaceObject still exists.")
			continue
		var body_transform: Transform3D = TMNodeUtil.get_relative_transform(_space_object.interpolated_node, model_body)
		var shape: JShape3D = model_body.shape
		if shape:
			shapes.push_back(shape)
			transforms.push_back(body_transform)
	var compound_shape := JCompoundShape3D.new()
	compound_shape.shapes = shapes
	compound_shape.transforms = transforms
	var promise = Zone.physics_hash_promises[cache_key]
	promise.set_result(compound_shape)
	return promise


static var cumulative_collision_mesh_assignment_time = 0


func _generate_mesh_collision(cache_key: String, is_concave: bool) -> Promise:
	if Zone.hash_requests.has(cache_key):
		Zone.hash_requests[cache_key] += 1
		return Zone.physics_hash_promises[cache_key]
	else:
		Zone.hash_requests[cache_key] = 1
		Zone.physics_hash_promises[cache_key] = Promise.new()
	var start_time = Time.get_unix_time_from_system()
	var mi := Util.recursive_find_nodes_of_type(self, MeshInstance3D)
	var mesh_instances: Array[MeshInstance3D] = []
	mesh_instances.resize(mi.size())
	for i in range(mi.size()):
		mesh_instances[i] = mi[i]

	var body: JBody3D = _space_object

	var async_collider_construction = true
	var shape: JShape3D = null

	if not async_collider_construction:
		shape = Zone.shapes_generator.generate_shape_for_meshes(body, mesh_instances, is_concave)[0]
	else:
		var promise = Zone.shapes_generator.async_generate_shape_for_meshes(body, mesh_instances, is_concave)
		assert(promise != null)
		await promise.wait_till_fulfilled()
		shape = promise.get_result()

	assert(shape != null)
	body.shape = shape
	# to ensure the pointers always match we must set it to the same reference
	# this de-duplicates the shapes
	# this is faster because one pointer for 50+ shapes, and 0 generation time for them.
	var promise = Zone.physics_hash_promises[cache_key]
	promise.set_result(body.shape)
	var shape_time = Time.get_unix_time_from_system() - start_time
	print("took ", shape_time, "to generate collision shape")
	cumulative_collision_mesh_assignment_time += shape_time
	print("cumulatively we have taken: ", cumulative_collision_mesh_assignment_time,  " seconds")
	return promise


## Ensure concave shapes are static, since physics engines do not support
## concave-concave collision required for concave shapes on moving bodies.
func _update_model_provided_physics_vars() -> void:
	_model_provided_shapes_require_static = false
	if _model_node == null:
		_model_provided_bodies.clear()
		return
	var all_model_provided_jbodies: Array[Node] = TMNodeUtil.recursive_find_nodes_by_type(self, JBody3D)
	for model_body in all_model_provided_jbodies:
		if model_body.is_sensor():
			continue
		if not model_body.has_meta(&"imported_jbody_mode"):
			continue
		# For solid bodies, keep track of them.
		_model_provided_bodies.append(model_body)
		if model_body.shape is JMeshShape3D or model_body.shape is JCompoundShape3D:
			_model_provided_shapes_require_static = true


func has_representation():
	return is_instance_valid(_model_node)


func _get_material(default: Material):
	if not _space_object.object_material_data or not _space_object.object_material_data.material:
		return default.duplicate(true)
	return _space_object.object_material_data.material.duplicate()


## Determines if user changed anything in material settings.
func _is_default_material():
	var color = _space_object.object_color
	if color != Color.WHITE:
		return false
	if _space_object.object_local_texture:
		return false
	if _space_object.object_texture_data and _space_object.object_texture_data.get_asset_file_promise().has_result():
		return false
	if _space_object.object_texture_triplanar:
		return false
	if not _space_object.object_texture_repeat:
		return false
	if not _space_object.object_texture_size.is_equal_approx(Vector3.ONE):
		return false
	if not _space_object.object_texture_offset.is_equal_approx(Vector3.ZERO):
		return false
	if  _space_object.object_material_data and _space_object.object_material_data.material:
		return false
	return true


func refresh_model_main_texture(texture_id: String) -> void:
	var surface_data = await GameplayTools.material_selector.get_raycasted_surface_data()
	if surface_data == null:
		return
	var mesh: MeshInstance3D = surface_data.mesh
	var surface_id: int = surface_data.surface_id
	var material = mesh.get_active_material(surface_id)
	if not material is MirrorMaterial:
		var duplicate_mat = material.duplicate()
		mesh.set_surface_override_material(surface_id, duplicate_mat)
		var override = {"texture_albedo": texture_id}
		await Zone.material_manager.create_instance_from_base_material(material, override, _space_object, mesh, surface_id)
	var mirror_material: MirrorMaterial = mesh.get_active_material(surface_id)
	mirror_material.set_shader_param("texture_albedo", texture_id)
	Zone.material_manager.update_material_instance(mirror_material)


func refresh_model_materials(force_full_refresh := false) -> void:
	if Zone.is_host():
		return
	if _space_object == null:
		return
	var meshes: Array[Node] = TMNodeUtil.recursive_find_nodes_by_type(self, MeshInstance3D)
	for i in range(meshes.size()):
		if not is_instance_valid(meshes[i]):
			continue
		var mesh: MeshInstance3D = meshes[i]
		var mesh_path = get_path_to(mesh)
		for x in range(mesh.get_surface_override_material_count()):
			if not is_instance_valid(mesh):
				break #this can happen because of awaits in loop
			var key: String = "%s:surface_%d" % [mesh_path, x]
			var surf_mat_data = _space_object.surface_material_id.get(key)
			if surf_mat_data != null and surf_mat_data is Array and surf_mat_data.size() == 2:
				var surf_mat_type = surf_mat_data[0]
				var surf_mat_id = surf_mat_data[1]
				await Zone.material_manager.lazy_set_material(mesh, x, surf_mat_id, surf_mat_type)
			elif not _space_object.material_id.is_empty():
				await Zone.material_manager.lazy_set_material(mesh, x, _space_object.material_id, Enums.MATERIAL_TYPE.ASSET)
			if _space_object.object_local_texture:
				var mat = mesh.get_active_material(x)
				if mat is BaseMaterial3D:
					# This is a local instance so we do not need to copy
					mat.albedo_texture = _space_object.object_local_texture
					if mat.albedo_texture.has_alpha():
					#	# For local textures we want to force alpha if it is in use
						mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				elif mat is MirrorMaterial:
					# improve this in the future:
					if mat.get_reference_count() > 3:
						mat = mat.duplicate()
						mesh.set_surface_override_material(x, mat)
					mat.set_shader_param("texture_albedo", _space_object.object_local_texture)


func refresh_surface_material(mesh: MeshInstance3D, surface_id: int) -> void:
	if Zone.is_host():
		return
	if not is_instance_valid(_space_object) or not is_instance_valid(mesh):
		return
	var mesh_path = get_path_to(mesh)
	var key: String = "%s:surface_%d" % [mesh_path, surface_id]
	var surf_mat_data = _space_object.surface_material_id.get(key)
	if surf_mat_data != null and surf_mat_data is Array and surf_mat_data.size() == 2:
		var surf_mat_type = surf_mat_data[0]
		var surf_mat_id = surf_mat_data[1]
		await Zone.material_manager.lazy_set_material(mesh, surface_id, surf_mat_id, surf_mat_type)
	elif not _space_object.material_id.is_empty():
		await Zone.material_manager.lazy_set_material(mesh, surface_id, _space_object.material_id, Enums.MATERIAL_TYPE.ASSET)


func refresh_model_visibility():
	if _space_object == null:
		return
	var meshes: Array[Node] = TMNodeUtil.recursive_find_nodes_by_type(self, MeshInstance3D)
	var shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _space_object.cast_shadows:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if is_zero_approx(_space_object.visible_from_margin) and is_zero_approx(_space_object.visible_to_margin):
		fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for mesh in meshes:
		mesh.cast_shadow = shadow_mode
		mesh.visibility_range_begin = _space_object.visible_from
		mesh.visibility_range_end = _space_object.visible_to
		mesh.visibility_range_begin_margin = _space_object.visible_from_margin
		mesh.visibility_range_end_margin = _space_object.visible_to_margin
		mesh.visibility_range_fade_mode = fade_mode
