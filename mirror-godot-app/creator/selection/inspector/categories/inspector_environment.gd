extends InspectorCategoryBase


const _ENVIRONMENTS_LIST: Dictionary = {
	"Procedural": {
		"environment": "procedural_sky",
		"features": []
	},
	"Cosmos": {
		"environment": "cosmos_sky",
		"features": []
	},
	"Physical": {
		"environment": "physical_sky",
		"features": ["physical"]
	},
	"Physical with Clouds": {
		"environment": "physical_clouds_sky",
		"features": ["clouds", "physical"]
	}
}

const _SHADOWS_LIST: Dictionary = {
	"disabled": "Disabled",
	"short": "Short distance, Highest Quality",
	"medium": "Medium distance, Medium Quality",
	"long": "Long distance, Lowest Quality"
}

const _TONEMAP_LIST: Dictionary = {
	"ACES": Environment.TONE_MAPPER_ACES,
	"Filmic": Environment.TONE_MAPPER_FILMIC,
	"Reinhard": Environment.TONE_MAPPER_REINHARDT,
	"Linear": Environment.TONE_MAPPER_LINEAR
}

var target_node: WorldEnvironment

var _environment: Environment
var _sky_material: Material

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _sky_property_list = _property_list.get_node(^"SkySubset/PropertyList")
@onready var _sky_top_color = _sky_property_list.get_node(^"SkyTopColor") # Zenith
@onready var _sky_horizon_color = _sky_property_list.get_node(^"SkyHorizonColor")
@onready var _sky_bottom_color = _sky_property_list.get_node(^"SkyBottomColor") # Nadir
@onready var _sun_count_slider = _sky_property_list.get_node(^"SunCountSlider")
@onready var _fog_checkbox = _property_list.get_node(^"FogCheckbox")
@onready var _fog_subset = _property_list.get_node(^"FogSubset")
@onready var _fog_property_list = _fog_subset.get_node(^"PropertyList")
@onready var _fog_volumetric_checkbox = _fog_property_list.get_node(^"VolumetricCheckbox")
@onready var _fog_density_slider = _fog_property_list.get_node(^"FogDensitySlider")
@onready var _fog_albedo_color = _fog_property_list.get_node(^"FogAlbedoColor")
@onready var _global_illumination_checkbox = _property_list.get_node(^"GlobalIllumination")
@onready var _environment_style_dropdown = _property_list.get_node(^"EnvironmentStyleDropdown")
@onready var _clouds_subset = _property_list.get_node(^"CloudsSubset")
@onready var _cloud_property_list = _clouds_subset.get_node(^"PropertyList")
@onready var _clouds_coverage_slider = _cloud_property_list.get_node(^"CloudsCoverageSlider")
@onready var _clouds_height_slider = _cloud_property_list.get_node(^"CloudsHeightSlider")
@onready var _clouds_speed_slider = _cloud_property_list.get_node(^"CloudsSpeedSlider")
@onready var _clouds_albedo_color = _cloud_property_list.get_node(^"CloudsAlbedoColor")
@onready var _clouds_checkbox = _property_list.get_node(^"CloudsCheckbox")
@onready var _ssao_checkbox = _property_list.get_node(^"SsaoCheckbox")
@onready var _glow_checkbox = _property_list.get_node(^"GlowCheckbox")
@onready var _shadows_distance_dropdown = _property_list.get_node(^"ShadowsDistanceDropdown")
@onready var _glow_subset = _property_list.get_node(^"GlowSubset")
@onready var _glow_threshold_slider =  _property_list.get_node(^"GlowSubset/PropertyList/GlowThresholdSlider")
@onready var _tonemap_dropdown = _property_list.get_node(^"TonemapDropdown")
@onready var _ssr_checkbox = _property_list.get_node(^"SSRCheckbox")


func _ready():
	_setup_world_environment()
	_load_environment_list()
	_load_shadows_list()
	_load_tonemap_list()
	refresh()
	if target_node.has_method(&"request_change"):
		inspected_object_updated.connect(target_node.request_change)
		target_node.environment_updated_from_dictionary.connect(refresh)
	super()


func _load_environment_list():
	for style_name in _ENVIRONMENTS_LIST:
		_environment_style_dropdown.add_item(style_name)


func _load_shadows_list():
	for shadow_setting in _SHADOWS_LIST:
		_shadows_distance_dropdown.add_item(_SHADOWS_LIST[shadow_setting])


func _load_tonemap_list():
	for tonemap in _TONEMAP_LIST:
		_tonemap_dropdown.add_item(tonemap)


func _check_feature_support(feature_name: String) -> bool:
	var style_name = _environment_style_dropdown.values[_environment_style_dropdown.current_value]
	return _ENVIRONMENTS_LIST.get(style_name, {}).get("features", []).has(feature_name)


func _setup_world_environment():
	if target_node.environment == null:
		target_node.environment = Environment.new()
	_environment = target_node.environment
	if _environment.sky == null:
		_environment.sky = Sky.new()
	if (
			_environment.sky.sky_material == null
			or not (
					_environment.sky.sky_material is ProceduralSkyMaterial
					or _environment.sky.sky_material is ShaderMaterial
			)
	):
		_environment.sky.sky_material = ProceduralSkyMaterial.new()
	_sky_material = _environment.sky.sky_material


