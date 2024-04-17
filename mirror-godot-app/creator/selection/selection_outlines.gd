extends Node


@export var selection_color := Color(0, 1, 0, 1)
@export var remote_selection_color := Color(0, 1, 0, 1)
@export var highlight_color := Color(1, 1, 1, 1)
@export var locked_color := Color(1, 0, 0, 1)


var _creator_ui: CreatorUI
var _scene_hierarchy: SceneHierarchy


func setup(creator_ui: CreatorUI, scene_hierarchy: SceneHierarchy) -> void:
	_creator_ui = creator_ui
	_scene_hierarchy = scene_hierarchy


func _can_draw_outlines() -> bool:
	return not (
		Zone.is_in_play_mode()
		or _creator_ui.is_edit_mode(Enums.EDIT_MODE.Terrain)
		or _creator_ui.is_edit_mode(Enums.EDIT_MODE.Model)
		or PlayerData.game_mode.get_current_mode() == GameMode.Mode.NORMAL and not _creator_ui.object_creation.is_browser_expanded
		or GameUI.instance.creator_ui.ui_request_captured
	)


func _process(_delta) -> void:
	if Zone.is_host():
		set_process(false)
		return
	_draw_remote_selection_outlines()
	if not _can_draw_outlines() or GameUI.instance.is_cinematic_mode_enabled():
		return
	_draw_highlight_outlines()
	_draw_selection_outlines()
	# TODO Make hightlight only be shown when we are hovering the world instead of UI:
#	if not GameUI.instance.is_mouse_hovering_ui():


func _draw_selection_outlines() -> void:
	if not _scene_hierarchy:
		return
	var selected_nodes: Array[Node] = _scene_hierarchy.get_selected_nodes()
	if selected_nodes.is_empty():
		return
	for selected_node in selected_nodes:
		var color: Color = selection_color
		if selected_node is SpaceObject and selected_node.locked:
			color = Color.ORANGE
		GameUI.instance.object_outlines.draw_wireframe_box_object(selected_node, color)


func _draw_remote_selection_outlines() -> void:
	if not _scene_hierarchy:
		return
	var selected_nodes: Array[Node] = _scene_hierarchy.get_selected_nodes()
	for remotely_selected_node in Zone.instance_manager.remotely_selected_nodes:
		if not is_instance_valid(remotely_selected_node) or selected_nodes.has(remotely_selected_node) or remotely_selected_node.selected_by_peers.has(get_tree().get_multiplayer().get_unique_id()):
			# This is a locally selected node as well; so nothing to do.
			continue
		GameUI.instance.object_outlines.draw_wireframe_box_object(remotely_selected_node, remote_selection_color)


func _draw_highlight_outlines() -> void:
	var player = PlayerData.get_local_player()
	var raycast_dict = player.camera_get_raycast_dict() if player else {}
	if not raycast_dict.has("collider"):
		return
	var object = raycast_dict.collider
	if not is_instance_valid(object):
		return
	var space_object = Util.get_space_object(object)
	if space_object:
		if space_object.asset_type == Enums.ASSET_TYPE.MAP:
			return
		object = space_object
	elif raycast_dict.has("shape"):
		object = object.get_child(raycast_dict.shape)
	if _creator_ui.selection_helper.is_object_selected(object.get_instance_id()):
		return
	if object is SpaceObject:
		var color: Color = highlight_color
		if object.locked:
			color = locked_color
		GameUI.instance.object_outlines.draw_wireframe_box_object(object, color)
	elif object is ModelPrimitive:
		GameUI.instance.object_outlines.draw_wireframe_box_object(object, highlight_color)
