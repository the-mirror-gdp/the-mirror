extends HoverableButton


@onready var _panel_container = $HBoxContainer/PanelContainer
@onready var _text_label = $HBoxContainer/TextLabel
@onready var _full_width: float = custom_minimum_size.x


func set_expanded(is_expanded: bool) -> void:
	_text_label.visible = is_expanded
	if is_expanded:
		custom_minimum_size.x = _full_width
	else:
		custom_minimum_size.x = _panel_container.size.x + 10.0
