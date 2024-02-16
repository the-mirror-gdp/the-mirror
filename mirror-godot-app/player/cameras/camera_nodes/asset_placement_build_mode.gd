extends "asset_placement_base.gd"

@onready var _audio_stream_player_create_object = $AudioStreamPlayerCreateObject

const ZOOM_TARGET_MULTIPLIER: float = 1.15
const CAMERA_ZOOM_SPEED: float = 8.0

var target_zoom: float:
	set(value):
		value = clamp(value, 0.1, 10000.0)
		target_zoom = value
		adjust_near_far_planes(value)


func _ready() -> void:
	# NO_COLLIDE should have no collision for players but we still need to
	# allow raycasts for them only in Build mode to allow selecting them.
	# If you want raycasts to hit from a player, use trigger instead.
	_raycastable_layers.append(&"NO_COLLIDE")


func update(delta: float) -> void:
	super.update(delta)
	# If the Z position is 0.0, then this is a free camera.
	if position.z != 0.0:
		var lerp_strength = clamp(delta * CAMERA_ZOOM_SPEED, 0.0, 1.0)
		position.z = lerpf(position.z, target_zoom, lerp_strength)


## Calls when an InputEvent hasn't been consumed.
## Handles input for object placement and object inspection.
func handle_asset_placement_input(input_event: InputEvent) -> void:
	super.handle_asset_placement_input(input_event)
	if not self.current:
		return
	var zoom_in = input_event.is_action_pressed(&"build_mode_camera_zoom_in")
	if zoom_in or input_event.is_action_pressed(&"build_mode_camera_zoom_out"):
		if input_event is InputEventMouseButton:
			if not GameUI.creator_ui.get_safe_area().has_point(input_event.position):
				return
		if zoom_in:
			target_zoom /= ZOOM_TARGET_MULTIPLIER
		else:
			target_zoom *= ZOOM_TARGET_MULTIPLIER
		get_viewport().set_input_as_handled()


func change_focus_point(new_focus_point: Vector3):
	target_zoom = global_transform.origin.distance_to(new_focus_point)
	# If the Z position is 0.0, then this was a free camera.
	if position.z == 0.0:
		position.z = 0.00001 # Any small non-zero number will work.


func adjust_near_far_planes(value: float) -> void:
	value = clamp(value, 0.1, 10000.0)
	near = sqrt(value) * 0.01
	far = sqrt(value) * 10000.0


## Places the currently selected asset in the world.
func _place_previewed_asset() -> void:
	super()
	_audio_stream_player_create_object.play()
