extends "asset_placement_base.gd"


func set_camera_zoom_scale(camera_zoom_scale: float) -> void:
	camera_zoom_scale = maxf(camera_zoom_scale, 0.1)
	near = 0.05 * camera_zoom_scale
	far = 4000.0 * camera_zoom_scale
