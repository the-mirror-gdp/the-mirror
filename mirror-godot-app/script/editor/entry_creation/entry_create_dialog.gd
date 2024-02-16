extends ConfirmationDialog


signal create_entry_block(block_json: Dictionary)

@onready var _entry_creation_menu: Control = $ScriptEntryCreationMenu
@onready var _signal_tree_populator = $ScriptEntrySignalTreePopulator


func _ready() -> void:
	_entry_creation_menu.setup(_signal_tree_populator)


func populate_and_show(target_node: Node) -> void:
	title = "Create Script Entry"
	_entry_creation_menu.populate_selection_tree(target_node)
	GameUI.grab_input_lock(self)
	popup_centered()
	_entry_creation_menu.focus_search_bar()


func _on_confirmed() -> void:
	var signal_dict = _entry_creation_menu.get_desired_signal_signature()
	if signal_dict == null:
		title = "Create Entry With Custom Signal"
		popup_centered()
		return
	var block_dict: Dictionary = signal_dict.duplicate(false)
	create_entry_block.emit(block_dict)


func _on_script_entry_creation_menu_confirmed() -> void:
	hide()
	_on_confirmed()
