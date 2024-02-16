extends VBoxContainer


signal is_expanded_changed(new_is_expanded)
signal request_script_edit(script_instance: ScriptInstance)

var _follow_build_bar_height: bool = false
var _target_offset_right: float = 0.0
var _creator_ui: CreatorUI
var _browser_expanded_size: Vector2
var _copy_transform: Transform3D

@onready var _hierarchy: SceneHierarchy = $SceneHierarchy
@onready var _inspector = $Inspector
@onready var _selection_helper: SelectionHelper = $SelectionHelper
@onready var _gizmo: Gizmo = $Gizmo
@onready var _grabber = $Grabber
@onready var _selection_outlines = $SelectionOutlines
@onready var _prim_model_tool = $ModelTool
@onready var _audio_stream_player_select = $AudioStreamPlayerSelect


func setup(creator_ui: CreatorUI, drag_selector: Control, undo_redo: Node, tool_options: Node) -> void:
	_creator_ui = creator_ui
	drag_selector.scene_hierarchy = _hierarchy
	_gizmo.transformation_started.connect(drag_selector.disable_drag)
	_gizmo.transformation_ended.connect(drag_selector.enable_drag)
	_grabber.grabbing_started.connect(drag_selector.disable_drag)
	_grabber.grabbing_ended.connect(drag_selector.enable_drag)
	_hierarchy.selection_changed.connect(undo_redo._on_selection_changed)
	_inspector.inspected_object_name_updated.connect(_hierarchy.update_tree_item_name)
	Zone.instance_manager.space_object_updated.connect(_on_space_object_updated)
	Zone.instance_manager.space_object_removed.connect(_on_space_object_removed)
	Zone.mode_changed.connect(_on_zone_mode_changed)
	_selection_helper._undo_redo_system = undo_redo
	_target_offset_right = size.x
	_hierarchy.setup(_grabber, _selection_helper)
	_selection_outlines.setup(creator_ui, _hierarchy)
	_prim_model_tool.setup(self, _hierarchy)
	tool_options.setup_model_tool_options(_prim_model_tool)


func _process(delta: float) -> void:
	var lerp_factor = clamp(delta * 10.0, 0.0, 1.0)
	offset_right = lerpf(offset_right, _target_offset_right, lerp_factor)
	offset_left = 0.0
	if _follow_build_bar_height:
		offset_top = lerpf(offset_top, _browser_expanded_size.y, lerp_factor)


func delete_objects() -> void:
	if _selection_helper.is_any_object_not_allowed_to_edit():
		Notify.error("Space Object Delete Error", "One or more of selected objects cannot be deleted due to permissions issue")
		return
	var space_object_ids = _selection_helper.delete_selected_nodes()
	Zone.send_data_to_server([Packet.TYPE.DELETE_SPACE_OBJECTS, space_object_ids])


func search_node_tree(search_text: String) -> void:
	_hierarchy.search_node_tree(search_text)


func copy_selected_nodes() -> void:
	var copied_nodes = _selection_helper.copy_selected_nodes()
	_copy_transform = _calculate_copy_transform(copied_nodes)


func paste_copied_nodes() -> void:
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role < Enums.ROLE.CONTRIBUTOR:
		Notify.error("Duplicating Object Error", "You do not have permission to edit this space")
		return
	var placement: Transform3D = _calculate_placement_transform()
	var delta_transform: Transform3D = placement * _copy_transform.inverse()
	var node_instance_ids = _selection_helper.paste_copied_nodes(delta_transform)
	_hierarchy.clear_selected_nodes()
	_hierarchy.select_nodes(node_instance_ids)


func duplicate_selected_nodes() -> void:
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role < Enums.ROLE.CONTRIBUTOR:
		Notify.error("Duplicating Object Error", "You do not have permission to edit this space")
		return
	var node_instance_ids = _selection_helper.duplicate_selected_nodes()
	_hierarchy.clear_selected_nodes()
	_hierarchy.select_nodes(node_instance_ids)


func clear_selection() -> void:
	_hierarchy.clear_selected_nodes()


func is_selection_empty() -> bool:
	return _hierarchy.is_selection_empty()


func get_selection_helper() -> SelectionHelper:
	return _selection_helper


func select_object(object: Node3D) -> void:
	if PlayerData.game_mode.get_current_mode() == PlayerData.game_mode.Mode.BUILD:
		_audio_stream_player_select.play()
	_hierarchy.select_node(object.get_instance_id())


func raycast_hit_object(hit: Node3D) -> void:
	select_object(hit)
	_grabber.try_start_grabbing(hit) # Only succeeds if grabber is enabled.


func refresh_inspector(force_rebuild: bool = true) -> void:
	_inspector.refresh_inspected_nodes(force_rebuild)


func refresh_scripts() -> void:
	_hierarchy.refresh_global_scripts()
	_inspector.refresh_global_scripts()


