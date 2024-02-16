extends VBoxContainer


@onready var _search: LineEdit = $Search
@onready var _tree: Tree = $Tree

var _signal_tree_populator: ScriptEntrySignalTreePopulator


func setup(signal_tree_populator: ScriptEntrySignalTreePopulator) -> void:
	_signal_tree_populator = signal_tree_populator


func populate_selection_tree(target_node: Node) -> void:
	_tree.clear()
	var root: TreeItem = _tree.create_item()
	root.set_text(0, "Signals")
	root.set_selectable(0, false)
	_signal_tree_populator.populate_tree_item_with_signals(root, _tree, target_node)


func focus_search_bar() -> void:
	_search.grab_focus()
	_search.select_all()


func get_selected_signal() -> Variant:
	var selected_tree_item: TreeItem = _tree.get_selected()
	if selected_tree_item == null:
		return null
	return selected_tree_item.get_metadata(0)


func _on_search_text_changed(new_text: String) -> void:
	var root_item: TreeItem = _tree.get_root()
	for base_tree_item in root_item.get_children():
		if _does_tree_item_match_search(base_tree_item, new_text):
			base_tree_item.visible = true
			for signal_tree_item in base_tree_item.get_children():
				signal_tree_item.visible = true
		else:
			base_tree_item.visible = false
			for signal_tree_item in base_tree_item.get_children():
				signal_tree_item.visible = false
				if _does_tree_item_match_search(signal_tree_item, new_text):
					signal_tree_item.visible = true
					base_tree_item.visible = true


## Checks if the current TreeItem matches, but does not consider children.
## Children are handled in the _on_search_text_changed method.
func _does_tree_item_match_search(tree_item: TreeItem, search_query: String) -> bool:
	if search_query.is_subsequence_ofn(tree_item.get_text(0)):
		return true
	var signal_metadata = tree_item.get_metadata(0)
	if signal_metadata is Dictionary:
		if signal_metadata.has("keywords"):
			var keywords: Array = signal_metadata["keywords"]
			for keyword in keywords:
				if search_query.is_subsequence_ofn(keyword):
					return true
	return false
