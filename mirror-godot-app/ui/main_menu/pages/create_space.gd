extends Control


@onready var _space_name_edit: LineEdit = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SpaceNameEdit
@onready var _preview_image = %Preview
@onready var _space_theme_label = %SpaceThemeLabel

var space_data: Dictionary = {"name": ""}


signal create_pressed(data: Dictionary)
signal cancel_pressed()


# Sets the space name
func _on_space_name_edit_changed(new_text):
	space_data["name"] = new_text


func _on_cancel_pressed():
	cancel_pressed.emit()


func _on_create_space_pressed():
	space_data["name"] = _space_name_edit.text
	create_pressed.emit(space_data)


func populate(template_data) -> void:
	if template_data.has("images") and not template_data.images.is_empty():
		if template_data.images[0] != null:
			_preview_image.set_image_from_url(template_data.images[0])
	if template_data.has("_id"):
		space_data["template_id"] = template_data["_id"]
	if template_data.has("name"):
		_space_theme_label.text = tr("%s Space Theme") % template_data["name"]
