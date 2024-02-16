class_name UndoRedoSystem extends Node


signal object_changed


@export var undo_actions_cache_size: int = 100


# TO USE THIS MODULE:
# Add the line below after any object_node.queue_update_network_object() function call:
# object_node.on_node_property_changed(&"property_name_here", old_value_here, new_value_here)

signal actions_updated(actions_to_undo, actions_to_redo)

## Action entries are Arrays built as [object_node, property_name, old_value, new_value]
var actions_to_redo: Array[UndoRedoAction] = []
var actions_to_undo: Array[UndoRedoAction] = []

var _selected_nodes: Array[SpaceObject] = []

var _creator_ui: CreatorUI


func setup(creator_ui: CreatorUI) -> void:
	_creator_ui = creator_ui


func clear() -> void:
	actions_to_undo.clear()
	actions_to_redo.clear()
	actions_updated.emit(actions_to_undo, actions_to_redo)


func _on_selection_changed(selected_nodes: Array[Node]) -> void:
	for selected_node in _selected_nodes:
		if is_instance_valid(selected_node):
			selected_node.node_property_changed.disconnect(_on_node_property_changed)
	_selected_nodes = _get_selected_space_objects(selected_nodes)
	for selected_node in _selected_nodes:
		selected_node.node_property_changed.connect(_on_node_property_changed)


func _get_selected_space_objects(selection: Array) -> Array[SpaceObject]:
	var space_objects: Array[SpaceObject] = []
	for node in selection:
		if is_instance_valid(node) and node is SpaceObject:
			space_objects.append(node)
	return space_objects


func _unhandled_input(input_event: InputEvent) -> void:
	# Prevent undoing/redoing from the main_menu and other windows
	if GameUI.is_any_full_screen_or_modal_ui_visible():
		return
	if input_event.is_action_pressed(&"ui_redo"):
		redo()
	elif input_event.is_action_pressed(&"ui_undo"):
		undo()


## Called when connected object has a property changed locally.
func _on_node_property_changed(object_node, property_name, old_value, new_value) -> void:
	var new_action: UndoRedoAction = UndoRedoAction.new()
	new_action.add_new_record(object_node, property_name, old_value, new_value)
	record_property_change(new_action)


func record_property_change(action: UndoRedoAction) -> void:
	if actions_to_undo.size() >= undo_actions_cache_size:
		actions_to_undo.pop_back()
	actions_to_undo.push_front(action)
	actions_to_redo = []
	actions_updated.emit(actions_to_undo, actions_to_redo)
	_update_global_menu()


## Pulls last action from dictionary, adds to redo and executes.
func undo() -> void:
	var had_action_to_execute = _execute_action(actions_to_undo, actions_to_redo)
	if not had_action_to_execute:
		Notify.warning("Undo failed","Nothing left to be undone.\nThe undo stack is already empty.")


## Places redo action back to undo list and executes.
func redo() -> void:
	var had_action_to_execute = _execute_action(actions_to_redo, actions_to_undo)
	if not had_action_to_execute:
		Notify.warning("Redo failed", "Nothing left to be redone.\nThe redo stack is already empty.")


## Consumes an action from an array, inverts it, and then appends the inverted action to the other array
func _execute_action(consume_action_from: Array[UndoRedoAction], store_inverted_action_in: Array[UndoRedoAction]) -> bool:
	var action = consume_action_from.pop_front()
	if action:
		var modified_objects: Array = action.execute_undo_redo_action()
		if not modified_objects.is_empty() and modified_objects[0].has("_id"):
			Zone.send_data_to_server([Packet.TYPE.UPDATE_SPACE_OBJECTS, modified_objects])
		store_inverted_action_in.push_front(action.get_inverse_action())
		object_changed.emit()
		actions_updated.emit(actions_to_undo, actions_to_redo)
	_update_global_menu()
	return (action != null)


func _update_global_menu() -> void:
	if not OS.get_name() == "macOS":
		return
	DisplayServer.global_menu_set_item_disabled("_main/Edit", 0, actions_to_undo.is_empty())
	DisplayServer.global_menu_set_item_disabled("_main/Edit", 1, actions_to_redo.is_empty())
