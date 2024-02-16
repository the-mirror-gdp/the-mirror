extends MarginContainer


signal material_created(type: String, material_id: String)

const _TMP_NORMALMAP_FILENAME = "tmp_gen_normalmap.webp"


@export var _texture_inspector_template: PackedScene
@export var _float_template: PackedScene
@export var _vec2_template: PackedScene
@export var _vec3_template: PackedScene
@export var _color_template: PackedScene


@onready var _material_template_list = $MaterialTemplateList
@onready var _property_list = $PropertyList

@onready var _albedo_color = $PropertyList/AlbedoColor
@onready var _albedo_texture = $PropertyList/HBoxContainer/VBoxContainer/AlbedoTexture
@onready var _albedo_mix = $PropertyList/HBoxContainer/VBoxContainer/InspectorNumberSlider
@onready var _normal_texture = $PropertyList/NormalTexture/InspectorPropertyTexture
@onready var _normal_scale = $PropertyList/NormalTexture/InspectorPropertyTexture/HBoxContainer/InspectorNumberSlider
@onready var _normal_invert = $PropertyList/NormalTexture/InspectorPropertyTexture/HBoxContainer/InspectorNumberSlider/InvertButton
@onready var _roughness_texture = $PropertyList/RoughnessTexture/InspectorPropertyTexture
@onready var _roughness_scale = $PropertyList/RoughnessTexture/InspectorPropertyTexture/HBoxContainer/InspectorNumberSlider
@onready var _metallic_texture = $PropertyList/MetallicTexture/InspectorPropertyTexture
@onready var _metallic_scale = $PropertyList/MetallicTexture/InspectorPropertyTexture/HBoxContainer/InspectorNumberSlider
@onready var _depth_texture = $PropertyList/DepthTexture/InspectorPropertyTexture
@onready var _depth_scale = $PropertyList/DepthTexture/InspectorPropertyTexture/HBoxContainer/InspectorNumberSlider
@onready var _uv_scale = $PropertyList/UVSection/VBoxContainer/UVScale
@onready var _uv_offset = $PropertyList/UVSection/VBoxContainer/UVOffset
@onready var _alpha_threshold_slider = $PropertyList/HBoxContainer/VBoxContainer/AlphaThresholdSlider
@onready var _triplanar = $PropertyList/UVSection/VBoxContainer/Triplanar
@onready var _refraction = $PropertyList/Refraction
@onready var _emission_texture = $PropertyList/EmissionTexture/InspectorPropertyTexture
@onready var _wave_stormy = $PropertyList/WaveStormy
@onready var _beers_value = $PropertyList/BeersValue
@onready var _albedo_2_color = $PropertyList/Albedo2Color
@onready var _uv_section = $PropertyList/UVSection
@onready var _uv_label_holder = $PropertyList/UVLabelHolder
@onready var _shader_button = $PropertyList/ShaderButton
@onready var _shader_update_delay = $PropertyList/ShaderButton/ShaderUpdateDelay
@onready var _custom_shader_parameters = $PropertyList/CustomShaderParameters
@onready var _convert_button = $PropertyList/ConvertButton
@onready var _change_type_button = $PropertyList/ChangeTypeButton
@onready var _custom_shader_properties_update_delay = $CustomShaderPropertiesUpdateDelay
@onready var _name = $PropertyList/Name
@onready var _parameter_update_delay: Timer = $ParameterUpdateDelay

@onready var _asset_preview = $AssetPreview

@onready var _inspector_mapping: Dictionary = {
	_normal_texture:  &"texture_normal",
	_albedo_color:  &"albedo",
	_albedo_texture: &"texture_albedo",
	_albedo_mix: &"albedo_mix",
	_normal_scale: &"normal_scale",
	_roughness_texture: &"texture_roughness",
	_roughness_scale: &"roughness",
	_metallic_texture: &"texture_metallic",
	_metallic_scale: &"metallic",
	_uv_scale: &"uv1_scale",
	_uv_offset: &"uv1_offset",
	_alpha_threshold_slider: &"alpha_threshold",
	_triplanar: &"triplanar",
	_refraction: &"refraction",
	_emission_texture: &"emission",
	_depth_texture: &"texture_heightmap",
	_depth_scale: &"heightmap_scale",
	_wave_stormy: &"stormy",
	_beers_value: &"beers_value",
	_albedo_2_color: &"albedo_shallow"
}


var target_material: MirrorMaterial = null
var _original_mesh_material: BaseMaterial3D = null
var _edited_space_object: SpaceObject = null
var _edited_mesh_instance: MeshInstance3D = null
var _edited_surface: int = -1


