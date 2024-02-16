class_name SpaceEnvironment
extends WorldEnvironment


signal environment_updated_from_dictionary()

# We are using preload here, we can't dynamically load using file_name - bug in Compute Shader
const _ENVIRONMENTS_LIST: Dictionary = {
	# filename : preload(file_path)
	"procedural_sky": preload("res://art/environments/procedural_sky.tres"),
	"cosmos_sky": preload("res://art/environments/cosmos_sky.tres"),
	"physical_sky": preload("res://art/environments/physical_sky.tres"),
	"physical_clouds_sky": preload("res://art/environments/physical_clouds_sky.tres"),
}

const _SHADOWS_SETTING_MAPPINGS: Dictionary = {
	"disabled": {
		"enabled": false,
		"max_distance": 100,
		"blur": 1.0
	},
	"short": {
		"enabled": true,
		"max_distance": 100,
		"blur": 1.0
	},
	"medium": {
		"enabled": true,
		"max_distance": 250,
		"blur": 0.5
	},
	"long": {
		"enabled": true,
		"max_distance": 500,
		"blur": 0.4
	},
}

# Constant, except Godot doesn't allow this to be a compile-time constant :(
var _DEFAULT_SUN_ROTATION_BASIS = Basis.from_euler(Vector3(-TAU / 6.0, -TAU / 12.0, 0.0))

var shadows_preset: String = "medium":
	set(value):
		shadows_preset = value
		_update_shadows_settings(shadows_preset)

var _dict_cached_data: Dictionary = {}
var _sky: Material

@onready var _clouds = TMNodeUtil.recursive_get_node_by_type(self, FogVolume)


func _ready():
	_setup_world_environment()
	GameplaySettings.render_quality_changed.connect(_on_quality_settings_changed)


func load_environment(env_name: String) -> bool:
	if not _ENVIRONMENTS_LIST.has(env_name):
		return false
	self.environment = _ENVIRONMENTS_LIST[env_name]
	if not _dict_cached_data.is_empty():
		_setup_world_environment()
		_update_environment_settings(_dict_cached_data)
	return true


func get_environment_name() -> String:
	return environment.resource_path.get_file().trim_suffix(".tres")


func _on_quality_settings_changed(new_value: int) -> void:
	camera_attributes.dof_blur_far_enabled = not Util.is_vr_enabled() and GameplaySettings.render_profile.dof_enabled


func _setup_world_environment() -> void:
	if environment == null:
		environment = Environment.new()
	if environment.sky == null:
		environment.sky = Sky.new()
	if (
			environment.sky.sky_material == null
			or not (
					environment.sky.sky_material is ProceduralSkyMaterial
					or environment.sky.sky_material is ShaderMaterial
			)
	):
		environment.sky.sky_material = ProceduralSkyMaterial.new()
	_sky = environment.sky.sky_material

	camera_attributes.dof_blur_far_enabled = GameplaySettings.render_profile.dof_enabled
	if Util.is_vr_enabled():
		environment.ssao_enabled = false
		environment.ssil_enabled = false
		environment.sdfgi_enabled = false
		environment.ssr_enabled = false
		camera_attributes.dof_blur_far_enabled = false



func get_shadow_preset_index() -> int:
	if not _SHADOWS_SETTING_MAPPINGS.has(shadows_preset):
		return 2
	return _SHADOWS_SETTING_MAPPINGS.keys().find(shadows_preset)


func _update_shadows_settings(preset: String, suns_children: Array[Node] = []) -> void:
	if not _SHADOWS_SETTING_MAPPINGS.has(preset):
		preset = "medium"
	var shadow = _SHADOWS_SETTING_MAPPINGS[preset]
	if suns_children.is_empty():
		for child in get_children():
			if child is DirectionalLight3D:
				suns_children.append(child)
	for sun in suns_children:
		sun.directional_shadow_max_distance = shadow["max_distance"]
		sun.shadow_enabled = shadow["enabled"]
		sun.shadow_blur = shadow["blur"]


