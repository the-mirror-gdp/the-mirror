extends MeshInstance3D


const _CRACK_SOUND_PATH = "res://player/equipable/gun/firearm/bullet_hole/crack/crack_%d.wav"
const _SPEED_OF_SOUND: float = 343.0 # Meters per second
const _PERSIST_TIME: float = 10.0

var _time_until_play := INF
var _time_until_fade: float = 0.0

@onready var _audio: AudioStreamPlayer3D = $__Audio


func _ready() -> void:
	_audio.stream = load(_CRACK_SOUND_PATH % (randi() % 8 + 1))
	_audio.pitch_scale = randf() * 0.1 + 0.95
	await get_tree().process_frame
	if not PlayerData.has_local_player():
		return
	var local_player: Player = PlayerData.get_local_player()
	var listener_position = local_player.get_global_eyes_position()
	var distance = listener_position.distance_to(global_position)
	# 1.25 assumes the bullet travels at 4x the speed of sound
	# (we add 0.25x to account for bullet travel time)
	_time_until_play = distance * (1.25 / _SPEED_OF_SOUND)
	_time_until_fade = _PERSIST_TIME


func _process(delta) -> void:
	_time_until_fade -= delta
	if _time_until_fade <= 0.0:
		set_transparency(lerpf(transparency, 1.0, delta * 2.0))
		if transparency >= 0.99:
			queue_free()
		return
	if is_instance_valid(_audio):
		_time_until_play -= delta
		if _time_until_play <= 0.0 and not _audio.is_playing():
			_audio.play()
			_time_until_play = INF # Avoid playing twice.


func _on_audio_finished() -> void:
	_audio.queue_free()