func setup_mesh_target(space_object: SpaceObject, mi: MeshInstance3D, surface_id: int) -> void:
	_edited_space_object = space_object
	_edited_mesh_instance = mi
	_edited_surface = surface_id
	var material =  mi.get_active_material(surface_id)
	var org_material = mi.mesh.surface_get_material(surface_id)
	if material == target_material:
		return
	if target_material is MirrorMaterial: # disconnect from old material
		Util.safe_signal_disconnect(target_material.parameter_changed, _update_control)
		Util.safe_signal_disconnect(target_material.shader_code_changed, _update_code)
	if material is MirrorMaterial:
		target_material = material
		_original_mesh_material = null
		_reload_shader_data()
		Util.safe_signal_connect(target_material.parameter_changed, _update_control)
		Util.safe_signal_connect(target_material.shader_code_changed, _update_code)
		_material_template_list.visible = false

	elif material == org_material and material is BaseMaterial3D:
		target_material = null
		_reload_from_pbr_data(material)
		_material_template_list.visible = false
		_original_mesh_material = org_material
	else:
		_reset_values()
		target_material = null
		_material_template_list.visible = true
		_original_mesh_material = null
	_property_list.visible = not _material_template_list.visible


func _ready() -> void:
	_refresh_bindings()
	_material_template_list.visible = true
	_property_list.visible = false


func _reset_values() -> void:
	for control in _inspector_mapping:
			control.current_value = control.reset_value


func _update_controls_by_shader_features(material: MirrorMaterial) -> void:
	_alpha_threshold_slider.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.ALPHA_MASKED)
	_triplanar.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.TRIPLANAR)
	_refraction.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.REFRACTION)
	_albedo_texture.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.PBR_TEXTURES)
	_albedo_mix.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.PBR_TEXTURES)
	_normal_texture.get_parent().visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.PBR_TEXTURES)
	_roughness_texture.get_parent().visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.PBR_TEXTURES)
	_metallic_texture.get_parent().visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.PBR_TEXTURES)
	_emission_texture.get_parent().visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.EMISSION)
	_depth_texture.get_parent().visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.POM)
	_uv_section.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.UV_EDITING)
	_uv_label_holder.visible = _uv_section.visible
	_shader_button.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER)
	_wave_stormy.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.WATER_SETTINGS)
	_beers_value.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.WATER_SETTINGS)
	_albedo_2_color.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.WATER_SETTINGS)
	_custom_shader_parameters.visible = material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER)
	_change_type_button.button_text = material.get_material_type_name()
	_name.visible = not material.is_asset_based



func _reload_from_pbr_data(original_material: BaseMaterial3D) -> void:
	var pbr_inspector_mappings: Dictionary = {
		_normal_texture:  &"normal_texture",
		_albedo_color:  &"albedo_color",
		_albedo_texture: &"albedo_texture",
		_normal_scale: &"normal_scale",
		_roughness_texture: &"roughness_texture",
		_roughness_scale: &"roughness",
		_metallic_texture: &"metallic_texture",
		_metallic_scale: &"metallic",
		_uv_scale: &"uv1_scale",
		_uv_offset: &"uv1_offset",
		_alpha_threshold_slider: &"alpha_scissor_threshold",
		_triplanar: &"uv1_triplanar",
		_emission_texture: &"emission_texture",
	}
	_clear_bindings()
	for control in pbr_inspector_mappings:
		var mat_param = pbr_inspector_mappings[control]
		var value = original_material[mat_param]
		if control.has_method("setup_from_vector3"):
			control.setup_from_vector3(value)
		if "drop_area" in control:
			control.current_value = ""
			control.drop_area.set_preview(value)
		else:
			control.current_value = value
		if control.has_method("refresh"):
			control.refresh()

	# This will make editor show all standard material controls
	var dummy_mat = MirrorMaterial.new()
	dummy_mat.override_shader_type(MirrorMaterial.SHADER_TYPE.STANDARD)
	_update_controls_by_shader_features(dummy_mat)
	_change_type_button.button_text = tr("original")
	_convert_button.visible = false
	_change_type_button.visible = true
	_refresh_bindings()


