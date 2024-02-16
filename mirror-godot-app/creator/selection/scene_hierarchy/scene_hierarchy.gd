class_name SceneHierarchy
extends Panel


signal selection_changed(selected_nodes)
signal hierarchy_script_button_pressed(for_object: SpaceObject)
signal item_activated()
signal request_add_script_dialog(target_node: Node)
signal request_script_edit(script_instance: ScriptInstance)
signal restrict_inspector_to_script_instance(script_instance: ScriptInstance)

var _selection_helper: SelectionHelper
var _grabber: Node

@onready var _search_field = $VBoxContainer/SearchField
@onready var _tree: HierarchyTree = $VBoxContainer/MarginContainer/Tree
@onready var _click_sound: AudioStreamPlayer = $ClickSound


func setup(grabber: Node, selection_helper: SelectionHelper):
	_selection_helper = selection_helper
	_grabber = grabber
	_tree.reset_hierarchy_tree()
	Zone.instance_manager.space_object_updated.connect(_tree._on_scene_node_updated)
	Zone.instance_manager.space_object_removed.connect(_tree._on_scene_node_removed)
	Zone.instance_manager.space_object_created.connect(create_tree_item_for_node)
	Zone.instance_manager.children_cleared.connect(_tree.reset_hierarchy_tree)
	Zone.client.disconnected.connect(_on_disconnected)
	Zone.client.join_server_complete.connect(_on_space_loaded)


func _process(_delta: float) -> void:
	if PriorityInput.is_action_pressed(&"action_deselect") and _tree.has_focus():
		_tree.release_focus()


func is_selection_empty() -> bool:
	return _tree.get_selected_nodes().is_empty()


func get_selected_nodes() -> Array[Node]:
	return _tree.get_selected_nodes()


func clear_selected_nodes() -> void:
	_selection_helper.clear_selected_nodes()
	_tree.clear_selected_nodes()


func select_nodes(new_selected_instance_ids: Array) -> void:
	var keep_previous_selection: bool = Input.is_action_pressed(&"object_multi_select")
	_tree.select_multiple_items(new_selected_instance_ids, keep_previous_selection)


func select_node(selected_node_instance_id: int) -> void:
	if Zone.is_in_play_mode():
		return
	if is_instance_valid(_grabber) and _grabber.is_enabled and is_instance_valid(_selection_helper) and _selection_helper.is_object_selected(selected_node_instance_id):
		return
	var center_on_item: bool = not is_instance_valid(_tree.get_selected())
	var keep_previous_selection: bool = Input.is_action_pressed(&"object_multi_select")
	_tree.update_tree_selection(selected_node_instance_id, center_on_item, keep_previous_selection)


func select_and_focus_on_node(selected_node: Node) -> void:
	assert(not Zone.is_in_play_mode())
	_tree.update_tree_selection(selected_node.get_instance_id(), true, false)


func create_tree_item_for_node(node: Node, uuid: String = "") -> void:
	_tree.create_tree_item_for_node(node)


func delete_tree_item(node: Node) -> void:
	_tree._on_scene_node_removed(node.get_instance_id())


func update_tree_item_name(node: Node) -> void:
	var node_name = node.get_space_object_name() if node is SpaceObject else String(node.name)
	_tree.update_tree_item_name(node.get_instance_id(), node_name)


func search_node_tree(search_text: String) -> void:
	_search_field.set_text(search_text)
	_tree.search_tree(search_text)


func refresh_global_scripts() -> void:
	_tree.refresh_global_scripts()


func _on_space_loaded() -> void:
	if Zone.Scene == null:
		# We clicked cancel on the space connection screen
		return
	var space_template: SpaceTemplate = Zone.Scene.get_space_template()
	_tree.setup_space_template_nodes(space_template.space_environment, space_template.space_global_scripts)


func _on_disconnected() -> void:
	_tree.reset_hierarchy_tree()


func _on_hierarchy_script_button_pressed(for_object: SpaceObject) -> void:
	hierarchy_script_button_pressed.emit(for_object)


func _on_selection_changed(selected_nodes: Array[Node]) -> void:
	selection_changed.emit(selected_nodes)


func _on_tree_multi_selected(_item: TreeItem, _column: int, selected: bool) -> void:
	if selected:
		_click_sound.play()


func _on_search_field_search_icon_pressed() -> void:
	Notify.info("Special Keywords", "Try searching for locked, unlocked, visible, invisible, script, noscript, edit, noedit.")


func _on_tree_item_activated() -> void:
	item_activated.emit()


func _on_tree_request_add_script_dialog(target_node: Node) -> void:
	request_add_script_dialog.emit(target_node)


func _on_tree_request_script_edit(script_instance: ScriptInstance) -> void:
	request_script_edit.emit(script_instance)


func _on_tree_restrict_inspector_to_script_instance(script_instance: ScriptInstance) -> void:
	restrict_inspector_to_script_instance.emit(script_instance)
