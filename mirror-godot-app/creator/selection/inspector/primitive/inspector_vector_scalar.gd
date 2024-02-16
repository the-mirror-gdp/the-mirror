@tool
extends "inspector_vector3.gd"


const LINKED_TEXTURE: Texture2D = preload("res://ui/art/linked.svg")
const UNLINKED_TEXTURE: Texture2D = preload("res://ui/art/unlinked.svg")

@onready var _xyz: Control = $Content/XYZ
@onready var _label_holder_z: Control = $Content/XYZ/LabelHolderZ
@onready var _linked_button: Button = $LinkedButton
@onready var _xyz_spin_box: Control = $Content/XYZ/SpinBoxHolder/SpinBox


func _ready() -> void:
	super()
	_xyz.current_value = _number_fields[0].current_value
	_xyz.refresh()


func setup_from_vector3(start_value: Vector3) -> void:
	current_value = start_value
	set_unified(is_value_unified())
	refresh_xyz()


func set_include_z(include_z: bool) -> void:
	_label_holder_z.visible = include_z
	_number_fields[2].visible = not _xyz.visible and include_z


func set_unified(is_unified: bool) -> void:
	_xyz.visible = is_unified
	_xyz_spin_box.editable = enabled
	_number_fields[0].visible = not is_unified
	_number_fields[1].visible = not is_unified
	_number_fields[2].visible = not is_unified and _label_holder_z.visible
	if is_unified:
		_linked_button.icon = LINKED_TEXTURE
		if not is_value_unified():
			current_value = Vector3.ONE * current_value.x
			value_changed.emit(current_value)
		refresh_xyz()
	else:
		_linked_button.icon = UNLINKED_TEXTURE


func refresh_xyz() -> void:
	_xyz.current_value = current_value.x
	_xyz.refresh()


func is_value_unified() -> bool:
	return current_value.x == current_value.y \
			and current_value.x == current_value.z


func hide_linked_button() -> void:
	_linked_button.hide()


func _on_linked_button_pressed() -> void:
	set_unified(not _xyz.visible)


func _on_xyz_value_changed(new_value: float) -> void:
	current_value = Vector3.ONE * new_value
	value_changed.emit(current_value)


func _on_xyz_value_preview(new_value: float) -> void:
	value_preview.emit(Vector3.ONE * new_value)
