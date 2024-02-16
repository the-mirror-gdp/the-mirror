extends Node3D

@export var _audio_set_terrain: PlayerAudioSetResource
@export var _audio_set_space_object: PlayerAudioSetResource
@export var _minimum_in_air_time_for_jump = 0.5

@onready var _footsteps_audio_stream_player_3d_left: AudioStreamPlayer3D = $FootstepsAudioStreamPlayer3D
@onready var _footsteps_audio_stream_player_3d_right = $FootstepsAudioStreamPlayer3D2
@onready var _verbal_audio_stream_player_3d = $VerbalAudioStreamPlayer3D
@onready var _footstep_player: Array[AudioStreamPlayer3D] = [
	_footsteps_audio_stream_player_3d_left,
	_footsteps_audio_stream_player_3d_right
]

var _player: Player
var _last_max_state_compatibility: Array[float] = [3.0, 3.0]
var _in_air_time := 0.0

enum SURFACE_TYPE {
	TERRAIN,
	SPACE_OBJECT
}

@onready var _audio_sets = [
	_audio_set_terrain,
	_audio_set_space_object
]

var _last_walked_on_object_type: SURFACE_TYPE = SURFACE_TYPE.TERRAIN


func _get_active_audio_set() -> PlayerAudioSetResource:
	if not is_instance_valid(_player) or Zone.is_host():
		return _audio_set_terrain

	# TODO add support to this feature again.
	if not _player.has_method("get_slide_collision_count"):
		return _audio_set_terrain

	for coll_idx in _player.get_slide_collision_count():
		var collider_obj = _player.get_slide_collision(coll_idx).get_collider()
		var space_object = Util.get_space_object(collider_obj)
		if space_object:
			if space_object.asset_type == Enums.ASSET_TYPE.MAP:
				_last_walked_on_object_type = SURFACE_TYPE.TERRAIN
			else:
				_last_walked_on_object_type = SURFACE_TYPE.SPACE_OBJECT
	return _audio_sets[_last_walked_on_object_type]


func footsteps_event_process(state_compatibility: float, leg_index: int):
	if  state_compatibility < 0.55:
		return
	var _footsteps_audio_stream_player_3d: AudioStreamPlayer3D = _footstep_player[leg_index]
	var is_more_compatible: bool = state_compatibility >= _last_max_state_compatibility[leg_index]
	if is_more_compatible or not _footsteps_audio_stream_player_3d.playing:
		_footsteps_audio_stream_player_3d.volume_db = lerp(-30.0, 0.0, state_compatibility)
		_last_max_state_compatibility[leg_index] = state_compatibility
		_footsteps_audio_stream_player_3d.stream = _get_active_audio_set().footsteps_audio_stream

		# Restart the foot step audio player
		_footsteps_audio_stream_player_3d.stop()
		_footsteps_audio_stream_player_3d.play()


func setup(player: Player) -> void:
	_player = player
	player.jump.connect(on_jump)


func on_jump():
	_verbal_audio_stream_player_3d.stream = _get_active_audio_set().jump_audio_stream
	_verbal_audio_stream_player_3d.play()


func _process(delta: float) -> void:
	if  Zone.is_host() or not is_instance_valid(_player) or not Zone.space_preload_done:
		return
	if not _player.is_on_floor():
		_in_air_time += delta
	else:
		if _in_air_time > _minimum_in_air_time_for_jump:
			_verbal_audio_stream_player_3d.stream = _get_active_audio_set().land_audio_stream
			_verbal_audio_stream_player_3d.play()
		_in_air_time = 0.0
