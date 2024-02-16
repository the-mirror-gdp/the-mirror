class_name HierarchyTree
extends DraggableTree


signal selection_changed(selected_nodes: Array[Node])
signal hierarchy_script_button_pressed(for_object: SpaceObject)
signal request_add_script_dialog(target_node: Node)
signal request_script_edit(script_instance: ScriptInstance)
signal restrict_inspector_to_script_instance(script_instance: ScriptInstance)

enum _TopLevelItemIndices {
	WORLD_ENTITIES = 0,
	GLOBAL_SCRIPTS = 1,
	MAPS = 2,
	ENVIRONMENT = 3,
}

enum _TreeItemButtons {
	VISIBLE = 0,
	SPACE_OBJECT_LOCK = 1,
	SPACE_OBJECT_SCRIPT = 2,
	GLOBAL_SCRIPT_ADD = 3,
	GLOBAL_SCRIPT_ENABLE = 4,
	GLOBAL_SCRIPT_DELETE = 5,
	PRIVILEGES_LOCKED = 6,
}

const HOVER_COLOR: Color = Color("#12ffd7")
const _NODE_KEY: StringName = &"meta_node"
const _GLOBAL_SCRIPT_KEY: StringName = &"meta_global_script"
const LOCAL_BLOCK_COLOR: Color = Color("#12ffd7")
const HIDDEN_NAME_PREFIXES: Array[String] = ["_", "@_"]

const _DEFAULT_TREE_ITEMS = {
	"WORLD ENTITIES": preload("res://creator/selection/scene_hierarchy/icons/globe_icon.svg"),
	"GLOBAL SCRIPTS": preload("res://creator/selection/scene_hierarchy/icons/script_global.svg"),
	"MAPS": preload("res://creator/selection/scene_hierarchy/icons/terrain_icon.svg"),
	"ENVIRONMENT": preload("res://creator/selection/scene_hierarchy/icons/environment_icon.svg"),
}

const _CHECKBOX_CHECKED = preload("res://ui/art/checkbox_checked.svg")
const _CHECKBOX_CHECKED_WHITE = preload("res://ui/art/checkbox_checked_white.svg")
const _CHECKBOX_UNCHECKED = preload("res://ui/art/checkbox_unchecked.svg")
const _DELETE_ICON = preload("res://script/editor/variable/icons/trash.svg")
const _SCRIPT_VISUAL_ICON = preload("res://creator/selection/scene_hierarchy/icons/script_visual.svg")
const _SCRIPT_TEXT_ICON = preload("res://creator/selection/scene_hierarchy/icons/script_text.svg")

var _can_emit_selection_changed = true

# This texture variables are a temporary workaround for an
# unresolved issue in Godot 4
# https://github.com/godotengine/godot/issues/56343
# Once this issue is resolved, this should be replaced with
# constants pointing to preloaded Texture2D resources
@export var _empty_icon: Texture2D
@export var _hidden_icon: Texture2D
@export var _visible_icon: Texture2D
@export var _3d_object_icon: Texture2D
@export var _effect_icon: Texture2D
@export var _lock_icon: Texture2D
@export var _script_icon: Texture2D
@export var _privileges_icon: Texture2D
@export var _top_level_font_color: Color
@export var _top_level_bg_color: Color

var _node_tree_items: Dictionary = {}
var _hovered_item: TreeItem = null
var _global_scripts_tree_item: TreeItem = null


func _ready() -> void:
	self.button_clicked.connect(_on_tree_button_clicked)
	# When changing the selection, multi_selected will be emitted for
	# deselecting the old selection, and for selecting the new selection.
	# These signals are fired while the tree is still processing the
	# selection, so we need to defer until the end of the frame when
	# it's done, otherwise we end up with unhelpful half-selections.
	self.multi_selected.connect(_on_tree_item_selected, ConnectFlags.CONNECT_DEFERRED)
	self.item_mouse_selected.connect(_on_item_mouse_selected)


func _process(_delta: float) -> void:
	# Highlight tree items when hovered
	var item = get_item_at_position(get_local_mouse_position())
	if item == _hovered_item:
		return
	_reset_hovered_item_color()
	if item:
		item.set_custom_color(0, HOVER_COLOR)
	_hovered_item = item


