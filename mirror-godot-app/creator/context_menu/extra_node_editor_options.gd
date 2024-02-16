extends VBoxContainer


@onready var _close_editor: Button = $CloseEditor

var _context_menu: PanelContainer = null
var _creator_ui: CreatorUI
var _extra_node_visual_editor: ExtraNodeVisualEditor = null


func setup(context_menu: PanelContainer, creator_ui: CreatorUI) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(_clear)
	_creator_ui = creator_ui


func open(object: ExtraNodeVisualEditor) -> void:
	set_visible(true)
	_extra_node_visual_editor = object


func _clear() -> void:
	set_visible(false)
	_extra_node_visual_editor = null


func _on_focus_pressed() -> void:
	if is_instance_valid(_extra_node_visual_editor):
		_creator_ui.select_object(_extra_node_visual_editor)
		if _creator_ui.is_game_mode(GameMode.Mode.BUILD):
			_creator_ui.focus_build_mode_camera()
	_context_menu.close()


func _on_close_editor_pressed() -> void:
	if is_instance_valid(_extra_node_visual_editor):
		_extra_node_visual_editor.write_data_and_update_space_object()
		var parent: Node = _extra_node_visual_editor.get_parent()
		parent.remove_child(_extra_node_visual_editor)
		_extra_node_visual_editor.free()
		_creator_ui.select_object(parent)
	_context_menu.close()
