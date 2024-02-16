extends HBoxContainer


@export var settings_icon: Texture2D = null

signal page_button_pressed(page_name: StringName)


# Populates the main menu with buttons
func populate_page_buttons(page_names: Array, whitelisted_page_names: Array) -> void:
	for page_name in page_names:
		var button := Button.new()
		button.name = page_name
		var button_text = str(page_name).replacen("_", " ")
		button.text = button_text.to_upper()
		if button.name == "Settings":
			button.icon = settings_icon
			button.text = ""
		self.add_child(button)
		button.pressed.connect(_on_button_pressed.bind(button.name))
		button.visible = (
			whitelisted_page_names.is_empty()
			or page_name in whitelisted_page_names
		)


# Triggers when a button gets pressed
func _on_button_pressed(button_name: StringName) -> void:
	print("Pressed %s button" % str(button_name))
	emit_signal("page_button_pressed", button_name)