func get_selected_nodes() -> Array[Node]:
	var selected_nodes: Dictionary = {}
	# Returns the first selected item
	var current_item = get_next_selected(null)
	while current_item != null:
		var current_node = _get_instance_node_from_tree_item(current_item)
		# Only select valid nodes on visible TreeItems.
		if current_node and current_item.visible:
			selected_nodes[current_node] = current_item
		current_item = get_next_selected(current_item)
	var safe_selection: Array[Node] = _prevent_selecting_child_of_selection(selected_nodes.keys())
	for node in selected_nodes.keys():
		if not node in safe_selection:
			selected_nodes[node].deselect(0)
	return safe_selection


func create_top_level_item(item_name: String, icon: Texture2D, tree: Tree = self) -> void:
	var top_level_item: TreeItem = tree.create_item(tree.get_root())
	if is_instance_valid(icon):
		top_level_item.set_icon(0, icon)
		top_level_item.set_icon_max_width(0, 22)
	top_level_item.set_custom_bg_color(0, _top_level_bg_color)
	top_level_item.set_text(0, item_name)
	top_level_item.set_custom_color(0, _top_level_font_color)
	top_level_item.custom_minimum_height = 28


func get_top_level_item(index: int) -> TreeItem:
	return self.get_root().get_child(index)


func _create_named_item(node: Node, parent: TreeItem, item_name: String = "", icon: Texture2D = null, recursive := false, idx := -1) -> TreeItem:
	if _node_tree_items.keys().has(node.get_instance_id()):
		return _node_tree_items[node.get_instance_id()]
	var tree_item: TreeItem = create_item(parent, idx)
	tree_item.set_icon_max_width(0, 22)
	if parent == get_root():
		tree_item.set_custom_color(0, _top_level_font_color)
		tree_item.set_custom_bg_color(0, _top_level_bg_color)
		tree_item.custom_minimum_height = 28
	tree_item.set_expand_right(0, true)
	if is_instance_valid(icon):
		tree_item.set_icon(0, icon)
	elif node is DirectionalLight3D:
		tree_item.set_icon(0, _effect_icon)
	elif node is Node3D:
		tree_item.set_icon(0, _3d_object_icon)
		tree_item.set_icon_max_width(0, 16)
		if node is ModelPrimitive or node is ModelRoot or node is Heightmap:
			tree_item.set_custom_color(0, LOCAL_BLOCK_COLOR)
	var node_name: String = node.name
	if node is SpaceObject:
		node_name = node.get_space_object_name()
	tree_item.set_text(0, node_name if item_name.is_empty() else item_name)
	tree_item.collapsed = true
	var can_edit = Util.can_edit_object_in_space(node)
	if (node is Node3D or node is CanvasItem) and can_edit:
		var texture = _visible_icon if node.visible else _hidden_icon
		tree_item.add_button(0, texture, _TreeItemButtons.VISIBLE, false, "Toggle visibility")
	if node is SpaceObject and can_edit:
		var lock_texture: Texture2D = _lock_icon if node.locked else _hidden_icon
		tree_item.add_button(0, lock_texture, _TreeItemButtons.SPACE_OBJECT_LOCK, false, "Toggle Locked")
		node.locked_state_changed.connect(_on_tree_locked_state_updated.bind(tree_item))
		# Add script icon.
		var script_texture: Texture2D = _script_icon if node.has_script_instances() else _empty_icon
		tree_item.add_button(0, script_texture, _TreeItemButtons.SPACE_OBJECT_SCRIPT, false, "View Scripts")
		node.scripts_changed.connect(_on_tree_script_instances_changed.bind(tree_item))
	if not can_edit:
		tree_item.add_button(0, _privileges_icon, _TreeItemButtons.PRIVILEGES_LOCKED, true, "You do not have permission to edit this object")
	tree_item.set_meta(_NODE_KEY, node)
	_node_tree_items[node.get_instance_id()] = tree_item
	if recursive:
		recursively_populate_tree(node, parent)
	return tree_item


func update_tree_item_name(instance_id, new_name: String) -> void:
	if not _node_tree_items.keys().has(instance_id):
		return
	if not is_instance_valid(_node_tree_items[instance_id]):
		_node_tree_items.erase(instance_id)
		return
	var tree_item: TreeItem = _node_tree_items[instance_id]
	tree_item.set_text(0, new_name)


