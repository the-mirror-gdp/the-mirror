class_name BrowserSection
extends BaseBrowserSection


enum AssetSource {
	NONE = 0,
	MY_ASSETS = 1,
	MIRROR_ASSETS = 2,
}

@export var _asset_source: AssetSource = AssetSource.NONE

var _categories: Dictionary = {}
var _selected_asset_type: String = ""

# These should be @onready vars but can't be due to a Godot bug.
var _category_container: Control
var _navigation_container: Control
var _sub_category_label: Label
var _results_container: Control
var _no_results_label: Label
var _endless_results_grid
var _filter_button: Button

@onready var _label_result_count: = %LabelResultCount
@onready var _label_result_keyword: = %LabelResultKeyword
@onready var _search_field: Control = %SearchField


func _ready() -> void:
	_category_container = _section_container.get_node(^"Categories")
	_navigation_container = _section_container.get_node(^"NavigationContainer")
	_sub_category_label = _navigation_container.get_node(^"HBoxContainer/SubCatLabel")
	_results_container = _section_container.get_node(^"ResultsContainer")
	_no_results_label = _results_container.get_node(^"NoResultsLabel")
	_endless_results_grid = _results_container.get_node(^"EndlessScrollFlowContainer")
	_filter_button = _results_container.get_node(^"HBoxContainer/FilterWithPills").filter_button
	super()
	_filter_button.filter_menu.changed.connect(_filter_changed)
	if _asset_source == AssetSource.MY_ASSETS:
		Net.asset_client.asset_created.connect(_on_asset_created)


func _compare_params(params, start_item ) -> bool:
	if params.start_by_item != start_item:
		return false
	if params.search != _search_field.get_text():
		return false
	if params.type != _selected_asset_type:
		return false
	var tags_data = _filter_button.filter_menu.get_tags()
	if tags_data.size() > 0:
		if params.tags != [tags_data["name"]]:
			return false
		if params.tag_type != tags_data["category"]:
			return false
	if params.sort_by != _filter_button.filter_menu.get_sort_by():
		return false
	if params.order != _filter_button.filter_menu.get_order():
		return false
	return true


func _fetch_results_cb(number_of_items: int, start_item: int) -> Promise:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.per_page = number_of_items
	#params.page = start_item/number_of_items + 1 # Couting from 1
	params.start_by_item = start_item
	params.field = "name"
	params.search = _search_field.get_text()
	params.type = _selected_asset_type
	var tags_data = _filter_button.filter_menu.get_tags()
	if tags_data.size() > 0:
		params.tags = [tags_data["name"]]
		params.tag_type = tags_data["category"]
	params.sort_by = _filter_button.filter_menu.get_sort_by()
	params.order = _filter_button.filter_menu.get_order()
	print("Requesting, nof: ", number_of_items, " si: ", start_item, " start_by_item: ", start_item)
	print("SEARCH QUERY: ", params.serialize())
	var return_promise: Promise = Promise.new()
	var promise: Promise = await _get_assets(params)
	promise.connect_func_to_fulfill(func():
		if promise.is_error():
			return_promise.set_error(promise.get_error_message())
			_category_container.hide()
			return
		if not _compare_params(params, start_item):
			# Search parameter changed, but we do not want to return error to user,
			# Just quietly ignore this response
			var container_data = _endless_results_grid.EndlessScrollerDataPortion.new()
			container_data.start_item = -1
			container_data.total_in_query = 0
			container_data.data = []
			return_promise.set_result(container_data)
			return
		var page: Dictionary = promise.get_result()
		var assets_arr: Array = page.get("data", [])
		var total = page.get("total", 0)
		var container_data = _endless_results_grid.EndlessScrollerDataPortion.new()
		container_data.start_item = start_item
		container_data.total_in_query = total
		container_data.data = assets_arr
		return_promise.set_result(container_data)

		_label_result_keyword.text = page.get("search", "")
		if page.get("search", "").is_empty():
			_sub_category_label.text = tr("All Results")
			_label_result_count.text = tr("{count} asset(s)").format({count = total})
		else:
			_sub_category_label.text = tr("Search Results for \"%s\"") % page.get("search", "")
			_label_result_count.text = tr("{count} asset(s) for").format({count = total})
		if params.page == 1 and total == 0:
			_label_result_count.text = tr("No results found.")
			# Notify.warning(tr("Search Results"), tr("Seems like page #%s is empty.") % page.get("page", "1"))
			_no_results_label.show()
	)
	return return_promise


func _on_asset_slot_added(asset_slot: AssetSlot):
	asset_slot.asset_deleted.connect(_on_asset_deleted)
	asset_slot.request_edit_asset.connect(_asset_browser.edit_slot_asset)
	asset_slot.request_edit_script_asset.connect(_asset_browser.edit_slot_script_asset)
	asset_slot.slot_activated.connect(_asset_browser.asset_slot_activated)
	asset_slot.slot_special_action.connect(_asset_browser.use_slot_asset)


