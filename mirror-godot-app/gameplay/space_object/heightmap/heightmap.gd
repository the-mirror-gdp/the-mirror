@tool
class_name Heightmap
extends Node3D

const _QUADTREE_CHUNK_SCENE = preload("quad_tree_chunk.tscn")
const _MATERIAL = preload("res://gameplay/space_object/heightmap/heightmap_material.tres")
const _CHECKER_TEXTURE = preload("res://gameplay/space_object/heightmap/checker-texture.png")
const MAP_HEIGHT_OFFSET = 1.0

signal camera_viewer_chunk_switched(camera_viewer_position: Vector3)
signal map_transform_changed(map_size: int, map_position: Vector3)
signal map_loaded()
signal heightmap_asset_loaded()

var heightmap_asset_is_loading := false
# This is used to prevent the heightmap to emit useless `on_transform_changed` events, when the set
# transform is the same as before.
var old_global_rotation: Transform3D = Transform3D(Basis(), Vector3(-110000, -110000, -110000))

## This is only used for previewing inside Godot Editor as a debug tool
#@export var generate := false:
#	set(v):
#		_mesh_cache_refresh()
#		generate_heightmap()
## Number of rows and cols of quads in single chunk. Higher makes terrain more detailed
@export var chunk_resolution := 0:
	set(value):
		if value != chunk_resolution:
			chunk_resolution = value
			_mesh_cache_refresh()
			generate_heightmap()
## Dimmensions of single chunk in meters
@export var chunk_size := 64
## Maximum size (in meters) of generated quadtree. Above this distance terrain is invisible
## Usually you want this to be set a lot higher than map_size
@export var quadtree_size := 8192:
	set(value):
		quadtree_size = value
		if is_inside_tree():
			map_transform_changed.emit(map_size, global_position)
## Size of terrain in meters. Quadtree outside this range is not rendered
@export var map_size: int = 0:
	set(value):
		if is_inside_tree():
			map_transform_changed.emit(value, global_position)
		_tween_shader_param("map_size", map_size, value)
		map_size = value
		if _space_object != null:
			RenderingServer.global_shader_parameter_set("world_map_size_01", Vector2(map_size, map_size))
		add_collisions()
		await map_loaded
		align_to_world_origin()
## Maximum height in meters defined by "white" color in heightmap.
@export var max_height = 32.0:
	set(value):
		_tween_shader_param("scale_z", max_height, value)
		max_height = value
		if _space_object != null:
			RenderingServer.global_shader_parameter_set("world_map_max_height_01", max_height)
		material_normalmap_generate()
		add_collisions()
		_update_aabb()
		await map_loaded
		align_to_world_origin()
@export var material: ShaderMaterial:
	set(value):
		# We are duplicating material to allow mutliple Heightmaps in single scene
		material = value #.duplicate()
		material_normalmap_generate()
@export var heightmap_texture: Texture2D:
	set(value):
		heightmap_texture = value
		if heightmap_texture !=  null:
			_heightmap_image_cache = heightmap_texture.get_image()
		else:
			_heightmap_image_cache = null
		material_normalmap_generate()
		add_collisions()
		await map_loaded
		align_to_world_origin()
@export var uv_flat_scale: float = 0.1:
	set(value):
		_set_shader_param("uv_scale_top", value)
		uv_flat_scale = value
@export var uv_cliff_scale: float = 0.1:
	set(value):
		_set_shader_param("uv_scale_side", value)
		uv_cliff_scale = value
@export var layer_offset: float = 0.08:
	set(value):
		layer_offset = value
		_set_shader_param("max_bump_strength", value)
@export var flat_cliff_ratio: float = -0.6:
	set(value):
		flat_cliff_ratio = value
		_set_shader_param("blend_weight_offset", value)
@export var flat_color: Color:
	set(value):
		flat_color = value
		_set_shader_param("albedo_top", value)
@export var cliff_color: Color:
	set(value):
		cliff_color = value
		_set_shader_param("albedo_side", value)
## Ths section is used only by Collsion generation
@export var use_collisions: bool = true
@export var generate_normalmap: bool = true
@export var collision_precision: float = 1.0
@export var colormap_texture: Texture2D:
	set(value):
		colormap_texture = value
		_set_shader_param("texture_color_map", value)
