class_name ScriptBlockCreationMenu
extends Control


enum ConstraintType {
	NONE,
	SEQUENCED_RUN,
	UNSEQUENCED_DATA,
	INPUT,
	OUTPUT,
}

var target_node: Node

@onready var _tree: Tree = $Tree
@onready var _search_bar: LineEdit = $Search
@onready var _constraint_filter: OptionButton = $Filtering/ConstraintType
@onready var _data_type_filter: OptionButton = $Filtering/DataType
@onready var _of_type_label: Label = $Filtering/OfType

var _signal_tree_populator: ScriptEntrySignalTreePopulator
var _script_block_signatures: Array[Dictionary]
var _search_text: String = ""
var _entry_tree_item: TreeItem
var _tree_items: Array[TreeItem] = []
var _category_tree_items: Dictionary = {} # Dictionary[String, TreeItem]
var _category_nosearch_collapse: Dictionary = {} # Dictionary[String, bool]


func setup(signal_tree_populator: ScriptEntrySignalTreePopulator, script_block_signatures: Array[Dictionary]) -> void:
	_signal_tree_populator = signal_tree_populator
	_script_block_signatures = script_block_signatures


func set_constraints(constraint: int, data_type: ScriptBlock.PortType) -> void:
	_constraint_filter.selected = _constraint_filter.get_item_index(constraint)
	_data_type_filter.selected = _data_type_filter.get_item_index(data_type)
	_update_filtering()
	_search_bar.grab_focus()
	_search_bar.select_all()


func get_desired_block_json() -> Dictionary:
	var tree_item: TreeItem = _tree.get_selected()
	if not tree_item:
		return {}
	var metadata = tree_item.get_metadata(0)
	if metadata == null:
		return {}
	var block_json: Dictionary = metadata.duplicate(true)
	# Set the type of math blocks to the desired type (or float if none).
	var data_type: ScriptBlock.PortType = _data_type_filter.get_item_id(_data_type_filter.selected) as ScriptBlock.PortType
	if not data_type in ScriptBlockMath.MATH_PORT_TYPES:
		data_type = ScriptBlock.PortType.FLOAT
	if block_json.has("inputs"):
		_replace_math_port_with_actual_type(block_json["inputs"], data_type)
	if block_json.has("outputs"):
		_replace_math_port_with_actual_type(block_json["outputs"], data_type)
	return block_json


func get_registered_block_json(block_name: String) -> Dictionary:
	for block_json in _script_block_signatures:
		if block_json["name"] == block_name:
			return block_json.duplicate(true)
	return {}


func _replace_math_port_with_actual_type(ports: Array, data_type: ScriptBlock.PortType) -> void:
	for port in ports:
		if port[1] == ScriptBlock.PortType.MATH:
			port[1] = data_type
			port[2] = type_convert(port[2], data_type)


func create_tree_items() -> void:
	if _search_text.is_empty():
		_save_collapsed_categories()
	_tree.clear()
	_tree_items.clear()
	_category_tree_items.clear()
	var root: TreeItem = _tree.create_item()
	root.set_text(0, "Blocks")
	root.set_selectable(0, false)
	for block_json in _script_block_signatures:
		assert(block_json.has("description"))
		if block_json.has("local_only") and not GameplaySettings.script_show_client_server_checkboxes:
			continue
		var tree_item: TreeItem
		if block_json.has("category"):
			tree_item = _create_tree_item_for_block_in_category(block_json["category"])
		else:
			tree_item = _tree.create_item()
		var block_name: String = block_json["name"]
		tree_item.set_text(0, block_json["name"])
		tree_item.set_tooltip_text(0, block_json["description"])
		tree_item.set_metadata(0, block_json)
		if block_name == "Entry":
			_create_entry_signal_tree_items(tree_item)
		else:
			_tree_items.append(tree_item)
	if _search_text.is_empty():
		_load_collapsed_categories()


func _create_tree_item_for_block_in_category(category_name_str: String) -> TreeItem:
	var category_tree_item: TreeItem
	if _category_tree_items.has(category_name_str):
		category_tree_item = _category_tree_items[category_name_str]
	else:
		category_tree_item = _tree.create_item()
		_category_tree_items[category_name_str] = category_tree_item
		category_tree_item.set_selectable(0, false)
		category_tree_item.set_text(0, category_name_str)
		category_tree_item.set_tooltip_text(0, _get_category_tooltip_text(category_name_str))
		category_tree_item.collapsed = _search_text.is_empty()
	return _tree.create_item(category_tree_item)


func _get_category_tooltip_text(category_name_str: String) -> String:
	var cat_name_snake: String = category_name_str.to_snake_case()
	if ScriptPropertyRegistration.has_registered_property(cat_name_snake):
		return ScriptPropertyRegistration.get_property_description(cat_name_snake)
	return VisualScriptBlockRegistration.get_category_description(category_name_str)


