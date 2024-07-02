extends Control


signal inspector_updated()
signal inspected_object_name_updated(target_node: Node)
signal request_add_script_dialog(target_node: Node)
signal request_script_edit(script_instance: ScriptInstance)
signal request_convert_prim_model_to_local(prim_model_space_object: SpaceObject)
signal request_save_local_prim_model()
signal request_select_and_focus_on_node(selected_node: Node)

const _OBJECT_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_object.tscn")
const _AUDIO_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_audio.tscn")
const _ENVIRONMENT_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_environment.tscn")
const _LIGHT_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_light.tscn")
const _PHYSICS_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_physics.tscn")
const _VISIBILITY_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_visibility.tscn")
const _SCRIPT_OBJECT_VARS_CATEGORY = preload("res://creator/selection/inspector/script/inspector_script_object_vars.tscn")
const _SCRIPT_INSTANCE_CATEGORY = preload("res://creator/selection/inspector/script/inspector_script_instance.tscn")
const _MODEL_NODES_CATEGORY = preload("res://creator/selection/inspector/nodes/inspector_model_nodes.tscn")
const _EXTRA_NODE_CATEGORY = preload("res://creator/selection/inspector/nodes/inspector_extra_node.tscn")
const _TRANSFORM_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_transform.tscn")
const _MODEL_PRIMITIVE_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_model_primitive.tscn")
const _MODEL_ROOT_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_model_root.tscn")
const _SPAWN_POINT_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_spawn_point.tscn")
const _MAP_CATEGORY = preload("res://creator/selection/inspector/categories/inspector_map.tscn")

@export var _selection_helper: Node3D
@export var _tab_properties_icon: Texture2D
@export var _tab_scripting_icon: Texture2D
@export var _tab_nodes_icon: Texture2D
@export var _tab_materials_icon: Texture2D

var _target_nodes: Array[Node] = []
var _restricted_to_script_instance: ScriptInstance
var _deletion_target_category: InspectorCategoryBase

@onready var _creator_title_tab: VBoxContainer = $VBoxContainer/CreatorTitleTab
@onready var _tab_cont: TabContainer = $VBoxContainer/TabContainer
@onready var _tab_properties = $VBoxContainer/TabContainer/Properties
@onready var _tab_scripting = $VBoxContainer/TabContainer/Scripting
@onready var _tab_nodes = $VBoxContainer/TabContainer/Nodes
@onready var _tab_materials = $VBoxContainer/TabContainer/Materials

@onready var _categories: VBoxContainer = _tab_cont.get_node(^"Properties/MarginContainer/Categories")
@onready var _script_main_vbox: VBoxContainer = _tab_cont.get_node(^"Scripting/MarginContainer/VBoxContainer")
@onready var _script_obj_vars: Control = _script_main_vbox.get_node(^"ScriptObjectVars")
@onready var _script_instances: VBoxContainer = _script_main_vbox.get_node(^"ScriptInstances")
@onready var _script_add_button: Button = _script_main_vbox.get_node(^"AddScriptButton")
@onready var _model_nodes_main_vbox: VBoxContainer = _tab_cont.get_node(^"Nodes/MarginContainer/VBoxContainer")
@onready var _model_nodes: VBoxContainer = _model_nodes_main_vbox.get_node(^"ModelNodes")
@onready var _extra_node_create_button: Button = _model_nodes_main_vbox.get_node(^"ExtraNodeCreateButton")
@onready var _button_sound: Node = $ButtonSound
@onready var _delete_dialog: ConfirmationDialog = $DeleteDialog
@onready var _surfaces_item_list: ItemList = $VBoxContainer/TabContainer/Materials/MarginContainer/VBoxContainer/MarginContainer/SurfacesItemList
@onready var _surface_pick_button = $VBoxContainer/TabContainer/Materials/MarginContainer/VBoxContainer/SurfaceLabelHolder/HBoxContainer/SurfacePickButton
@onready var _material_inspector = $VBoxContainer/TabContainer/Materials/MarginContainer/VBoxContainer/MaterialInspector
@onready var _surface_material = $VBoxContainer/TabContainer/Materials/MarginContainer/VBoxContainer/SurfaceMaterial
@onready var _audio_stream_player_tab_changed: AudioStreamPlayer = $AudioStreamPlayerTabChanged