func _reload_shader_data() -> void:
	if not is_instance_valid(target_material):
		return
	_clear_bindings()
	for control in _inspector_mapping:
		if not target_material.has_parameter_in_cache(_inspector_mapping[control]):
			control.current_value = control.reset_value
			continue
		var value =  target_material.get_parameter_from_cache(_inspector_mapping[control])
		if control.has_method("setup_from_vector3"):
			control.setup_from_vector3(value)
		else:
			control.current_value = value
		if control.has_method("refresh"):
			control.refresh()
	if target_material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER):
		_update_code(target_material.shader.code)
	_update_controls_by_shader_features(target_material)
	_convert_button.visible = not target_material.is_asset_based
	_change_type_button.visible = true
	_name.current_value = target_material.instance_name
	_refresh_bindings()


func _unbind_inspector_parameter(control: Control, shader_parameter: String) -> void:
	Util.safe_signal_disconnect(control.value_changed, _update_material_param.bind(shader_parameter))
	if control.has_signal(&"value_preview"):
		Util.safe_signal_disconnect(control.value_preview, _update_material_param.bind(shader_parameter))


func _clear_bindings() -> void:
	Util.safe_signal_disconnect(_shader_button.value_changed, _on_shader_button_value_changed)
	for control in _inspector_mapping:
		_unbind_inspector_parameter(control, _inspector_mapping[control])


func _bind_inspector_parameter(control: Control, shader_parameter: String) -> void:
	Util.safe_signal_connect(control.value_changed, _update_material_param.bind(shader_parameter))
	if control.has_signal(&"value_preview"):
		Util.safe_signal_connect(control.value_preview, _update_material_param.bind(shader_parameter))


func _refresh_bindings() -> void:
	for control in _inspector_mapping:
		_bind_inspector_parameter(control, _inspector_mapping[control])
	Util.safe_signal_connect(_shader_button.value_changed, _on_shader_button_value_changed)


func _update_material_param(value: Variant, parameter: String) -> void:
	if is_instance_valid(_original_mesh_material):
		await create_instance_from_base_material({parameter: value})
	if not is_instance_valid(target_material):
		return
	if (
			target_material.has_parameter_in_cache(parameter)
			and target_material.get_parameter_from_cache(parameter) == value
	):
		return
	target_material.set_shader_param(parameter, value)
	if target_material.is_asset_based:
		await create_instance_from_asset()

	Util.safe_signal_connect(_parameter_update_delay.timeout, _on_parameter_update_delay_timeout.bind(target_material), CONNECT_ONE_SHOT)
	_parameter_update_delay.start()


func _update_control(parameter: String, value: Variant) -> void:
	for control in _inspector_mapping:
		if _inspector_mapping[control] == parameter:
			control.current_value = value


func _update_code(code: String) -> void:
	_shader_button.current_value = code
	# reload shader values, use a timeout to avoid multiple node tree changes in single frame
	# this issue is obvious for example when loading a secene
	_custom_shader_properties_update_delay.start()



func create_instance_from_base_material(override: Dictionary) -> void:
	if not is_instance_valid(_original_mesh_material) or is_instance_valid(target_material):
		return
	# make copies before await so we are sure that we assign correct mesh
	var mi_ref = weakref(_edited_mesh_instance)
	var edited_surface_copy = _edited_surface
	var id = await Zone.material_manager.create_instance_from_base_material(_original_mesh_material, override, _edited_space_object, _edited_mesh_instance, _edited_surface)
	if mi_ref.get_ref() == null or mi_ref.get_ref() != _edited_mesh_instance or edited_surface_copy != _edited_surface:
		return # user selected different material, ignore updates
	var current_material = _edited_mesh_instance.get_active_material(edited_surface_copy)
	if not current_material is MirrorMaterial:
		assert(not current_material is MirrorMaterial)
		printerr("Current material is not a Mirror material")
		return
	target_material = current_material
	_original_mesh_material = null
	_reload_shader_data()
	target_material.parameter_changed.connect(_update_control)
	target_material.shader_code_changed.connect(_update_code)
	_reload_shader_data()
	material_created.emit(Enums.MATERIAL_TYPE.INSTANCE, id)


func create_instance_from_asset() -> void:
	if target_material == null:
		return
	var current_target = target_material
	target_material = MirrorMaterial.new()
	target_material.parameter_changed.connect(_update_control)
	target_material.shader_code_changed.connect(_update_code)
	target_material.allow_local = true
	target_material.is_asset_based = false
	target_material.move_from(current_target)
	var promise = Zone.material_manager.create_material_instance(target_material)
	# TODO: lock inspector
	var data = await promise.wait_till_fulfilled()
	# wait one frame to be sure that all callbacks on instance material created are executed
	await get_tree().process_frame
	# TODO: unlock inspector
	if is_instance_valid(_edited_mesh_instance):
		_edited_space_object.set_surface_material(_edited_mesh_instance, _edited_surface, data["_id"], false)
	_reload_shader_data()
	material_created.emit(Enums.MATERIAL_TYPE.INSTANCE, data["_id"])


