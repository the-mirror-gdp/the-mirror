extends AssetData
class_name AssetDataMaterial

signal preview_textures_loaded()
signal textures_loaded()

var material: Material
var material_name: String = ""
var material_transparency_mode: String = ""
var material_transparency_properties: String = ""
var material_textures: Array = []

var _material_textures_data: Dictionary
var _material_hq_loaded = false


func _set_texture_data(asset_data_dict: Dictionary) -> void:
	var texture_data = AssetDataTexture.new()
	texture_data.preview_downloaded.connect(_check_preview_material)
	texture_data.files_loaded.connect(_check_material)
	texture_data.populate(asset_data_dict)
	if texture_data.texture_property_applies_to.is_empty():
		print("Error: Texture %s has no property assigned to it" % [str(texture_data.asset_id)])
		return
	_material_textures_data[texture_data.texture_property_applies_to] = texture_data
	texture_data.try_get_preview_texture(Enums.DownloadPriority.SPACE_OBJECT_HIGH)
	texture_data.try_download_file(Enums.DownloadPriority.SPACE_OBJECT_MEDIUM)
	_check_preview_material()
	_check_material()


func _on_asset_received(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] in material_textures:
		_set_texture_data(asset_dict)


func try_download_material(priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> void:
	if files_loaded.is_connected(_on_try_using_file_promise):
		files_loaded.connect(_on_try_using_file_promise)
	_material_hq_loaded = false
	# Material is in Resource file
	if not file_url.is_empty():
		await super.try_download_file(priority)
		_on_try_using_file_promise()
	# Check if there are textures to load
	if len(material_textures) == 0:
		return
	if not Net.asset_client.asset_received.is_connected(_on_asset_received):
		Net.asset_client.asset_received.connect(_on_asset_received)
	for texture_id in material_textures:
		var texture_json: Dictionary = Net.asset_client.get_asset_json(texture_id)
		if texture_json.is_empty():
			Net.asset_client.queue_download_asset(texture_id)
		else:
			_set_texture_data(texture_json)


func populate(dict: Dictionary) -> void:
	if dict == null:
		return
	assert(dict.get("__t", "") == "Material")
	if dict.has("materialName"):
		material_name = dict.get("materialName", "")
	if dict.has("materialTransparencyMode"):
		material_transparency_mode = dict.get("materialTransparencyMode", "")
	if dict.has("materialTransparencyProperties"):
		material_transparency_properties = dict.get("materialTransparencyProperties", "")
	if dict.has("textures"):
		material_textures = dict["textures"]
	super.populate(dict)


func _on_try_using_file_promise() -> void:
	if file_url.is_empty():
		print("Error: File URL empty")
		return
	var asset_file_promise = get_asset_file_promise()
	if not asset_file_promise.has_result():
		return
	if asset_file_promise.is_error():
		printerr("Error: AssetDataMaterial: ", asset_file_promise.get_error_message())
		return
	var asset_file_result = asset_file_promise.get_result()
	if not asset_file_result is Material:
		printerr("Error: AssetDataMaterial material is of incorrect type")
		return
	material = asset_file_result.duplicate()
	_material_hq_loaded = true
	textures_loaded.emit()


func _setup_material():
	material.normal_enabled = _material_textures_data.has("normal_texture")
	if _material_textures_data.has("metallic_texture"):
		material.metallic = 1.0
	else:
		material.metallic = 0.0
	if material.albedo_texture is Texture2D and material.albedo_texture.has_alpha():
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = _material_textures_data.has("emission_texture")


func _check_preview_material():
	if _material_hq_loaded:
		return
	for tex_type in _material_textures_data:
		var data = _material_textures_data[tex_type]
		if not data.preview_texture:
			return
	material = StandardMaterial3D.new()
	for tex_type in _material_textures_data:
		var data = _material_textures_data[tex_type]
		material.set(tex_type, data.preview_texture)
	_setup_material()
	preview_textures_loaded.emit()


func _check_material():
	for tex in _material_textures_data:
		var asset_file_promise = _material_textures_data[tex].get_asset_file_promise()
		if not asset_file_promise.has_result():
			return
		if asset_file_promise.is_error():
			printerr("Error: AssetDataMaterial Texture: ", asset_file_promise.get_error_message())
			return
		var asset_file_result = asset_file_promise.get_result()
		if not asset_file_result is Texture2D:
			printerr("Error: AssetDataMaterial Texture is of incorrect type")
			return
	material = StandardMaterial3D.new()
	for tex in _material_textures_data:
		var data = _material_textures_data[tex]
		material.set(tex, data.get_asset_file_promise().get_result())
	_material_hq_loaded = true
	_setup_material()
	textures_loaded.emit()
