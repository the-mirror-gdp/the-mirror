extends PanelContainer

signal changed(sort_by, order, tags, asset_type)

@export var filter_asset_type: bool:
	set(value):
		%AssetType.visible = value
	get:
		return %AssetType.visible


@onready var _option_category = $MarginContainer/FilterMenu/Category/HBoxContainer/OptionCategory
@onready var _option_sort_by = $MarginContainer/FilterMenu/SortBy/HBoxContainer/OptionSortBy
@onready var _option_asset_type = $MarginContainer/FilterMenu/AssetType/HBoxContainer/OptionAssetType
@onready var _reset_category = $MarginContainer/FilterMenu/Category/HBoxContainer/ResetCategory
@onready var _reset_sort_by = $MarginContainer/FilterMenu/SortBy/HBoxContainer/ResetSortBy
@onready var _reset_asset_type = $MarginContainer/FilterMenu/AssetType/HBoxContainer/ResetAssetType


func _ready() -> void:
	await LoginUI.wait_till_login(get_tree())
	var promise = Net.asset_client.get_public_library_tags()
	var tags = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error during receing public library tags!")
		return
	var mat_tags = tags.filter(func(tag): return tag.get("__t","") == "ThemeTag")
	mat_tags.sort_custom(func(a, b): return a.get("name").naturalnocasecmp_to(b.get("name")) < 0)
	_option_category.delete_dropdown_filter_menu_items()
	_option_category.add_dropdown_filter_menu_item(tr(_option_category.default_text), null)
	for tag in mat_tags:
		var tag_data = {
			"name": tag.get("name"),
			"category": tag.get("__t", "").trim_suffix("Tag").to_camel_case()
		}
		_option_category.add_dropdown_filter_menu_item( tag.get("name"), tag_data)


func is_default():
	return ( _option_sort_by.get_selected_id() == 0
			and _option_category.selected_metadata == null
			# 3 is an id in _option_asset_type for "All"
			and (not filter_asset_type or _option_asset_type.get_selected_id() == 3)
	)


func get_sort_by() -> String:
	return {
		0: 'updatedAt',
		1: 'updatedAt',
		2: 'name',
	}.get(_option_sort_by.get_selected_id(), 'updatedAt')


func get_sort_by_name() -> String:
	var idx = _option_sort_by.get_item_index(_option_sort_by.get_selected_id())
	return _option_sort_by.get_item_text(idx)


func get_asset_type() -> String:
	var all := 'MESH,AUDIO,IMAGE'
	return {
		0: 'MESH',
		1: 'AUDIO',
		2: 'IMAGE',
		3: all
	}.get(_option_asset_type.get_selected_id(), all)


func get_asset_type_name() -> String:
	var idx = _option_asset_type.get_item_index(_option_asset_type.get_selected_id())
	return _option_asset_type.get_item_text(idx)


func get_order() -> String:
	return  {
		0: 'desc',
		1: 'asc',
		2: 'asc'
	}.get(_option_sort_by.get_selected_id(), 'desc')


func get_tags() -> Dictionary:
	var tags = {}
	if _option_category.selected_metadata != null:
		tags = _option_category.selected_metadata
	return tags


func get_tags_names() -> Array:
	var tags = []
	if _option_category.selected_metadata != null:
		tags = [_option_category.text]
	return tags


func reset_sort_by():
	_option_sort_by.select(0)
	update_filter_criteria()


func reset_category():
	_option_category.clear_dropdown_search()
	update_filter_criteria()


func reset_asset_type():
	_option_asset_type.select(0)
	update_filter_criteria()


func update_filter_criteria():
	var tags = get_tags()
	_reset_category.visible = tags.size() > 0
	_reset_sort_by.visible = _option_sort_by.get_selected_id() != 0
	_reset_asset_type.visible = _option_asset_type.get_selected_id() != 3
	changed.emit(get_sort_by(), get_order(), tags, get_asset_type())


func _on_option_sort_by_item_selected(index):
	update_filter_criteria()


func _on_option_category_item_selected(title, metadata):
	update_filter_criteria()


func _on_option_asset_type_item_selected(index):
	update_filter_criteria()


func _on_reset_category_pressed():
	reset_category()


func _on_reset_sort_by_pressed():
	reset_sort_by()


func _on_reset_asset_type_pressed():
	reset_asset_type()