func _ready() -> void:
	assert(_script_instances != null)
	_setup_tabs_icons()


func _setup_tabs_icons() -> void:
	var prop_idx = _tab_cont.get_tab_idx_from_control(_tab_properties)
	var script_idx = _tab_cont.get_tab_idx_from_control(_tab_scripting)
	var node_idx = _tab_cont.get_tab_idx_from_control(_tab_nodes)
	var materials_idx = _tab_cont.get_tab_idx_from_control(_tab_materials)
	_tab_cont.set_tab_icon(prop_idx, _tab_properties_icon)
	_tab_cont.set_tab_icon(script_idx, _tab_scripting_icon)
	_tab_cont.set_tab_icon(node_idx, _tab_nodes_icon)
	_tab_cont.set_tab_icon(materials_idx, _tab_materials_icon)


func _select_surface_in_list(mi: MeshInstance3D, surface_id: int) -> void:
	_surfaces_item_list.deselect_all()
	var cnt = _surfaces_item_list.item_count
	for i in cnt:
		var meta = _surfaces_item_list.get_item_metadata(i)
		if meta[0] == mi and meta[1] == surface_id:
			_surfaces_item_list.select(i, true)
			_surfaces_item_list.ensure_current_is_visible()
			# ItenList will not emit a signal on its own
			_surfaces_item_list.item_selected.emit(i)
			break


func _extract_surface_name(mi: MeshInstance3D, surface_id: int) -> String:
	var mesh = mi.mesh
	if not is_instance_valid(mesh):
		return str(surface_id)
	var material = mesh.surface_get_material(surface_id)
	if not is_instance_valid(material) or material.resource_name.is_empty():
		return str(surface_id)
	return material.resource_name


func _refresh_material_tabs(selected_nodes: Array[Node]):
	_surface_pick_button.set_pressed_no_signal(false)
	_surfaces_item_list.visible = selected_nodes.size() != 0
	_material_inspector.visible = selected_nodes.size() != 0
	if selected_nodes.size() == 0:
		return
	var mesh_nodes = selected_nodes.filter(func(target_node):
		return target_node is SpaceObject and target_node.asset_type == Enums.ASSET_TYPE.MESH
	)
	var materials_idx = _tab_cont.get_tab_idx_from_control(_tab_materials)
	_tab_cont.set_tab_hidden(materials_idx, mesh_nodes.size() == 0)

	var previously_selected_idx = -1
	if  _surfaces_item_list.get_selected_items().size() == 1:
		previously_selected_idx = _surfaces_item_list.get_selected_items()[0]
	_surfaces_item_list.clear()
	var space_obj_cnt = 0
	var idx = -1
	for space_obj in mesh_nodes:
		var mesh_instances = Util.recursive_find_nodes_of_type(space_obj.scaled_model, MeshInstance3D)
		for mi in mesh_instances:
			var surface_cnt = mi.get_surface_override_material_count()
			for x in surface_cnt:
				var surface_name = ""
				if mesh_nodes.size() > 1:
					surface_name += "%d " % space_obj_cnt
				if mesh_instances.size() > 1:
					surface_name += "%s " %  mi.name
				surface_name += _extract_surface_name(mi, x)
				idx = _surfaces_item_list.add_item(surface_name, _tab_materials_icon)
				_surfaces_item_list.set_item_metadata(idx, [mi, x, space_obj])
		space_obj_cnt += 1
	if not is_instance_valid(GameUI.instance.creator_ui):
		return
	if idx > -1:
		if previously_selected_idx != -1 and previously_selected_idx < idx:
			# We try to select previously selected surface, if it exists
			# This maybe a different surface in different mesh, but there is no harm in it
			idx = previously_selected_idx
		_surfaces_item_list.select(idx, true)
		_surfaces_item_list.ensure_current_is_visible()
		_on_surfaces_item_list_item_selected(idx, false)
	var material_creator = GameUI.instance.creator_ui.material_creator_window.material_creator
	Util.safe_signal_connect(material_creator.on_surface_material_updated, _on_surface_material_updated)
	Util.safe_signal_connect(_material_inspector.material_created, _on_material_created)


