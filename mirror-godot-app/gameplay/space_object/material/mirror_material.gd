extends ShaderMaterial
class_name MirrorMaterial


signal parameter_changed(parameter: String, value: Variant)
signal shader_code_changed(code: String)

enum MATERIAL_FEATURE {
	ALPHA,
	ALPHA_MASKED,
	EMISSION,
	TRIPLANAR,
	POM,
	REFRACTION,
	PBR_TEXTURES,
	CUSTOM_SHADER,
	UV_EDITING,
	WATER_SETTINGS,
}

class SHADER_TYPE:
	const STANDARD := "standard"
	const OPACITY_MASKED := "opacity_masked"
	const DISPLACED := "displaced"
	const GLASS := "glass"
	const VARNISH := "varnish"
	const WATER := "water"
	const CUSTOM_SHADER = "shader"

const _STANDARD_SHADER = preload("res://gameplay/space_object/material/standard.gdshader")
const _OPACITY_MASKED_SHADER = preload("res://gameplay/space_object/material/opacity_masked.gdshader")
const _DISPLACED_SHADER = preload("res://gameplay/space_object/material/displaced.gdshader")
const _GLASS_SHADER = preload("res://gameplay/space_object/material/glass.gdshader")
const _VARNISH_SHADER = preload("res://gameplay/space_object/material/standard.gdshader")
const _WATER_SHADER = preload("res://gameplay/space_object/material/water/water-shader.tres")
const _CUSTOM_SHADER_TEMPLATE = preload("res://gameplay/space_object/material/custom_shader_template.gdshader")

const _WATER_NORMAL = preload("res://gameplay/space_object/material/water/water-normal.png")
const _WATER_NORMAL2 = preload("res://gameplay/space_object/material/water/water-normal2.png")
const _WATER_FLOWMAP = preload("res://gameplay/space_object/material/water/flowmap-water.png")
const _WATER_CAUSTICS = preload("res://gameplay/space_object/material/water/water-caustic.png")
const _WATER_FOAM_MAP = preload("res://gameplay/space_object/material/water/foam.png")
const _WATER_LENS_GLARE = preload("res://gameplay/space_object/material/water/lense-glare.png")

var id: String = ""
var instance_name: String = ""
var allow_local = false
var is_asset_based = true
var is_pbr_compatiblity = false
var pbr_asset_data_promise: Promise

var _current_shader_type: String = SHADER_TYPE.STANDARD
var _local_parameters_cache := {}

var _pbr_to_mirror_convert: Dictionary = {
	"albedo_texture": "texture_albedo",
	"roughness_texture": "texture_roughness",
	"metallic_texture": "texture_metallic",
	"normal_texture": "texture_normal",
	"emission_texture": "emission"
}

var _shader_feature_support_map: Dictionary = {
	SHADER_TYPE.STANDARD: [MATERIAL_FEATURE.TRIPLANAR, MATERIAL_FEATURE.PBR_TEXTURES, MATERIAL_FEATURE.EMISSION, MATERIAL_FEATURE.UV_EDITING],
	SHADER_TYPE.OPACITY_MASKED: [MATERIAL_FEATURE.ALPHA_MASKED, MATERIAL_FEATURE.TRIPLANAR, MATERIAL_FEATURE.PBR_TEXTURES, MATERIAL_FEATURE.EMISSION, MATERIAL_FEATURE.UV_EDITING],
	SHADER_TYPE.DISPLACED: [MATERIAL_FEATURE.POM, MATERIAL_FEATURE.PBR_TEXTURES, MATERIAL_FEATURE.EMISSION, MATERIAL_FEATURE.UV_EDITING],
	SHADER_TYPE.GLASS: [MATERIAL_FEATURE.ALPHA, MATERIAL_FEATURE.REFRACTION, MATERIAL_FEATURE.PBR_TEXTURES, MATERIAL_FEATURE.UV_EDITING],
	SHADER_TYPE.WATER: [MATERIAL_FEATURE.REFRACTION, MATERIAL_FEATURE.WATER_SETTINGS],
	SHADER_TYPE.CUSTOM_SHADER: [MATERIAL_FEATURE.CUSTOM_SHADER]
}


func get_material_type_name() -> String:
	return tr(_current_shader_type)


func feature_supported(feature: MATERIAL_FEATURE) -> bool:
	return feature in _shader_feature_support_map.get(_current_shader_type, [])


func _set_texture_parameter(shader_parameter: String, asset_id: String) -> void:
	if asset_id.is_empty():
		set_shader_parameter(shader_parameter, null)
		return
	if allow_local and FileAccess.file_exists(asset_id):
		# This is a local file, for previewing only
		var img = Util.load_image(asset_id)
		set_shader_parameter(shader_parameter, img)
	else:
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
				set_shader_parameter(shader_parameter, preview_image)
		var promise: Promise = Net.file_client.get_file(asset_data.file_url)
		var image = await promise.wait_till_fulfilled()
		if promise.is_error():
			print("Failure loading image from url: %s" %asset_data.file_url)
		else:
			set_shader_parameter(shader_parameter, image)