func _count_suns(target_node):
	var count = 0
	for child in target_node.get_children():
		if not child is DirectionalLight3D:
			continue
		count += 1
	return count


func _update_environment_style_selection():
	var env_name = target_node.get_environment_name()
	var index = 0
	for env in _ENVIRONMENTS_LIST:
		if env_name == _ENVIRONMENTS_LIST[env].get("environment"):
			_environment_style_dropdown.current_value = index
			break
		index += 1


func _update_shadows_selection():
	var shadows_preset = target_node.shadows_preset
	var index = 0
	for preset in _SHADOWS_LIST:
		if shadows_preset == preset:
			_shadows_distance_dropdown.current_value = index
			break
		index += 1


func _update_tonemap_selection():
	var index = 0
	for tonemap in _TONEMAP_LIST:
		if _environment.tonemap_mode == _TONEMAP_LIST[tonemap]:
			_tonemap_dropdown.current_value = index
			break
		index += 1


func refresh():
	update_active_fields_by_permissions()
	_update_environment_style_selection()
	_update_shadows_selection()
	_update_tonemap_selection()
	if _sky_material is ProceduralSkyMaterial:
		_sky_top_color.current_value = _sky_material.sky_top_color
		_sky_horizon_color.current_value = _sky_material.sky_horizon_color
		_sky_bottom_color.current_value = _sky_material.ground_bottom_color
	elif _sky_material is ShaderMaterial:
		_sky_top_color.current_value = Color(_sky_material.get_shader_parameter("sky_top_color"))
		_sky_horizon_color.current_value = Color(_sky_material.get_shader_parameter("sky_horizon_color"))
		_sky_bottom_color.current_value = Color(_sky_material.get_shader_parameter("sky_bottom_color"))
	var clouds_physical_units = _check_feature_support("physical")
	if clouds_physical_units:
		_sky_top_color.label_text = tr("Rayleigh (Sky Color)")
		_sky_horizon_color.label_text = tr("Mie (Sun Color)")
		_sky_bottom_color.label_text = tr("Ground Color")
	else:
		_sky_top_color.label_text = tr("Sky Top Color")
		_sky_horizon_color.label_text = tr("Sky Horizon Color")
		_sky_bottom_color.label_text = tr("Sky Bottom Color")
	_fog_volumetric_checkbox.current_value = _environment.volumetric_fog_enabled
	_fog_checkbox.current_value = _environment.fog_enabled or _environment.volumetric_fog_enabled
	_fog_subset.visible = _fog_checkbox.current_value
	_fog_density_slider.current_value = _environment.volumetric_fog_density
	_fog_density_slider.refresh()
	_fog_albedo_color.current_value = _environment.volumetric_fog_albedo
	_global_illumination_checkbox.current_value = _environment.sdfgi_enabled
	_ssao_checkbox.current_value = _environment.ssao_enabled
	_ssr_checkbox.current_value = _environment.ssr_enabled
	_glow_checkbox.current_value = _environment.glow_enabled
	_glow_subset.visible = _glow_checkbox.current_value
	_glow_threshold_slider.current_value = _environment.glow_hdr_threshold
	_glow_threshold_slider.refresh()
	_sun_count_slider.current_value = _count_suns(target_node)
	_sun_count_slider.refresh()

	_clouds_coverage_slider.current_value = target_node.get_clouds_shader_value("cloud_coverage")
	_clouds_coverage_slider.refresh()
	_clouds_height_slider.current_value = target_node.get_clouds_shader_value("height_offset")
	_clouds_height_slider.refresh()
	_clouds_speed_slider.current_value = target_node.get_clouds_shader_value("_time_scale")
	_clouds_speed_slider.refresh()
	_clouds_albedo_color.current_value = target_node.get_clouds_shader_value("albedo")
	var clouds_in_sky = _check_feature_support("clouds")
	_clouds_height_slider.visible = not clouds_in_sky
	_clouds_albedo_color.visible = not clouds_in_sky # TDOO: albedo makes sense, but needs research
	_clouds_checkbox.current_value = (_fog_volumetric_checkbox.current_value and target_node.clouds_enabled()) or clouds_in_sky
	target_node.set_clouds_enabled(_clouds_checkbox.current_value and not clouds_in_sky)
	_clouds_subset.visible = _clouds_checkbox.current_value
	_clouds_checkbox.enabled = not clouds_in_sky and _fog_volumetric_checkbox.current_value
	_clouds_checkbox.visible = _clouds_subset.visible
	_shadows_distance_dropdown.select_index_no_signal(target_node.get_shadow_preset_index())


func _on_sky_top_color_value_changed(new_color):
	if _sky_material is ProceduralSkyMaterial:
		_sky_material.sky_top_color = new_color
	elif _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("sky_top_color", new_color)
	_inspected_object_updated(target_node)


