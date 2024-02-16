class_name AudioInputDetector
extends AudioStreamPlayer


signal audio_input_detection_state_changed(state: bool)

@export var volume_threshold = 120 # lower is louder
@export var delay_time = 0.5


var _last_time_above_threshold: float = 0
var _last_state: bool = false


func _ready() -> void:
	if Zone.is_host():
		set_process(false)
		stop()
	elif GameplaySettings.CAN_DETECT_AUDIO_FROM_MIC:
		play()


func _process(delta: float) -> void:
	if not GameplaySettings.is_microphone_enabled:
		return
	var volume = abs(AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Record"), 0))
	if volume < volume_threshold:
		if not audio_input_detected():
			audio_input_detection_state_changed.emit(true)
		_last_state = true
		_last_time_above_threshold = Time.get_unix_time_from_system()
	elif not audio_input_detected() and _last_state:
		_last_state = false
		audio_input_detection_state_changed.emit(false)


func audio_input_detected() -> bool:
	return _last_time_above_threshold + delay_time > Time.get_unix_time_from_system()