@export var normalmap: Texture2D:
	set(value):
		normalmap = value
		material.set_shader_parameter.call_deferred("texture_global_normalmap", normalmap)
@export var colormap_strength: float:
	set(value):
		colormap_strength = value
		_set_shader_param("colormap_strength", value)

var asset_data: AssetDataMap
var precision: float = 1.0:
	set(value):
		precision = value
		calculate_precision(value)

var asset_material_flat_id: String
var asset_material_cliff_id: String
var asset_heightmap_image_id: String
var asset_colormap_image_id: String

var _mesh_cache: Array[Mesh] = []
var _heightmap_image_cache: Image = null
var _visual_node = Node3D.new()
var _asset_heightmap_image: AssetData
var _asset_colormap_image: AssetData
var _collision_generation_task_id: int = -1
var _normalmap_generation_task_id: int = -1
var _collision_generation_awaiting: bool = false

@onready var _is_using_server_camera = ProjectSettings.get_setting("mirror/use_server_camera")

var _space_object

const _UNDO_REDO_PROPERTY_NAME_DICT = [
	"chunk_resolution", "chunk_size", "quadtree_size", "map_size", "max_height",
	"heightmap_texture", "uv_flat_scale", "uv_cliff_scale", "layer_offset",
	"flat_cliff_ratio", "flat_color", "cliff_color", "colormap_texture"
]


func _tween_shader_param(param_name: String, value_from: Variant, value_to: Variant, length: float = 0.5):
	if not material:
		return
	if not is_inside_tree():
		material.set_shader_parameter(param_name, value_to)
		return
	var tween = create_tween()
	tween.tween_method((func(value):
			material.set_shader_parameter(param_name, value)
			), value_from, value_to, length
	)


func _set_shader_param(param_name: String, value: Variant) -> void:
	if material:
		material.set_shader_parameter(param_name, value)


func _get_configuration_warnings() -> PackedStringArray:
	var errors = []
	if heightmap_texture == null:
		errors.append("Please provide heightmap texture")
	if material == null:
		errors.append("Please provide material")
	return errors


func material_normalmap_generate():
	if material == null:
		return
	material.set_shader_parameter("texture_heightmap", heightmap_texture)
	# Set global, we are supporting only map for now so its safe
	if _space_object != null:
		RenderingServer.global_shader_parameter_set("world_heightmap_01", heightmap_texture)
	if heightmap_texture == null or not generate_normalmap:
		material.set_shader_parameter("texture_global_normalmap", null)
		return
	if _heightmap_image_cache == null:
		printerr("Heightmap image cache is null")
		return

	var heightmap_cache_before_await = _heightmap_image_cache
	# Generate collision shape in thread but do not spawn unlimited number of
	# threads.
	if _normalmap_generation_task_id > -1:
		# wait async:
		while not WorkerThreadPool.is_task_completed(_normalmap_generation_task_id):
			await Zone.get_tree().create_timer(0.5).timeout
	if heightmap_cache_before_await != _heightmap_image_cache:
		printerr("Started heightmap normalmap generation with old data")
		return

	var normal_map: Image = _heightmap_image_cache.duplicate()
	var normal_texture = ImageTexture.new()
	_normalmap_generation_task_id = WorkerThreadPool.add_task(func():
		if normal_map.is_compressed():
			normal_map.decompress()
		if normal_map.get_format() == Image.FORMAT_RGB8:
			# This a bit ugly workaround for low quality hightmaps (8bits
			# We probably should switch to Sobel filtering
			# We are sampling on 4x times less resolution and than interpolate up to avoid "steps" artifacts
			var size_scaler = 4.0 if map_size <= 1024 else 2.0
			normal_map.resize(normal_map.get_width() / size_scaler, normal_map.get_height() / size_scaler, Image.INTERPOLATE_LANCZOS)
			normal_map.bump_map_to_normal_map(max_height/(0.75*size_scaler))
			normal_map.resize(normal_map.get_width() * size_scaler, normal_map.get_height() * size_scaler)
		else:
			normal_map.bump_map_to_normal_map(max_height * 1.25)
		normal_texture.set_image(normal_map)
		normalmap = normal_texture
	)


