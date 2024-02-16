## Global settings
## To add new setting create new public variable set default value and implement the setter.
## You also need to add the new mapping to the "_name_to_section_and_key_map" that will identify how
## this setting will be stored in a config file
extends Node

signal concurrent_downloads_changed(new_value: int)
signal render_quality_changed(new_value: int)
signal ui_scale_changed(new_value: float)
signal view_distance_changed(new_value: int)

## Emitted when settings load
signal settings_loaded()

enum RenderQuality {
	LOW, MEDIUM, HIGH
}


const _CONFIG_FILE_PATH = "user://player_settings.cfg"
const _CONFIG_OVERRIDE_FILE_PATH = "user://player_settings_override.cfg"
static var CAN_DETECT_AUDIO_FROM_MIC: bool = OS.get_name() == "Windows" and ProjectSettings.get_setting("feature_flags/detect_audio", false)

const MIN_UI_SCALE = 0.2
const MAX_UI_SCALE = 8.0

# The minimum is one because the VoxelTerrain starts from 1
# But below 17, the terrain is not always spawn under the avatar feet,
# so 17 it is for now (2022-12-14)
const MIN_VIEW_DISTANCE: int = 17
# That maximum comes from the VoxelTerrain maximum_view_distance
# ANd that can never be higher than 512 for now,
# as that 512 is hardcoded in the voxel terrain C++ module
# https://themirrormegaverse.slack.com/archives/C0301HB298F/p1669808124902219
# https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/#i_max_view_distance
const MAX_VIEW_DISTANCE: int = 512

const MIN_RESOLUTION_SCALE = 0.25
const MAX_RESOLUTION_SCALE = 1.0
const MIN_SOUND_VOLUME = -80.0
const MAX_SOUND_VOLUME = 24.0

const _SECTION_GRAPHICS = "graphics"
const _SECTION_INTERFACE = "interface"
const _SECTION_CONTROLS = "controls"
const _SECTION_AUDIO = "audio"
const _SECTION_SCRIPT = "script"
const _SECTION_ADVANCED = "advanced"
const _SECTION_LOGIN = "login"

const _IDX_SECTION = 0
const _IDX_PROPERTY_NAME = 1

const MAX_HTTP_REQUESTS : int = 40
const MIN_HTTP_REQUESTS : int = 1

const _name_to_section_and_key_map = {
	&"render_quality": [_SECTION_GRAPHICS, "render_quality"],
	&"auto_performance": [_SECTION_GRAPHICS, "auto_performance"],
	&"resolution_scale": [_SECTION_GRAPHICS, "render_resoultion_scale"],
	&"view_distance": [_SECTION_GRAPHICS, "view_distance"],
	&"volumetric_fog_enabled": [_SECTION_GRAPHICS, "volumetric_fog_enabled"],
	&"ui_scale": [_SECTION_INTERFACE, "ui_scale"],
	&"show_floating_control_hints": [_SECTION_INTERFACE, "show_floating_control_hints"],
	&"show_framerate_enabled": [_SECTION_INTERFACE, "show_framerate_enabled"],
	&"crosshair_color": [_SECTION_INTERFACE, "crosshair_color"],
	&"auto_close_script_editor": [_SECTION_INTERFACE, "auto_close_script_editor"],
	&"camera_mouse_sensitivity": [_SECTION_CONTROLS, "camera_mouse_sensitivity"],
	&"sound_volume_db": [_SECTION_AUDIO, "volume_db"],
	&"menu_ambience_volume_db": [_SECTION_AUDIO, "menu_ambience_volume_db"],
	&"is_microphone_enabled": [_SECTION_AUDIO, "is_microphone_enabled"],
	&"script_quick_attach_existing": [_SECTION_SCRIPT, "script_quick_attach_existing"],
	&"script_show_add_inspector_input": [_SECTION_SCRIPT, "script_show_add_inspector_input"],
	&"script_show_client_server_checkboxes": [_SECTION_SCRIPT, "script_show_client_server_checkboxes"],
	&"show_space_object_internal_nodes": [_SECTION_ADVANCED, "show_space_object_internal_nodes"],
	&"force_single_threaded_mode": [_SECTION_ADVANCED, "force_single_threaded_mode"],
	&"concurrent_http_requests": [_SECTION_ADVANCED, "concurrent_http_requests"],
	&"login_remember_me": [_SECTION_LOGIN, "login_remember_me"],
}