func refresh_inspected_nodes(force_rebuild: bool = true) -> void:
	inspect_nodes(_target_nodes, force_rebuild)


func refresh_global_scripts() -> void:
	if get_single_selected_node() is SpaceGlobalScripts:
		refresh_inspected_nodes()


func select_nodes(selected_nodes: Array[Node]) -> void:
	inspect_nodes(selected_nodes)


## Inspects the given nodes and their descendants with our high-level inspector.
## If the target nodes are already being inspected and force_rebuild is false,
## this will skip updating the inspector. When the tree structure of a node's
## children changes, this method needs to be called with force_rebuild = true.
func inspect_nodes(new_nodes: Array[Node], force_rebuild: bool = false) -> void:
	if not force_rebuild:
		# Check if the arrays are the same. If they are, we can skip rebuilding.
		if _target_nodes.hash() == new_nodes.hash():
			return
	# Disconnect changed signal from old nodes and connect to new ones.
	for old_node in _target_nodes:
		if not is_instance_valid(old_node):
			continue
		if old_node is SpaceObject:
			if old_node.node_structure_changed.is_connected(refresh_inspected_nodes):
				old_node.node_structure_changed.disconnect(refresh_inspected_nodes)
			if old_node.locked_state_changed.is_connected(refresh_inspected_nodes):
				old_node.locked_state_changed.disconnect(refresh_inspected_nodes)
			if old_node.scripts_changed.is_connected(_on_scripts_changed):
				old_node.scripts_changed.disconnect(_on_scripts_changed)
	for new_node in new_nodes:
		assert(is_instance_valid(new_node))
		if new_node is SpaceObject:
			if not new_node.node_structure_changed.is_connected(refresh_inspected_nodes):
				new_node.node_structure_changed.connect(refresh_inspected_nodes)
			if not new_node.locked_state_changed.is_connected(refresh_inspected_nodes):
				new_node.locked_state_changed.connect(refresh_inspected_nodes)
	# From here on, either the new target is different, and/or force_rebuild
	# was set to true, so we are rebuilding the inspector categories.
	# The first step is to delete old categories if they exist.
	_remove_old_category_children(_categories)
	_remove_old_category_children(_script_instances)
	_remove_old_category_children(_script_obj_vars)
	_remove_old_category_children(_model_nodes)
	# Update a few misc things.
	_button_sound.refresh()
	_script_add_button.show()
	_update_name_and_size(new_nodes)
	# Set up the inspector categories.
	_setup_new_categories(new_nodes)
	# If there are a few categories, show them all by default.
	# If there are a lot of categories, hide them all by default.
	_set_category_visibility_based_on_count(_categories, 5)
	_set_category_visibility_based_on_count(_script_instances, 4)
	_set_category_visibility_based_on_count(_model_nodes, 4)

	_refresh_material_tabs(new_nodes)
	_target_nodes = new_nodes

	var script_idx = _tab_cont.get_tab_idx_from_control(_tab_scripting)
	var scripts_hidden = _target_nodes.size() != 1
	_tab_cont.set_tab_hidden(script_idx, scripts_hidden)


func set_tab(tab_id: int = 0) -> void:
	_tab_cont.current_tab = tab_id


## Some parts of the UI only support interacting with a single SpaceObject.
## For example, creating a script event or extra node only supports one target.
func get_single_selected_space_object() -> SpaceObject:
	return get_single_selected_node() as SpaceObject


func get_single_selected_node() -> Node:
	if _target_nodes.size() == 1:
		return _target_nodes[0]
	return null


