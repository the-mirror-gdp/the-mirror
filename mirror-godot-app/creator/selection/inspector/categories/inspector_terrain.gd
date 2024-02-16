extends InspectorCategoryBase


var target_node: SpaceTemplate
var _terrain_properties_cache: TerrainProperties

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _seed_property = _property_list.get_node(^"TerrainSeed")
@onready var _height_start_property = _property_list.get_node(^"TerrainHeightStart")
@onready var _height_range_property = _property_list.get_node(^"TerrainHeightRange")
@onready var _material_name_property = _property_list.get_node(^"TerrainMaterialName")
@onready var _generator_name_property = _property_list.get_node(^"TerrainGeneratorName")
@onready var _noise_type_property = _property_list.get_node(^"TerrainNoiseType")
@onready var _lower_y_limit_property = _property_list.get_node(^"LowerYLimit")


func _process(_delta):
	if not is_instance_valid(target_node):
		return
	var target_terrain_properties: TerrainProperties = target_node.get_terrain_properties()
	if not is_instance_valid(target_terrain_properties):
		return
	if (
		not is_instance_valid(_terrain_properties_cache)
		or not target_terrain_properties.equals(_terrain_properties_cache)
	):
		_terrain_properties_cache = target_terrain_properties
		refresh()


func refresh():
	_seed_property.current_value = _terrain_properties_cache.terrain_seed
	_seed_property.refresh()
	_height_start_property.current_value = _terrain_properties_cache.height_start
	_height_start_property.refresh()
	_height_range_property.current_value = _terrain_properties_cache.height_range
	_height_range_property.refresh()
	_material_name_property.current_value = _terrain_properties_cache.material_name
	_material_name_property.refresh()
	_generator_name_property.current_value = _terrain_properties_cache.generator_name
	_generator_name_property.refresh()
	_noise_type_property.current_value = _terrain_properties_cache.noise_type
	_noise_type_property.refresh()
	_lower_y_limit_property.current_value = _terrain_properties_cache.lower_y_limit
	_lower_y_limit_property.refresh()


func _on_reset_button_pressed() -> void:
	if not is_instance_valid(target_node):
		return
	target_node.request_clear_modified_voxels()


func _on_terrain_seed_value_changed(new_value) -> void:
	target_node.terrain_seed = new_value


func _on_terrain_height_start_value_changed(new_value) -> void:
	target_node.terrain_height_start = new_value


func _on_terrain_height_range_value_changed(new_value) -> void:
	target_node.terrain_height_range = new_value


func _on_regenerate_button_pressed():
	target_node.request_change_terrain()
