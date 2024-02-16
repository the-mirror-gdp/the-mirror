@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: Vector2)

@export var reset_value := Vector2.ZERO
@export var current_value := Vector2.ZERO:
	get:
		if _number_fields == null:
			return reset_value
		return Vector2(_number_fields[0].current_value, _number_fields[1].current_value)
	set(value):
		if _number_fields == null:
			return
		_update_reset_visibility(not value.is_equal_approx(reset_value))
		for i in range(2):
			_number_fields[i].current_value = value[i]
			_number_fields[i].refresh()

@export var unit_suffix: String = ""
@export var step: float = 0.001

@onready var _number_fields = [$Content/X, $Content/Y]


func _ready():
	_label_node.text = label_text
	for i in range(2):
		_number_fields[i].step = step
		_number_fields[i].unit_suffix = unit_suffix
		_number_fields[i].refresh_full()
		_number_fields[i].value_submitted.connect(emit_value_submitted)
	_update_reset_visibility(not current_value.is_equal_approx(reset_value))


func cleanup_and_delete() -> void:
	for i in range(2):
		_number_fields[i].cleanup_and_delete()
	queue_free()


func _on_number_field_value_changed(_new_value: float) -> void:
	_update_reset_visibility(not current_value.is_equal_approx(reset_value))
	value_changed.emit(current_value)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	value_changed.emit(current_value)
