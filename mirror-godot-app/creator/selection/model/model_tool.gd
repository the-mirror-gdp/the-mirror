class_name ModelTool
extends Node


signal selected_model_changed()

var current_model_root: ModelRoot = null

var _is_model_mode: bool = false
var _object_selection: Control
var _scene_hierarchy: SceneHierarchy

@onready var model_builder = $ModelBuilder


func setup(object_selection: Control, scene_hierarchy: SceneHierarchy) -> void:
	_object_selection = object_selection
	_scene_hierarchy = scene_hierarchy
	scene_hierarchy.selection_changed.connect(_on_selection_changed)


func edit_mode_changed(new_edit_mode: Enums.EDIT_MODE) -> void:
	_is_model_mode = new_edit_mode == Enums.EDIT_MODE.Model
	_update_model_tool_enabled()


func zone_mode_changed(_new_zone_mode: int) -> void:
	_update_model_tool_enabled()


func load_local_model(space_object: SpaceObject) -> void:
	var promise = space_object.asset_data.get_asset_file_promise()
	assert(promise.has_result())
	var file = promise.get_result()
	_object_selection.delete_objects()
	create_local_model(space_object)
	current_model_root.load_from_node_tree(file)
	_update_model_tool_enabled()


func save_local_model() -> void:
	if not is_instance_valid(current_model_root) or current_model_root.get_child_count() == 0:
		Notify.error("Saving Model Failed", "Model has no primitives!")
		return
	var file_path_glb: String = current_model_root.save_to_gltf_file()
	# Upload as an asset.
	var asset_browser: AssetBrowser = GameUI.instance.creator_ui.asset_browser
	var promise = await asset_browser.create_asset_from_url(file_path_glb)
	if promise.is_error():
		print("Failed to save a local model: %s" % promise.get_error_message())
		return
	var asset_data = promise.get_result()
	if not is_instance_valid(current_model_root):
		return
	var properties: Dictionary = {
		"asset": asset_data["_id"],
		"position": Serialization.vector3_to_array(current_model_root.position),
		"rotation": Serialization.vector3_to_array(current_model_root.rotation),
		"scale": Serialization.vector3_to_array(current_model_root.scale),
	}
	var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
	Zone.client_send_create_space_object(properties, receipt)
	delete_local_model(current_model_root)
	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)


func create_local_model(space_object: SpaceObject = null) -> void:
	current_model_root = ModelRoot.new()
	if space_object:
		var block_model_name: String = space_object.get_space_object_name()
		var paren_index = block_model_name.find(" (")
		if paren_index != -1:
			block_model_name = block_model_name.substr(0, paren_index)
		current_model_root.name = Util.clean_string_for_model_file_path(block_model_name)
		current_model_root.transform = space_object.transform
	else:
		current_model_root.name = "New Model"
	add_child(current_model_root)
	_scene_hierarchy.create_tree_item_for_node(current_model_root)
	current_model_root.deletion_requested.connect(delete_local_model.bind(current_model_root))
	_scene_hierarchy.select_node(current_model_root.get_instance_id())
	_update_model_tool_enabled()


func delete_local_model(model_root: ModelRoot) -> void:
	assert(is_instance_valid(model_root))
	_delete_model_root(model_root)
	_update_model_tool_enabled()


func clear_children() -> void:
	for child in get_children():
		if child is ModelRoot:
			_delete_model_root(child)
	_update_model_tool_enabled()


func _delete_model_root(model_root: ModelRoot) -> void:
	if model_root == current_model_root:
		current_model_root = null
		selected_model_changed.emit(null)
	remove_child(model_root)
	_scene_hierarchy.delete_tree_item(model_root)
	model_root.queue_free()


func _update_model_tool_enabled() -> void:
	var is_enabled: bool = _is_model_mode and is_instance_valid(current_model_root) and Zone.is_in_edit_mode()
	model_builder.set_model_builder_enabled(is_enabled)
	if is_enabled:
		_scene_hierarchy.select_node(current_model_root.get_instance_id())


func _on_model_builder_request_primitive_placement(new_primitive: ModelPrimitive) -> void:
	assert(is_instance_valid(current_model_root))
	# Reinterpret the transform as the global transform, since it comes from
	# the model builder which only works in global space.
	var primitive_global_transform: Transform3D = new_primitive.transform
	current_model_root.add_child(new_primitive, true)
	new_primitive.global_transform = primitive_global_transform
	current_model_root.set_origin_point()


func _on_selection_changed(selected_nodes: Array[Node]) -> void:
	for node in selected_nodes:
		if node is ModelRoot:
			current_model_root = node
			selected_model_changed.emit(current_model_root)
			return
