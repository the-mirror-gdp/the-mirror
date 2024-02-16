extends Control
class_name BuildToolbar


signal is_expanded_changed(is_expanded: bool, size: Vector2)
signal gizmo_button_pressed(gizmo_part: int)
signal snap_check_pressed(is_checked: bool)
signal relative_check_pressed(is_checked: bool)
signal snap_value_changed(amount: float)
signal terrain_button_pressed()
signal model_builder_button_pressed()
signal toggle_main_menu_pressed(show_space_settings: bool)
signal toggle_variable_editor_pressed()
signal toggle_teams_editor_pressed()
signal map_button_pressed()
signal publish_button_pressed()
signal restore_button_pressed()
signal save_version_button_pressed()

signal undo_button_toggled(button_pressed)
signal redo_button_toggled(button_pressed)

var _is_expanded: bool = false

@onready var _left_section: Control = $Left
@onready var _right_section: Control = $Right
@onready var _right_section_expanded_full_width: float = _right_section.size.x + 16.0

# Buttons
@onready var _play_button: Button = $Right/PlayButton # Fix this
@onready var _gizmo_options := $Left/BuildBarGizmoOptions
@onready var _terrain_button := $Left/Terrain
@onready var _model_builder_button := $Left/PrimitiveModelBuilder
@onready var _map_button = $Left/Map
@onready var _mirror_logo = $Left/MirrorLogo
@onready var _users = $Right/UsersPresent
@onready var _users_filter_menu = $Right/UsersPresent/FilterMenu
@onready var _save_space = %SaveSpace
@onready var _visible_collisions = %VisibleCollisions
@onready var _audio_stream_player_click = $AudioStreamPlayerClick
@onready var _version_menu = %VersionMenu
@onready var _version_button = %VersionButton
@onready var _version_popup = %VersionMenu/VersionPopup


func _ready() -> void:
	var is_undo_redo_debug_tool_enabled = ProjectSettings.get_setting("feature_flags/undo_redo_tools", false)
	if is_undo_redo_debug_tool_enabled:
		$"Left/Undo".show()
		$"Left/Redo".show()
	_play_button.disabled = not _preview_play_button_enabled()
	PlayerData.game_mode_changed.connect(_on_game_mode_changed)
	_map_button.visible = ProjectSettings.get_setting("feature_flags/map_builder", false)
	_save_space.visible = ProjectSettings.get_setting("feature_flags/export_spaces", false)
	_on_visible_collisions_toggled(false)


func _input(input_event: InputEvent) -> void:
	if _version_menu.is_visible_in_tree() and input_event is InputEventMouseButton and input_event.pressed:
		var local = _version_popup.make_input_local(input_event)
		if not Rect2(Vector2.ZERO, _version_popup.get_rect().size).has_point(local.position):
			_version_menu.hide()


func _process(delta: float) -> void:
	var lerp_factor = clamp(delta * 10.0, 0.0, 1.0)
	var target_position = -size.y if not _is_expanded else 0.0
	position.y = lerpf(position.y, target_position, lerp_factor)


func _on_server_joined():
	_users_filter_menu.delete_filter_menu_items()


func _on_user_present_filter_menu_item_selected(_title, metadata):
	if metadata is Player:
		GameUI.creator_ui.open_context_menu(metadata)


func _on_game_mode_changed(new_mode: GameMode.Mode, _previous_mode: GameMode.Mode) -> void:
	match new_mode:
		GameMode.Mode.BUILD:
			set_expanded(true)
		GameMode.Mode.NORMAL:
			_users_filter_menu.hide()
			_version_menu.hide()
			set_expanded(false)


func edit_mode_changed(new_mode: int) -> void:
	_gizmo_options.set_buttons_as_not_pressed()
	match new_mode:
		Enums.EDIT_MODE.Asset:
			_terrain_button.button_pressed = false
			_model_builder_button.button_pressed = false
			_map_button.button_pressed = false
			_gizmo_options.set_gizmo_type(PlayerData.currently_selected_tool)
		Enums.EDIT_MODE.Terrain:
			_terrain_button.button_pressed = true
		Enums.EDIT_MODE.Model:
			_model_builder_button.button_pressed = true
		Enums.EDIT_MODE.Map:
			_map_button.button_pressed = true


func _preview_play_button_enabled() -> bool:
	return ProjectSettings.get_setting("feature_flags/preview", false)


func set_expanded(value: bool) -> void:
	_is_expanded = value
	is_expanded_changed.emit(_is_expanded, size)


func set_gizmo_type(new_type: int, snap_step: float) -> void:
	_gizmo_options.set_gizmo_type(new_type, snap_step)


func set_gizmo_relative(new_relative: bool) -> void:
	_gizmo_options.set_gizmo_relative(new_relative)


func set_gizmo_snap_checked(new_checked: bool) -> void:
	_gizmo_options.set_gizmo_snap_checked(new_checked)


func _on_terrain_pressed() -> void:
	terrain_button_pressed.emit()


func _on_primitive_model_builder_pressed() -> void:
	model_builder_button_pressed.emit()