func recursively_populate_tree(node: Node, parent_item: TreeItem) -> void:
	if not GameplaySettings.show_space_object_internal_nodes:
		for hidden_prefix in HIDDEN_NAME_PREFIXES:
			if String(node.name).begins_with(hidden_prefix):
				return
	var current_item: TreeItem = _create_named_item(node, parent_item)
	if not node.child_exiting_tree.is_connected(_on_internal_node_removed):
		node.child_exiting_tree.connect(_on_internal_node_removed)
	if not node.child_entered_tree.is_connected(recursively_populate_tree):
		node.child_entered_tree.connect(recursively_populate_tree.bind(current_item))
	for child in node.get_children():
		recursively_populate_tree(child, current_item)


func reset_hierarchy_tree() -> void:
	clear() # Tree.clear()
	_node_tree_items.clear()
	var root: TreeItem = create_item()
	for top_item_name in _DEFAULT_TREE_ITEMS:
		create_top_level_item(top_item_name, _DEFAULT_TREE_ITEMS[top_item_name])
	_global_scripts_tree_item = root.get_child(_TopLevelItemIndices.GLOBAL_SCRIPTS)
	_global_scripts_tree_item.add_button(0, preload("res://script/visual/editor/icons/add.svg"), _TreeItemButtons.GLOBAL_SCRIPT_ADD)


func setup_space_template_nodes(environment: SpaceEnvironment, global_scripts: SpaceGlobalScripts) -> void:
	var env_tree_item: TreeItem = get_root().get_child(_TopLevelItemIndices.ENVIRONMENT)
	env_tree_item.set_meta(_NODE_KEY, environment)
	_node_tree_items[environment.get_instance_id()] = env_tree_item
	for child in environment.get_children():
		recursively_populate_tree(child, env_tree_item)
	_global_scripts_tree_item.set_meta(_NODE_KEY, global_scripts)
	_node_tree_items[global_scripts.get_instance_id()] = _global_scripts_tree_item
	global_scripts.scripts_changed.connect(refresh_global_scripts)
	refresh_global_scripts()


func refresh_global_scripts() -> void:
	for global_script_item in _global_scripts_tree_item.get_children():
		global_script_item.free()
	var global_scripts_node: SpaceGlobalScripts = _global_scripts_tree_item.get_meta(_NODE_KEY)
	for script_instance in global_scripts_node.get_script_instances():
		var script_tree_item: TreeItem = create_item(_global_scripts_tree_item)
		script_tree_item.set_meta(_NODE_KEY, global_scripts_node)
		script_tree_item.set_meta(_GLOBAL_SCRIPT_KEY, script_instance)
		script_tree_item.set_text(0, script_instance.script_name)
		var script_icon: Texture2D = _SCRIPT_VISUAL_ICON if script_instance is VisualScriptInstance else _SCRIPT_TEXT_ICON
		script_tree_item.set_icon(0, script_icon)
		var enabled_icon: Texture2D = _CHECKBOX_CHECKED if script_instance.script_enabled else _CHECKBOX_UNCHECKED
		script_tree_item.add_button(0, enabled_icon, _TreeItemButtons.GLOBAL_SCRIPT_ENABLE)
		script_tree_item.add_button(0, _DELETE_ICON, _TreeItemButtons.GLOBAL_SCRIPT_DELETE)
		if not script_instance.script_contents_changed.is_connected(refresh_global_scripts):
			script_instance.script_contents_changed.connect(refresh_global_scripts)


func search_tree(search_text: String) -> void:
	var category_tree_item: TreeItem = get_root().get_first_child()
	while category_tree_item != null:
		var tree_item: TreeItem = category_tree_item.get_first_child()
		while tree_item != null:
			if search_text.is_empty():
				tree_item.visible = true
			else:
				tree_item.visible = _does_item_match_keywords(search_text, tree_item)
			tree_item = tree_item.get_next()
		category_tree_item = category_tree_item.get_next()


func update_tree_selection(instance_id, center_on_item: bool, keep_previous_selection: bool) -> void:
	if not _node_tree_items.keys().has(instance_id):
		return
	if not keep_previous_selection:
		clear_selected_nodes()
	var tree_item: TreeItem = _node_tree_items[instance_id]
	var node = _get_instance_node_from_tree_item(tree_item)
	var selected_nodes: Array[Node] = get_selected_nodes()
	var node_idx: int = selected_nodes.find(node)
	if node_idx > -1:
		selected_nodes.remove_at(node_idx)
		tree_item.deselect(0)
	else:
		# Ensure that the parent items are uncollapsed before selecting.
		var parent: TreeItem = tree_item.get_parent()
		while parent:
			parent.collapsed = false
			parent = parent.get_parent()
		tree_item.select(0)
		selected_nodes.push_front(node)
		self.scroll_to_item(tree_item, center_on_item)
	selection_changed.emit(selected_nodes)