func _search_fetch_and_populate():
	_endless_results_grid.clear()
	if _asset_browser_sections.size.y <= 0:
		# This is the estimate number of what
		# _asset_browser_sections.size.y should be around.
		var section_height = get_viewport_rect().size.y * 0.85
		var section_width = _asset_browser.size.x
		_endless_results_grid.fetch_and_populate(Vector2(section_width, section_height))
	else:
		_endless_results_grid.fetch_and_populate(_asset_browser_sections.size)


func setup(asset_browser: AssetBrowser, sections: Control) -> void:
	super(asset_browser, sections)
	for category in _category_container.get_children():
		category.setup(asset_browser)
	_endless_results_grid.fetch_callable = _fetch_results_cb
	_endless_results_grid.on_item_created_callable = _on_asset_slot_added
	await LoginUI.wait_till_login(get_tree())
	_endless_results_grid.setup()


func reset() -> void:
	_search_field.clear_text()
	_selected_asset_type = ""
	_show_categories()


func _on_asset_created(_new_asset: Dictionary) -> void:
	_search_for_categories()


func _on_search_field_text_submitted(search_text: String) -> void:
	if PlayerData.get_local_player() == null:
		return
	_sub_category_label.text = "Search Results for \"%s\"" % search_text
	_filter_changed()


func _filter_changed(_sort_by=null, _order=null, _tags=null, _asset_type=null):
	_asset_browser.set_selected_slot(null)
	if not is_visible_in_tree():
		return
	if _filter_button.filter_menu.filter_asset_type:
		_selected_asset_type = _filter_button.filter_menu.get_asset_type()
	_show_results()
	_search_fetch_and_populate()


func _get_assets(params) -> Promise:
	await LoginUI.wait_till_login(get_tree())
	match _asset_source:
		AssetSource.MY_ASSETS:
			return Net.asset_client.get_my_assets(params)
		AssetSource.MIRROR_ASSETS:
			# if we're not doing a name search, only get mirror assets
			if params.field != "name":
				return Net.asset_client.get_mirror_assets(params)
			else: # otherwise get the library assets
				return Net.asset_client.get_library_assets(params)
	return Promise.new()


func _on_category_view_all_pressed(category_name: String, search_text: String, field: String, asset_type: String, tag: String) -> void:
	_search_field.clear_text()
	_navigation_container.show()
	_filter_button.filter_menu.filter_asset_type = false
	_sub_category_label.text = category_name
	_selected_asset_type = asset_type
	_show_results()
	_search_fetch_and_populate()


func _on_back_button_pressed() -> void:
	if _asset_browser:
		_asset_browser.set_selected_slot(null)
	reset()


func _show_categories() -> void:
	_navigation_container.hide()
	_results_container.hide()
	_no_results_label.hide()
	_category_container.show()
	_filter_button.filter_menu.filter_asset_type = true
	_search_for_categories()


func _show_results() -> void:
	_navigation_container.show()
	_no_results_label.hide()
	_category_container.hide()
	_results_container.show()


func _search_for_categories() -> void:
	for category in _category_container.get_children():
		if not category.visible or not category is CategoryPreview:
			continue
		var params = Net.asset_client.AssetListRequestParameters.new()
		params.search = category.get_search_text()
		params.field = category.get_field()
		params.type = category.get_asset_type()
		if params.search.is_empty() and params.type.is_empty():
			continue
		category.clear()
		var results_per_page: int = 4
		if category.get_index() == 0:
			results_per_page = _calculate_results_per_page(345)
		category.set_asset_slot_count(results_per_page)
		var promise: Promise = await _get_assets(params)
		promise.connect_func_to_fulfill(func():
			if promise.is_error():
				Notify.error("Search Results Error", promise.get_error_message())
				return
			category.populate(promise.get_result())
		)


func _calculate_results_per_page(intra_holder_spacing: int = 160) -> int:
	var section_height := _asset_browser_sections.size.y
	# When we are fetching when the asset_browser is not expanded
	# Like on space join, see this PR: https://github.com/the-mirror-megaverse/mirror-godot-app/pull/1393
	if section_height <= 0:
		# This is the estimate number of what
		# _asset_browser_sections.size.y should be around.
		section_height = get_viewport_rect().size.y * 0.85
	var holder_height: int = int(section_height) - 48 * _asset_browser_sections.get_child_count()
	@warning_ignore("integer_division")
	var rows = (holder_height - intra_holder_spacing) / 96
	return maxi(1, rows) * 4


func _on_asset_deleted(asset_slot: BaseAssetSlot) -> void:
	_asset_browser.on_asset_deleted(false)
	_endless_results_grid.remove_item(asset_slot)


func _on_search_field_text_changed(new_text: String) -> void:
	_on_search_field_text_submitted(new_text)