func _mesh_cache_refresh():
	var c_gen = QuadTreeChunkMeshGenerator.new()
	c_gen.resolution = chunk_resolution
	c_gen.size = chunk_size
	_mesh_cache.resize(c_gen.PERMUTATION.MAX)

	for x in c_gen.PERMUTATION.MAX:
		c_gen.permutation = x
		_mesh_cache[x] = c_gen.generate_mesh()


func _update_viewer_position(viewer_position: Vector3):
	_visual_node.global_position.x = floor(viewer_position.x)
	_visual_node.global_position.z = floor(viewer_position.z)
	_visual_node.global_position.x -= int(floor(viewer_position.x)) % int(chunk_size)
	_visual_node.global_position.z -= int(floor(viewer_position.z)) % int(chunk_size)


func _clear_children():
	for x in _visual_node.get_children():
		_visual_node.remove_child(x)
		x.queue_free()


func generate_heightmap():
	_clear_children()
	add_collisions()
	if Engine.is_editor_hint() or not Zone.is_host() or _is_using_server_camera:
		_quad_tree_gen(Vector2(0,0), quadtree_size, Vector2(0,0), Vector2i(0,0), Vector2i(0,0))
		_update_aabb()


func get_height(world_pos: Vector2) -> float:
	if not _heightmap_image_cache:
		return 0.0
	var vec2_size = Vector2(map_size, map_size)
	var start: Vector2 = - vec2_size/2.0
	if is_inside_tree():
		start = Vector2(global_position.x, global_position.z) - vec2_size/2.0
	var rect = Rect2(start, vec2_size)
	if not rect.has_point(world_pos):
		return 0.0

	var relative_pos = world_pos - start
	var heightmap_image = _heightmap_image_cache
	var img_aspect = Vector2(heightmap_image.get_size())/vec2_size
	var aspect_corrected = relative_pos * img_aspect
	var img_data = heightmap_image.get_pixelv(aspect_corrected).r
	return img_data * max_height


func add_collisions():
	var is_server = TMSceneSync.is_server()
	if not _space_object:
		return
	if not use_collisions:
		return
	if not is_inside_tree():
		return

	# Add a cross to find the terrain origin.
	if false:
		var mi = MeshInstance3D.new()
		add_child(mi)
		mi.mesh = BoxMesh.new()
		mi.mesh.size = Vector3(1,10000,1)
		mi.owner = self
		mi = MeshInstance3D.new()
		add_child(mi)
		mi.mesh = BoxMesh.new()
		mi.mesh.size = Vector3(10000, 1, 1)
		mi.owner = self
		mi = MeshInstance3D.new()
		add_child(mi)
		mi.mesh = BoxMesh.new()
		mi.mesh.size = Vector3(1, 1, 10000)
		mi.owner = self

	if not heightmap_texture:
		if not heightmap_asset_is_loading:
			var shape = JBoxShape3D.new()
			shape.size = Vector3(map_size, 0.05, map_size)
			_space_object.set_shape_and_create_body(shape)
			# Emit it as otherwise terrains without heightmap will never leave a preload state
			map_loaded.emit()
		return

	if _heightmap_image_cache == null:
		printerr("Heightmap image cache is null")
		return
	var heightmap_cache_before_await = _heightmap_image_cache
	# Generate collision shape in thread but do not spawn unlimited number of
	# threads.
	if _collision_generation_task_id > -1:
		# wait async:
		while not WorkerThreadPool.is_task_completed(_collision_generation_task_id):
			_collision_generation_awaiting = true
			await Zone.get_tree().create_timer(0.5).timeout
		_collision_generation_awaiting = false
		#WorkerThreadPool.wait_for_task_completion(_collision_generation_task_id)
	if heightmap_cache_before_await != _heightmap_image_cache:
		printerr("Started heightmap shape generation with old data")
		return
	var heightmap_image: Image = _heightmap_image_cache.duplicate()

	_freeze_local_player(true)

	_collision_generation_task_id = WorkerThreadPool.add_task(func():
		var compressed = heightmap_image.is_compressed()
		if compressed:
			heightmap_image.decompress()

		var desired_size := int(min(heightmap_image.get_width(), heightmap_image.get_height()))
		assert(desired_size > 2)

		# Scale the heightmap so we can work with a much smaller image if the
		# map_size is not that big.
		if map_size < desired_size:
			desired_size = map_size

		desired_size = int(round(desired_size / collision_precision))

		# Make sure the desired size is a multiple of 2.
		if (desired_size % 2) != 0:
			desired_size = int(round(desired_size / 2) * 2)

		if desired_size != heightmap_image.get_width() or desired_size != heightmap_image.get_height():
			# Rescale the image to be squared:
			# Upsacling is using bilinear interpolation in shaders, downscaling is just nearest.
			# Using nearest mipmapped would be better in shader, but it's more costly to get matching
			# result on CPU side
			var mode := Image.INTERPOLATE_BILINEAR if desired_size > heightmap_image.get_width() else Image.INTERPOLATE_NEAREST
			heightmap_image.resize(
					desired_size,
					desired_size,
					mode)

		assert(heightmap_image.get_width() == heightmap_image.get_height())
		Thread.set_thread_safety_checks_enabled(false)
		var y_offset = -get_height(Vector2(0,0)) - MAP_HEIGHT_OFFSET
		Thread.set_thread_safety_checks_enabled(true)
		var sample_count = heightmap_image.get_width()
		var scaling = float(map_size) / float(sample_count)
		var shape := JHeightFieldShape3D.new()

		var data := PackedFloat32Array()
		data.resize(sample_count * sample_count)

		shape.scale = Vector3(scaling, 1.0, scaling)
		# Offset the HeightField to center.
		shape.offset = (Vector3(sample_count, 0.0, sample_count) * shape.scale) * -0.5
		shape.block_size = 2

		var i = 0
		for y in sample_count:
			for x in sample_count:
				data[i] = (heightmap_image.get_pixel(x, y).r * max_height) + y_offset
				i += 1

		shape.field_data = data

		# Build the shape now on this thread.
		shape.make_shape()

		# Emit it from subtask so we load object after collision is done
		_update_space_object_shape.call_deferred(shape)

	)