# Graphics
var render_quality: RenderQuality = RenderQuality.MEDIUM:
	set = _apply_render_quality

var auto_performance: bool = false:
	set = _apply_auto_performance

var resolution_scale: float = 1.0:
	set = _apply_resolution_scale

var view_distance: int = 128:
	set = _apply_view_distance

var volumetric_fog_enabled: bool = false:
	set = _apply_volumetric_fog_enabled

# Interface
var ui_scale: float = 1.0:
	set = _apply_ui_scale

var show_floating_control_hints: bool = true:
	set = _apply_show_floating_control_hints

var show_framerate_enabled: bool = false:
	set = _apply_show_framerate_enabled

var crosshair_color: Color = Color(0.145, 1, 1, 1):
	set = _apply_crosshair_color

# Controls
var camera_mouse_sensitivity: float = 0.005:
	set = _apply_camera_mouse_sensitivity

# Audio
var sound_volume_db: float = 0.0:
	set = _apply_sound_volume_db

var menu_ambience_volume_db: float = 0.0:
	set = _apply_menu_ambience_volume_db

var is_microphone_enabled: bool = CAN_DETECT_AUDIO_FROM_MIC:
	set = _apply_is_microphone_enabled

# Script
var script_quick_attach_existing: bool = false:
	set = _apply_script_quick_attach_existing

var script_show_add_inspector_input: bool = false:
	set = _apply_script_show_add_inspector_input

var script_show_client_server_checkboxes: bool = false:
	set = _apply_script_show_client_server_checkboxes

var auto_close_script_editor: bool = true:
	set = _apply_auto_close_script_editor

# Advanced
var show_space_object_internal_nodes: bool = false:
	set = _apply_show_space_object_internal_nodes

var concurrent_http_requests: int = 20:
	set = _apply_http_concurrent_requests

var force_single_threaded_mode: bool = false:
	set = _apply_force_single_threaded_mode

# Login
var login_remember_me: bool = true:
	set = _apply_login_remember_me

var _config_file: ConfigFile = ConfigFile.new()
var _is_loading: bool = true

var render_profile := RenderProfile.new()


func _ready() -> void:
	_load_config_file()
	get_viewport().size_changed.connect(_window_size_changed)
	render_profile.load_viewport_settings()


func _save_config_file():
	if _is_loading:
		return
	for property_name in _name_to_section_and_key_map:
		var category_info = _name_to_section_and_key_map[property_name]
		var setting_value = get(property_name)
		_config_file.set_value(category_info[_IDX_SECTION], category_info[_IDX_PROPERTY_NAME], setting_value)
	_config_file.save(_CONFIG_FILE_PATH)


func _load_config_file() -> void:
	_is_loading = true
	var err = _config_file.load(_CONFIG_FILE_PATH)
	if err != OK:
		print_verbose("GlobalSettings: Unable to load config file, creating a new one...")
		if Zone.is_host():
			# we might want to apply server preset here first
			pass
	err = _config_file.load(_CONFIG_OVERRIDE_FILE_PATH)
	for property_name in _name_to_section_and_key_map:
		var category_info = _name_to_section_and_key_map[property_name]
		var value_from_file = _config_file.get_value(category_info[_IDX_SECTION],
			category_info[_IDX_PROPERTY_NAME], get(property_name))
		set(property_name, value_from_file)
	_is_loading = false
	_save_config_file()
	settings_loaded.emit()


func reapply_all_settings():
	for property_name in _name_to_section_and_key_map:
		# `set` triggers the setter logic for a given property.
		set(property_name, get(property_name))


func _window_size_changed() -> void:
	_apply_ui_scale(ui_scale)