func set_shader_param(parameter: String, value: Variant) -> void:
	if Zone.is_host():
		return
	if value is String:
		# String values are accepted only for texture asset_ids
		_set_texture_parameter(parameter, value)
	else:
		set_shader_parameter(parameter, value)
	if value is Texture2D:
		return
	if _local_parameters_cache.get(parameter) != value:
		parameter_changed.emit(parameter, value)
	_local_parameters_cache[parameter] = value


func has_parameter_in_cache(parameter: String):
	return _local_parameters_cache.has(parameter)


func get_parameter_from_cache(parameter: String):
	return _local_parameters_cache.get(parameter, null)


func _setup_properties(properties: Dictionary) -> void:
	var uniforms = shader.get_shader_uniform_list(true)
	for uniform in uniforms:
		if not properties.has(uniform.name):
			continue
		var value = properties.get(uniform.name)
		match uniform.type:
			TYPE_COLOR:
				value = Serialization.array_to_color(value)
			TYPE_VECTOR2:
				value = Serialization.array_to_vector2(value)
			TYPE_VECTOR3:
				value = Serialization.array_to_vector3 (value)
		set_shader_param(uniform.name, value)



func _setup_water_shader() -> void:
	set_shader_parameter("normalmap1", _WATER_NORMAL)
	set_shader_parameter("normalmap2", _WATER_NORMAL2)
	set_shader_parameter("glare_lense_map", _WATER_LENS_GLARE)
	set_shader_parameter("foam_map", _WATER_FOAM_MAP)
	set_shader_parameter("caustic_map", _WATER_CAUSTICS)
	set_shader_parameter("uv_sampler_map", _WATER_FLOWMAP)


func _upload_texture_to_asset(type: String, texture: Texture2D) -> Promise:
	var res_promise = Promise.new()

	var asset_name: String = instance_name + "_" + type
	var asset_type = Enums.ASSET_TYPE.IMAGE

	var asset_data_req: Dictionary = {
		"name": asset_name,
		"assetType": asset_type,
	}
	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)
	var promise = Net.asset_client.create_asset(asset_data_req)
	var asset_data  = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Failed To Create Asset", promise.get_error_message())
		res_promise.set_error(promise.get_error_message())
		return res_promise
	var mime_type = "image/webp"
	var file_data = Util.get_webp_data(texture)
	var promise_upload = Net.asset_client.upload_file_public(asset_data.get("_id"), file_data, mime_type)
	var asset_data_file = await promise_upload.wait_till_fulfilled()
	if promise_upload.is_error():
		Notify.error(tr("File Upload Error"), promise_upload.get_error_message())
	res_promise.set_result(asset_data_file)
	set_shader_param(type, asset_data_file.get("_id"))
	return res_promise


func _upload_async_textures(mat: BaseMaterial3D, promise: Promise, blacklist: Array) -> void:
	# setup material preview for local user
	for texture_basematerial in _pbr_to_mirror_convert:
		var tex = mat[texture_basematerial]
		var mirror_mat_prop = _pbr_to_mirror_convert[texture_basematerial]
		if tex == null or not tex is Texture2D or mirror_mat_prop in blacklist:
			continue
		set_shader_parameter(mirror_mat_prop, tex)

	# upload & setup textures parameters
	var queued_promises: Array[Promise] = []
	for texture_basematerial in _pbr_to_mirror_convert:
		var tex = mat[texture_basematerial]
		var mirror_mat_prop = _pbr_to_mirror_convert[texture_basematerial]
		if tex == null or not tex is Texture2D or mirror_mat_prop in blacklist:
			continue
		queued_promises.append(await _upload_texture_to_asset(mirror_mat_prop, tex))

	for queued_promise in queued_promises:
		await queued_promise.wait_till_fulfilled()
		if queued_promise.is_error() or not queued_promise.get_result().has("_id"):
			printerr("Error while moving texture: ", queued_promise)
			promise.set_error("Error while moving texture")
			return
	promise.set_result("")


func move_from_base_material(mat: BaseMaterial3D, blacklist: Array) -> Promise:
	var promise = Promise.new()
	#mappings without textures, that are special case
	var basematerial_mappings: Dictionary = {
		&"albedo": &"albedo_color",
		&"normal_scale": &"normal_scale",
		&"roughness": &"roughness",
		&"metallic": &"metallic",
		&"uv1_scale": &"uv1_scale",
		&"uv1_offset": &"uv1_offset",
		&"alpha_threshold": &"alpha_scissor_threshold",
		&"triplanar": &"uv1_triplanar",
	}
	var material_type = SHADER_TYPE.STANDARD
	match mat.transparency:
		BaseMaterial3D.TRANSPARENCY_ALPHA:
			material_type = SHADER_TYPE.GLASS
		BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
			material_type = SHADER_TYPE.OPACITY_MASKED

	var asset_data: Dictionary = {
		"materialType": material_type,
		"parameters": {},
	}
	setup(asset_data)
	for param in basematerial_mappings:
		if param in blacklist:
			continue
		var base_mat_param = basematerial_mappings[param]
		set_shader_param(param, mat[base_mat_param])
	_upload_async_textures(mat,promise, blacklist)
	return promise



