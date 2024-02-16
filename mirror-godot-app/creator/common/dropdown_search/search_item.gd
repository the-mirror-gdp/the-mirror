extends Button


signal button_double_clicked()

@export var metadata = {}

@export var virtual_focus_style: StyleBox = null
@export var standard_style: StyleBox = null

@export var virtual_focus: bool:
	set(value):
		virtual_focus = value
		var new_style = virtual_focus_style if value else standard_style
		add_theme_stylebox_override("normal", new_style)


func _gui_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton and input_event.double_click:
		get_window().set_input_as_handled()
		button_double_clicked.emit()