func _create_entry_signal_tree_items(entry_tree_item: TreeItem) -> void:
	_entry_tree_item = entry_tree_item
	entry_tree_item.set_selectable(0, false)
	entry_tree_item.collapsed = _search_text.is_empty()
	_signal_tree_populator.populate_tree_item_with_signals(entry_tree_item, _tree, target_node)
	for entry_signal_category in entry_tree_item.get_children():
		entry_signal_category.set_selectable(0, false)
		entry_signal_category.collapsed = _search_text.is_empty()
		var entry_category_name: String = "EntryCategory" + entry_signal_category.get_text(0)
		_category_tree_items[entry_category_name] = entry_signal_category
		for entry_signal_item in entry_signal_category.get_children():
			_tree_items.append(entry_signal_item)
	_category_tree_items["Entry"] = entry_tree_item
	return


func _on_constraint_type_item_selected(_index: int) -> void:
	_update_filtering()


func _on_data_type_item_selected(_index: int) -> void:
	_update_filtering()


func _update_filtering() -> void:
	var constraint: ConstraintType = _constraint_filter.get_item_id(_constraint_filter.selected) as ConstraintType
	var data_type: ScriptBlock.PortType = _data_type_filter.get_item_id(_data_type_filter.selected) as ScriptBlock.PortType
	var is_math_type: bool = data_type in ScriptBlockMath.MATH_PORT_TYPES
	var show_data_type: bool = constraint in [ConstraintType.INPUT, ConstraintType.OUTPUT]
	_of_type_label.visible = show_data_type
	_data_type_filter.visible = show_data_type
	for tree_item in _tree_items:
		var block_json: Dictionary = tree_item.get_metadata(0)
		tree_item.visible = _does_tree_item_match_search(block_json, _search_text)
		if constraint == ConstraintType.NONE or not tree_item.visible:
			continue
		if constraint == ConstraintType.SEQUENCED_RUN:
			tree_item.visible = bool(block_json["sequenced"])
			continue
		if constraint == ConstraintType.UNSEQUENCED_DATA:
			tree_item.visible = not bool(block_json["sequenced"])
			continue
		var has_suitable_port: bool = false
		var array_to_search_through: Array
		if constraint == ConstraintType.INPUT:
			array_to_search_through = block_json.get("inputs", [])
		else:
			array_to_search_through = block_json.get("outputs", [])
		for port_json in array_to_search_through:
			var block_port_type: ScriptBlock.PortType = port_json[1]
			if is_math_type and block_port_type == ScriptBlock.PortType.MATH \
					or block_port_type == ScriptBlock.PortType.ANY_DATA \
					or data_type == ScriptBlock.PortType.ANY_DATA \
					or block_port_type == data_type:
				has_suitable_port = true
				break
		tree_item.visible = has_suitable_port
	for category_name in _category_tree_items:
		var category_tree_item: TreeItem = _category_tree_items[category_name]
		category_tree_item.visible = _is_any_child_visible(category_tree_item)
	_entry_tree_item.visible = constraint == ConstraintType.NONE and _entry_tree_item.visible


## Checks if the current TreeItem matches. Does not consider children.
func _does_tree_item_match_search(block_json: Dictionary, search_query: String) -> bool:
	if search_query.is_subsequence_ofn(block_json["name"]):
		return true
	if block_json.has("enum_values"):
		var enum_values: Array = block_json["enum_values"]
		for enum_value in enum_values:
			if search_query.is_subsequence_ofn(enum_value):
				return true
	if block_json.has("keywords"):
		var keywords: Array = block_json["keywords"]
		for keyword in keywords:
			if search_query.is_subsequence_ofn(keyword):
				return true
	return false


func _is_any_child_visible(tree_item: TreeItem) -> bool:
	var children = tree_item.get_children()
	for child in children:
		if child.visible:
			return true
	return false


func _on_search_text_changed(new_text: String) -> void:
	if new_text.is_empty() and not _search_text.is_empty():
		_load_collapsed_categories()
	elif _search_text.is_empty() and not new_text.is_empty():
		_save_collapsed_categories()
		_expand_all_categories()
	_search_text = new_text
	_update_filtering()


func _save_collapsed_categories() -> void:
	for category_name in _category_tree_items:
		var item: TreeItem = _category_tree_items[category_name]
		_category_nosearch_collapse[category_name] = item.collapsed


func _expand_all_categories() -> void:
	for category_name in _category_tree_items:
		var item: TreeItem = _category_tree_items[category_name]
		item.collapsed = false


func _load_collapsed_categories() -> void:
	for category_name in _category_tree_items:
		var item: TreeItem = _category_tree_items[category_name]
		item.collapsed = _category_nosearch_collapse.get(category_name, true)


func _on_tree_item_activated():
	var selected_item: TreeItem = _tree.get_selected()
	if selected_item.get_metadata(0) == null:
		selected_item.collapsed = not selected_item.collapsed
		return
	var parent_dialog: ConfirmationDialog = get_parent()
	parent_dialog._on_confirmed()
	parent_dialog.hide()
