extends AudioStreamPlayer


@export var _sound_drag: AudioStream
@export var _sound_extrude: AudioStream
@export var _sound_finish: AudioStream
@export var _sound_fail: AudioStream


func _on_state_changed(state: ModelBuilder.State) -> void:
	match state:
		ModelBuilder.State.DRAG:
			_play_sound(_sound_drag)
		ModelBuilder.State.EXTRUDE:
			_play_sound(_sound_extrude)
		ModelBuilder.State.SLIDE:
			_play_sound(_sound_extrude)


func _on_placement_finished() -> void:
	_play_sound(_sound_finish)


func _on_placement_failed() -> void:
	_play_sound(_sound_fail)


func _play_sound(sound: AudioStream) -> void:
	if sound:
		stream = sound
		play()