func select_multiple_items(new_selection_ids: Array, keep_previous_selection: bool) -> void:
	if not keep_previous_selection:
		clear_selected_nodes()
	for instance_id in new_selection_ids:
		if not _node_tree_items.keys().has(instance_id):
			continue
		var tree_item: TreeItem = _node_tree_items[instance_id]
		tree_item.select(0)
	selection_changed.emit(get_selected_nodes())


func clear_selected_nodes() -> void:
	# Returns the first selected item
	var current_item = get_next_selected(null)
	while current_item != null:
		current_item.deselect(0)
		current_item = get_next_selected(current_item)
	selection_changed.emit(get_selected_nodes())


func _prevent_selecting_child_of_selection(selected_nodes: Array) -> Array[Node]:
	var ret: Array[Node] = []
	for node in selected_nodes:
		if not _is_any_node_ancestor(node, selected_nodes):
			ret.append(node)
	return ret


func _is_any_node_ancestor(node: Node, possible_ancestors: Array) -> bool:
	for any_node in possible_ancestors:
		if any_node.is_ancestor_of(node):
			return true
	return false


func create_tree_item_for_node(node: Node) -> void:
	if _is_node_map(node):
		recursively_populate_tree(node, get_root().get_child(_TopLevelItemIndices.MAPS))
	else:
		recursively_populate_tree(node, get_root().get_child(_TopLevelItemIndices.WORLD_ENTITIES))


func _is_node_map(node: Node) -> bool:
	if node is Heightmap:
		return true
	return node is SpaceObject and node.asset_type == Enums.ASSET_TYPE.MAP


