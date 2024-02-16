extends Node

signal low_performance_detected
signal good_performance_detected

# If game is unable to achieve fps from this threshold then quality will be decreased
const _IDEAL_FRAMERATE_THRESHOLD_BELOW_WHICH_QUALITY_IS_DECREASED = 0.9
const _NMB_OF_MEASUREMENTS_TO_CHANGE_QUALITY = 120
const _NMB_OF_CONSECUTIVE_TIMES_PERFORMANCE_IS_GOOD_TO_INCREASE_QUALITY = 3


var _frame_measurements: Array[float] = []
var _good_performance_measurements_counter: int = 0


func enable() -> void:
	set_process(true)


func disable() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	_frame_measurements.append(Engine.get_frames_per_second())

	if _frame_measurements.size() >= _NMB_OF_MEASUREMENTS_TO_CHANGE_QUALITY:
		_check_performance()
		_frame_measurements.clear()


func _check_performance() -> void:
	var ideal_framerate = DisplayServer.screen_get_refresh_rate()
	ideal_framerate = ideal_framerate if ideal_framerate > 0.0 else 60.0
	var decrease_quality_below_fps = ideal_framerate * _IDEAL_FRAMERATE_THRESHOLD_BELOW_WHICH_QUALITY_IS_DECREASED

	var is_performance_above_threshold := false
	var is_performance_always_good := true
	for measurement in _frame_measurements:
		if measurement >= decrease_quality_below_fps:
			is_performance_above_threshold = true
		if measurement < ideal_framerate:
			is_performance_always_good = false

	if not is_performance_above_threshold:
		# All measured frames are below a threshold, time to report performance problems
		low_performance_detected.emit()

	if is_performance_always_good:
		_good_performance_measurements_counter += 1
	else:
		_good_performance_measurements_counter = 0

	if _good_performance_measurements_counter >= _NMB_OF_CONSECUTIVE_TIMES_PERFORMANCE_IS_GOOD_TO_INCREASE_QUALITY:
		# All frames during couple last measurements are excelent, we can report good performance
		good_performance_detected.emit()
		_good_performance_measurements_counter = 0