func _update_space_object_shape(shape: JShape3D) -> void:
	_space_object.set_shape_and_create_body(shape) # this takes time
	align_to_world_origin()
	map_loaded.emit()
	if not _collision_generation_awaiting:
		_freeze_local_player(false)


func _emit_map_loaded() -> void:
	map_loaded.emit()


func _update_aabb():
	for x in _visual_node.get_children():
		var aabb = x.get_aabb()
		aabb.size.y = max_height * 2.0
		x.set_custom_aabb(aabb)


func _add_mesh(quadrant_pos: Vector2, quadrant_size: float, sub_quadrant_pos: Vector2i, edge_type: Vector2i):
	var scale_xz = quadrant_size/chunk_size
	var mi = _QUADTREE_CHUNK_SCENE.instantiate()
	if edge_type == Vector2i(0,0) or (edge_type.x == sub_quadrant_pos.x and edge_type.y == sub_quadrant_pos.y) :
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.NONE]
	# this is top
	elif edge_type.x == sub_quadrant_pos.x and edge_type.y > sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.TOP]
	# bottom
	elif edge_type.x == sub_quadrant_pos.x and edge_type.y < sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.BOTTOM]
	# left
	elif edge_type.y == sub_quadrant_pos.y and edge_type.x > sub_quadrant_pos.x:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.LEFT]
	# right
	elif edge_type.y == sub_quadrant_pos.y and edge_type.x < sub_quadrant_pos.x:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.RIGHT]

	# top right
	elif edge_type.x < sub_quadrant_pos.x and edge_type.y > sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.TOP_RIGHT]
	# top left
	elif edge_type.x > sub_quadrant_pos.x and edge_type.y > sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.LEFT_TOP]
	# bottom right
	elif edge_type.x < sub_quadrant_pos.x and edge_type.y < sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.RIGHT_BOTTOM]
	# bottom left
	elif edge_type.x > sub_quadrant_pos.x and edge_type.y < sub_quadrant_pos.y:
		mi.mesh = _mesh_cache[QuadTreeChunkMeshGenerator.PERMUTATION.BOTTOM_LEFT]
	else:
		print("Heightmap Error: no solution for: ",edge_type, " -> ", sub_quadrant_pos )
		push_error("Heightmap Error: no solution for: ",edge_type, " -> ", sub_quadrant_pos )

	_visual_node.add_child(mi)
	mi.transform.origin = Vector3(quadrant_pos.x, 0.0, quadrant_pos.y)
	mi.scale = Vector3(scale_xz, 1.0, scale_xz)
	mi.material_override = material
	map_transform_changed.connect(mi.on_map_transform_changed, CONNECT_DEFERRED)


