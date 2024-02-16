extends AssetData
class_name AssetDataMap

signal preview_textures_loaded()
signal textures_loaded()

const _MATERIAL = preload("res://gameplay/space_object/heightmap/heightmap_material.tres")

var heightmap_asset_id = ''
var flat_material_asset_id = ''
var cliff_material_asset_id = ''
var map_size = 512
var map_precision = 1.0
var height_scale = 32.0
var layer_offset = 0.0
var flat_uv_scale = 1.0
var cliff_uv_scale = 1.0
var flat_cliff_ratio = -0.6
var flat_color: Color = Color.WHITE
var cliff_color: Color = Color.WHITE
var colormap_assset_id = ''
var colormap_strength = 0.5

var map: Heightmap = null


func _generate_preview_texture(force: bool = false) -> void:
	if not is_instance_valid(map):
		return
	# wait on main map to be loaded so we don't re-request assets
	if not map.is_loaded():
		print("map was not loaded")
		await map.map_loaded
	_preview_node = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.subdivide_depth = 100
	plane.subdivide_width = 100
	plane.size = Vector2(map.map_size, map.map_size)
	_preview_node.mesh = plane
	_preview_node.material_override = map.material
	_loaded_file_promise.set_result(_preview_node)
	super._generate_preview_texture(true)


func _generate_mesh_preview(node: Node, path: String) -> void:
	# duplicate node so it is not freed from memory after preview is generated.
	_preview_node = node
	_asset_preview = _ASSET_PREVIEW_TSCN.instantiate()
	GameUI.add_child(_asset_preview)


	# set an offset so it is not on screen.
	_asset_preview.position.x = -1000
	_asset_preview.position.y = -1000
	_asset_preview.preview_generated.connect(_handle_preview_generated, CONNECT_ONE_SHOT)
	_asset_preview.size = Vector2(300, 300)
	_asset_preview.add_asset(_preview_node)
	if is_instance_valid(map):
		_preview_node.position.y = - map.get_height(Vector2(0,0))
	# use the deferred save image method to allow the render to complete
	_asset_preview.deferred_save_image(path)


func populate(dict: Dictionary) -> void:
	if dict == null:
		return
	assert(dict.get("__t", "") == "MapAsset")
	if dict.has("heightmapAssetId"):
		heightmap_asset_id = dict.get("heightmapAssetId", "")
	if dict.has("flatMaterialAssetId"):
		flat_material_asset_id = dict.get("flatMaterialAssetId", "")
	if dict.has("cliffMaterialAssetId"):
		cliff_material_asset_id = dict.get("cliffMaterialAssetId", "")
	if dict.has("mapSize"):
		map_size = dict.get("mapSize", "")
	if dict.has("mapPrecision"):
		map_precision = dict.get("mapPrecision", "")
	if dict.has("heightScale"):
		height_scale = dict.get("heightScale", "")
	if dict.has("layerOffset"):
		layer_offset = dict.get("layerOffset", "")
	if dict.has("flatUVScale"):
		flat_uv_scale = dict.get("flatUVScale", "")
	if dict.has("cliffUVScale"):
		cliff_uv_scale = dict.get("cliffUVScale", "")
	if dict.has("flatCliffRatio"):
		flat_cliff_ratio = dict.get("flatCliffRatio", "")
	if dict.has("flatColor"):
		var color = dict.get("flatColor", "")
		if not color is Array or not color.size() > 2:
			print("Flat Color has incorrect value!")
			return
		flat_color = Serialization.array_to_color(color)
	if dict.has("cliffColor"):
		var color = dict.get("cliffColor", "")
		if not color is Array or not color.size() > 2:
			print("Flat Color has incorrect value!")
			return
		cliff_color = Serialization.array_to_color(color)
	if dict.has("colormapAssetId"):
		colormap_assset_id = dict.get("colormapAssetId", "")
	if dict.has("colormapStrength"):
		colormap_strength = dict.get("colormapStrength", "")
	super.populate(dict)


func try_creating_map(old_map: Heightmap):
	if is_instance_valid(old_map):
		map = old_map
	else:
		map = Heightmap.new()
		map.setup()
	# Disable collisions and normalmaps so changing data will not trigger regeneration
	map.use_collisions = false
	map.generate_normalmap = false
	map.asset_data = self
	if map.map_size != map_size:
		map.map_size = map_size
	#if not is_equal_approx(map_precision, map.precision):
	map.precision = map_precision
	var map_unchanged = true
	if not is_equal_approx(height_scale, map.max_height):
		map.max_height = height_scale
		map_unchanged = false
	if flat_material_asset_id !=  map.asset_material_flat_id:
		map.set_flat_material_asset_id(flat_material_asset_id)
	if cliff_material_asset_id !=  map.asset_material_cliff_id:
		map.set_cliff_material_asset_id(cliff_material_asset_id)
	map.uv_flat_scale = flat_uv_scale
	map.uv_cliff_scale = cliff_uv_scale
	map.layer_offset = layer_offset
	map.flat_cliff_ratio = flat_cliff_ratio
	map.flat_color = flat_color
	map.cliff_color = cliff_color
	if colormap_assset_id != map.asset_colormap_image_id:
		map.set_colormap_asset_id(colormap_assset_id)
	map.colormap_strength = colormap_strength
	# Enable collisions after loading all map data
	if heightmap_asset_id != map.asset_heightmap_image_id:
		map.set_heightmap_asset_id(heightmap_asset_id)
		if not map.is_loaded():
			await map.heightmap_asset_loaded
		map_unchanged = false
	map.use_collisions = true
	map.generate_normalmap = true
	if map_unchanged: # We did not changed a map, so we need to manually retrigger
		map.map_loaded.emit()
	else:
		# TODO this s incorrect we need to wait for heightmap
		map.material_normalmap_generate()
		map.add_collisions()
		map.align_to_world_origin()
		await map.map_loaded
		map.align_to_world_origin()
