class_name CameraManager
extends Node


var is_selected_asset_placeable: bool = false
var placement_offset := Vector3.ZERO
var _placement_preview_asset_id: String = ""

var _current_camera_holder: CameraHolder

@onready var _main_viewport: Viewport = get_viewport()
@onready var _viewport_container: SubViewportContainer = get_node(^"SubViewportContainer")
@onready var _viewport: SubViewport = _viewport_container.get_node(^"SubViewport")
@onready var _player_head_camera_holder: CameraHolder = _viewport.get_node(^"PlayerHeadCamera")
@onready var _free_camera_holder: CameraHolder = _viewport.get_node(^"FreeCamera")
@onready var _placement_preview: Node3D = _viewport.get_node(^"PlacementPreview")
@onready var jolt_debugger: JoltDebugGeometry3D = _viewport.get_node(^"JoltDebugGeometry3D")


func _ready():
	set_jolt_debugger_enabled(false)


func _process(delta: float) -> void:
	_current_camera_holder.update(delta)
	var size := Vector2i(_viewport_container.size)
	if _viewport.size != size:
		_viewport.size = size
	var cam_attr = _main_viewport.world_3d.camera_attributes
	if cam_attr is CameraAttributesPractical:
		cam_attr.dof_blur_amount = size.y * _viewport.scaling_3d_scale * 0.00001


func enable_for_player(player: TMCharacter3D):
	var gizmo: Gizmo = GameUI.instance.get_node(^"CreatorUI/ObjectSelection/Gizmo")
	_player_head_camera_holder.setup(player, self, gizmo)
	_free_camera_holder.setup(player, self, gizmo)
	_placement_preview.setup(self)
	_current_camera_holder = _player_head_camera_holder
	_set_active_camera_holder(_player_head_camera_holder)
	PlayerData.game_mode.game_mode_changed.connect(self._on_game_mode_changed)
	Zone.mode_changed.connect(_on_zone_mode_changed)
	var window: Window = get_tree().get_root()
	window.size_changed.connect(_on_window_size_changed)
	GameplaySettings.render_quality_changed.connect(self._on_render_quality_changed)
	GameplaySettings.render_profile.update_viewport(_viewport)


func _on_render_quality_changed(_render_quality: int):
	GameplaySettings.render_profile.update_viewport(_viewport)


func get_camera_viewport() -> SubViewport:
	return _viewport


func _on_window_size_changed() -> void:
	var window: Window = get_tree().get_root()
	_viewport.size = window.size


func get_placement_preview_asset_id() -> String:
	return _placement_preview_asset_id


func set_placement_preview_asset_id(asset_id: String) -> void:
	_placement_preview_asset_id = asset_id
	_placement_preview.set_placement_preview_asset_id(asset_id)


func change_focus_point(in_focus_point: Vector3) -> void:
	_free_camera_holder.change_focus_point(in_focus_point)


func change_focus_point_zoom(new_zoom: float) -> void:
	_free_camera_holder.change_focus_point_zoom(new_zoom)


func clear_focus_point() -> void:
	_free_camera_holder.clear_focus_point()


func reset_camera_transforms(new_transform := Transform3D.IDENTITY) -> void:
	_player_head_camera_holder.transform = new_transform


func unproject_position_to_screen(position: Vector3) -> Vector2:
	return _current_camera_holder.get_camera().unproject_position(position)


func is_position_behind_camera(position: Vector3) -> bool:
	return _current_camera_holder.get_camera().is_position_behind(position)


func set_collide_with_object(collision_object: CollisionObject3D, is_enabled: bool) -> void:
	_player_head_camera_holder.set_collide_with_object(collision_object, is_enabled)


func get_head_global_transform() -> Transform3D:
	return _player_head_camera_holder.get_global_transform()


func get_camera_raycast_dict(ignored_bodies=[]) -> Dictionary:
	return _current_camera_holder.get_camera_raycast_dict(ignored_bodies)


func get_camera_rotation() -> Vector3:
	if is_instance_valid(_player_head_camera_holder):
		return _player_head_camera_holder.global_transform.basis.get_euler()
	return Vector3.ZERO


func camera_get_look_target() -> Vector3:
	var head = get_head_global_transform()
	return head.origin + head.basis.z * 10000


func get_camera_placement_transform(): # -> Transform3D?
	if is_instance_valid(_current_camera_holder):
		return _current_camera_holder.get_camera_placement_transform()
	return Transform3D.IDENTITY


func get_active_player_head_camera() -> Camera3D:
	return _player_head_camera_holder.get_camera()


func set_camera_rotation_y(rot: float) -> void:
	_player_head_camera_holder.rotation.y = rot


func set_camera_zoom_scale(camera_zoom_scale: float) -> void:
	_player_head_camera_holder.set_camera_zoom_scale(camera_zoom_scale)


func set_camera_3d_scale(new_3d_scale: float) -> void:
	assert(new_3d_scale >= 0.249 and new_3d_scale <= 1.001, "3D resolution scale is out of asssumed range,
			if we need we can change it (for example to support oversampling)")
	_viewport.scaling_3d_scale = new_3d_scale


func add_camera_punch(camera_punch: float) -> void:
	_player_head_camera_holder.add_camera_punch(camera_punch)


func get_view_model() -> EquipableViewModel:
	return _player_head_camera_holder.equipable_view_model


func _unhandled_input(input_event: InputEvent) -> void:
	_current_camera_holder.handle_asset_placement_input(input_event)
	if input_event.is_action_released(&"secondary_action") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		var dict = get_camera_raycast_dict()
		if not dict.has("collider") or not dict.has("position"):
			return
		GameUI.instance.creator_ui.open_context_menu(dict.collider, dict.position)
	if GameUI.instance.is_mouse_needed_for_ui():
		if input_event.is_action_pressed("primary_action"):
			# Works to release focus from all SpinBox and text boxes
			_main_viewport.gui_release_focus()
		return

	_main_viewport.gui_release_focus()
	_current_camera_holder.handle_input(input_event)


func _on_zone_mode_changed(_new_zone_mode) -> void:
	_set_active_camera_holder(_player_head_camera_holder)


func _on_game_mode_changed(new_mode: GameMode.Mode, previous_mode: GameMode.Mode) -> void:
	if new_mode == GameMode.Mode.BUILD:
		_set_active_camera_holder(_free_camera_holder)
	elif previous_mode == GameMode.Mode.BUILD:
		_set_active_camera_holder(_player_head_camera_holder)


func _set_active_camera_holder(in_camera_holder: CameraHolder) -> void:
	assert(Zone.is_client())
	_current_camera_holder.exit()
	var target_transform: Transform3D = _current_camera_holder.get_next_camera_target_transform()
	_current_camera_holder = in_camera_holder
	_current_camera_holder.enter(target_transform)


func set_jolt_debugger_enabled(e: bool):
	jolt_debugger.draw_bodies = e
	jolt_debugger.draw_shapes = e
	jolt_debugger.draw_constraints = e
	await get_tree().create_timer(0.5).timeout
	jolt_debugger.set_process_internal(e)
