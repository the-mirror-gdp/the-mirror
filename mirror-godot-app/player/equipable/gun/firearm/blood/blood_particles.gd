extends CPUParticles3D


@export var _hit_sounds: Array[AudioStream] = []
@onready var _audio: AudioStreamPlayer3D = $Audio


func _ready() -> void:
	_audio.stream = _hit_sounds.pick_random()
	_audio.pitch_scale = randf() * 0.1 + 0.95
	_audio.play()
	emitting = true
	await get_tree().create_timer(lifetime).timeout
	queue_free()