# Graphics
func _apply_render_quality(new_render_quality: int):
	if not new_render_quality in RenderQuality.values():
		new_render_quality = RenderQuality.MEDIUM
	if render_quality == new_render_quality:
		return
	render_quality = new_render_quality as RenderQuality
	_save_config_file()
	if Zone.is_host():
		# Server does not render anything.
		return
	match render_quality:
		RenderQuality.LOW:
			render_profile.set_low()
		RenderQuality.HIGH:
			render_profile.set_high()
		_, RenderQuality.MEDIUM:
			render_profile.set_medium()
	render_profile.set_profile()
	render_quality_changed.emit(render_quality)


func _apply_resolution_scale(new_resolution_scale: float):
	new_resolution_scale = clamp(new_resolution_scale, MIN_RESOLUTION_SCALE, MAX_RESOLUTION_SCALE)
	if resolution_scale != new_resolution_scale:
		resolution_scale = new_resolution_scale
		_save_config_file()
	if Zone.is_host():
		# Server does not render anything.
		return
	if not PlayerData.has_local_user_id():
		return
	var local_player: Player = PlayerData.get_local_player()
	if is_instance_valid(local_player):
		local_player.camera_set_3d_resolution_scale(resolution_scale)


func _apply_view_distance(new_view_distance: int):
	if view_distance != new_view_distance:
		view_distance = clamp(new_view_distance, MIN_VIEW_DISTANCE, MAX_VIEW_DISTANCE)
		_save_config_file()
	view_distance_changed.emit(view_distance)


func _apply_volumetric_fog_enabled(is_volumetric_fog_enabled: bool):
	if volumetric_fog_enabled != is_volumetric_fog_enabled:
		volumetric_fog_enabled = is_volumetric_fog_enabled
		_save_config_file()
	if Zone.is_host():
		# Server does not render anything.
		return


func _apply_auto_performance(in_auto_performance: bool):
	if auto_performance != in_auto_performance:
		auto_performance = in_auto_performance
		_save_config_file()
	var auto_performance_adjuster = get_tree().get_first_node_in_group("AutoPerformanceAdjuster")
	if is_instance_valid(auto_performance_adjuster):
		if auto_performance and not Zone.is_host():
			auto_performance_adjuster.enable()
		else:
			auto_performance_adjuster.disable()


# Interface
func _apply_ui_scale(new_ui_scale: float):
	if Zone.is_host():
		# Server does not have UI.
		return
	var base_res := Vector2(1920, 1080)
	var window_size: Vector2 = get_viewport().size
	var scale: float = min(window_size.x / base_res.x, window_size.y / base_res.y)
	# we don't really want to keep scale linear as it look bad
	# so for scales below < 1 we will scale UI a bit less
	if scale < 1.0:
		scale = minf(scale * 1.2, 1.0)
	elif scale > 1.0:
		scale = maxf(scale * 0.8, 1.0)

	if ui_scale != new_ui_scale:
		ui_scale = new_ui_scale
		ui_scale_changed.emit(ui_scale)
		_save_config_file()
	# keeping in mind that scale = 1 smallest font is around 11pt,
	# we don't want to go below 6pts so we stop scaling at ~0.6
	get_viewport().content_scale_factor = max(ui_scale * scale, 0.6)


func _apply_show_floating_control_hints(is_show_floating_control_hints: bool):
	if show_floating_control_hints != is_show_floating_control_hints:
		show_floating_control_hints = is_show_floating_control_hints
		_save_config_file()


func _apply_auto_close_script_editor(is_auto_close_script_editor: bool):
	if auto_close_script_editor != is_auto_close_script_editor:
		auto_close_script_editor = is_auto_close_script_editor
		_save_config_file()


func _apply_show_framerate_enabled(is_show_framerate_enabled: bool):
	if show_framerate_enabled != is_show_framerate_enabled:
		show_framerate_enabled = is_show_framerate_enabled
		_save_config_file()
	GameUI.fps_label.visible = show_framerate_enabled


func _apply_crosshair_color(new_crosshair_color: Color) -> void:
	if crosshair_color != new_crosshair_color:
		crosshair_color = new_crosshair_color
		_save_config_file()
	GameUI.crosshair.set_color(new_crosshair_color)


