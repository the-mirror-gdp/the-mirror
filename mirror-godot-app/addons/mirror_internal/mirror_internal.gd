@tool
extends EditorPlugin


const _CONFIG_PATH = "res://addons/mirror_internal/env_configs/"
const _TOOLBAR_PANEL_PATH = "res://addons/mirror_internal/toolbar_panel/toolbar_panel.tscn"

var _env_dropdown: OptionButton


func _enter_tree() -> void:
	_set_up_clear_cache_button()
	_set_up_environment_configs()


func _exit_tree() -> void:
	if _env_dropdown:
		_env_dropdown.free()
		_env_dropdown = null


func _set_up_clear_cache_button() -> void:
	var toolbar_panel: Control = preload(_TOOLBAR_PANEL_PATH).instantiate()
	add_control_to_container(CONTAINER_TOOLBAR, toolbar_panel)


## Sets up the environment switch options button on the toolbar.
func _set_up_environment_configs() -> void:
	# Set up the dropdown node.
	_env_dropdown = OptionButton.new()
	_env_dropdown.custom_minimum_size = Vector2(64, 16)
	_env_dropdown.item_selected.connect(_env_selected)
	add_control_to_container(CONTAINER_TOOLBAR, _env_dropdown)
	# Check for and load environment configs.
	var current_env: String = _check_for_existing_environment_config()
	_load_environment_configs_from_folder(current_env)


## Check if we have an environment already. This is usually the case,
## except a clean repo will not have one. If missing, default to "dev".
func _check_for_existing_environment_config() -> String:
	if FileAccess.file_exists("res://override.cfg"):
		var override_config := ConfigFile.new()
		override_config.load("res://override.cfg")
		return override_config.get_value("mirror", "env_name")
	return "official"


## Load the available configs from the folder and check for our active one.
func _load_environment_configs_from_folder(current_env):
	var dir = DirAccess.open(_CONFIG_PATH)
	if dir == null:
		printerr("MI: CRITICAL: Unable to open environment config folder.")
		return
	dir.list_dir_begin()
	# The main logic is below.
	var file_name = dir.get_next()
	var index_id = 0
	while file_name != "":
		var env_name = file_name.get_basename()
		_env_dropdown.add_item(env_name, index_id)
		if env_name == current_env:
			_env_dropdown.select(index_id)
			_env_selected(index_id)
		index_id += 1
		file_name = dir.get_next()


## Called when switching environments to a new value.
func _env_selected(value: int) -> void:
	var dir = DirAccess.open("res://")
	if dir == null:
		printerr("MI: CRITICAL: Unable to open the res:// folder.")
		return
	# The main logic is below.
	if dir.file_exists("res://override.cfg"):
		dir.remove("res://override.cfg")
	var env_name = _env_dropdown.get_item_text(value)
	var env_file = "res://addons/mirror_internal/env_configs/" + env_name + ".cfg"
	var err = dir.copy(env_file, "res://override.cfg")
	if err != OK:
		printerr("MI: CRITICAL: Unable to copy environment config.")