func _check_quadrant_subdivision(quadrant_pos: Vector2, quadrant_size: float, quadtree_center: Vector2):
	return quadrant_pos.distance_to(quadtree_center) < quadrant_size and quadrant_size > chunk_size


func _check_quadrant_subdivision_childs(quadrant_pos: Vector2, quadrant_size: float, quadtree_center: Vector2) ->  Vector2i:
	var result = Vector2i(0,0)
	var cnt = 0
	for x in [-1 , 1]:
		for y in [-1, 1]:
			var child_pos = Vector2(x, y) * quadrant_size / 4.0 + quadrant_pos
			if _check_quadrant_subdivision(child_pos, quadrant_size / 2.0, quadtree_center):
				result =  Vector2i(x,y)
				cnt +=1
	if cnt == 1:
		return result
	else:
		return Vector2i(0,0)


func _quad_tree_gen(quadrant_pos: Vector2, quadrant_size: float, quadtree_center: Vector2, sub_quadrant_pos: Vector2i, edge_type: Vector2i):
	if _check_quadrant_subdivision(quadrant_pos, quadrant_size, quadtree_center):
		#check if child will subdivide further
		var edge_child = _check_quadrant_subdivision_childs(quadrant_pos, quadrant_size, quadtree_center)
		for x in [-1 , 1]:
			for y in [-1, 1]:
				var child_pos = Vector2(x, y) * quadrant_size / 4.0 + quadrant_pos
				var edge_type_child = edge_child if edge_child == Vector2i(x,y) else edge_type
				_quad_tree_gen(child_pos, quadrant_size / 2.0, quadtree_center, Vector2i(x,y), edge_type_child)
	else:
		_add_mesh(quadrant_pos, quadrant_size, sub_quadrant_pos, edge_type)


func _ready() -> void:
	if _visual_node.get_parent() == null:
		add_child(_visual_node)
	if Engine.is_editor_hint() or not Zone.is_host() or _is_using_server_camera:
		_mesh_cache_refresh()
	generate_heightmap()
	if Zone.is_host():
		Util.safe_signal_connect(Net.zone_socket.asset_received, _on_asset_received)
	else:
		Util.safe_signal_connect(Net.asset_client.asset_received, _on_asset_received)


func _set_heightmap_data(asset_dict) -> void:
	heightmap_asset_is_loading = true
	_asset_heightmap_image = AssetData.new()
	_asset_heightmap_image.populate(asset_dict)
	if _asset_heightmap_image.type != Enums.ASSET_TYPE.IMAGE:
		asset_heightmap_image_id = ""
		_asset_heightmap_image = null
		Notify.error("Map heightmap", "Heightmap asset is not an Image")
		return
	var asset_file_promise = _asset_heightmap_image.get_asset_file_promise()
	_asset_heightmap_image.try_download_file(Enums.DownloadPriority.MAP_HEIGHTMAP)
	# This if is making it execute in one cycle
	if not asset_file_promise.has_result():
		await asset_file_promise.wait_till_fulfilled()
	if asset_file_promise.is_error():
		heightmap_asset_is_loading = false
		print("Error on loading heightmap data: %s", asset_file_promise.get_error_message())
		map_loaded.emit() # Emit map_loaded so we do not block preloading of scene
		heightmap_asset_loaded.emit()
		return
	heightmap_asset_is_loading = false
	heightmap_texture = asset_file_promise.get_result()
	heightmap_asset_loaded.emit()


