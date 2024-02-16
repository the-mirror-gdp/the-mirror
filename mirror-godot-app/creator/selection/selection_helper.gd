class_name SelectionHelper
extends Node3D


@onready var _gizmo : Gizmo = $"../Gizmo"
@onready var _ws_debug_prints = ProjectSettings.get_setting("debug_flags/show_web_socket_debug", false)

var _grabbed_object: Node3D = null
var _grab_offset_from_bottom: Vector3
var _selected_nodes: Array[Node] = []
var _copied_nodes: Array[Node] = []
var _duplicated_nodes: Array[Dictionary] = []
var _node_original_transform: Dictionary = {}
var _node_original_scale: Dictionary = {}
var _selection_helper_starting_transform: Transform3D
var _undo_redo_system


func _ready():
	assert(_gizmo is Gizmo)
	_gizmo.transformation_started.connect(_on_transformation_started)
	_gizmo.transformation_ended.connect(_on_transformation_ended)


func _process(_delta) -> void:
	if Zone.is_in_play_mode():
		return
	update_position()


func select_nodes(new_nodes: Array[Node]) -> void:
	Zone.instance_manager.update_selected_nodes(new_nodes)
	# Deselect old nodes.
	for old_node in _selected_nodes:
		if not is_instance_valid(old_node):
			continue
		var parent = old_node.get_parent()
		if parent and parent.has_method(&"request_change_from_children"):
			_gizmo.transformation_ended.disconnect(parent.request_change_from_children)
	_selected_nodes.clear()
	# Select new nodes.
	_selected_nodes = new_nodes.duplicate()
	for new_node in _selected_nodes:
		assert(is_instance_valid(new_node))
		if new_node is SpaceTemplate or not new_node is Node3D:
			# SelectionHelper is used for making the gizmo and the transform
			# inspector work with multiple selected objects. It has no business
			# selecting SpaceTemplate, which is not supposed to ever move.
			# It also has no business selecting any non-3D node.
			_selected_nodes.erase(new_node)
			continue
		var parent = new_node.get_parent()
		if parent and parent.has_method(&"request_change_from_children"):
			_gizmo.transformation_ended.connect(parent.request_change_from_children)
	reset_scale_and_rotation()
	_gizmo.update_gizmo_visibility()


func delete_selected_nodes() -> Array[StringName]:
	var space_object_ids: Array[StringName] = []
	for node in _selected_nodes:
		if not is_instance_valid(node):
			continue
		if node is SpaceObject:
			node.hide()
			space_object_ids.append(node.name)
		elif node.has_method(&"scene_hierarchy_delete"):
			node.scene_hierarchy_delete()
	return space_object_ids


func copy_selected_nodes() -> Array[Node]:
	_copied_nodes = _selected_nodes.duplicate()
	return _copied_nodes


func paste_copied_nodes(delta_transform: Transform3D) -> Array[int]:
	return _create_copies_of_nodes(_copied_nodes, delta_transform)


func duplicate_selected_nodes() -> Array[int]:
	return _create_copies_of_nodes(_selected_nodes, Transform3D(Basis.IDENTITY, Vector3.UP))


func _create_copies_of_nodes(nodes: Array[Node], delta_transform: Transform3D) -> Array[int]:
	var node_instance_ids: Array[int] = []
	if nodes.is_empty():
		return node_instance_ids
	for node in nodes:
		if not is_instance_valid(node) or (not node is SpaceObject and not node is ModelPrimitive and not node is ModelRoot):
			continue
		if node is SpaceObject:
			var new_space_object_transform: Transform3D = delta_transform * node.transform
			var scaled_model_transform: Transform3D = node.scaled_model.transform
			var properties: Dictionary = _get_space_object_properties(node)
			properties["asset"] = node.asset_id
			properties["position"] = Serialization.vector3_to_array(new_space_object_transform.origin)
			properties["rotation"] = Serialization.vector3_to_array(new_space_object_transform.basis.get_euler())
			properties["scale"] = Serialization.vector3_to_array(scaled_model_transform.basis.get_scale())
			var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
			Zone.client_send_create_space_object(properties, receipt)
		elif node is ModelPrimitive:
			var dupe: ModelPrimitive = node.duplicate_model_primitive()
			dupe.position += Vector3.UP
			node.add_sibling(dupe)
			node_instance_ids.append(dupe.get_instance_id())
	return node_instance_ids