func _on_sky_horizon_color_value_changed(new_color):
	if _sky_material is ProceduralSkyMaterial:
		_sky_material.sky_horizon_color = new_color
		_sky_material.ground_horizon_color = new_color
	elif _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("sky_horizon_color", new_color)
		_sky_material.set_shader_parameter("ground_horizon_color", new_color)
	_inspected_object_updated(target_node)


func _on_sky_bottom_color_value_changed(new_color):
	if _sky_material is ProceduralSkyMaterial:
		_sky_material.ground_bottom_color = new_color
	elif _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("sky_bottom_color", new_color)
	_inspected_object_updated(target_node)


func _on_sun_count_slider_value_changed(sun_count: int) -> void:
	target_node.set_sun_count(sun_count)
	_inspected_object_updated(target_node)
	refresh_inspected_nodes.emit()


func _on_fog_checkbox_value_changed(new_value):
	_fog_subset.visible = new_value
	if new_value:
		_environment.volumetric_fog_enabled = _fog_volumetric_checkbox.current_value
		_environment.fog_enabled = not _fog_volumetric_checkbox.current_value
	else:
		_environment.volumetric_fog_enabled = false
		_environment.fog_enabled = false
	_inspected_object_updated(target_node)


func _on_volumetric_checkbox_value_changed(new_value):
	if not _fog_checkbox.current_value:
		return
	_environment.volumetric_fog_enabled = new_value
	_environment.fog_enabled = not new_value
	_inspected_object_updated(target_node)


func _on_fog_density_slider_value_changed(new_value):
	_environment.fog_density = new_value * 0.5
	_environment.volumetric_fog_density = new_value
	_inspected_object_updated(target_node)


func _on_fog_albedo_color_value_changed(new_color):
	_environment.fog_light_color = new_color
	_environment.volumetric_fog_albedo = new_color
	_environment.volumetric_fog_emission = new_color
	_inspected_object_updated(target_node)


func _on_global_illumination_value_changed(new_value):
	_environment.sdfgi_enabled = false if Util.is_vr_enabled() else new_value
	_inspected_object_updated(target_node)


func _on_environment_style_dropdown_value_changed(new_index):
	var style_name = _environment_style_dropdown.values[new_index]
	if _ENVIRONMENTS_LIST.has(style_name):
		target_node.load_environment(_ENVIRONMENTS_LIST.get(style_name).get("environment"))
		_setup_world_environment()
	else:
		#target_node.environment = Environment.new()
		printerr("Error: Unknow Environment Style selected!")
	_inspected_object_updated(target_node)
	refresh()


func _on_clouds_coverage_slider_value_changed(new_value) -> void:
	target_node.set_clouds_shader_value("cloud_coverage", new_value)
	if _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("cloud_coverage", new_value)
	_inspected_object_updated(target_node)


func _on_clouds_height_slider_value_changed(new_value) -> void:
	target_node.set_clouds_shader_value("height_offset", new_value)
	_inspected_object_updated(target_node)


func _on_clouds_speedt_slider_value_changed(new_value):
	target_node.set_clouds_shader_value("_time_scale", new_value)
	if _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("_time_scale", new_value)
	_inspected_object_updated(target_node)


func _on_clouds_albedo_color_value_changed(new_value):
	target_node.set_clouds_shader_value("albedo", new_value)
	if _sky_material is ShaderMaterial:
		_sky_material.set_shader_parameter("clouds_color", new_value)
	_inspected_object_updated(target_node)


func _on_clouds_checkbox_value_changed(new_value):
	_clouds_subset.visible = new_value
	if _check_feature_support("clouds"):
		# do not show fog clounds if sky shader is already provinding clouds
		target_node.set_clouds_enabled(false)
	else:
		target_node.set_clouds_enabled(new_value)
	_inspected_object_updated(target_node)


func _on_glow_checkbox_value_changed(new_value):
	_environment.glow_enabled = false if Util.is_vr_enabled() else new_value
	_inspected_object_updated(target_node)


func _on_ssao_checkbox_value_changed(new_value):
	_environment.ssao_enabled = false if Util.is_vr_enabled() else new_value
	_inspected_object_updated(target_node)


func _on_glow_threshold_slider_value_changed(new_value):
	_environment.glow_hdr_threshold = new_value
	_inspected_object_updated(target_node)


func _on_shadows_distance_dropdown_value_changed(new_index):
	var value = _shadows_distance_dropdown.values[new_index]
	for preset in _SHADOWS_LIST:
		if _SHADOWS_LIST[preset] == value:
			target_node.shadows_preset = preset
			_inspected_object_updated(target_node)


func _on_tonemap_dropdown_value_changed(new_index):
	var value = _tonemap_dropdown.values[new_index]
	var tonemap_enum = _TONEMAP_LIST[value]
	_environment.tonemap_mode = tonemap_enum
	_inspected_object_updated(target_node)


func _on_ssr_value_changed(new_value):
	_environment.ssr_enabled = false if Util.is_vr_enabled() else new_value
	_inspected_object_updated(target_node)