func _on_internal_node_removed(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_on_scene_node_removed(node.get_instance_id())


func _on_scene_node_removed(instance_id) -> void:
	if not _node_tree_items.keys().has(instance_id):
		return
	if not is_instance_valid(_node_tree_items[instance_id]):
		_node_tree_items.erase(instance_id)
		return
	var tree_item: TreeItem = _node_tree_items[instance_id]
	var parent: TreeItem = tree_item.get_parent()
	parent.remove_child(tree_item)
	_node_tree_items.erase(instance_id)
	tree_item.call_recursive("free")


func _on_scene_node_updated(instance_id) -> void:
	if not _node_tree_items.keys().has(instance_id):
		return
	if not is_instance_valid(_node_tree_items[instance_id]):
		_node_tree_items.erase(instance_id)
		return
	var tree_item: TreeItem = _node_tree_items[instance_id]
	var node = _get_instance_node_from_tree_item(tree_item)
	if not node:
		return
	if node is SpaceObject:
		tree_item.set_text(0, node.get_space_object_name())


## Retrieves the instanced node from the tree item meta data.
## Returns the instance or null.
func _get_instance_node_from_tree_item(tree_item: TreeItem) -> Node:
	if not tree_item.has_meta(_NODE_KEY):
		return null
	var node = tree_item.get_meta(_NODE_KEY)
	if not is_instance_valid(node) or not node.is_inside_tree():
		return null
	return node


func _get_drag_data(drag_position := Vector2.ZERO) -> Variant:
	var tree_item: TreeItem = get_item_at_position(drag_position)
	if not tree_item or not tree_item.has_meta(_NODE_KEY):
		return null
	var node: Node = tree_item.get_meta(_NODE_KEY)
	if node is SpaceObject:
		return {
			"drag_type": "dragged_space_object",
			"string_to_drop": node.name,
		}
	return null


func _get_drag_icon(drag_position := Vector2.ZERO) -> Texture2D:
	var tree_item: TreeItem = get_item_at_position(drag_position)
	return tree_item.get_icon(0)


func _can_drop_data(_drag_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		var dict: Dictionary = data
		if dict.get("drag_type") == "dragged_asset":
			var asset_type: String = dict["asset_type"]
			return asset_type == "SCRIPT"
	return false


func _drop_data(drag_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		var dict: Dictionary = data
		if dict.get("drag_type") == "dragged_asset":
			var asset_type: String = dict["asset_type"]
			if asset_type == "SCRIPT":
				var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
				if not Util.can_local_user_edit_scripts():
					Notify.warning("Permissions Error", "You don't have permission to add scripts to objects.")
					return
				var tree_item: TreeItem = get_item_at_position(drag_position)
				var target_node: Node = tree_item.get_meta(_NODE_KEY)
				var asset_data: AssetData = dict["asset_data"]
				if target_node and target_node.has_method(&"add_script_instance"):
					if _is_node_map(target_node):
						return
					Net.script_client.client_create_new_script_entity_from_asset(target_node, asset_data)


## For example, `word1 word2 block="Set Player Team" word3` will tokenize into:
## ["word1", "word2", 'block="Set Player Team"', "word3"]
func _tokenize_search_text(search_text: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var current_token: String = ""
	var inside_quotes: bool = false
	for char in search_text:
		if char == '"':
			inside_quotes = not inside_quotes
			current_token += char
		elif char == ' ' and not inside_quotes:
			if current_token != "":
				tokens.append(current_token)
				current_token = ""
		else:
			current_token += char
	if current_token != "":
		tokens.append(current_token)
	return tokens


func _does_item_match_keywords(search_text: String, tree_item: TreeItem) -> bool:
	var tree_item_name: String = tree_item.get_text(0)
	var node: Node = tree_item.get_meta(_NODE_KEY)
	var split_search_text: PackedStringArray = _tokenize_search_text(search_text)
	for keyword in split_search_text:
		if _does_item_not_match_keyword(keyword, tree_item, tree_item_name, node):
			return false
	return true


func _does_item_not_match_keyword(keyword: String, tree_item: TreeItem, item_name: String, node: Node) -> bool:
	if node is SpaceGlobalScripts:
		assert(tree_item.has_meta(_GLOBAL_SCRIPT_KEY), "Searches involving SpaceGlobalScripts should always have a global script key.")
		if keyword.begins_with("block=") or keyword.begins_with("block:"):
			var block_name: String = keyword.trim_prefix("block=").trim_prefix("block:").trim_prefix('"').trim_suffix('"')
			var global_script: ScriptInstance = tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
			if global_script is VisualScriptInstance:
				for block in global_script.script_builder.all_blocks:
					if block.graph_name.findn(block_name) != -1 or block.get_script_block_type().findn(block_name) != -1:
						return false
			return true
		elif keyword.begins_with("script_id=") or keyword.begins_with("script_id:"):
			var script_id: String = keyword.trim_prefix("script_id=").trim_prefix("script_id:")
			var global_script: ScriptInstance = tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
			return global_script.script_id != script_id
	if node is SpaceObject:
		if keyword == "locked":
			return not node.locked
		elif keyword == "unlocked":
			return node.locked
		elif keyword == "script":
			return not node.has_script_instances()
		elif keyword == "noscript":
			return node.has_script_instances()
		elif keyword.begins_with("block=") or keyword.begins_with("block:"):
			var block_name: String = keyword.trim_prefix("block=").trim_prefix("block:").trim_prefix('"').trim_suffix('"')
			for script in node.get_script_instances():
				if script is VisualScriptInstance:
					for block in script.script_builder.all_blocks:
						if block.graph_name.findn(block_name) != -1 or block.get_script_block_type().findn(block_name) != -1:
							return false
			return true
		elif keyword.begins_with("script_id=") or keyword.begins_with("script_id:"):
			var script_id: String = keyword.trim_prefix("script_id=").trim_prefix("script_id:")
			for script in node.get_script_instances():
				if script.script_id == script_id:
					return false
			return true
		elif keyword.begins_with("-"):
			var avoid_keyword: String = keyword.trim_prefix("-")
			return item_name.findn(avoid_keyword) != -1
	if node.has_method(&"is_visible"):
		if keyword == "visible":
			return not node.is_visible()
		elif keyword == "invisible":
			return node.is_visible()
	if keyword == "edit":
		return not Util.can_edit_object_in_space(node)
	elif keyword == "noedit":
		return Util.can_edit_object_in_space(node)
	return item_name.findn(keyword) == -1


func _on_tree_button_clicked(tree_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var node: Node = _get_instance_node_from_tree_item(tree_item)
	match _id:
		_TreeItemButtons.VISIBLE:
			assert(node is Node3D or node is CanvasItem)
			node.visible = not node.visible
			var texture = _visible_icon if node.visible else _hidden_icon
			tree_item.set_button(0, 0, texture)
		_TreeItemButtons.SPACE_OBJECT_LOCK:
			assert(node is SpaceObject)
			node.locked = not node.locked
		_TreeItemButtons.SPACE_OBJECT_SCRIPT:
			assert(node is SpaceObject)
			var selected_nodes: Array[Node] = [node]
			selection_changed.emit(selected_nodes)
			hierarchy_script_button_pressed.emit(node)
		_TreeItemButtons.GLOBAL_SCRIPT_ADD:
			assert(node is SpaceGlobalScripts)
			request_add_script_dialog.emit(node)
		_TreeItemButtons.GLOBAL_SCRIPT_ENABLE:
			assert(node is SpaceGlobalScripts)
			assert(tree_item.has_meta(_GLOBAL_SCRIPT_KEY))
			var global_script: ScriptInstance = tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
			global_script.script_enabled = not global_script.script_enabled
			global_script.script_instance_changed()
		_TreeItemButtons.GLOBAL_SCRIPT_DELETE:
			assert(node is SpaceGlobalScripts)
			assert(tree_item.has_meta(_GLOBAL_SCRIPT_KEY))
			var global_script: ScriptInstance = tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
			node.delete_script_instance(global_script)
		_TreeItemButtons.PRIVILEGES_LOCKED:
			Notify.info("Permissions error", "You do not have permission to edit this object")


func _on_tree_locked_state_updated(tree_item: TreeItem) -> void:
	var node = _get_instance_node_from_tree_item(tree_item)
	var texture: Texture2D = _lock_icon if node.locked else _hidden_icon
	tree_item.set_button(0, 1, texture)


func _on_tree_script_instances_changed(tree_item: TreeItem) -> void:
	var node = _get_instance_node_from_tree_item(tree_item)
	var texture: Texture2D = _script_icon if node.has_script_instances() else _empty_icon
	tree_item.set_button(0, 2, texture)


func _on_item_mouse_selected(_position: Vector2, mouse_button: int) -> void:
	if mouse_button == MOUSE_BUTTON_RIGHT and not Input.is_action_pressed(&"object_multi_select"):
		var node = _get_instance_node_from_tree_item(get_next_selected(null))
		GameUI.creator_ui.open_context_menu(node)


func _on_tree_item_selected(ui_only_tree_item: TreeItem, _selected_column: int, ui_only_is_selected: bool) -> void:
	# WARNING: This function is called multiple times when selecting tree items.
	# The TreeItem parameter will include multiple items including items being deselected.
	# This parameter can be used for updating the theme, but do not rely on it for
	# the critial logic at the bottom of this function because of duplicate emissions.
	if ui_only_tree_item.has_meta(_GLOBAL_SCRIPT_KEY):
		# Switch to a white checkbox
		var script_instance: ScriptInstance = ui_only_tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
		if script_instance.script_enabled:
			var enable_index: int = ui_only_tree_item.get_button_by_id(0, _TreeItemButtons.GLOBAL_SCRIPT_ENABLE)
			assert(enable_index != -1)
			ui_only_tree_item.set_button(0, enable_index, _CHECKBOX_CHECKED_WHITE if ui_only_is_selected else _CHECKBOX_CHECKED)
	# This pattern ensures the signal will be emitted at most once per frame.
	if not _can_emit_selection_changed:
		return
	_can_emit_selection_changed = false
	set_deferred(&"_can_emit_selection_changed", true)
	var selected_nodes: Array[Node] = get_selected_nodes()
	selection_changed.emit(selected_nodes)
	# Check if the TreeItem has a script instance directly on it, if so, edit it.
	var selected_tree_item: TreeItem = get_selected()
	if selected_nodes.size() == 1 and selected_nodes[0] is SpaceGlobalScripts:
		if selected_tree_item.has_meta(_GLOBAL_SCRIPT_KEY):
			var script_instance: ScriptInstance = selected_tree_item.get_meta(_GLOBAL_SCRIPT_KEY)
			restrict_inspector_to_script_instance.emit(script_instance)
			request_script_edit.emit(script_instance)
			return
	restrict_inspector_to_script_instance.emit(null)


func _on_mouse_entered():
	set_process(true)


func _reset_hovered_item_color():
	if is_instance_valid(_hovered_item):
		var node = _get_instance_node_from_tree_item(_hovered_item)
		if _hovered_item.get_parent() == get_root():
			_hovered_item.set_custom_color(0, _top_level_font_color)
		elif is_instance_valid(node) and node is ModelRoot:
			_hovered_item.set_custom_color(0, LOCAL_BLOCK_COLOR)
		else:
			_hovered_item.clear_custom_color(0)
		_hovered_item = null


func _on_mouse_exited():
	set_process(false)
	_reset_hovered_item_color()