func apply_transform_to_selection(new_position: Vector3, new_rotation: Basis, new_scale: Vector3):
	var delta_position: Vector3 = new_position - position
	var delta_rotation: Basis = transform.basis.orthonormalized().inverse() * new_rotation.orthonormalized()
	var delta_scale: Vector3 = new_scale / transform.basis.get_scale()
	# Some bools for optimization to avoid computing these more than once.
	var same_position: bool = delta_position.is_zero_approx()
	var same_rotation: bool = delta_rotation.is_equal_approx(Basis.IDENTITY)
	var same_scale: bool = delta_scale.is_equal_approx(Vector3.ONE)
	if same_position and same_rotation and same_scale:
		return
	# If we got here, something has changed. Start and process the transformation.
	_on_transformation_started()
	if not same_position:
		process_active_translation(delta_position)
	if not same_rotation:
		process_active_rotation(delta_rotation)
	if not same_scale:
		process_active_scaling(delta_scale, _gizmo.is_relative)
		_record_properties_changed(&"scale")
	else:
		# Any change that isn't scale just needs the transform property recorded.
		_record_properties_changed(&"transform")
	_on_transformation_ended()


func update_position() -> void:
	if _selected_nodes.size() == 1:
		var selected_node = _selected_nodes[0]
		if not is_instance_valid(selected_node) or not selected_node is Node3D:
			return
		if selected_node is SpaceObject:
			# Take SpaceObject's rotation & position and dynamic mesh's scale
			global_transform.basis = selected_node.global_transform.basis.orthonormalized() * Basis.from_scale(selected_node.get_model_scale())
			global_transform.origin = selected_node.global_transform.origin
		else:
			global_transform = selected_node.global_transform
		return
	# If we got here, we have multiple nodes selected. Use the average position.
	var new_position: Vector3 = Vector3.ZERO
	var node3d_count: int = 0
	for node in _selected_nodes:
		if is_instance_valid(node) and node is Node3D:
			node3d_count += 1
			new_position += node.global_position
	if node3d_count == 0:
		return
	global_transform.origin = new_position / float(node3d_count)


func clear_selected_nodes() -> void:
	if _grabbed_object:
		cancel_grabbing()
	_selected_nodes.clear()


func _on_transformation_started() -> void:
	_selection_helper_starting_transform = global_transform
	_duplicated_nodes.clear()
	for selected_node in _selected_nodes:
		if not is_instance_valid(selected_node) or not selected_node is Node3D:
			continue
		if selected_node is SpaceObject:
			if Input.is_action_pressed(&"object_snap") and selected_node.scaled_model.has_representation():
				var duplicated_model = selected_node.scaled_model.duplicate()
				selected_node.add_sibling(duplicated_model)
				duplicated_model.global_transform = selected_node.scaled_model.global_transform
				var duplicated_node_dict: Dictionary = _get_space_object_properties(selected_node)
				duplicated_node_dict["model"] = duplicated_model
				duplicated_node_dict["asset"] = selected_node.asset_id
				_duplicated_nodes.append(duplicated_node_dict)
			selected_node.freeze_override = true
			_node_original_scale[selected_node.get_instance_id()] = selected_node.get_model_scale()
			_node_original_transform[selected_node.get_instance_id()] = selected_node.get_space_object_global_transform()
		else:
			_node_original_scale[selected_node.get_instance_id()] = selected_node.scale
			_node_original_transform[selected_node.get_instance_id()] = selected_node.global_transform