func _migrate_to_texture(asset_id: String, param_name: String) -> bool:
	if asset_id.is_empty():
		return false
	var promise = Net.asset_client.queue_download_asset(asset_id)
	# Make it a Callable to utilize concurrency
	var asset = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Material Upload Error - Texture conversion", promise.get_error_message())
		return false
	if asset.assetType == Enums.ASSET_TYPE.TEXTURE:
		return true # It's already a texture
	var asset_data: Dictionary = {
		"name": asset.name,
		"assetType": "TEXTURE",
		"textureImagePropertyAppliesTo": param_name,
		"__t": "Texture",
		# This will reuse the same url as original asset
		"thumbnail": asset.get("thumnail", ""),
		"currentFile": asset.get("currentFile", ""),
	}
	var promise2: Promise = Net.asset_client.create_asset(asset_data)
	var asset_dict = await promise2.wait_till_fulfilled()
	if promise2.is_error():
		Notify.error("Material Upload Error - Texture Re-Upload", promise2.get_error_message())
		return false
	target_material.set_shader_param(param_name, asset_dict.get("_id"))
	return true


func _generate_instance_preview(material: MirrorMaterial) -> Image:
	_asset_preview.position.x = -1000
	_asset_preview.position.y = -1000
	_asset_preview.size = Vector2(300, 300)
	var _preview_node = MeshInstance3D.new()
	_preview_node.mesh = SphereMesh.new()
	_preview_node.material_override = material
	_asset_preview.add_asset(_preview_node)
	var image = await _asset_preview.render_to_image()
	_preview_node.queue_free()
	return image


func create_asset_from_instance() -> void:
	if target_material == null or target_material.is_asset_based:
		return
	_convert_button.enabled = false

	var asset_data: Dictionary = {
		"name": target_material.instance_name,
		"assetType": "MATERIAL",
		"__t": "Material"
	}
	var serialized = target_material.serialize()
	# Replace IMAGE assets with TEXTURE assets, so users will not see them and not delete
	for param in serialized.parameters:
		if not serialized.parameters[param] is String:
			continue
		var conversion_status = await _migrate_to_texture(serialized.parameters[param], param)
		if not conversion_status:
			_convert_button.enabled = true
			return
	# Serialiaze again after conversion
	serialized = target_material.serialize()
	# Remove data that relates to instance
	serialized.erase("name")
	serialized.erase("_id")

	asset_data.merge(serialized)

	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)
	var promise: Promise = Net.asset_client.create_asset(asset_data)
	var new_asset = await promise.wait_till_fulfilled()
	_convert_button.enabled = true
	if promise.is_error():
		print("Error:", promise.get_error_message())
		Notify.error(tr("Material Asset Save Error"), promise.get_error_message())
		return
	target_material.is_asset_based = true
	var asset_id = new_asset.get("_id")
	target_material.resource_name = asset_id

	Zone.material_manager.replace_material_references(Enums.MATERIAL_TYPE.INSTANCE, target_material.id, Enums.MATERIAL_TYPE.ASSET, asset_id)
	target_material.id = ""

	# Generate thumbnail and upload to asset
	var image = await _generate_instance_preview(target_material)
	var bytes = image.save_webp_to_buffer(true)
	var promise_thb = Net.asset_client.upload_asset_thumb(asset_id, bytes)
	promise_thb.connect_func_to_fulfill(func():
		if promise_thb.is_error():
			print("Error during uploading a preview texture: ", promise_thb.get_error_message())
	)
	material_created.emit(Enums.MATERIAL_TYPE.ASSET, asset_id)


func create_new_material(template: String) -> void:
	target_material = MirrorMaterial.new()
	target_material.parameter_changed.connect(_update_control)
	target_material.shader_code_changed.connect(_update_code)
	target_material.allow_local = true
	target_material.is_asset_based = false
	target_material.setup({"materialType": template, "parameters": {}})
	var promise = Zone.material_manager.create_material_instance(target_material)
	# TODO: lock inspector
	var data = await promise.wait_till_fulfilled()
	# wait one frame to be sure that all callbacks on instance material created are executed
	await get_tree().process_frame
	# TODO: unlock inspector
	if is_instance_valid(_edited_mesh_instance):
		await _edited_space_object.set_surface_material(_edited_mesh_instance, _edited_surface, data["_id"], false)
	_reload_shader_data()
	material_created.emit(Enums.MATERIAL_TYPE.INSTANCE, data["_id"])


