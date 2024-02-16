@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: float)

@export var reset_value: float = 0.0
@export var current_value: float = 0.0
@export var unit_suffix: String = ""
@export var step: float = 0.001

@onready var _spin_box_node: SpinBox = $SpinBoxHolder/SpinBox
@onready var _line_edit_node: LineEdit = _spin_box_node.get_line_edit()
@export var enabled: bool = true:
	set(value):
		if is_instance_valid(_spin_box_node):
			enabled = value
			_spin_box_node.editable = enabled


func _ready() -> void:
	super()
	_line_edit_node.text_changed.connect(_on_spin_box_text_changed)
	_line_edit_node.focus_entered.connect(_on_focus_entered)
	_line_edit_node.focus_exited.connect(_on_focus_exited)
	_line_edit_node.text_submitted.connect(emit_value_submitted)
	refresh_full()


func refresh_full() -> void:
	_spin_box_node.suffix = unit_suffix
	_spin_box_node.step = step
	_spin_box_node.set_value_no_signal(current_value)
	_spin_box_node.apply()
	if step == int(step):
		_spin_box_node.remove_theme_icon_override(&"updown")
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))


func refresh() -> void:
	if get_viewport() and get_viewport().gui_get_focus_owner() == _line_edit_node:
		return
	if not is_equal_approx(_spin_box_node.value, current_value):
		_spin_box_node.value = current_value
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))


func cleanup_and_delete() -> void:
	if is_queued_for_deletion():
		return
	_line_edit_node.text_changed.disconnect(_on_spin_box_text_changed)
	_line_edit_node.focus_entered.disconnect(_on_focus_entered)
	_line_edit_node.focus_exited.disconnect(_on_focus_exited)
	_line_edit_node.text_submitted.disconnect(emit_value_submitted)
	_spin_box_node.free()
	queue_free()


## Listening to value changed allows us to detect if the value was changed
## when exiting focus of the widget and not just on-confirm-pressed.
func _on_spin_box_value_changed(val: float) -> void:
	current_value = val
	# even though CONNECT_ONE_SHOT has been used, this will fire twice unless disconnected.
	_spin_box_node.value_changed.disconnect(_on_spin_box_value_changed)
	value_changed.emit(current_value)


func _on_spin_box_text_changed(new_text: String) -> void:
	current_value = new_text.to_float()
	value_changed.emit(current_value)


func _on_focus_entered() -> void:
	_spin_box_node.value_changed.connect(_on_spin_box_value_changed, CONNECT_ONE_SHOT)
	GameUI.grab_input_lock(self)
	await get_tree().process_frame
	_line_edit_node.select_all()


func _on_focus_exited():
	assert(not is_queued_for_deletion())
	refresh_full()
	GameUI.release_input_lock(self)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	refresh()
	value_changed.emit(current_value)