## parameter selected_node CANNOT be type-hinted or else an invalid instance exception is thrown.
func _is_selected_node_being_transformed(selected_node) -> bool:
	if not is_instance_valid(selected_node):
		printerr("Selection helper - node instance is no longer valid!")
		return false
	if not _node_original_transform.has(selected_node.get_instance_id()):
		printerr("Selection helper - original transform does not exist!")
		return false
	return true


func process_active_rotation(rotation_delta: Basis) -> void:
	for selected_node in _selected_nodes:
		if not _is_selected_node_being_transformed(selected_node):
			continue
		var selected_node_original_transform: Transform3D = _node_original_transform[selected_node.get_instance_id()]
		var gt: Transform3D = selected_node.global_transform
		if selected_node is SpaceObject:
			selected_node_original_transform.basis = selected_node_original_transform.basis.orthonormalized()
		# Calculate the basis and rotate by it.
		gt.basis = rotation_delta * selected_node_original_transform.basis
		if not _gizmo.is_relative:
			var global_transform_orthonormalized: Transform3D = global_transform
			global_transform_orthonormalized.basis = global_transform_orthonormalized.basis.orthonormalized()
			var initial_transform_orthonormalized = _selection_helper_starting_transform
			initial_transform_orthonormalized.basis = initial_transform_orthonormalized.basis.orthonormalized()
			gt.origin = global_transform_orthonormalized * (selected_node_original_transform.origin * initial_transform_orthonormalized)
		if selected_node is SpaceObject:
			selected_node.editmode_set_new_transform(gt)
		else:
			selected_node.global_transform = gt

	global_transform.basis = rotation_delta * _selection_helper_starting_transform.basis


func process_active_translation(offset: Vector3) -> void:
	var new_origin: Vector3 = _selection_helper_starting_transform.origin
	new_origin += offset
	Zone.get_local_character().translation_offset_all_selected_nodes(new_origin)
	for node in _selected_nodes:
		if not node is SpaceObject:
			var start: Transform3D = _node_original_transform[node.get_instance_id()]
			node.global_position = start.origin + offset
	global_transform.origin = new_origin


func process_active_scaling(scale_delta: Vector3, is_relative: bool) -> void:
	for selected_node in _selected_nodes:
		if not _is_selected_node_being_transformed(selected_node):
			continue
		var original_global_transform: Transform3D = _node_original_transform[selected_node.get_instance_id()]
		if is_relative:
			if selected_node is SpaceObject:
				selected_node.set_model_scale(_node_original_scale[selected_node.get_instance_id()] * scale_delta)
			else:
				var scale_basis: Basis
				if selected_node.has_method(&"apply_scale_constraint"):
					var constrained_scale_delta: Vector3 = selected_node.apply_scale_constraint(scale_delta)
					scale_basis = Basis.from_scale(constrained_scale_delta)
				else:
					scale_basis = Basis.from_scale(scale_delta)
				selected_node.global_transform.basis = original_global_transform.basis * scale_basis
		else:
			# Calculate the basis and scale by it.
			var new_scale = _apply_global_scale(scale_delta, original_global_transform.basis)
			if selected_node is SpaceObject:
				selected_node.set_model_scale(new_scale)
			else:
				if selected_node.has_method(&"apply_scale_constraint"):
					new_scale = selected_node.apply_scale_constraint(new_scale)
				selected_node.global_transform.basis = selected_node.global_transform.basis.orthonormalized() * Basis.from_scale(new_scale)
			var original_pos: Vector3 = original_global_transform.origin
			var sel_help_pos: Vector3 = _selection_helper_starting_transform.origin
			var offset: Vector3 = original_pos - sel_help_pos
			selected_node.global_transform.origin = sel_help_pos + offset * scale_delta
	if is_relative:
		var original_scale = _selection_helper_starting_transform.basis.get_scale()
		global_transform.basis = global_transform.basis.orthonormalized() * Basis.from_scale(original_scale).scaled(scale_delta)
	else:
		global_transform.basis = Basis.from_scale(scale_delta) * _selection_helper_starting_transform.basis


