class_name SpaceTemplate
extends Node3D


const MATERIAL_PATH_FORMAT = "res://prefabs/space/templates/%s.mat.tres"

signal template_ready

@export var lower_y_limit: int = -200

var _space_data: Dictionary = {}

var _terrain_data: Dictionary = {}
var _is_host: bool = false

# Note: These node names will show up in the inspector UI, so make them look fancy.
@onready var space_environment: SpaceEnvironment = $"Space Environment" as SpaceEnvironment
@onready var space_global_scripts: SpaceGlobalScripts = $"Space Global Scripts" as SpaceGlobalScripts


func populate_space_template(is_host: bool, space: Dictionary) -> void:
	_is_host = is_host
	_space_data = space
	lower_y_limit = _space_data.get("lowerLimitY", lower_y_limit)


func _ready() -> void:
	if _space_data.has("environment"):
		space_environment.apply_from_dictionary(_space_data["environment"])
	if _space_data.has("scriptInstances"):
		space_global_scripts.load_global_script_instances(_space_data["scriptInstances"])
	template_ready.emit()
	GameplaySettings.reapply_all_settings()