func set_color_map_data(asset_dict) -> void:
	_asset_colormap_image = AssetData.new()
	_asset_colormap_image.populate(asset_dict)
	var asset_file_promise = _asset_colormap_image.get_asset_file_promise()
	_asset_colormap_image.try_download_file(Enums.DownloadPriority.MAP_HEIGHTMAP)
	# This if is making it execute in one cycle
	if not asset_file_promise.has_result():
		await asset_file_promise.wait_till_fulfilled()
	if asset_file_promise.is_error():
		print("Error on loading colormap data: %s", asset_file_promise.get_error_message())
		return
	colormap_texture = asset_file_promise.get_result()
	if material:
		material.set_shader_parameter("colormap_present", true)


func _on_asset_received(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] in asset_heightmap_image_id:
		_set_heightmap_data(asset_dict)
	if asset_dict["_id"] in asset_colormap_image_id:
		set_color_map_data(asset_dict)


func _queue_download_asset_all(asset_id: String):
	if Zone.is_host():
		var promise: Promise = Net.zone_socket.queue_download_asset(asset_id)
		await promise.wait_till_fulfilled()
		if promise.is_error():
			printerr("Invalid terrain asset %s" % promise.get_error_message())
			return
		print_verbose("Loaded asset successfully: ", asset_id)
	else:
		var promise = Net.asset_client.queue_download_asset(asset_id)
		await promise.wait_till_fulfilled()
		if asset_id == asset_heightmap_image_id:
			if promise.is_error():
				Notify.error("Map heightmap", "Heightmap image was not loaded correctly")
				map_loaded.emit()


func is_loaded():
	# just a height data for now
	if asset_heightmap_image_id.is_empty() or asset_heightmap_image_id ==null:
		return true
	if not is_instance_valid(_asset_heightmap_image):
		return false
	if _asset_heightmap_image.asset_id != asset_heightmap_image_id:
		return false
	if not use_collisions:
		return true
	if _collision_generation_task_id == -1:
		return false
	return WorkerThreadPool.is_task_completed(_collision_generation_task_id)


func set_heightmap_asset_id(image_asset_id):
	asset_heightmap_image_id = image_asset_id
	if asset_heightmap_image_id.is_empty():
		heightmap_texture = null
		map_loaded.emit()
		return
	var asset_json: Dictionary = Net.asset_client.get_asset_json(image_asset_id)
	if asset_json.is_empty():
		_queue_download_asset_all(image_asset_id)
	else:
		_set_heightmap_data(asset_json)


func set_colormap_asset_id(image_asset_id):
	asset_colormap_image_id = image_asset_id

	if asset_colormap_image_id.is_empty():
		colormap_texture = null
		if material:
			material.set_shader_parameter("colormap_present", false)
		return
	var asset_json: Dictionary = Net.asset_client.get_asset_json(image_asset_id)
	if asset_json.is_empty():
		_queue_download_asset_all(image_asset_id)
	else:
		set_color_map_data(asset_json)


func _set_texture_from_material(mat: MirrorMaterial, texture_name: String, map_shader_param: String) -> void:
	if not is_instance_valid(material):
		return
	if mat.is_pbr_compatiblity:
		await mat.pbr_asset_data_promise.wait_till_fulfilled()
	if not mat.has_parameter_in_cache(texture_name):
		return
	# try extracting from material, if loaded
	var texture = mat.get_shader_parameter(texture_name)
	if is_instance_valid(texture):
		material.set_shader_parameter(map_shader_param, texture)
		return
	var asset_id = mat.get_parameter_from_cache(texture_name)
	var ad_promise = Net.asset_client.queue_download_asset(asset_id)
	var asset_dict = await ad_promise.wait_till_fulfilled()
	if ad_promise.is_error():
		print("Failure loading asset_data for asset_id: %s" % asset_id)
		return
	var asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	assert(asset_data.type in [Enums.ASSET_TYPE.TEXTURE, Enums.ASSET_TYPE.IMAGE])
	var preview_url = asset_data.thumbnail_url
	if not preview_url.is_empty():
		var preview_promise: Promise = Net.file_client.get_file(preview_url)
		var preview_image = await preview_promise.wait_till_fulfilled()
		if not preview_promise.is_error():
			# set preview only if success but do not exit early otherwise
			material.set_shader_parameter(map_shader_param, preview_image)
	var promise: Promise = Net.file_client.get_file(asset_data.file_url)
	var image = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Failure loading image from url: %s" %asset_data.file_url)
	else:
		material.set_shader_parameter(map_shader_param, image)


