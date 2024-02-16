@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: Vector3)
signal value_preview(new_value: Vector3)

@export var reset_value := Vector3.ZERO
@export var current_value := Vector3.ZERO:
	get:
		if _number_fields == null:
			return reset_value
		return Vector3(_number_fields[0].current_value, _number_fields[1].current_value, _number_fields[2].current_value)
	set(value):
		if _number_fields == null:
			return
		_update_reset_visibility(not value.is_equal_approx(reset_value))
		for i in range(3):
			_number_fields[i].current_value = value[i]
			_number_fields[i].refresh()

@export var unit_suffix: String = ""
@export var step: float = 0.001
@export var enabled: bool = true:
	set(value):
		if _number_fields == null:
			return
		enabled = value
		for field in _number_fields:
			if is_instance_valid(field):
				field.enabled = enabled

@onready var _number_fields = [$Content/X, $Content/Y, $Content/Z]


func _ready():
	_label_node.text = label_text
	for i in range(3):
		_number_fields[i].step = step
		_number_fields[i].unit_suffix = unit_suffix
		_number_fields[i].refresh_full()
		_number_fields[i].value_submitted.connect(emit_value_submitted)
	_update_reset_visibility(not current_value.is_equal_approx(reset_value))


func cleanup_and_delete() -> void:
	for i in range(3):
		_number_fields[i].cleanup_and_delete()
	queue_free()


func _on_number_field_value_changed(_new_value: float) -> void:
	_update_reset_visibility(not current_value.is_equal_approx(reset_value))
	value_changed.emit(current_value)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	value_changed.emit(current_value)


func _on_x_value_preview(new_value):
	value_preview.emit(Vector3(
			new_value,
			_number_fields[1].current_value,
			_number_fields[2].current_value)
	)


func _on_y_value_preview(new_value):
	value_preview.emit(Vector3(
			_number_fields[0].current_value,
			new_value,
			_number_fields[2].current_value)
	)


func _on_z_value_preview(new_value):
	value_preview.emit(Vector3(
			_number_fields[0].current_value,
			_number_fields[1].current_value,
			new_value)
	)
