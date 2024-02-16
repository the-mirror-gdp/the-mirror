class_name BaseSetting
extends Control


signal setting_changed(value)

var current_value: Variant


func _init():
	focus_entered.connect(_on_focus_entered)
	mouse_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_exited.connect(_on_focus_exited)


func _ready():
	get_child(0).value_changed.connect(_on_value_changed)


# Override
# Applies value to the UI
func apply_setting_to_ui(_value):
	push_error("This method must be overridden.")


# Override
# Get's setting value and converts it to a value which can be directly used by UI (e.g. value of a slider)
# This value will be passed to set_value() and apply_setting_to_ui()
func convert_gameplay_value_for_ui():
	push_error("A default value is required. This method must be overridden.")


# Override
# Applies UI value to the gameplay
func apply_setting_to_gameplay():
	push_error("This method must be overridden.")


# Updates the state of the setting, called every time any other settings changes it's state
# can be overriden to react to such state change
func refresh_ui():
	var value = convert_gameplay_value_for_ui()
	if value == current_value:
		return
	current_value = value
	apply_setting_to_ui(value)


# Updates the state of the setting,
# e.g. used when setting screen appears
func prepare_ui():
	set_value(convert_gameplay_value_for_ui())


# Applies value to the UI
func set_value(value: Variant) -> void:
	if value == current_value:
		return
	current_value = value
	apply_setting_to_ui(value)
	setting_changed.emit(value)


func _on_value_changed(new_value: Variant) -> void:
	set_value(new_value)


func _on_focus_entered():
	add_theme_stylebox_override("panel", preload("res://ui/main_menu/pages/settings/theme/container_hover.stylebox.tres"))


func _on_focus_exited():
	remove_theme_stylebox_override("panel")
