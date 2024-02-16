extends Control


@onready var _label = $Label


func set_title_text(new_text: String) -> void:
	_label.text = new_text
	if new_text.length() > 20:
		# Magic numbers, feel free to adjust if needed.
		var font_size: int = 400.0 / sqrt(new_text.length())
		_label.add_theme_font_size_override(&"font_size", mini(font_size, 52))