func set_inspector_tab(tab_id: int = 0) -> void:
	_inspector.set_tab(tab_id)


func set_game_mode(new_game_mode):
	match new_game_mode:
		GameMode.Mode.NORMAL:
			# In normal mode, we do not show object details.
			# Users can either go to inspect mode or build mode for them.
			_target_offset_right = size.x
			# We clear selection, so that the selected objects are unfrozen
			clear_selection()
		GameMode.Mode.INSPECT:
			# In inspect mode, we move the object details to be "hovering"
			# instead of directly touching the right side of the screen.
			# However, we don't need the hierarchy in inspect mode.
			_hierarchy.visible = false
			_target_offset_right = -50.0
			_follow_build_bar_height = false
			offset_top = 100.0
			offset_bottom = -100.0
		GameMode.Mode.BUILD:
			# In build mode, we move the object details to be directly touching
			# the right side of the screen, using the full height under the bar.
			_hierarchy.visible = true
			_target_offset_right = 0.0
			_follow_build_bar_height = true
			offset_top = _browser_expanded_size.y
			offset_bottom = 0


func set_gizmo_type(new_type: int, snap_step: Variant = null) -> void:
	_gizmo.set_gizmo_type(new_type, snap_step)
	_grabber.is_enabled = new_type == Enums.GIZMO_TYPE.GRAB


func edit_mode_changed(new_edit_mode: int) -> void:
	_prim_model_tool.edit_mode_changed(new_edit_mode)
	_refresh_gizmos(new_edit_mode)


func zone_mode_changed(new_zone_mode: int) -> void:
	_prim_model_tool.zone_mode_changed(new_zone_mode)


func _calculate_copy_transform(copied_nodes: Array[Node]) -> Transform3D:
	var placement_transform: Transform3D = _calculate_placement_transform()
	# We use the placement transform to get the orientation, but we want
	# the copy position to be the relative-bottom-center of the nodes.
	# This means that on paste at mouse position we put the bottom-center
	# of the group of objects (instead of the mouse position at copy time).
	var copied_node_3ds = copied_nodes.filter(func(n): return n is Node3D)
	if copied_node_3ds.size() > 0:
		var relative_aabb := AABB()
		var relative_aabb_setup: bool = false
		for node in copied_node_3ds:
			var node_local_bottom: Vector3 = TMNodeUtil.get_local_bottom_point(node)
			var node_relative_bottom: Vector3 = (node.transform * node_local_bottom) * placement_transform
			if relative_aabb_setup:
				relative_aabb = relative_aabb.expand(node_relative_bottom)
			else:
				relative_aabb_setup = true
				relative_aabb.position = node_relative_bottom
		var relative_bottom: Vector3 = relative_aabb.get_center()
		relative_bottom.y -= relative_aabb.size.y * 0.5
		placement_transform.origin = placement_transform * relative_bottom
	return placement_transform


func _calculate_placement_transform() -> Transform3D:
	var local_player: Player = PlayerData.get_local_player()
	var placement_transform = local_player.camera_get_placement_transform_or_null()
	if placement_transform == null:
		return Transform3D.IDENTITY
	return placement_transform


func _refresh_gizmos(new_edit_mode: Enums.EDIT_MODE) -> void:
	if new_edit_mode != Enums.EDIT_MODE.Asset:
		_gizmo.hide()
		return
	_gizmo.set_gizmo_type(PlayerData.currently_selected_tool)


func _on_request_script_edit(script_instance: ScriptInstance) -> void:
	request_script_edit.emit(script_instance)


func _on_selection_changed(selected_nodes: Array[Node]) -> void:
	_grabber.cancel_grabbing()
	var game_mode = PlayerData.game_mode.get_current_mode()
	if selected_nodes.size() > 0 and game_mode == PlayerData.game_mode.Mode.BUILD:
		_audio_stream_player_select.play()
	_selection_helper.select_nodes(selected_nodes)
	_inspector.select_nodes(selected_nodes)


func _on_build_toolbar_is_expanded_changed(is_expanded, current_size):
	if is_expanded:
		_browser_expanded_size = current_size
		return
	_browser_expanded_size = Vector2.ZERO


func _on_space_object_updated(instance_id) -> void:
	var space_object = instance_from_id(instance_id)
	if not is_instance_valid(space_object):
		return
	if _selection_helper.is_object_selected(instance_id):
		refresh_inspector(false)


func _on_space_object_removed(instance_id) -> void:
	# Clear current object selection
	var space_object = instance_from_id(instance_id)
	if not is_instance_valid(space_object):
		return
	var nodes: Array = TMNodeUtil.get_all_descendants(space_object)
	nodes.append(space_object)
	for node in nodes:
		if _selection_helper.is_object_selected(node.get_instance_id()):
			_on_selection_changed([])
			return


func _on_zone_mode_changed(new_zone_mode: int) -> void:
	clear_selection()