func _update_environment_settings(data: Dictionary) -> void:
	set_sky_color(
		_array_to_color(data["skyTopColor"]),
		_array_to_color(data["skyHorizonColor"]),
		_array_to_color(data["skyBottomColor"]))
	set_fog_properties(
		data["fogEnabled"],
		data["fogVolumetric"],
		data["fogDensity"],
		_array_to_color(data["fogColor"]))
	environment.sdfgi_enabled = false if Util.is_vr_enabled() else data["globalIllumination"]
	environment.ssao_enabled = false if Util.is_vr_enabled() else data.get("ssao", true)
	environment.glow_enabled = false if Util.is_vr_enabled() else data.get("glow", true)
	environment.ssr_enabled = false if Util.is_vr_enabled() else data.get("ssr", false)
	environment.glow_hdr_threshold = data.get("glowHdrThreshold", 1.0)
	environment.tonemap_mode = data.get("tonemap", Environment.TONE_MAPPER_FILMIC)
	shadows_preset = data.get("shadowsPreset", "medium")
	# Apply suns. Use suns array data if available, but always use sun_count
	# for the amount (so that the default settings of 1 sun and an empty suns
	# array will give the default sun instead of no suns).
	var sun_count = mini(data["sunCount"], 4)
	var suns_children: Array[Node] = set_sun_count(sun_count)
	var suns = data["suns"]
	assert(suns_children.size() == sun_count)
	assert(suns.size() == sun_count)
	# If there is sun information in the array, apply it to our lights.
	for i in range(min(suns.size(), sun_count)):
		var sun_dict = suns[i]
		var sun_node: DirectionalLight3D = suns_children[i]
		sun_node.light_color = _array_to_color(sun_dict["color"])
		sun_node.light_energy = abs(sun_dict["brightness"])
		sun_node.light_negative = sun_dict["brightness"] < 0.0
		sun_node.rotation = Vector3(sun_dict["rotation"][0], sun_dict["rotation"][1], 0.0)
		sun_node.position = Vector3(sun_dict["position"][0], sun_dict["position"][1], sun_dict["position"][2])
	if data.has("clouds") and data["clouds"] is Dictionary:
		var clouds = data["clouds"]
		set_clouds_enabled(clouds.get("visible", false))
		set_clouds_shader_value("height_offset", clouds.get("height", 200.0))
		var time_scale =  clouds.get("timeScale", 0.02)
		var cloud_coverage = clouds.get("coverage", 0.6)
		var clouds_color = _array_to_color( clouds.get("albedo", [1,1,1]) )
		set_clouds_shader_value("cloud_coverage", cloud_coverage)
		set_clouds_shader_value("_time_scale", time_scale)
		set_clouds_shader_value("albedo",clouds_color)
		if _sky is ShaderMaterial:
			_sky.set_shader_parameter("clouds_color", clouds_color)
			_sky.set_shader_parameter("_time_scale", time_scale)
			_sky.set_shader_parameter("cloud_coverage", cloud_coverage)


func apply_from_dictionary(data: Dictionary) -> void:
	_dict_cached_data = data
	if data.has("environment") :
		load_environment(data["environment"])
	else:
		_update_environment_settings(data)
	environment_updated_from_dictionary.emit()


func serialize_to_dictionary() -> Dictionary:
	var suns: Array = []
	for child in get_children():
		if not child is DirectionalLight3D:
			continue
		suns.append({
			"lightType": "DIRECTIONAL", # Suns are always directional lights.
			"color": _color_to_array(child.light_color),
			"brightness": child.light_energy * (-1.0 if child.light_negative else 1.0),
			"rotation": [child.rotation.x, child.rotation.y],
			"position": [child.position.x, child.position.y, child.position.z],
			"range": 5.0, # Does not matter what value we use here.
			"spotAngleDegrees": 45.0, # Does not matter.
		})
	var fog_density = environment.volumetric_fog_density
	if environment.fog_enabled:
		fog_density = environment.fog_density * 2.0

	var clouds = {
		"visible": clouds_enabled(),
		"coverage": get_clouds_shader_value("cloud_coverage"),
		"height": get_clouds_shader_value("height_offset"),
		"timeScale": get_clouds_shader_value("_time_scale"),
		"albedo": _color_to_array(get_clouds_shader_value("albedo"))
	}

	var env_name = get_environment_name()

	var env_data = {
		"environment": env_name,
		"sunCount": suns.size(),
		"suns": suns,
		"clouds": clouds,
		"fogEnabled": environment.fog_enabled or environment.volumetric_fog_enabled,
		"fogVolumetric": environment.volumetric_fog_enabled,
		"fogDensity": fog_density,
		"fogColor": _color_to_array(environment.fog_light_color),
		"globalIllumination": environment.sdfgi_enabled,
		"ssao": environment.ssao_enabled,
		"ssr": environment.ssr_enabled,
		"glow": environment.glow_enabled,
		"glowHdrThreshold": environment.glow_hdr_threshold,
		"shadowsPreset": shadows_preset,
		"tonemap": environment.tonemap_mode
	}

	if _sky is ProceduralSkyMaterial:
		env_data.merge({
			"skyTopColor": _color_to_array(_sky.sky_top_color),
			"skyHorizonColor": _color_to_array(_sky.sky_horizon_color),
			"skyBottomColor": _color_to_array(_sky.ground_bottom_color),
		})
	elif _sky is ShaderMaterial:
		var shader_whitelist = ["skyTopColor", "skyHorizonColor", "skyBottomColor"]
		for shader_param in shader_whitelist:
			env_data[shader_param] = _color_to_array(
					_sky.get_shader_parameter(shader_param.to_snake_case())
			)
	return env_data


