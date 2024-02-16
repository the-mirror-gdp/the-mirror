extends MarginContainer


signal text_submitted(new_text: String)
signal text_changed(new_text: String)
signal search_icon_pressed()
signal search_gui_input(event: InputEvent)

@export var placeholder_text = "search over 5000+ assets"
@export var text_changed_delay: float = 0.5
@export var style_enabled: StyleBox
@export var style_disabled: StyleBox
@export var disabled: bool:
	set(value):
		disabled = value
		if is_instance_valid(_line_edit_node):
			_line_edit_node.editable = not disabled
			_update_style()

var _time_to_emit_text_changed: float = INF

@onready var _line_edit_node: LineEdit = $Panel/HBoxContainer/SearchField/LineEdit
@onready var _panel = $Panel


func _update_style():
	if not is_instance_valid(_panel):
		return
	_panel.remove_theme_stylebox_override("panel")
	if disabled:
		_panel.add_theme_stylebox_override("panel", style_disabled)
	else:
		_panel.add_theme_stylebox_override("panel", style_enabled)


func _ready():
	_line_edit_node.focus_entered.connect(_on_focus_entered)
	_line_edit_node.focus_exited.connect(_on_focus_exited)
	_line_edit_node.placeholder_text = placeholder_text
	_update_style()


func _process(delta: float) -> void:
	_time_to_emit_text_changed -= delta
	if _time_to_emit_text_changed < 0.0:
		text_changed.emit(_line_edit_node.text)
		_time_to_emit_text_changed = INF


func clear_text() -> void:
	var old_value_empty = _line_edit_node.text.is_empty()
	_line_edit_node.text = ""
	if not old_value_empty:
		text_changed.emit("")


func get_text() -> String:
	return _line_edit_node.text


func set_text(search_text: String) -> void:
	_line_edit_node.text = search_text


func _on_line_edit_text_submitted(new_text: String) -> void:
	text_submitted.emit(new_text)


func _on_focus_entered():
	GameUI.grab_input_lock(self)


func _on_focus_exited():
	GameUI.release_input_lock(self)


func focus():
	_line_edit_node.grab_focus()
	_line_edit_node.select_all()


func _on_line_edit_text_changed(new_text: String) -> void:
	if is_zero_approx(text_changed_delay):
		text_changed.emit(new_text)
	else:
		_time_to_emit_text_changed = text_changed_delay


func _on_search_icon_pressed() -> void:
	search_icon_pressed.emit()


func _on_line_edit_gui_input(event):
	search_gui_input.emit(event)
