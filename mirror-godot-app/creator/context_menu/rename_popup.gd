extends PanelContainer


@onready var _line_edit: LineEdit = %LineEdit

var _creator_ui: CreatorUI
var _nodes_to_rename: Array = []


func _ready():
	_line_edit.focus_exited.connect(_on_focus_exited)
	_line_edit.text_submitted.connect(_on_text_submitted)


func setup(creator_ui: CreatorUI) -> void:
	_creator_ui = creator_ui


func open(nodes: Array) -> void:
	_nodes_to_rename = nodes
	if nodes.size() <= 0:
		return
	var display_name: String = _nodes_to_rename[0].name
	if _nodes_to_rename[0] is SpaceObject:
		display_name = _nodes_to_rename[0].get_space_object_name()
	_line_edit.text = display_name
	_line_edit.grab_focus()
	position = get_viewport().get_mouse_position() - size * 0.5
	_keep_in_viewport()
	show()


func _keep_in_viewport() -> void:
	var viewport_size: Vector2i = get_viewport_rect().size
	if position.x + size.x > viewport_size.x:
		position.x -= size.x
	if position.y + size.y > viewport_size.y:
		position.y -= size.y


func _on_focus_exited() -> void:
	hide()


func _on_text_submitted(text: String) -> void:
	if not visible:
		return
	for object in _nodes_to_rename:
		if object is SpaceObject:
			object.set_space_object_name(text)
			continue
		object.name = text
	_creator_ui.object_selection.refresh_inspector()
	hide()
