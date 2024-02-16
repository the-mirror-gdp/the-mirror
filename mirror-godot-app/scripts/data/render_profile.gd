class_name RenderProfile
extends Resource


var anisotropic_filter_level: int = 4
var use_nearest_mipmap_filter: bool = false
var msaa: int = 0
var taa: bool = true
var fxaa: bool = false
var texture_array_reflections: bool = true
var volumetric_volume_depth: int = 64
var volumetric_volume_size: int = 64
var volumetric_use_filter: bool = true
var ssao_quality: int = 2
var ssr_quality: int = 1
var dof_enabled: bool = true
var dof_quality: int = 2
var sdfgi_probe_ray_count: int = RenderingServer.ENV_SDFGI_RAY_COUNT_16

var force_vertex_shading: bool = false
var force_lambert_over_burley: bool = false

var subsurface_scattering_quality: int = 1
var soft_shadow_filter_quality: int = 2
var current_profile: int = 2



func set_high():
	anisotropic_filter_level = 16
	use_nearest_mipmap_filter = false
	msaa = 0
	taa = true
	fxaa = false
	ssao_quality = 2
	dof_quality = 2
	ssr_quality = 1
	dof_enabled = true

	volumetric_volume_depth= 128
	volumetric_volume_size = 128
	volumetric_use_filter = false
	sdfgi_probe_ray_count =  RenderingServer.ENV_SDFGI_RAY_COUNT_96

	texture_array_reflections = true

	force_vertex_shading = false
	force_lambert_over_burley = false

	subsurface_scattering_quality = 0 if Util.is_vr_enabled() else 2
	soft_shadow_filter_quality = 5
	current_profile = 3


func set_medium():
	anisotropic_filter_level = 4
	use_nearest_mipmap_filter = false
	msaa = 0
	taa = true
	fxaa = false
	ssao_quality = 2
	dof_quality = 1
	ssr_quality = 1
	dof_enabled = true

	volumetric_volume_depth= 64
	volumetric_volume_size = 64
	volumetric_use_filter = true
	sdfgi_probe_ray_count = RenderingServer.ENV_SDFGI_RAY_COUNT_32

	texture_array_reflections = true

	force_vertex_shading = false
	force_lambert_over_burley = false

	subsurface_scattering_quality = 0 if Util.is_vr_enabled() else 1
	soft_shadow_filter_quality = 2
	current_profile = 2


func set_low():
	anisotropic_filter_level = 2
	use_nearest_mipmap_filter = true
	msaa = 0
	taa = false
	fxaa = not Util.is_vr_enabled()
	ssao_quality = 1
	dof_quality = 0
	ssr_quality = 0
	dof_enabled = false

	volumetric_volume_depth= 64
	volumetric_volume_size = 64
	volumetric_use_filter = true
	sdfgi_probe_ray_count = RenderingServer.ENV_SDFGI_RAY_COUNT_16

	texture_array_reflections = false

	force_vertex_shading = false
	force_lambert_over_burley = false

	subsurface_scattering_quality = 0 if Util.is_vr_enabled() else 1
	soft_shadow_filter_quality = 0
	current_profile = 1


func get_setting_def(path: String, default):
	if ProjectSettings.has_setting(path):
		return ProjectSettings.get_setting(path)
	else:
		return default


func load_viewport_settings():
	msaa = get_setting_def("themirror/rendering/anti_aliasing/quality/msaa_3d", msaa)
	taa = get_setting_def("themirror/rendering/anti_aliasing/quality/use_taa", taa)
	fxaa = get_setting_def("themirror/rendering/anti_aliasing/quality/screen_space_aa", fxaa)


func set_profile():
	ProjectSettings.set_setting("rendering/environment/subsurface_scattering/subsurface_scattering_quality", subsurface_scattering_quality)
	ProjectSettings.set_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", soft_shadow_filter_quality)
	ProjectSettings.set_setting("rendering/environment/ssao/quality", ssao_quality)
	ProjectSettings.set_setting("rendering/camera/depth_of_field/depth_of_field_bokeh_quality", dof_quality)
	ProjectSettings.set_setting("rendering/environment/screen_space_reflection/roughness_quality", ssr_quality)

	ProjectSettings.set_setting("rendering/environment/volumetric_fog/use_filter", volumetric_use_filter)
	ProjectSettings.set_setting("rendering/environment/volumetric_fog/volume_depth", volumetric_volume_depth)
	ProjectSettings.set_setting("rendering/environment/volumetric_fog/volume_size", volumetric_volume_size)

	# This property is only read when the project starts. There is currently no way to change this setting at run-time.
	ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", anisotropic_filter_level)
	ProjectSettings.set_setting("rendering/textures/default_filters/use_nearest_mipmap_filter", use_nearest_mipmap_filter)
	ProjectSettings.set_setting("rendering/reflections/sky_reflections/texture_array_reflections", texture_array_reflections)
	ProjectSettings.set_setting("rendering/shading/overrides/force_vertex_shading", force_vertex_shading)
	ProjectSettings.set_setting("rendering/shading/overrides/force_lambert_over_burley", force_lambert_over_burley)
	ProjectSettings.set_setting("rendering/global_illumination/sdfgi/probe_ray_count", sdfgi_probe_ray_count)

	# This sections is a group of custom fields, we do need them at main viewport only in camera viewport
	ProjectSettings.set_setting("themirror/rendering/anti_aliasing/quality/msaa_3d", msaa)
	ProjectSettings.set_setting("themirror/rendering/anti_aliasing/quality/use_taa", taa)
	ProjectSettings.set_setting("themirror/rendering/anti_aliasing/quality/screen_space_aa", fxaa)

	# apply changes to running instance
	RenderingServer.directional_soft_shadow_filter_set_quality(soft_shadow_filter_quality)
	RenderingServer.sub_surface_scattering_set_quality(subsurface_scattering_quality)
	RenderingServer.environment_set_volumetric_fog_volume_size(volumetric_volume_size, volumetric_volume_depth)
	RenderingServer.environment_set_volumetric_fog_filter_active(volumetric_use_filter)
	RenderingServer.environment_set_sdfgi_ray_count(sdfgi_probe_ray_count)


func update_viewport(viewport: Viewport):
	viewport.msaa_3d = msaa
	viewport.use_taa = taa
	if fxaa:
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