func restrict_script_inspector_to_instance(script_instance: ScriptInstance) -> void:
	_restricted_to_script_instance = script_instance
	if not script_instance:
		if get_single_selected_node() is SpaceGlobalScripts:
			refresh_inspected_nodes()
		return
	_remove_old_category_children(_script_instances)
	_setup_script_instance(script_instance)
	_set_category_visibility_based_on_count(_script_instances, 4)
	_script_add_button.hide()


func _remove_old_category_children(category_root: Control) -> void:
	for child in category_root.get_children():
		child.cleanup_and_delete()
		category_root.remove_child(child)


func _set_category_visibility_based_on_count(category_root: Control, count: int) -> void:
	if category_root.get_child_count() <= count:
		for child in category_root.get_children():
			child.set_visible_to_maximum_size()


func _update_name_and_size(target_nodes: Array[Node]) -> void:
	if target_nodes.is_empty():
		size_flags_stretch_ratio = 0.1
		_creator_title_tab.secondary_name = ""
	else:
		size_flags_stretch_ratio = 1.0
		if target_nodes.size() == 1:
			_creator_title_tab.secondary_name = str(_get_node_true_name(target_nodes.front()))
		else:
			_creator_title_tab.secondary_name = "Multiple objects selected"
	_creator_title_tab.refresh()


func _setup_new_categories(target_nodes: Array[Node]) -> void:
	if target_nodes.size() == 0:
		_script_main_vbox.hide()
		_tab_cont.tabs_visible = false
	elif target_nodes.size() == 1:
		var target_node = target_nodes.front()
		if target_node is SpaceObject and target_node.get_heightmap_or_null() == null:
			# On single SpaceObjects, show the object category and all tabs.
			var cat = _setup_category(target_node, _OBJECT_CATEGORY)
			cat.name_updated.connect(_on_object_name_updated.bind(target_node))
			if target_node.scaled_model.is_block_model():
				var prim_model_cat = _setup_category(target_node, _MODEL_ROOT_CATEGORY)
				prim_model_cat.request_convert_to_local.connect(_on_request_convert_prim_model_to_local.bind(target_node))
			target_node.scripts_changed.connect(_on_scripts_changed)
			_setup_script_instances(target_node)
			_setup_script_obj_vars(target_node)
			_script_main_vbox.show()
			_tab_cont.tabs_visible = true
			_setup_extra_model_nodes(target_node)
		else:
			_tab_cont.tabs_visible = false
			if target_node is SpaceGlobalScripts:
				_tab_cont.current_tab = 1
				target_node.scripts_changed.connect(_on_scripts_changed)
				_setup_script_instances(target_node)
				_setup_script_obj_vars(target_node)
				_script_main_vbox.show()
			else:
				_tab_cont.current_tab = 0
		if target_node is ModelRoot:
			var cat = _setup_category(target_node, _MODEL_ROOT_CATEGORY)
			cat.model_name_updated.connect(_on_object_name_updated.bind(target_node))
			cat.request_save_local.connect(_on_request_save_local_prim_model)
		if target_node is Node3D:
			_setup_category(target_node, _TRANSFORM_CATEGORY)
	else: # target_nodes.size() > 1
		_tab_cont.current_tab = 0
		_tab_cont.tabs_visible = false
		if _selection_helper and target_nodes.any(func(node): return node is Node3D):
			_setup_category(_selection_helper, _TRANSFORM_CATEGORY)
	# Set up these categories for each node. If multiple, use a suffix.
	for target_node in target_nodes:
		var custom_suffix: String = ""
		if target_nodes.size() > 1:
			custom_suffix = _get_node_true_name(target_node)
		if target_node is SpaceObject and target_node.asset_type == Enums.ASSET_TYPE.MESH:
			_setup_category(target_node, _PHYSICS_CATEGORY, custom_suffix)
			_setup_category(target_node, _VISIBILITY_CATEGORY, custom_suffix)
		if target_node is WorldEnvironment:
			_setup_category(target_node, _ENVIRONMENT_CATEGORY, custom_suffix)
		if target_node is ModelPrimitive:
			_setup_category(target_node, _MODEL_PRIMITIVE_CATEGORY, custom_suffix)
		_setup_many(target_node, _AUDIO_CATEGORY, AudioStreamPlayer3D, custom_suffix)
		_setup_many(target_node, _LIGHT_CATEGORY, Light3D, custom_suffix)
		_setup_many_meta(target_node, _SPAWN_POINT_CATEGORY, "OMI_spawn_point")
		if target_node is SpaceObject:
			if target_node.asset_type == Enums.ASSET_TYPE.MAP:
				_setup_category(target_node, _MAP_CATEGORY, custom_suffix)


