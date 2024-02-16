extends VBoxContainer


var _context_menu: PanelContainer = null
var _recent_script_entity_slot: RecentScriptEntitySlot = null
var _creator_ui: CreatorUI

@onready var _edit_script_button: Button = $EditScript


func setup(context_menu: PanelContainer, creator_ui: CreatorUI) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(hide)
	_creator_ui = creator_ui


func open(asset_slot: RecentScriptEntitySlot) -> void:
	_recent_script_entity_slot = asset_slot
	show()


func _on_edit_asset_pressed() -> void:
	_context_menu.close()
	if is_instance_valid(_recent_script_entity_slot):
		_recent_script_entity_slot.edit_script_entity()