func start_grabbing(grabbed_object: Node3D) -> void:
	Cursors.set_cursor(Cursors.GRAB)
	_grabbed_object = grabbed_object
	_grab_offset_from_bottom = -TMNodeUtil.get_local_bottom_point(grabbed_object)
	for node in _selected_nodes:
		if node is Node3D:
			_node_original_transform[node.get_instance_id()] = node.global_transform
			if node is SpaceObject:
				node.freeze_override = true
				node.grab()
			if node is ModelPrimitive:
				node.grab()


func process_grabbing(local_player) -> void:
	var raycast_dict: Dictionary = local_player.camera_get_raycast_dict(_selected_nodes)
	if not raycast_dict.has("position"):
		return
	if _grabbed_object == raycast_dict["collider"]:
		return
	var grabbed_object_new_position : Vector3 = raycast_dict["position"]
	if not is_instance_valid(_grabbed_object):
		return
	var grabbed_original_transform: Transform3D = _node_original_transform[_grabbed_object.get_instance_id()]
	var new_origin: Vector3 = grabbed_object_new_position + grabbed_original_transform.basis * _grab_offset_from_bottom
	if _grabbed_object is TMSpaceObjectBase:
		var gt = _grabbed_object.global_transform
		gt.origin = new_origin
		_grabbed_object.editmode_set_new_transform(gt)
	else:
		_grabbed_object.global_transform.origin = new_origin

	for node in _selected_nodes:
		if not is_instance_valid(node):
			continue
		var offset = new_origin - grabbed_original_transform.origin
		if node is TMSpaceObjectBase:
			var gt = node.global_transform
			gt.origin = _node_original_transform[node.get_instance_id()].origin + offset
			node.editmode_set_new_transform(gt)
		else:
			node.global_transform.origin = _node_original_transform[node.get_instance_id()].origin + offset


func finish_grabbing() -> void:
	Cursors.set_cursor()
	if not _grabbed_object:
		return
	record_property_changed(&"position")
	for node in _selected_nodes:
		if is_instance_valid(node) and node.has_method(&"release"):
			node.release()
			if node is SpaceObject:
				node.freeze_override = false
	queue_update_network_objects()
	_grabbed_object = null


func cancel_grabbing() -> void:
	if not _grabbed_object:
		return
	for node in _selected_nodes:
		if is_instance_valid(node):
			if node is Node3D:
				if node is TMSpaceObjectBase:
					var gt = node.global_transform
					gt.origin = _node_original_transform[node.get_instance_id()].origin
					node.editmode_set_new_transform(gt)
				else:
					node.global_transform.origin = _node_original_transform[node.get_instance_id()].origin
			if node.has_method(&"release"):
				node.release()
	_grabbed_object = null


func queue_update_network_objects() -> void:
	_selected_nodes.map(func (node):
		if node.has_method(&"queue_update_network_object"):
			node.queue_update_network_object()
	)


func record_property_changed(property_name: StringName, _old_value: Variant = null, _new_value: Variant = null) -> void:
	_record_properties_changed(property_name)