func _on_help_pressed() -> void:
	GameUI.user_tutorial.show_tutorial_type(UserTutorial.Tutorial_Type.SPACE)


func _on_teleport_pressed() -> void:
	# Ideally this is sent from here to CreatorUI and from CreatorUI, to the appropriate place.
	# The UI shouldn't be setting the camera, and changing the player's position.
	# It should only trigger the event.
	var viewport = PlayerData.get_local_player().camera_get_viewport()
	var camera: Camera3D = viewport.get_camera_3d()
	PlayerData.get_local_player().teleport.rpc(camera.global_position, camera.global_rotation)
	PlayerData.enter_normal_mode()


func _on_play_button_pressed() -> void:
	Zone.client_ready_check()
	Notify.success("Ready Check", "Preview Mode ready check started.")


func _on_build_bar_gizmo_options_gizmo_button_pressed(gizmo_part: int) -> void:
	gizmo_button_pressed.emit(gizmo_part)
	_audio_stream_player_click.play()


func _on_build_bar_gizmo_options_relative_check_pressed(is_checked: bool) -> void:
	relative_check_pressed.emit(is_checked)
	_audio_stream_player_click.play()


func _on_build_bar_gizmo_options_snap_check_pressed(is_checked: bool) -> void:
	snap_check_pressed.emit(is_checked)
	_audio_stream_player_click.play()


func _on_build_bar_gizmo_options_snap_value_changed(amount: float) -> void:
	snap_value_changed.emit(amount)


func _on_mirror_logo_pressed() -> void:
	toggle_main_menu_pressed.emit(false)
	_mirror_logo.release_focus()


func _on_open_space_settings_pressed() -> void:
	toggle_main_menu_pressed.emit(true)


func _on_variable_editor_pressed() -> void:
	toggle_variable_editor_pressed.emit()


func _on_teams_pressed() -> void:
	toggle_teams_editor_pressed.emit()


func _on_users_present_pressed() -> void:
	# Zone.social_manager.player_connected is not emitted with populated user
	# data, so we will just regenerate list here, instead of creating signal mess
	_users_filter_menu.delete_filter_menu_items()
	for player in Zone.social_manager.players.get_children():
		_users_filter_menu.add_filter_menu_item(player.get_player_name(), player)
	_users_filter_menu.show()


func _on_map_pressed() -> void:
	map_button_pressed.emit()


func _on_visible_collisions_toggled(button_pressed):
	if Zone.is_host() or not PlayerData.has_local_player():
		return
	PlayerData.get_local_player()._camera_manager.set_jolt_debugger_enabled(button_pressed)


func _on_save_space_pressed():
	var allow_exports = ProjectSettings.get_setting("feature_flags/export_spaces", false)
	if not allow_exports:
		Notify.error("Feature Error", "Export feature was not enabled")
		return
	# Export the scene
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var objects = Zone.instance_manager.get_all_instances()
	var object_filtered := objects.filter(func(object):
		return object is SpaceObject and object.asset_type == Enums.ASSET_TYPE.MESH
	)
	var err = OK
	print("Exporting space_objects to GLB: ", object_filtered.size())
	for obj in object_filtered:
		err = gltf_doc.append_from_scene(obj, gltf_state)
		if err != OK:
			Notify.error("Export error", "Error appending from scene")
			printerr("Error appending from scene...")
	# Save the GLTFState data to a file.
	var file_name = "space_snapshot"
	var file_path_base: String = Util.get_files_directory_path() + file_name
	var file_path_glb: String = file_path_base + ".glb"
	err = gltf_doc.write_to_filesystem(gltf_state, file_path_glb)
	if err != OK:
		Notify.error("Export error", "Error exporting glb")
		printerr("Save error:", err, " file path: ", file_path_glb)
		return
	print("Save done, file path: ", file_path_glb)
	Notify.success("Export Success", "Space, without the terrain map, was saved to a file: %s" % file_path_glb)


func _on_publish_button_pressed() -> void:
	publish_button_pressed.emit()


func _on_resized() -> void:
	offset_left = 0.0
	offset_right = 0.0
	if _right_section:
		_right_section.set_expanded(size.x > _left_section.size.x + _right_section_expanded_full_width)


func _on_undo_toggled(button_pressed):
	undo_button_toggled.emit(button_pressed)


func _on_redo_toggled(button_pressed):
	redo_button_toggled.emit(button_pressed)


func _on_button_pressed():
	_audio_stream_player_click.play()


func _can_save_restore_space() -> bool:
	var role =Util.get_role_for_user(Zone.space, Net.user_id)
	return role >= Enums.ROLE.MANAGER


func _on_restore_space_pressed():
	if not _can_save_restore_space():
		Notify.warning("Space Version Restore", "Permissions denided!")
		return
	restore_button_pressed.emit()
	_version_menu.hide()


func _on_save_version_button_pressed():
	if not _can_save_restore_space():
		Notify.warning("Space Version Save", "Permissions denided!")
		return
	save_version_button_pressed.emit()
	_version_menu.hide()


func _on_version_button_pressed():
	_version_menu.global_position.x = _version_button.global_position.x
	_version_menu.show()