## Sets up potentially multiple categories by searching for descendant nodes.
func _setup_many(target_node: Node, category_scene: PackedScene, node_type, custom_suffix: String = ""):
	var suffixes: PackedStringArray = []
	if not custom_suffix.is_empty():
		suffixes.append(custom_suffix)
	var found_nodes = Util.recursive_find_nodes_of_type(target_node, node_type)
	for node in found_nodes:
		if String(node.name).begins_with("__"):
			continue
		var node_suffixes: PackedStringArray = suffixes.duplicate()
		if found_nodes.size() > 1:
			node_suffixes.append(String(node.name))
		if node_type == GeometryInstance3D and node is MeshInstance3D:
			# This is a bit weird, but it should be the only exception. Most
			# nodes don't need duplicate inspector categories, just meshes.
			var surface_count = node.get_surface_override_material_count()
			for i in range(node.get_surface_override_material_count()):
				var material_suffixes: PackedStringArray = node_suffixes.duplicate()
				if surface_count > 1:
					material_suffixes.append(str(i))
				var cat = _setup_category(node, category_scene, " / ".join(material_suffixes))
				cat.target_surface = i
		else:
			# Most cases use this simpler code (anything but materials for MeshInstance3D).
			_setup_category(node, category_scene, " / ".join(node_suffixes))


## Sets up potentially multiple categories by searching for descendant nodes.
func _setup_many_meta(target_node: Node, category_scene: PackedScene, meta: String, custom_suffix: String = ""):
	var suffixes: PackedStringArray = []
	if not custom_suffix.is_empty():
		suffixes.append(custom_suffix)
	var found_nodes = Util.recursive_find_nodes_with_meta(target_node, meta)
	for node in found_nodes:
		if String(node.name).begins_with("__"):
			continue
		var node_suffixes: PackedStringArray = suffixes.duplicate()
		node_suffixes.append(String(node.name))
		# Most cases use this simpler code (anything but materials for MeshInstance3D).
		_setup_category(node, category_scene, " / ".join(node_suffixes))


func _setup_category(
	category_target_node: Node,
	category_scene: PackedScene,
	custom_suffix: String = "",
	parent: Control = _categories
) -> InspectorCategoryBase:
	var instance: InspectorCategoryBase = category_scene.instantiate()
	instance.target_node = category_target_node
	if not custom_suffix.is_empty():
		instance.set_custom_suffix(": " + custom_suffix)
	instance.inspected_object_updated.connect(_on_inspected_object_updated)
	instance.refresh_inspected_nodes.connect(refresh_inspected_nodes)
	parent.add_child(instance)
	return instance


func _setup_script_instances(space_object_or_global_scripts: Node) -> void:
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	_script_add_button.visible = space_role >= Enums.ROLE.CONTRIBUTOR
	var script_instances: Array[ScriptInstance] = space_object_or_global_scripts.get_script_instances()
	if _restricted_to_script_instance in script_instances:
		_setup_script_instance(_restricted_to_script_instance)
		return
	for script_instance in script_instances:
		_setup_script_instance(script_instance)


func _setup_script_obj_vars(space_object_or_global_scripts: Node) -> void:
	# Set up script object variables inspector, if it has any.
	var object_variables: Dictionary
	if space_object_or_global_scripts.has_meta(&"MirrorScriptObjectVariables"):
		object_variables = space_object_or_global_scripts.get_meta(&"MirrorScriptObjectVariables")
	if object_variables.is_empty():
		if not _is_any_script_instance_gdscript(space_object_or_global_scripts):
			return
	var obj_var_cat = _SCRIPT_OBJECT_VARS_CATEGORY.instantiate()
	obj_var_cat.setup(space_object_or_global_scripts, Util.can_local_user_edit_scripts())
	_script_obj_vars.add_child(obj_var_cat)
	obj_var_cat.setup_object_vars(object_variables)