func set_flat_material_asset_id(material_id):
	asset_material_flat_id = material_id
	if Zone.is_host():
		return
	if asset_material_flat_id.is_empty():
		material.set_shader_parameter("texture_albedo_top", _CHECKER_TEXTURE)
		material.set_shader_parameter("texture_normalmap_top", null)
		material.set_shader_parameter("texture_roughness_top", null)
		return
	var promise = Zone.material_manager.get_material_asset(material_id)
	var mat = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Map Erorr", "Could not load flat material.")
		set_flat_material_asset_id("")
		return
	if mat.resource_name != asset_material_flat_id:
		# This if is necessary after await, becase user could change material faster
		return
	var params_convert: Dictionary = {
		"texture_albedo": "texture_albedo_top",
		"texture_normal": "texture_normalmap_top",
		"texture_roughness": "texture_roughness_top",
	}
	for param in params_convert:
		_set_texture_from_material(mat, param, params_convert[param])


func set_cliff_material_asset_id(material_id):
	asset_material_cliff_id = material_id
	if Zone.is_host():
		return
	if asset_material_cliff_id.is_empty():
		material.set_shader_parameter("texture_albedo_side", _CHECKER_TEXTURE)
		material.set_shader_parameter("texture_normalmap_side", null)
		material.set_shader_parameter("texture_roughness_side", null)
		return
	var promise = Zone.material_manager.get_material_asset(material_id)
	var mat = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Map Erorr", "Could not load flat material.")
		set_flat_material_asset_id("")
		return
	if mat.resource_name != asset_material_cliff_id:
		# This if is necessary after await, becase user could change material faster
		return
	var params_convert: Dictionary = {
		"texture_albedo": "texture_albedo_side",
		"texture_normal": "texture_normalmap_side",
		"texture_roughness": "texture_roughness_side",
	}
	for param in params_convert:
		_set_texture_from_material(mat, param, params_convert[param])


func _process(_delta):
	if Engine.is_editor_hint() or Zone.is_host():
		return
	var local_player: Player = PlayerData.get_local_player()
	if local_player == null:
		return
	var camera: Camera3D = local_player.camera_get_viewport().get_camera_3d()
	if camera != null:
		_update_viewer_position(camera.global_position)
	else:
		_update_viewer_position(Vector3.ZERO)


func _enter_tree() -> void:
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if old_global_rotation == global_transform:
			return
		# cancel any rotation in pitch and roll
		global_rotation.x = 0.0
		global_rotation.z = 0.0
		# cancel scaling
		scale = Vector3.ONE
		material.set_shader_parameter("map_center_position", global_position)
		material.set_shader_parameter("map_yaw_rotation", global_rotation.y)
		old_global_rotation = global_transform
		map_transform_changed.emit(map_size, global_position)


func calculate_precision(precision: float) -> void:
	var chunk_size_perf_scaler = 2
	if precision > 2.1:
		chunk_size = 8
	elif precision > 1.1:
		chunk_size = 16
	else:
		chunk_size = 32

	chunk_size *= chunk_size_perf_scaler

	chunk_resolution =  int(chunk_size * precision)


func setup() -> void:
	material = _MATERIAL.duplicate()
	if Zone.is_host():
		Util.safe_signal_connect(Net.zone_socket.asset_received, _on_asset_received)
	else:
		Util.safe_signal_connect(Net.asset_client.asset_received, _on_asset_received)
		material.set_shader_parameter("texture_albedo_side", _CHECKER_TEXTURE)
		material.set_shader_parameter("texture_albedo_top", _CHECKER_TEXTURE)


