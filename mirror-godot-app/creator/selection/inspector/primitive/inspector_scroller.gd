@tool
extends "inspector_property_base.gd"


signal value_changed(new_index: int)

@export var values: Array
@export var reset_value: int = 0
@export var current_value: int:
	get:
		return _internal_value
	set(value):
		if _internal_value == value or _internal_value >= values.size():
			return
		_internal_value = value
		_update_pills()
		if _reset_button:
			_update_reset_visibility(value != reset_value)
		value_changed.emit(value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _button_right:
			_button_right.disabled = not value
		if _button_left:
			_button_left.disabled = not value

@export var _stylebox_pill_active: StyleBoxFlat
@export var _stylebox_pill: StyleBoxFlat

@onready var _pills_container = %PillsContainer
@onready var _option_label = %OptionLabel
@onready var _button_right = %ButtonRight
@onready var _button_left = %ButtonLeft


var _internal_value = 0

func _update_pills():
	if not _pills_container or not _option_label:
		return
	for child in _pills_container.get_children():
		child.queue_free()
	if values.size() == 0:
		return
	_option_label.text = values[_internal_value]

	var cnt = 0
	for value in values:
		var pill = Panel.new()
		var stylebox = _stylebox_pill if cnt != _internal_value else _stylebox_pill_active
		pill.add_theme_stylebox_override("panel", stylebox)
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill.custom_minimum_size.y = 3
		cnt += 1
		_pills_container.add_child(pill)


func _ready():
	values = values.duplicate()
	super()
	_update_pills()


func add_item(new_item: Variant) -> void:
	if values.has(new_item):
		return
	values.append(new_item)
	_update_pills()


func get_value_at_index(index: int) -> Variant:
	return values[index]


func select_value(value: Variant) -> void:
	current_value = values.find(value)


func select_value_no_signal(value: Variant) -> void:
	var index: int = values.find(value)
	if index < 0:
		return
	_internal_value = index
	_update_reset_visibility(index != reset_value)


func select_index_no_signal(index: int) -> void:
	_internal_value = index
	_update_reset_visibility(index != reset_value)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	_update_reset_visibility(false)
	value_changed.emit(current_value)


func _on_button_left_pressed():
	current_value = max(0, _internal_value - 1)


func _on_button_right_pressed():
	current_value = min(values.size() - 1, _internal_value + 1)