func move_from(original: MirrorMaterial) -> void:
	var asset_data: Dictionary = {
		"materialType": original._current_shader_type,
		"code": original.shader.code,
		"parameters": {},
	}
	setup(asset_data)
	for param in original._local_parameters_cache:
		set_shader_param(param, original._local_parameters_cache[param])


func setup(asset_data: Dictionary) -> void:
	if not asset_data.has("materialType"):
		await from_pbr(asset_data)
		return
	_current_shader_type = asset_data.get("materialType")
	match _current_shader_type:
		SHADER_TYPE.OPACITY_MASKED:
			shader = _OPACITY_MASKED_SHADER
		SHADER_TYPE.DISPLACED:
			shader = _DISPLACED_SHADER
		SHADER_TYPE.GLASS:
			shader = _GLASS_SHADER
		SHADER_TYPE.VARNISH:
			shader = _VARNISH_SHADER
		SHADER_TYPE.WATER:
			shader = _WATER_SHADER
			_setup_water_shader()
		SHADER_TYPE.CUSTOM_SHADER:
			update_code(asset_data.get("code", _CUSTOM_SHADER_TEMPLATE.code))
		SHADER_TYPE.STANDARD, _:
			shader = _STANDARD_SHADER

	_setup_properties(asset_data.get("parameters", {}))



func _setup_pbr_texture(asset_data: AssetDataTexture, shader_prop: String) -> void:
	var preview_url = asset_data.thumbnail_url
	if not preview_url.is_empty():
		var preview_promise: Promise = Net.file_client.get_file(preview_url)
		var preview_image = await preview_promise.wait_till_fulfilled()
		if not preview_promise.is_error():
			# set preview only if success but do not exit early otherwise
			set_shader_parameter(shader_prop, preview_image)
	var promise: Promise = Net.file_client.get_file(asset_data.file_url)
	var image = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Failure loading image from url: %s" %asset_data.file_url)
	else:
		set_shader_parameter(shader_prop, image)
		if shader_prop == "texture_metallic":
			set_shader_parameter("metallic", 1.0)


## Compatibilty mode with old format
func from_pbr(material_asset_dict: Dictionary) -> void:
	is_pbr_compatiblity = true
	pbr_asset_data_promise = Promise.new()
	shader = _STANDARD_SHADER
	_current_shader_type = SHADER_TYPE.STANDARD

	for asset_id in material_asset_dict.get("textures", []):
		var asset_dict = Net.asset_client.get_asset_json(asset_id)
		if asset_dict.is_empty():
			var ad_promise = Net.asset_client.queue_download_asset(asset_id)
			asset_dict = await ad_promise.wait_till_fulfilled()
			if ad_promise.is_error():
				print("Failure loading asset_data for asset_id: %s" % asset_id)
				continue
		var asset_data = AssetDataTexture.new()
		asset_data.populate(asset_dict)
		var shader_prop = _pbr_to_mirror_convert.get(asset_data.texture_property_applies_to)
		if shader_prop == null:
			continue
		if _local_parameters_cache.get(shader_prop) != asset_id:
			_local_parameters_cache[shader_prop] = asset_id
			parameter_changed.emit(shader_prop, asset_id)
		_setup_pbr_texture(asset_data, shader_prop)
	pbr_asset_data_promise.set_result(true)


func update_code(code: String) -> void:
	if feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER):
		if shader != null and shader.code == code:
			return
		shader = Shader.new()
		shader.code = code
		shader_code_changed.emit(code)


func serialize() -> Dictionary:
	var dict: Dictionary = {
		"materialType": _current_shader_type,
		"externalAssetIds": []
	}
	if not id.is_empty():
		dict["_id"] = id
	if not instance_name.is_empty():
		dict["name"] = instance_name
	var remote_parameters = {}
	for x in _local_parameters_cache:
		var value = _local_parameters_cache[x]
		if value is String or value is StringName:
			if (allow_local and FileAccess.file_exists(value)):
				continue # Do not store local files values
			dict["externalAssetIds"].append(value)
		remote_parameters[x] = Serialization.type_convert_to_json(value)
	dict["parameters"] =  remote_parameters
	if feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER):
		dict["code"] = shader.code
	return dict


func override_shader_type(type: String) -> void:
	_current_shader_type = type