func _is_any_script_instance_gdscript(space_object_or_global_scripts: Node) -> bool:
	var script_instances: Array[ScriptInstance] = space_object_or_global_scripts.get_script_instances()
	for script_inst in script_instances:
		if script_inst is GDScriptInstance:
			return true
	return false


func _setup_script_instance(script_instance: ScriptInstance) -> void:
	var cat: InspectorCategoryBase = _setup_category(script_instance.target_node, _SCRIPT_INSTANCE_CATEGORY, "", _script_instances)
	cat.setup(script_instance)
	cat.request_script_edit.connect(_on_request_script_edit)
	cat.request_delete_prompt.connect(_open_delete_script_prompt.bind(cat))


func _setup_extra_model_nodes(space_object: SpaceObject) -> void:
	var model_node: Node = space_object.scaled_model.get_model_root_node()
	if not model_node:
		return # This SpaceObject's model has not loaded yet, we can't inspect its nodes.
	var has_edit_permission: bool = Util.can_edit_object_in_space(space_object)
	_extra_node_create_button.visible = has_edit_permission
	var model_cat: InspectorCategoryBase = _setup_category(model_node, _MODEL_NODES_CATEGORY, "", _model_nodes)
	model_cat.populate_model_scene_tree(model_node)
	model_cat.request_open_extra_node_create_dialog.connect(_extra_node_create_button.open_extra_node_create_dialog)
	var extra_nodes = Util.recursive_find_nodes_with_meta(model_node, &"MirrorExtraNode")
	for extra_node in extra_nodes:
		var suffix: String = str(extra_node.name) + " (" + extra_node.get_class() + ")"
		var extra_cat = _setup_category(space_object, _EXTRA_NODE_CATEGORY, suffix, _model_nodes)
		extra_cat.populate_extra_node_inspector(extra_node.get_meta(&"MirrorExtraNode"))
		extra_cat.request_select_and_focus_on_node.connect(_on_request_select_and_focus_on_node)


func _on_request_script_edit(script_instance: ScriptInstance) -> void:
	request_script_edit.emit(script_instance)


func _open_delete_script_prompt(script_category: InspectorCategoryBase) -> void:
	_deletion_target_category = script_category
	var pos: Vector2i = Vector2i(script_category.global_position) - Vector2i(250, 0)
	_delete_dialog.prompt_for_deletion("Script Instance", pos)


func _on_delete_dialog_confirmed() -> void:
	if is_instance_valid(_deletion_target_category):
		# For now only script instances can be deleted. If needed, add more code here.
		_deletion_target_category.delete_script_instance_and_self()
	_deletion_target_category = null


func _on_request_convert_prim_model_to_local(prim_model_space_object: SpaceObject) -> void:
	request_convert_prim_model_to_local.emit(prim_model_space_object)


func _on_request_save_local_prim_model() -> void:
	request_save_local_prim_model.emit()


func _on_inspected_object_updated() -> void:
	_button_sound.refresh()
	inspector_updated.emit()


func _on_object_name_updated(node: Node) -> void:
	_update_name_and_size(_target_nodes)
	inspected_object_name_updated.emit(node)


func _get_node_true_name(node: Node) -> String:
	if node is SpaceObject:
		return node.get_space_object_name()
	return String(node.name)


func _on_scripts_changed() -> void:
	_remove_old_category_children(_script_instances)
	var single_selected_node: Node = get_single_selected_node()
	if not single_selected_node or not single_selected_node.has_method(&"get_script_instances"):
		return
	_setup_script_instances(single_selected_node)
	_set_category_visibility_based_on_count(_script_instances, 4)


func _on_request_select_and_focus_on_node(selected_node: Node) -> void:
	request_select_and_focus_on_node.emit(selected_node)