func populate(space_object, space_object_data: Dictionary = {}) -> void:
	material.set_shader_parameter("map_center_position", global_position)
	material.set_shader_parameter("map_yaw_rotation", global_rotation.y)
	#populate global settings
	#RenderingServer.global_shader_parameter_add("world_heightmap_01", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, PlaceholderTexture2D.new())
	RenderingServer.global_shader_parameter_set("world_map_size_01", Vector2(map_size, map_size))
	RenderingServer.global_shader_parameter_set("world_map_max_height_01", max_height)
	RenderingServer.global_shader_parameter_set("world_heightmap_01", heightmap_texture)
	RenderingServer.global_shader_parameter_set("world_colormap_01", colormap_texture)
	RenderingServer.global_shader_parameter_set("world_map_max_height_offset_01", _visual_node.position.y)
	_space_object = space_object
	add_collisions()


func get_space_object():
	return _space_object


func serialize_to_dictionary() -> Dictionary:
	var hist_dict: Dictionary = {}

	# Map godot properties to the correct database columns for saving them
	for prop in _UNDO_REDO_PROPERTY_NAME_DICT:
		hist_dict[prop] = self[prop]
	return hist_dict


func move_data(heightmap: Heightmap):
	asset_data = heightmap.asset_data
	asset_data.map = self # remove refernce from asset data to old map
	# Expensive setters are guarded with if's
	if map_size != heightmap.map_size:
		map_size = heightmap.map_size
	if not is_equal_approx(precision, heightmap.precision):
		precision = heightmap.precision
	if not is_equal_approx(max_height, heightmap.max_height):
		max_height = heightmap.max_height
	if asset_material_flat_id !=  heightmap.asset_material_flat_id:
		set_flat_material_asset_id(heightmap.asset_material_flat_id)
	if asset_material_cliff_id !=  heightmap.asset_material_cliff_id:
		set_cliff_material_asset_id(heightmap.asset_material_cliff_id)
	uv_flat_scale = heightmap.uv_flat_scale
	uv_cliff_scale = heightmap.uv_cliff_scale
	layer_offset = heightmap.layer_offset
	flat_cliff_ratio = heightmap.flat_cliff_ratio
	flat_color = heightmap.flat_color
	cliff_color = heightmap.cliff_color
	if asset_colormap_image_id != heightmap.asset_colormap_image_id:
		set_colormap_asset_id(heightmap.asset_colormap_image_id)
	colormap_strength = heightmap.colormap_strength
	if asset_heightmap_image_id != heightmap.asset_heightmap_image_id:
		set_heightmap_asset_id(heightmap.asset_heightmap_image_id)
	elif is_loaded():
		map_loaded.emit()


func _offset_spawn_points(map_offset: float = 0.0):
	var space_instances: Array[Node] = Zone.instance_manager.get_all_instances()
	var spawns = space_instances.filter(func(x):
		return x is SpaceObject and (
				Util.recursive_find_nodes_with_meta(x, &"OMI_spawn_point").size() > 0
				or  x.spawn_points.size() > 0
			)
	)
	for spawn in spawns:
		var pos = spawn.global_position
		var spawn_aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(spawn)
		# Assumes that center of object is object origin
		var map_height = get_height(Vector2(pos.x, pos.z)) + map_offset + spawn_aabb.size.y/2.0
		if map_height > pos.y:
			spawn.global_position.y = map_height


func _freeze_local_player(frozen: bool) -> void:
	if Zone.is_host():
		return
	var player: Player = PlayerData.get_local_player()
	if not is_instance_valid(player):
		return
	player.set_frozen(frozen)


func _offset_local_player(map_offset: float = 0.0) -> void:
	if Zone.is_host():
		return
	var player: Player = PlayerData.get_local_player()
	if not is_instance_valid(player):
		return
	var pos = player.global_position
	var map_height: float = get_height(Vector2(pos.x, pos.z)) + map_offset + player.character_height
	if map_height > pos.y:
		player.teleport.rpc(Vector3(pos.x, map_height, pos.z))


func align_to_world_origin() -> void:
	if not is_inside_tree():
		return
	var y_offset = 0.0
	if heightmap_texture != null:
		y_offset = -get_height(Vector2(0,0)) - MAP_HEIGHT_OFFSET

	_visual_node.position.y = y_offset
	if _space_object != null:
		RenderingServer.global_shader_parameter_set("world_map_max_height_offset_01", _visual_node.position.y)
	if not Zone.space_preload_done:
		return
	_offset_spawn_points(y_offset)
	_offset_local_player(y_offset)
