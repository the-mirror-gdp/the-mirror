class_name ScriptCommentGraphNode
extends GraphNode


signal comment_changed()
signal request_comment_color_edit(comment_graph_node: GraphNode, color: Color)

const _SNAP_MULTIPLE = Vector2(20.0, 20.0)
# Value determined from trial-and-error. (40, 60) is too little.
const _COMMENT_MARGIN = Vector2(50.0, 70.0)

var script_comment: VisualScriptComment
var _stylebox_focused: StyleBoxFlat
var _stylebox_unfocused: StyleBoxFlat
var _default_color: Color
var _queue_update_comment_frames: int = -1000

@onready var _body_text_edit: TextEdit = $Holder/BodyTextEdit
@onready var _title_line_edit: LineEdit = $Holder/TitleLineEdit


func _process(_delta: float) -> void:
	_queue_update_comment_frames -= 1
	if _queue_update_comment_frames == 0:
		comment_changed.emit()


func _gui_input(input_event: InputEvent) -> void:
	if not input_event is InputEventMouseButton:
		return
	if input_event.double_click:
		title = ""
		_title_line_edit.show()
		_title_line_edit.grab_focus()
		_title_line_edit.select_all()
		get_viewport().set_input_as_handled()
	elif input_event.is_action_pressed(&"secondary_action"):
		request_comment_color_edit.emit(self, _stylebox_focused.bg_color)
		get_viewport().set_input_as_handled()


func setup(in_script_comment: VisualScriptComment) -> void:
	script_comment = in_script_comment
	_setup()
	script_comment.script_comment_received_network_update.connect(_setup)


func _setup() -> void:
	title = script_comment.title
	_title_line_edit.text = script_comment.title
	_set_body_text(script_comment.text)
	position_offset = script_comment.position
	size = script_comment.size
	_setup_styleboxes_and_color()
	update_comment_size()


func cleanup_and_delete() -> void:
	if is_instance_valid(script_comment):
		script_comment.script_comment_received_network_update.disconnect(_setup)
	script_comment = null
	get_parent().remove_child(self)
	queue_free()


func _set_body_text(new_text: String) -> void:
	# If an update happens too soon after an edit, ignore it, because
	# we don't want echo updates to disrupt the user.
	if _queue_update_comment_frames > -50:
		return
	var column: int = _body_text_edit.get_caret_column(0)
	var line: int = _body_text_edit.get_caret_line(0)
	_body_text_edit.text = new_text
	_body_text_edit.set_caret_column(column)
	_body_text_edit.set_caret_line(line)


func _setup_styleboxes_and_color() -> void:
	_stylebox_focused = get_theme_stylebox(&"comment_focus").duplicate()
	add_theme_stylebox_override(&"comment_focus", _stylebox_focused)
	_stylebox_unfocused = get_theme_stylebox(&"comment").duplicate()
	add_theme_stylebox_override(&"comment", _stylebox_unfocused)
	_default_color = _stylebox_focused.bg_color
	_stylebox_focused.bg_color = script_comment.color
	_stylebox_unfocused.bg_color = script_comment.color


func set_comment_color(color: Color) -> void:
	_stylebox_focused.bg_color = color
	_stylebox_unfocused.bg_color = color
	script_comment.color = color


func _on_color_picker_popup_hide() -> void:
	_queue_update_comment_frames = 10


func _on_resize_request(new_size: Vector2) -> void:
	new_size = new_size.snapped(_SNAP_MULTIPLE)
	size = new_size
	script_comment.size = new_size
	_queue_update_comment_frames = 10


func _on_position_offset_changed() -> void:
	script_comment.position = position_offset
	_queue_update_comment_frames = 10


func update_comment_size() -> void:
	await get_tree().process_frame
	if not is_instance_valid(script_comment):
		return
	custom_minimum_size = (_body_text_edit.get_minimum_size() + _COMMENT_MARGIN).snapped(_SNAP_MULTIPLE)
	script_comment.size = size


func _on_body_text_changed() -> void:
	# Update the text.
	script_comment.text = _body_text_edit.text
	_queue_update_comment_frames = 10
	# Ensure the comment is big enough to handle the text.
	update_comment_size()


func _on_title_line_edit_text_submitted(new_text: String) -> void:
	title = new_text
	script_comment.title = new_text
	_title_line_edit.hide()
	_queue_update_comment_frames = 10


func _on_title_line_edit_focus_exited() -> void:
	title = _title_line_edit.text
	script_comment.title = _title_line_edit.text
	_title_line_edit.hide()
	_queue_update_comment_frames = 10
