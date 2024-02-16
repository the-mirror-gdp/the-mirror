class_name TerrainProperties
extends RefCounted


var terrain_seed: int
var height_start: int
var height_range: int
var material_name: String
var generator_name: String
var noise_type: FastNoiseLite.NoiseType
var lower_y_limit: int


func _init(
	_terrain_seed,
	_height_start,
	_height_range,
	_material_name: String,
	_generator_name: String,
	_noise_type: FastNoiseLite.NoiseType,
	_lower_y_limit: int
):
	self.terrain_seed = _terrain_seed
	self.height_start = _height_start
	self.height_range = _height_range
	self.material_name = _material_name
	self.generator_name = _generator_name
	self.noise_type = _noise_type
	self.lower_y_limit = _lower_y_limit


func equals(right: TerrainProperties) -> bool:
	return (
		self.terrain_seed == right.terrain_seed and \
		self.height_start == right.height_start and \
		self.height_range == right.height_range and \
		self.material_name == right.material_name and \
		self.generator_name == right.generator_name and \
		self.noise_type == right.noise_type and \
		self.lower_y_limit == right.lower_y_limit
	)