# Controls
func _apply_camera_mouse_sensitivity(new_camera_mouse_sensitivity: float):
	if camera_mouse_sensitivity != new_camera_mouse_sensitivity:
		camera_mouse_sensitivity = new_camera_mouse_sensitivity
		_save_config_file()


# Audio
func _apply_sound_volume_db(new_sound_volume: float):
	new_sound_volume = clamp(new_sound_volume, MIN_SOUND_VOLUME, MAX_SOUND_VOLUME)
	if sound_volume_db != new_sound_volume:
		sound_volume_db = new_sound_volume
		_save_config_file()
	if Zone.is_host():
		# Server does not play any audio.
		return
	AudioServer.set_bus_volume_db(0, sound_volume_db - 10.0)


func _apply_menu_ambience_volume_db(new_ambience_volume: float):
	new_ambience_volume = clamp(new_ambience_volume, MIN_SOUND_VOLUME, MAX_SOUND_VOLUME)
	if menu_ambience_volume_db != new_ambience_volume:
		menu_ambience_volume_db = new_ambience_volume
		_save_config_file()
	if Zone.is_host():
		# Server does not play any audio.
		return
	GameUI.menu_ambience.volume_db = menu_ambience_volume_db - 10.0
	GameUI.menu_ambience.check_update_stream()


func _apply_is_microphone_enabled(new_is_microphone_enabled: bool) -> void:
	new_is_microphone_enabled = new_is_microphone_enabled and CAN_DETECT_AUDIO_FROM_MIC
	if is_microphone_enabled != new_is_microphone_enabled:
		is_microphone_enabled = new_is_microphone_enabled
		_save_config_file()
	if Zone.is_host():
		# Server does not record any audio.
		return
	var record_bus_index: int = AudioServer.get_bus_index(&"Record")
	AudioServer.set_bus_mute(record_bus_index, true)


# Script
func _apply_script_quick_attach_existing(is_script_quick_attach_existing_enabled: bool):
	if script_quick_attach_existing != is_script_quick_attach_existing_enabled:
		script_quick_attach_existing = is_script_quick_attach_existing_enabled
		_save_config_file()


func _apply_script_show_add_inspector_input(is_script_show_add_inspector_input_enabled: bool):
	if script_show_add_inspector_input != is_script_show_add_inspector_input_enabled:
		script_show_add_inspector_input = is_script_show_add_inspector_input_enabled
		_save_config_file()


func _apply_script_show_client_server_checkboxes(is_script_show_client_server_checkboxes_enabled: bool):
	if script_show_client_server_checkboxes != is_script_show_client_server_checkboxes_enabled:
		script_show_client_server_checkboxes = is_script_show_client_server_checkboxes_enabled
		_save_config_file()


# Advanced
func _apply_show_space_object_internal_nodes(is_show_space_object_internal_nodes_enabled: bool):
	if show_space_object_internal_nodes != is_show_space_object_internal_nodes_enabled:
		show_space_object_internal_nodes = is_show_space_object_internal_nodes_enabled
		_save_config_file()


# Note this functionality applies to server and client.
func _apply_http_concurrent_requests(new_http_request_value: int):
	print("Trying to set concurrent http requests: ", new_http_request_value)
	if concurrent_http_requests != new_http_request_value:
		print("Set concurrent http requests: ", new_http_request_value)
		concurrent_http_requests = clamp(new_http_request_value, MIN_HTTP_REQUESTS, MAX_HTTP_REQUESTS)
		_save_config_file()
	concurrent_downloads_changed.emit(concurrent_http_requests)


# Note this functionality applies to server and client.
func _apply_force_single_threaded_mode(is_force_single_threaded_enabled: bool):
	if force_single_threaded_mode != is_force_single_threaded_enabled:
		force_single_threaded_mode = is_force_single_threaded_enabled
		_save_config_file()


# Login
func _apply_login_remember_me(is_login_remember_me_enabled: bool):
	if login_remember_me != is_login_remember_me_enabled:
		login_remember_me = is_login_remember_me_enabled
		_save_config_file()