func _record_properties_changed(property_name: StringName):
	var action: UndoRedoAction = UndoRedoAction.new()
	for selected_node in _selected_nodes:
		if not _is_selected_node_being_transformed(selected_node):
			continue
		var node_original_local_transform: Transform3D = _node_original_transform[selected_node.get_instance_id()]
		var parent = selected_node.get_parent()
		if parent is Node3D:
			node_original_local_transform = parent.global_transform.affine_inverse() * node_original_local_transform
		match property_name:
			&"position":
				action.add_new_record(selected_node, property_name, node_original_local_transform.origin, selected_node.transform.origin)
			&"scale":
				if selected_node.has_method("get_model_scale"):
					action.add_new_record(selected_node, property_name, _node_original_scale[selected_node.get_instance_id()], selected_node.get_model_scale())
				elif selected_node.has_method("apply_scale"):
					var node_scale: Vector3 = selected_node.scale
					action.add_new_record(selected_node, property_name, node_scale.inverse(), node_scale)
				else:
					action.add_new_record(selected_node, property_name, _node_original_scale[selected_node.get_instance_id()], selected_node.scale)
				# A multi-node global scale will also change the positions of the nodes.
				if _selected_nodes.size() > 1 and not _gizmo.is_relative:
					action.add_new_record(selected_node, &"position", node_original_local_transform.origin, selected_node.transform.origin)
			&"transform":
				action.add_new_record(selected_node, property_name, node_original_local_transform, selected_node.transform)
	_undo_redo_system.record_property_change(action)


func _on_transformation_ended() -> void:
	Cursors.set_cursor()
	for duplicated_node_dict in _duplicated_nodes:
		duplicated_node_dict["model"].queue_free()
		duplicated_node_dict.erase("model")
		var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
		Zone.client_send_create_space_object(duplicated_node_dict, receipt)
	for selected_node in _selected_nodes:
		if not is_instance_valid(selected_node):
			continue
		if selected_node is SpaceObject:
			selected_node.freeze_override = false
		elif selected_node.has_method(&"apply_scale"):
			selected_node.apply_scale(selected_node.transform.basis.get_scale())
			selected_node.transform.basis = selected_node.transform.basis.orthonormalized()

	queue_update_network_objects()
	_node_original_transform.clear()
	_node_original_scale.clear()
	reset_scale_and_rotation()


func _get_space_object_properties(space_object: SpaceObject) -> Dictionary:
	return {
		"position": Serialization.vector3_to_array(space_object.position),
		"rotation": Serialization.vector3_to_array(space_object.rotation),
		"scale": Serialization.vector3_to_array(space_object.get_model_scale()),
		"name": space_object.get_space_object_name(),
		"locked": space_object.locked,
		"collisionEnabled": space_object.collision_enabled,
		"shapeType": space_object.physics_shape_type,
		"bodyType": space_object.physics_body_type,
		"massKg": space_object.mass,
		"gravityScale": space_object.gravity_scale,
		"offset": Serialization.vector3_to_array(space_object.get_model_offset()),
		"extraNodes": space_object.serialize_extra_nodes(),
		"objectTexture": space_object.object_texture_id,
		"surfaceMaterialId": Serialization.serialize_dictionary_to_json(space_object.surface_material_id),
		"scriptEvents": space_object.serialize_script_instances(),
		"castShadows": space_object.cast_shadows,
		"visibleFrom": space_object.visible_from,
		"visibleTo": space_object.visible_to,
		"visibleFromMargin": space_object.visible_from_margin,
		"visibleToMargin": space_object.visible_to_margin,
	}


func reset_scale_and_rotation() -> void:
	if _selected_nodes.size() > 1:
		global_transform.basis = Basis()


func is_selection_empty() -> bool:
	return _selected_nodes.is_empty()


func is_object_selected(instance_id) -> bool:
	return _selected_nodes.any(func (element): return is_instance_valid(element) and element.get_instance_id() == instance_id)


func is_any_object_not_allowed_to_edit() -> bool:
	return _selected_nodes.any(func (element):
		return is_instance_valid(element) and not Util.can_edit_object_in_space(element)
	)


func is_space_object_asset_type(object_asset_type) -> bool:
	return _selected_nodes.any(func (element): return is_instance_valid(element) and element is SpaceObject and element.asset_type == object_asset_type)


func _apply_global_scale(new_global_scale: Vector3, rotation_basis: Basis) -> Vector3:
	return (Basis.from_scale(new_global_scale) * rotation_basis).get_scale().abs()