func _map_process(file_path: String, map_control: Control, process: Callable, tmp_file: String) -> void:
	# assume new value is an image path
	if not FileAccess.file_exists(file_path):
		return
	var image: Image = Image.new()
	if image.load(file_path) != OK:
		return
	if process.call(image) == false:
		return
	var save_path = Util.get_files_directory_path() + tmp_file
	if image.save_webp(save_path) != OK:
		return
	map_control.current_value = "" # Force clear
	map_control.current_value = save_path


func _generate_normalmap_from_albedomap(file_path):
	# assume new value is an image path
	_map_process(file_path, _normal_texture,(
		func(image):
			image.adjust_bcs(1, 1, 0)
			image.bump_map_to_normal_map(-4.0 if _normal_invert.button_pressed else 4.0)
			return true
	), _TMP_NORMALMAP_FILENAME)


func _on_albedo_texture_value_changed(new_value):
	var tmp_normalmap_filepath = Util.get_files_directory_path() + _TMP_NORMALMAP_FILENAME
	if not new_value.is_empty() and (_normal_texture.current_value.is_empty() or _normal_texture.current_value == tmp_normalmap_filepath):
		_generate_normalmap_from_albedomap(new_value)


func _on_normalmap_invert_button_toggled(button_pressed):
	var file_path = _normal_texture.current_value
	if file_path.is_empty():
		return
	_map_process(file_path, _normal_texture,(
		func(image):
			var img_size = image.get_size()
			for x in img_size.x:
				for y in img_size.y:
					var color = image.get_pixel(x,y)
					image.set_pixel(x,y, Color(color.r, 1.0 - color.g, color.b))
			return true
	), _TMP_NORMALMAP_FILENAME)


func _on_material_template_list_on_template_selected(template) -> void:
	create_new_material(template)
	_material_template_list.visible = false
	_property_list.visible = true


func _on_shader_button_value_changed(new_value) -> void:
	if not is_instance_valid(target_material) or not target_material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER):
		return
	_shader_update_delay.start()


func _on_shader_update_delay_timeout() -> void:
	if not is_instance_valid(target_material) or not target_material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER):
		return
	target_material.update_code(_shader_button.current_value)
	#_reload_custom_shader_controls()
	if not target_material.is_asset_based:
		Zone.material_manager.update_material_instance(target_material)


func _on_custom_shader_properties_update_delay_timeout() -> void:
	if not is_instance_valid(target_material):
		return
	var uniforms = target_material.shader.get_shader_uniform_list(true)
	#print(Engine.get_frames_drawn(), "is_asset: ", target_material.is_asset_based, " instance_name: ", target_material.instance_name)
	#print_stack()
	for child in _custom_shader_parameters.get_children():
		if not is_instance_valid(child):
			continue
		if child.has_method(&"cleanup_and_delete"):
			child.cleanup_and_delete()
		else:
			child.queue_free()
	for uniform in uniforms:
		var inspector_control: Control = null
		match uniform.type:
			TYPE_COLOR:
				inspector_control = _color_template.instantiate()
			TYPE_OBJECT:
				if not uniform.hint_string == "Texture2D":
					continue
				inspector_control = _texture_inspector_template.instantiate()
			TYPE_VECTOR2:
				inspector_control = _vec2_template.instantiate()
			TYPE_VECTOR3:
				inspector_control = _vec3_template.instantiate()
			TYPE_FLOAT:
				inspector_control = _float_template.instantiate()

		if inspector_control != null:
			inspector_control.label_text = uniform.name
			_custom_shader_parameters.add_child(inspector_control)
			if target_material.has_parameter_in_cache(uniform.name):
				inspector_control.current_value = target_material.get_parameter_from_cache(uniform.name)
				if inspector_control.has_method("refresh"):
					inspector_control.refresh()
			_bind_inspector_parameter(inspector_control, uniform.name)


func _on_change_type_button_inspector_button_pressed() -> void:
	_material_template_list.visible = true
	_property_list.visible = false


func _on_name_value_changed(new_value) -> void:
	if not is_instance_valid(target_material) or target_material.is_asset_based:
		return
	target_material.instance_name = new_value
	Zone.material_manager.update_material_instance(target_material)


func _on_parameter_update_delay_timeout(material: MirrorMaterial):
	Zone.material_manager.update_material_instance(material)