func set_sky_color(top: Color, horizon: Color, bottom: Color) -> void:
	if _sky is ProceduralSkyMaterial:
		_sky.sky_top_color = top
		_sky.sky_horizon_color = horizon
		_sky.ground_horizon_color = horizon
		_sky.ground_bottom_color = bottom
	elif _sky is ShaderMaterial:
		_sky.set_shader_parameter("sky_top_color", top)
		_sky.set_shader_parameter("sky_horizon_color", horizon)
		_sky.set_shader_parameter("sky_bottom_color", bottom)


func set_sun_count(sun_count: int) -> Array[Node]:
	if sun_count > 4:
		sun_count = 4
	var suns_children: Array[Node] = []
	var counter: int = sun_count
	for child in get_children():
		if not child is DirectionalLight3D:
			continue
		counter -= 1
		# If counter ends up negative, we have too many suns. Delete the extras.
		if counter < 0:
			remove_child(child)
			child.free()
		else:
			suns_children.append(child)
	# If counter ends up positive, we have too few suns. Add some more.
	if counter > 0:
		for i in range(counter):
			var sun = DirectionalLight3D.new()
			sun.name = "Sun" + str(get_child_count())
			sun.basis = _DEFAULT_SUN_ROTATION_BASIS
			add_child(sun)
			suns_children.append(sun)
	_update_shadows_settings(shadows_preset, suns_children)
	return suns_children


func set_fog_properties(enabled: bool, volumetric: bool, density: float, color: Color) -> void:
	environment.fog_enabled = enabled and not volumetric
	environment.volumetric_fog_enabled = enabled and volumetric
	environment.fog_density = density * 0.5
	environment.volumetric_fog_density = density
	environment.fog_light_color = color
	environment.volumetric_fog_albedo = color
	environment.volumetric_fog_emission = color
	if _sky is ShaderMaterial:
		_sky.set_shader_parameter("fog_color", color)


func request_change_from_children() -> void:
	request_change()


func request_change() -> void:
	var env_dict: Dictionary = serialize_to_dictionary()
	if Zone.is_host():
		Zone.server.server_update_environment(env_dict)
	else:
		Zone.send_data_to_server([Packet.TYPE.ENVIRONMENT_CHANGE, env_dict])


func _array_to_color(array: Array) -> Color:
	return Color(array[0], array[1], array[2])


func _color_to_array(color: Color) -> Array:
	# We only want 5 digits of precision for Color. Any more is useless.
	return [
		snapped(color.r, 0.00001),
		snapped(color.g, 0.00001),
		snapped(color.b, 0.00001),
	]


func clouds_enabled() -> bool:
	if not is_instance_valid(_clouds):
		return false
	return _clouds.visible


func set_clouds_enabled(state: bool) -> void:
	if not is_instance_valid(_clouds):
		return
	_clouds.visible = state


func get_clouds_shader_value(shader_param) -> Variant:
	if not is_instance_valid(_clouds):
		return null
	var clouds_material: ShaderMaterial = _clouds.material
	if not clouds_material:
		return null
	return clouds_material.get_shader_parameter(shader_param)


func set_clouds_shader_value(shader_param, new_value) -> void:
	if not is_instance_valid(_clouds):
		return
	var clouds_material: ShaderMaterial = _clouds.material
	if not clouds_material:
		return
	clouds_material.set_shader_parameter(shader_param, new_value)