func _on_scene_hierarchy_script_button_pressed(for_object: SpaceObject) -> void:
	set_tab(1)
	var script_instances: Array[ScriptInstance] = for_object.get_script_instances()
	# If there is only one script, assume the user wants that one, and open it.
	if script_instances.size() == 1:
		request_script_edit.emit(script_instances[0])


func _on_add_script_button_pressed() -> void:
	var selected_node: Node = get_single_selected_node()
	if not is_instance_valid(selected_node):
		return
	assert(selected_node is SpaceObject or selected_node is SpaceGlobalScripts, "The add script button shouldn't be visible in any other case.")
	request_add_script_dialog.emit(selected_node)


func _on_material_creator_button_pressed() -> void:
	var selected_surface = _surfaces_item_list.get_selected_items()
	if selected_surface.size() != 1:
		#GameUI.instance.creator_ui.material_creator_window.edit_material_for_mesh()
		return
	var data = _surfaces_item_list.get_item_metadata(selected_surface[0])
	# data contains [MeshInstance, surface_id, SpaceObject]
	GameUI.instance.creator_ui.material_creator_window.edit_material_for_mesh(data[2], data[0], data[1])


func _on_surface_picked(data) -> void:
	_surface_pick_button.set_pressed_no_signal(false)
	GameplayTools.material_selector.enabled = false
	if data == null:
		return
	_select_surface_in_list(data.mesh, data.surface_id)


func _on_surface_pick_button_toggled(button_pressed) -> void:
	if not button_pressed:
		return
	GameplayTools.material_selector.space_object_material_selected.connect(_on_surface_picked, CONNECT_ONE_SHOT)
	GameplayTools.material_selector.enabled = true


func _on_surfaces_item_list_item_selected(index, setup_mesh = true) -> void:
	var data = _surfaces_item_list.get_item_metadata(index)
	var space_object: SpaceObject = data[2]
	var mesh: MeshInstance3D = data[0]
	var surface_id: int = data[1]
	if setup_mesh:
		_material_inspector.setup_mesh_target(space_object, mesh, surface_id)
	var mesh_path = space_object.scaled_model.get_path_to(mesh)
	var key: String = "%s:surface_%d" % [mesh_path, surface_id]
	var surf_mat_data = space_object.surface_material_id.get(key)
	if surf_mat_data != null and surf_mat_data is Array and surf_mat_data.size() == 2:
		_surface_material.current_value = surf_mat_data
	#elif not space_object.material_id.is_empty():
	#	_surface_material.current_value = [Enums.MATERIAL_TYPE.ASSET, space_object.material_id]
	else:
		_surface_material.current_value = ["", ""]


func _on_surface_material_updated(mi: MeshInstance3D, surface_id: int, material: MirrorMaterial) -> void:
	var selected_surface = _surfaces_item_list.get_selected_items()
	if selected_surface.size() != 1:
		return
	var data = _surfaces_item_list.get_item_metadata(selected_surface[0])
	if mi != data[0] or surface_id != data[1]:
		return
	# force reload of material data
	_material_inspector.setup_mesh_target(data[2], data[0], data[1])


func _on_surface_material_value_changed(new_value):
	var material_type = new_value[0]
	var material_id = new_value[1]
	var selected_surface = _surfaces_item_list.get_selected_items()
	if selected_surface.size() != 1:
		return
	var data = _surfaces_item_list.get_item_metadata(selected_surface[0])
	if data == null:
		return
	var space_object: SpaceObject = data[2]
	var is_asset = material_type == Enums.MATERIAL_TYPE.ASSET
	await space_object.set_surface_material(data[0], data[1], material_id, is_asset)
	# force reload of material data
	if not is_instance_valid(data[0]):
		return
	_material_inspector.setup_mesh_target(space_object, data[0], data[1])


func _on_material_created(type: String, material_id: String) -> void:
	_surface_material.current_value = [type, material_id]


func _on_tab_container_tab_changed(_tab: int) -> void:
	if is_instance_valid(_audio_stream_player_tab_changed):
		_audio_stream_player_tab_changed.play()
