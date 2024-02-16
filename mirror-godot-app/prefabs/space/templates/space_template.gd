class_name SpaceTemplate
extends Node3D


const MATERIAL_PATH_FORMAT = "res://prefabs/space/templates/%s.mat.tres"

signal template_ready

@export var terrain_seed = 0
@export var terrain_height_start = -20
@export var terrain_height_range = 30
@export var terrain_material_name: String = "mars"
@export var terrain_generator_name: String = "fnl_generator01"
@export var terrain_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.NoiseType.TYPE_SIMPLEX

@export var lower_y_limit: int = -200

var _space_data: Dictionary = {}

var _terrain_data: Dictionary = {}
var _is_host: bool = false

@onready var voxel_terrain: VoxelEditor = get_node_or_null(^"VoxelEditor")
# Note: These node names will show up in the inspector UI, so make them look fancy.
@onready var space_environment: SpaceEnvironment = $"Space Environment" as SpaceEnvironment
@onready var space_global_scripts: SpaceGlobalScripts = $"Space Global Scripts" as SpaceGlobalScripts


func populate_space_template(is_host: bool, space: Dictionary) -> void:
	_is_host = is_host
	_space_data = space
	lower_y_limit = _space_data.get("lowerLimitY", lower_y_limit)


func _populate_terrain(terrain: Dictionary) -> void:
	_terrain_data = terrain
	terrain_seed = _terrain_data.get("seed", terrain_seed)
	terrain_noise_type = _terrain_data.get("noiseType", terrain_noise_type)
	terrain_material_name = _terrain_data.get("material", terrain_material_name)
	terrain_height_start = _terrain_data.get("heightStart", terrain_height_start)
	terrain_height_range = _terrain_data.get("heightRange", terrain_height_range)
	terrain_generator_name = _terrain_data.get("generator", terrain_generator_name)


func _ready() -> void:
	_setup_terrain()
	if _space_data.has("environment"):
		space_environment.apply_from_dictionary(_space_data["environment"])
	if _space_data.has("scriptInstances"):
		space_global_scripts.load_global_script_instances(_space_data["scriptInstances"])
	template_ready.emit()
	GameplaySettings.reapply_all_settings()


## client pressed clear modified voxels. Ask the server to do it.
func request_clear_modified_voxels() -> void:
	if not voxel_terrain:
		return
	assert(Zone.is_client())
	voxel_terrain.server_clear_voxel_modifications.rpc_id(Zone.SERVER_PEER_ID)


## client changed terrain.
func request_change_terrain() -> void:
	assert(not Zone.is_host())
	Zone.send_data_to_server([Packet.TYPE.TERRAIN_CHANGE, _serialize_terrain_generator()])


func receive_terrain_change(terrain: Dictionary) -> void:
	_populate_terrain(terrain)
	_setup_terrain()


func _serialize_terrain_generator() -> Dictionary:
	var terrain = {
		"seed": terrain_seed,
		"noiseType": terrain_noise_type,
		"material": terrain_material_name,
		"heightStart": terrain_height_start,
		"heightRange": terrain_height_range,
		"generator": terrain_generator_name,
	}
	return terrain


func _setup_terrain() -> void:
	if not voxel_terrain:
		return
	_setup_terrain_host_settings()
	_setup_terrain_material()
	if _is_host:
		_setup_terrain_generator()
		voxel_terrain.setup_stream()


func _setup_terrain_material() -> void:
	var material_location = MATERIAL_PATH_FORMAT % terrain_material_name
	var material_resource = load(material_location)
	if not material_resource is Material:
		return
	voxel_terrain.material_override = material_resource


func _setup_terrain_host_settings() -> void:
	voxel_terrain.block_enter_notification_enabled = _is_host
	voxel_terrain.area_edit_notification_enabled = _is_host
	voxel_terrain.automatic_loading_enabled = _is_host


func _setup_terrain_generator() -> void:
	if terrain_generator_name.is_empty():
		voxel_terrain.set_generator(null)
		print("Set terrain generator: empty")
		return
	var generator_location: String = "res://prefabs/space/templates/%s.tres" % terrain_generator_name
	var loaded_generator = load(generator_location)
	if loaded_generator and loaded_generator is VoxelGenerator:
		print("set generator: %s" % terrain_generator_name)
		voxel_terrain.set_generator(loaded_generator)
	else:
		print("Unable to load generator: %s" % terrain_generator_name)
		return

	if voxel_terrain.generator is VoxelGeneratorNoise2D:
		var noise2dgen: VoxelGeneratorNoise2D = voxel_terrain.generator as VoxelGeneratorNoise2D
		noise2dgen.set_height_start(terrain_height_start)
		print("set terrain generator height_start: %s" % str(terrain_height_start))
		noise2dgen.set_height_range(terrain_height_range)
		print("set terrain generator height_range: %s" % str(terrain_height_range))
		if noise2dgen.noise is FastNoiseLite:
			var n = noise2dgen.noise as FastNoiseLite
			n.set_seed(terrain_seed)
			print("set terrain generator seed: %s" % str(terrain_seed))
			n.set_noise_type(terrain_noise_type)
			print("set terrain generator noise type: %s" % str(terrain_noise_type))

	elif voxel_terrain.generator is VoxelGeneratorFlat:
		var flatgen: VoxelGeneratorFlat = voxel_terrain.generator as VoxelGeneratorFlat
		flatgen.set_height(terrain_height_start)
		print("set terrain generator height (height_start): %s" % str(terrain_height_start))


func get_terrain_properties() -> TerrainProperties:
	return TerrainProperties.new(
			terrain_seed,
			terrain_height_start,
			terrain_height_range,
			terrain_material_name,
			terrain_generator_name,
			terrain_noise_type,
			lower_y_limit
	)
