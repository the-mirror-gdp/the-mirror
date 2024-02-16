class_name Gizmo
extends Node3D


signal gizmo_changed
signal transformation_ended
signal transformation_started

const TRANSFORM_START_SFX = preload("res://creator/selection/audio/click_hold.wav")
const TRANSFORM_END_SFX = preload("res://creator/selection/audio/click_release.wav")

@export var target: Node3D = null

var is_relative: bool = false
var is_snap_checked: bool = true
var is_transforming: bool = false
var _was_previously_highlighting: bool = false

@onready var _translation_gizmo = $TranslationGizmo
@onready var _rotation_gizmo = $RotationGizmo
@onready var _scale_gizmo = $ScaleGizmo
@onready var _gizmo_array = [_translation_gizmo, _rotation_gizmo, _scale_gizmo]
@onready var _audio_stream_player = $AudioStreamPlayer


func _ready() -> void:
	assert(is_instance_valid(target))
	_hide_all_gizmos()
	PlayerData.game_mode_changed.connect(_on_game_mode_changed)


func _process(_delta: float) -> void:
	if not visible:
		# If the gizmo is not visible, we don't need to update the gizmo.
		# This will also be the case when we aren't on a client in a Zone.
		return
	process_follow_target()
	# Scale gizmo based on camera distance
	var camera: Camera3D
	if PlayerData.has_local_player():
		var local_player = PlayerData.get_local_player()
		camera = local_player.camera_get_viewport().get_camera_3d()
	else:
		camera = get_viewport().get_camera_3d()
	if is_instance_valid(camera):
		var distance = (camera.global_transform.origin - global_transform.origin).length()
		scale = distance * 0.15 * Vector3.ONE
		if not is_transforming:
			_update_gizmo_highlights(camera)


func _update_gizmo_highlights(camera: Camera3D) -> void:
	if not camera.has_method(&"get_mouse_raycast"):
		return
	# Only highlight if the secondary action is not pressed.
	if not Input.is_action_pressed(&"secondary_action"):
		var gizmo_raycast_dict = camera.get_mouse_raycast(["GIZMO"])
		if gizmo_raycast_dict.has("collider"):
			var collider = gizmo_raycast_dict["collider"]
			if collider.has_method(&"start_highlight"):
				collider.start_highlight()
			_was_previously_highlighting = true
			return
	if _was_previously_highlighting:
		_was_previously_highlighting = false
		for gizmo_part in _gizmo_array:
			gizmo_part.stop_highlight()


func process_follow_target() -> void:
	if is_instance_valid(target) and target.is_inside_tree():
		transform.origin = target.global_transform.origin
		transform.basis = target.global_transform.basis if is_relative else Basis()


# Second arg is float or null.
func set_gizmo_type(new_type: Enums.GIZMO_TYPE, snap_step: Variant = null) -> void:
	PlayerData.currently_selected_tool = new_type
	update_gizmo_visibility()
	if snap_step != null:
		set_snap_step(new_type, snap_step)


func update_gizmo_visibility() -> void:
	if (
			target.is_selection_empty()
			or target.is_space_object_asset_type(Enums.ASSET_TYPE.MAP)
			or target.is_any_object_not_allowed_to_edit()
			or not GameUI.creator_ui.is_edit_mode(Enums.EDIT_MODE.Asset)
			or PlayerData.game_mode.get_current_mode() == PlayerData.game_mode.Mode.NORMAL
	):
		_hide_all_gizmos()
	else:
		match PlayerData.currently_selected_tool:
			Enums.GIZMO_TYPE.GRAB:
				_hide_all_gizmos()
			Enums.GIZMO_TYPE.MOVE:
				_show_translation_gizmo()
			Enums.GIZMO_TYPE.ROTATE:
				_show_rotation_gizmo()
			Enums.GIZMO_TYPE.SCALE:
				_show_scale_gizmo()


func _show_translation_gizmo() -> void:
	visible = true
	_translation_gizmo.show_gizmo()
	_rotation_gizmo.hide_gizmo()
	_scale_gizmo.hide_gizmo()
	gizmo_changed.emit()


func _show_rotation_gizmo() -> void:
	visible = true
	_translation_gizmo.hide_gizmo()
	_rotation_gizmo.show_gizmo()
	_scale_gizmo.hide_gizmo()
	gizmo_changed.emit()


func _show_scale_gizmo() -> void:
	visible = true
	_translation_gizmo.hide_gizmo()
	_rotation_gizmo.hide_gizmo()
	_scale_gizmo.show_gizmo()
	gizmo_changed.emit()


func _hide_all_gizmos() -> void:
	visible = false
	_translation_gizmo.hide_gizmo()
	_rotation_gizmo.hide_gizmo()
	_scale_gizmo.hide_gizmo()
	gizmo_changed.emit()


func get_snap_step(gizmo_type: Enums.GIZMO_TYPE) -> float:
	match gizmo_type:
		Enums.GIZMO_TYPE.GRAB:
			return _translation_gizmo.snap_meters
		Enums.GIZMO_TYPE.MOVE:
			return _translation_gizmo.snap_meters
		Enums.GIZMO_TYPE.ROTATE:
			return _rotation_gizmo.snap_radians
		Enums.GIZMO_TYPE.SCALE:
			return _scale_gizmo.snap_ratio
	push_error("Tried to get the gizmo snap step, but the given type was not valid.")
	return 0.0


func set_snap_step(gizmo_type: Enums.GIZMO_TYPE, snap_step: float):
	match gizmo_type:
		Enums.GIZMO_TYPE.GRAB:
			_translation_gizmo.snap_meters = snap_step
		Enums.GIZMO_TYPE.MOVE:
			_translation_gizmo.snap_meters = snap_step
		Enums.GIZMO_TYPE.ROTATE:
			_rotation_gizmo.snap_radians = snap_step
		Enums.GIZMO_TYPE.SCALE:
			_scale_gizmo.snap_ratio = snap_step


## Returns true if snap is held xor the UI checkbox is checked.
func is_snap_enabled() -> bool:
	var snap_held = Input.is_action_pressed(&"object_snap")
	return snap_held != is_snap_checked


func on_transformation_ended() -> void:
	_audio_stream_player.stream = TRANSFORM_END_SFX
	_audio_stream_player.play()
	is_transforming = false
	transformation_ended.emit()


func on_transformation_started() -> void:
	_audio_stream_player.stream = TRANSFORM_START_SFX
	_audio_stream_player.play()
	transformation_started.emit()


func _on_game_mode_changed(_new_mode: GameMode.Mode, _previous_mode: GameMode.Mode) -> void:
	update_gizmo_visibility()
