extends Control


@export var selection_rectangle_color: Color = Color(0.5, 0.5, 0.5)
@export var max_results: int = 1000
@export var min_threshold: float = 10.0
@export_flags_3d_physics var selection_collision_mask = (
	1 << (Constants.PHYSICS_LAYER_SPACE_OBJECT - 1) |
	1 << (Constants.PHYSICS_LAYER_STATIC_SPACE_OBJECT - 1)
)

var scene_hierarchy: SceneHierarchy

var _dragging = false
var _drag_start = Vector2.ZERO
var _accumulated_drag: Vector2 = Vector2.ZERO
var _previous_position: Vector2 = Vector2.ZERO
var _drag_enabled: bool = true


# This method is part of the Control API and is called by Godot.
func _draw():
	if _dragging:
		var rect := Rect2(_drag_start, get_global_mouse_position() - _drag_start)
		draw_rect(rect.abs(), selection_rectangle_color, false, 3.0)


# This method is part of the Control API and is called by Godot.
func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data.has("asset_id")


# This method is part of the Control API and is called by Godot.
func _drop_data(_position, data) -> void:
	if data["asset_type"] != "IMAGE" and data["asset_type"] != "MATERIAL":
		return
	var player = PlayerData.get_local_player()
	var raycast_dict = player.camera_get_raycast_dict() if player else {}
	if not raycast_dict.has("collider"):
		return
	var space_object = Util.get_space_object(raycast_dict.collider)
	if space_object:
		if data["asset_type"] == "IMAGE":
			space_object.object_texture_id = data["asset_id"]
		elif data["asset_type"] == "MATERIAL":
			space_object.material_id = data["asset_id"]
	Analytics.track_event_client(AnalyticsEvent.TYPE.OBJECT_PLACED)


func _gui_input(input_event: InputEvent) -> void:
	if input_event.is_action(&"primary_action"):
		if input_event.pressed:
			if Input.is_action_pressed(&"secondary_action"):
				return
			_start_dragging(input_event)
		elif _dragging:
			_end_dragging(input_event)
	elif input_event is InputEventMouseMotion and _dragging:
		if not _drag_enabled:
			_dragging = false
			_reset_drag_count()
			queue_redraw()
			return
		_accumulated_drag += (input_event.position - _previous_position).abs()
		_previous_position = input_event.position
		if _accumulated_drag.length() < min_threshold:
			return
		queue_redraw()


func edit_mode_changed(mode: Enums.EDIT_MODE) -> void:
	_drag_enabled = mode == Enums.EDIT_MODE.Asset or mode == Enums.EDIT_MODE.Map


func enable_drag() -> void:
	_drag_enabled = true


func disable_drag() -> void:
	_drag_enabled = false


func _reset_drag_count() -> void:
	_previous_position = Vector2.ZERO
	_accumulated_drag = Vector2.ZERO


func _start_dragging(input_event: InputEvent) -> void:
	if not _dragging:
		_dragging = true
		_drag_start = input_event.position
		_previous_position = _drag_start


## This code is based on `void Node3DEditorViewport::_select_region()`
## from Godot source code: `editor\plugins\node_3d_editor_plugin.cpp`
## This is using a RenderingServer not a JoltPhysics
func _end_dragging(input_event: InputEvent) -> void:
	_dragging = false
	queue_redraw()
	if _accumulated_drag.length() < min_threshold:
		_reset_drag_count()
		return
	_reset_drag_count()
	var local_player = PlayerData.get_local_player()
	var viewport = local_player.camera_get_viewport()
	var camera = viewport.get_camera_3d()
	var drag_end = input_event.position

	var z_offset = max(0.0, 5.0 - camera.near)
	var box: Array[Vector2] = [
		Vector2(
				min(_drag_start.x, drag_end.x),
				min(_drag_start.y, drag_end.y)),
		Vector2(
				max(_drag_start.x, drag_end.x),
				min(_drag_start.y, drag_end.y)),
		Vector2(
				max(_drag_start.x, drag_end.x),
				max(_drag_start.y, drag_end.y)),
		Vector2(
				min(_drag_start.x, drag_end.x),
				max(_drag_start.y, drag_end.y))
	]

	var frustum: Array[Plane]
	var cam_pos = camera.global_transform.origin
	for i in range(4):
		var a = camera.project_position(box[i], z_offset)
		var b = camera.project_position(box[(i + 1) % 4], z_offset)
		frustum.push_back(Plane(a, b, cam_pos))


	var camera_normal = -Vector3(camera.global_transform.basis.z)
	var near = Plane(-camera_normal, cam_pos)
	near.d -= camera.near
	frustum.push_back(near)

	var far: Plane = -near
	far.d += camera.far
	frustum.push_back(far)


	var instances = RenderingServer.instances_cull_convex(frustum, camera.get_tree().get_root().get_world_3d().get_scenario());
	var _selected_objects_instance_ids = []
	for x in instances:
		var object = instance_from_id(x)
		var space_object = Util.get_space_object(object)
		if space_object == null or space_object.locked or space_object.asset_type == Enums.ASSET_TYPE.MAP:
			continue
		var aabb: AABB = object.global_transform * object.get_aabb()
		var aabb_in_frustum = true
		# only select object in full AABB is selected
		for aabb_point_index in range(8):
			var point = aabb.get_endpoint(aabb_point_index)
			for plane in frustum:
				if plane.is_point_over(point):
					aabb_in_frustum = false
					break
		if not aabb_in_frustum:
			continue
		_selected_objects_instance_ids.append(space_object.get_instance_id())

	if not _selected_objects_instance_ids.is_empty():
		scene_hierarchy.select_nodes(_selected_objects_instance_ids)
