extends Panel

signal selected_material_slot_changed()

@export var local_materials_dir: String
@export var _asset_slot_scene: PackedScene
@export var _instance_slot_scene: PackedScene

@onready var search_field = %Assets/VBoxContainer/TopContainer/SearchField
@onready var materials_list_container = %Assets/VBoxContainer/MarginContainer/Panel/ScrollContainer/VBoxContainer/MaterialsListContainer
@onready var _type_option_button = %Assets/VBoxContainer/TopContainer/TypeOptionButton
@onready var _source_option_button: OptionButton = %Assets/VBoxContainer/TopContainer/SourceOptionButton
@onready var _more_button = %Assets/VBoxContainer/MarginContainer/Panel/ScrollContainer/VBoxContainer/MoreButton
@onready var _name_label = %Assets/VBoxContainer/NameLabel

@onready var _instances_list_container = %InstancesListContainer
@onready var _asset_preview = $AssetPreview



const SOURCE_ALL := 0
const SOURCE_LOCAL := 1
const SOURCE_REMOTE := 2

var _materials: Array[Dictionary] = []
var _tags: Array[String] = ["local"]
var _selected_slot: AssetSlot
var _page_number = 1


func clean_search_bar() -> void:
	_type_option_button.clear_dropdown_search()
	_source_option_button.select(SOURCE_ALL)
	search_field.clear_text()


func clean_selected_slot() -> void:
	_selected_slot = null
	_name_label.text = ""
	selected_material_slot_changed.emit()


func set_selected_slot(slot: AssetSlot, _select_asset_id: bool) -> void:
	if slot == _selected_slot:
		return
	if _selected_slot and is_instance_valid(_selected_slot):
		_selected_slot.set_selected(false)
	if slot:
		slot.set_selected(true)
	_selected_slot = slot
	if slot and slot.asset_data:
		_name_label.text = slot.asset_data.asset_name
	selected_material_slot_changed.emit()


func get_selected_slot() -> Control:
	if not is_instance_valid(_selected_slot):
		return null
	return _selected_slot


func _cleanup_material_list() -> void:
	for n in materials_list_container.get_children():
		materials_list_container.remove_child(n)
		n.queue_free()


func _has_material_id(asset_id: String) -> bool:
	for n in materials_list_container.get_children():
		if n.asset_id == asset_id:
			return true
	return false


func _search_local_materials() -> void:
	var search_text = search_field.get_text()
	var tag = ""
	if _type_option_button.selected_metadata != null:
		tag = _type_option_button.text
	_materials = Net.asset_client.get_local_assets(search_text, Enums.ASSET_TYPE.MATERIAL, tag)
	for asset_dict in _materials:
		var asset_slot: AssetSlot = _asset_slot_scene.instantiate()
		asset_slot.slot_activated.connect(set_selected_slot)
		materials_list_container.add_child(asset_slot)
		asset_slot.populate_item_slot(asset_dict)


func _search_library_materials():
	await LoginUI.wait_till_login(get_tree())
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = _page_number
	params.search = search_field.get_text()
	params.field = "name"
	params.type = Enums.ASSET_TYPE.MATERIAL
	params.sort_by = "name"
	params.order = "desc"
	params.per_page = 35
	if _type_option_button.selected_metadata != null:
		params.tag_type = "material"
		params.tags = [_type_option_button.selected_metadata]

	var promise = Net.asset_client.get_library_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Material Search Results Error", promise.get_error_message())
		return
	var total_pages = page.get("totalPage", 1)
	var page_num = page.get("page_num", 1)
	if not is_visible_in_tree(): # or not _results_container.visible:
		return
	var assets_arr: Array = page.get("data", [])
	_populate_grid(assets_arr)
	if total_pages > page_num:
		_more_button.show()


func _ready() -> void:
	_page_number = 1
	await LoginUI.wait_till_login(get_tree())
	_cleanup_material_list()
	#_search_local_materials()
	_search_library_materials()
	var promise = Net.asset_client.get_public_library_tags()
	var tags = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Failed to get tags", promise.get_error_message())
		tags = []
	var mat_tags = tags.filter(func(tag): return tag.get("__t","") == "MaterialTag")
	mat_tags.sort_custom(func(a, b): return a.get("name").naturalnocasecmp_to(b.get("name")) < 0)
	_type_option_button.delete_dropdown_filter_menu_items()
	_type_option_button.add_dropdown_filter_menu_item(tr(_type_option_button.default_text), null)
	for tag in mat_tags:
		_type_option_button.add_dropdown_filter_menu_item( tag.get("name"), tag.get("name"))
	_populate_instances_list()
	Zone.material_manager.material_instance_created.connect(_on_instance_created)
	Zone.material_manager.material_instance_removed.connect(_on_instance_removed)


func search():
	_page_number = 1
	_cleanup_material_list()
	_more_button.hide()
	#if _source_option_button.get_selected_id() != SOURCE_REMOTE:
	#	_search_local_materials()
	if _source_option_button.get_selected_id() != SOURCE_LOCAL:
		_search_library_materials()


func _on_search_field_text_changed(new_text) -> void:
	search()


func _on_source_option_button_item_selected(index):
	search()


func _populate_grid(assets_arr: Array) -> void:
	for asset_dict in assets_arr:
		var asset_slot: AssetSlot = _asset_slot_scene.instantiate()
		asset_slot.slot_activated.connect(set_selected_slot)
		asset_slot.allow_empty_file_url = true
		if _has_material_id(asset_dict._id):
			continue
		materials_list_container.add_child(asset_slot)
		asset_slot.populate_item_slot(asset_dict)


func _on_more_button_pressed():
	_page_number += 1
	_search_library_materials()
	_more_button.hide()


func _on_dropdown_button_item_selected(title, metadata):
	search()


func _cleanup_instances_list() -> void:
	for n in _instances_list_container.get_children():
		_instances_list_container.remove_child(n)
		n.queue_free()



func _generate_instance_preview(material: MirrorMaterial) -> ImageTexture:
	_asset_preview.position.x = -1000
	_asset_preview.position.y = -1000
	_asset_preview.size = Vector2(300, 300)
	var _preview_node = MeshInstance3D.new()
	_preview_node.mesh = SphereMesh.new()
	_preview_node.material_override = material
	_asset_preview.add_asset(_preview_node)
	var image = await _asset_preview.render_to_image()
	_preview_node.queue_free()
	return ImageTexture.create_from_image(image)


func _populate_instances_list() -> void:
	_cleanup_instances_list()
	var instances_list = Zone.material_manager.get_loaded_material_instances()
	for instance in instances_list:
		var asset_slot: AssetSlot = null
		var preview = await _generate_instance_preview(instance)
		asset_slot = _instance_slot_scene.instantiate()
		_instances_list_container.add_child(asset_slot)
		asset_slot.populate_item_slot({"material": instance, "preview": preview})
		asset_slot.slot_activated.connect(set_selected_slot)
	var assets_list = Zone.material_manager.get_loaded_material_assets()
	for asset in assets_list:
		var asset_slot: AssetSlot = null
		var asset_dict = Net.asset_client.get_asset_json(asset.resource_name)
		asset_slot = _asset_slot_scene.instantiate()
		asset_slot.allow_empty_file_url = true
		_instances_list_container.add_child(asset_slot)
		asset_slot.populate_item_slot(asset_dict)


func _on_instance_created(material_id) -> void:
	_populate_instances_list()


func _on_instance_removed(material_id) -> void:
	_populate_instances_list()


func _on_instances_list_container_visibility_changed() -> void:
	_populate_instances_list()
