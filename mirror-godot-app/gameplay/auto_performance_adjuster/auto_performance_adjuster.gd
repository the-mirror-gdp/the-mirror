extends Node

const MIN_AUTO_RESOLUTION_SCALE := 0.3
const MAX_AUTO_RESOLUTION_SCALE := 1.0
const AUTO_RESOLUTION_STEP_DECREASE := 0.1
const AUTO_RESOLUTION_STEP_INCREASE := 0.05


@onready var performance_monitor = $PerformanceMonitor


func enable():
	performance_monitor.enable()


func disable():
	performance_monitor.disable()


func _on_performance_monitor_low_performance_detected() -> void:
	_decrease_resolution_scale()


func _decrease_resolution_scale():
	var resolution_scale: float = GameplaySettings.resolution_scale
	resolution_scale -= AUTO_RESOLUTION_STEP_DECREASE
	if resolution_scale > MIN_AUTO_RESOLUTION_SCALE:
		if resolution_scale != GameplaySettings.resolution_scale:
			GameplaySettings.resolution_scale = resolution_scale
			print_verbose("AutoPerformanceAdjuster: auto increasing rendering quality, new resolution scale: ",
				GameplaySettings.resolution_scale)


func _on_performance_monitor_good_performance_detected() -> void:
	_increase_resolution_scale()


func _increase_resolution_scale():
	var resolution_scale: float = GameplaySettings.resolution_scale
	resolution_scale = min(1.0, resolution_scale + AUTO_RESOLUTION_STEP_INCREASE)
	if resolution_scale <= MAX_AUTO_RESOLUTION_SCALE:
		if resolution_scale != GameplaySettings.resolution_scale:
			GameplaySettings.resolution_scale = resolution_scale
			print_verbose("AutoPerformanceAdjuster: auto decreasing rendering quality, new resolution scale: ",
				GameplaySettings.resolution_scale)
