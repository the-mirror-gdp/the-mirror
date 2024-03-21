extends Control


enum DATA_SOURCE {
	USER_SPACES,
	BUILD_SPACES,
	PUBLISHED_SPACES,
}

enum SpaceSortOrder {
	POPULAR = 0,
	LAST_UPDATED = 1,
}

@export var _data_source: DATA_SOURCE
@export var _space_panel: PackedScene

@onready var _endless_scroll_flow_container = %EndlessScrollFlowContainer
@onready var _source_option_button: OptionButton = %SourceOptionButton
@onready var _search_field = %SearchField
@onready var _audio_stream_player = $AudioStreamPlayer


var _sort_order: SpaceSortOrder = SpaceSortOrder.LAST_UPDATED
var _published_spaces: Array = []
var _last_visibility_state = false
var _search_title: String = ""
var _search_tags: Array[String] = []


func _get_sort_by() -> String:
	var id = _source_option_button.get_selected_id()
	match id:
		SpaceSortOrder.LAST_UPDATED:
			return "createdAt"
		SpaceSortOrder.POPULAR:
			return "popular"
	return "popular"


func _get_sort_order() -> String:
	var id = _source_option_button.get_selected_id()
	match id:
		SpaceSortOrder.LAST_UPDATED:
			return "desc"
		SpaceSortOrder.POPULAR:
			return "asc"
	return "asc"


func _get_spaces(params) -> Promise:
	match _data_source:
		DATA_SOURCE.USER_SPACES:
			return Net.space_client.get_current_user_spaces(params)
		DATA_SOURCE.BUILD_SPACES:
			return Net.space_client.get_discover_spaces(params)
		DATA_SOURCE.PUBLISHED_SPACES:
			return Net.space_client.get_published_spaces(params)
	return Net.space_client.get_discover_spaces(params) # shouldn't get here


func _compare_params(params, start_by_item ) -> bool:
	if params.start_by_item != start_by_item:
		return false
	if params.search != _search_title:
		return false
	if params.tags != _search_tags:
		return false
	if params.sort_by != _get_sort_by():
		return false
	if params.order != _get_sort_order():
		return false
	return true


func _fetch_results_cb(number_of_items: int, start_item: int) -> Promise:
	var params = Net.space_client.SpaceListRequestParameters.new()
	params.per_page = number_of_items
	#params.page = start_item/number_of_items + 1 # Couting from 1
	params.start_by_item = start_item
	params.search = _search_title
	params.field = "name"
	params.sort_by = _get_sort_by()
	params.order = _get_sort_order()
	params.tags = _search_tags
	var return_promise: Promise = Promise.new()
	var promise: Promise = _get_spaces(params)
	promise.connect_func_to_fulfill(func():
		if promise.is_error():
			return_promise.set_error(promise.get_error_message())
			return
		if not _compare_params(params, start_item):
			# Search parameter changed, but we do not want to return error to user,
			# Just quietly ignore this response
			var container_data = _endless_scroll_flow_container.EndlessScrollerDataPortion.new()
			container_data.start_item = -1
			container_data.total_in_query = 0
			container_data.data = []
			return_promise.set_result(container_data)
			return
		var page: Dictionary = promise.get_result()
		var assets_arr: Array = page.get("data", [])
		var total = page.get("total", 0)
		var container_data = _endless_scroll_flow_container.EndlessScrollerDataPortion.new()
		container_data.start_item = start_item
		container_data.total_in_query = total
		container_data.data = assets_arr
		return_promise.set_result(container_data)

	)
	return return_promise


func _ready() -> void:
	# defer signal, otherwise visible flag is sometimes not updated
	visibility_changed.connect(_on_visibility_changed, CONNECT_DEFERRED)
	if _source_option_button:
		_sort_order = _source_option_button.get_item_id(_source_option_button.selected)
	await LoginUI.wait_till_login(get_tree())
	_endless_scroll_flow_container.fetch_callable = _fetch_results_cb
	_endless_scroll_flow_container.on_item_created_callable = _on_space_item_added


func _reset():
	_endless_scroll_flow_container.clear()
	if not _is_able_to_refresh():
		return
	_endless_scroll_flow_container.setup(size)

var _first_refresh_completed = false

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_last_visibility_state = false
		return
	# Do not refresh if state changed from visible to visible
	if _last_visibility_state != true and not _first_refresh_completed:
		_reset()
		_last_visibility_state = true
		_first_refresh_completed = true


func _is_able_to_refresh() -> bool:
	return Firebase.Auth and not Firebase.Auth.get_jwt().is_empty()


func on_space_created(space_data: Variant) -> void:
	_reset()


func on_search_title(search: String) -> void:
	var words = search.split(" ", false)
	var title_words: Array[String] = []
	_search_tags = []
	for word in words:
		if word.begins_with("#"):
			_search_tags.append(word.right(-1))
		else:
			title_words.append(word)
	_search_title = " ".join(title_words)
	_reset()


func _on_space_item_added(panel: Control) -> void:
	if panel.has_signal(&"create_pressed"):
		panel.create_pressed.connect(_on_create_pressed)
	#if panel.has_signal("publish_pressed"):
	#	panel.publish_pressed.connect(_on_publish_pressed)
	if panel.has_signal("space_pressed"):
		panel.space_pressed.connect(_on_space_pressed)


func _on_create_pressed() -> void:
	GameUI.main_menu_ui.change_page(&"My_Spaces")
	GameUI.main_menu_ui.change_subpage(&"SelectTemplate")
	_audio_stream_player.play()


func _on_space_pressed(space: Dictionary) -> void:
	GameUI.main_menu_ui.change_subpage("ViewSpace", space)
	_audio_stream_player.play()


func _on_source_option_button_item_selected(index):
	_reset()


func populate(search: String) -> void:
	_search_field.set_text(search)
	on_search_title(search)


func _on_refresh_pressed():
	_reset()
