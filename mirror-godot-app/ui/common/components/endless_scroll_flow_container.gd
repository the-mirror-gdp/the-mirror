class_name EndlessScrollFlowContainer
extends ScrollContainer

const _V_SCROLL_WIDTH = 8  # this is taken from debugger

@export var item_scene: PackedScene
@export var preload_pages_in_advance: int = 2
@export var rows_before_fetch_request: int = 2
@export var minimum_items_per_page: int = 1


## This Callable will be called with (number_of_items, start_item) arguments
## Whenever Scroll container needs more items It expect a Promise as result,
## get_result() should cantain EndlessScrollerDataPortion instance. Each item of
## EndlessScrollerDataPortion.data will be used as populate() argument of item_scene
var fetch_callable: Callable
var on_item_created_callable: Callable

@onready var _items_container = %ItemsContainer
@onready var _loading_section = %LoadingSection
@onready var _retry_button = %RetryButton

var _item_dimensions: Vector2 = Vector2.ZERO:
	get:
		if _item_dimensions == Vector2.ZERO:
			var tmp_item: Control = item_scene.instantiate()
			_item_dimensions = tmp_item.size
		return _item_dimensions
var _current_item_offset = 0
var _is_already_requesting_next_page = false
var _lowest_known_scroll_position = 0
var _is_fully_loaded = false
var _configured = false


func clear() -> void:
	for item in _items_container.get_children():
		item.queue_free()
	_current_item_offset = 0
	_is_already_requesting_next_page = 0
	_lowest_known_scroll_position = 0
	_is_fully_loaded = false
	set_deferred("scroll_vertical", 0)


func remove_item(item: Control) -> void:
	item.queue_free()
	_current_item_offset = max(0, _current_item_offset - 1)


## This function calculates how many items can be fitted in parent container
## per row in the same time so all are visible. It takes into account spacing
func _calculate_max_per_row(forced_size = Vector2.ZERO) -> int:
	var parent_size = forced_size if forced_size != Vector2.ZERO else get_parent_area_size()
	parent_size -= Vector2(_V_SCROLL_WIDTH, 0)
	var x_sep = _items_container.get_theme_constant("h_separation")

	var x_cnt = int(parent_size.x + x_sep) / int(_item_dimensions.x + x_sep)
	#print("X number of items : ", x_cnt, " parent size: ", parent_size.x, " item size: ", _item_dimensions.x)
	return x_cnt


## This function calculates how many items can be fitted in parent container
## in total in the same time so all are visible. It takes into account spacing
func _calculate_max_items_on_screen(forced_size = Vector2.ZERO) -> int:
	var parent_size = forced_size if forced_size != Vector2.ZERO else get_parent_area_size()
	var y_sep = _items_container.get_theme_constant("v_separation")
	var y_cnt = int(parent_size.y + y_sep) / int(_item_dimensions.y + y_sep)
	return y_cnt*_calculate_max_per_row(forced_size)


func _fetch_data(cnt_items_to_fetch: int) -> Array:
	if not fetch_callable.is_valid():
		# this could be caused by the data not being initialised before this is called
		# it happens generally if you're not logged in before populating this.
		push_error("invalid fetch callable in endless scroll container")
		return []
	assert(fetch_callable.is_valid())
	if _is_already_requesting_next_page:
		return [] # Some old request is in working...
	_is_already_requesting_next_page = true
	_loading_section.visible = true
	_retry_button.visible = false
	cnt_items_to_fetch = max(minimum_items_per_page, cnt_items_to_fetch)
	var promise: Promise = await fetch_callable.call(cnt_items_to_fetch, _current_item_offset)
	var partial_data = await promise.wait_till_fulfilled()
	_loading_section.visible = false
	_is_already_requesting_next_page = false
	if promise.is_error():
		Notify.error("Fetch Data Error", promise.get_error_message())
		_retry_button.visible = true
		return []
	assert(partial_data is EndlessScrollerDataPortion)
	if partial_data.start_item != _current_item_offset:
		print("Received request is not aligned with current start item. Probably old data")
		return []
	_current_item_offset += partial_data.data.size()
	_is_fully_loaded = _current_item_offset >= partial_data.total_in_query
	return partial_data.data


func _populate_items(items_data: Array) -> void:
	for data in items_data:
		var item: Control = item_scene.instantiate()
		_items_container.add_child(item)
		item.populate_item_slot(data)
		if on_item_created_callable.is_valid():
			on_item_created_callable.call(item)


func _check_if_should_fetch() -> bool:
	var height = _items_container.size.y - size.y
	var scroll_left = height - scroll_vertical
	return scroll_left <= rows_before_fetch_request * _item_dimensions.y


func setup(forced_start_size = Vector2.ZERO) -> void:
	var items_to_fetch = (preload_pages_in_advance) * _calculate_max_items_on_screen(forced_start_size)
	var items_data = await _fetch_data(items_to_fetch)
	_populate_items(items_data)
	_configured = true


func fetch_and_populate(forced_start_size = Vector2.ZERO) -> void:
	if _is_fully_loaded:
		#print("Endless container is in fully loaded state, no reqests sent!")
		return
	var items_to_fetch = preload_pages_in_advance * _calculate_max_items_on_screen(forced_start_size)
	# check if we have an even number to fill full last row
	# this may be not true if we resized the container
	var items_per_row = max(_calculate_max_per_row(), 1)
	var offset_modulo = _current_item_offset %items_per_row
	if offset_modulo > 0:
		items_to_fetch += items_per_row - offset_modulo
	var items_data = await _fetch_data(max(1,items_to_fetch))
	_populate_items(items_data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if scroll_vertical <= _lowest_known_scroll_position:
		return
	_lowest_known_scroll_position = scroll_vertical
	if _check_if_should_fetch():
		fetch_and_populate()


# This function is only for demo purposes
#func _ready():
	# wait one frame so parent container is setup
	#await get_tree().process_frame
	#fetch_callable = func(number_of_items: int, start_item: int) -> Promise:
	#	var ret_array: Array = []
	#	var ret_promise: Promise = Promise.new()
	#	for x in range(number_of_items):
	#		ret_array.append({"id": x + start_item})
	#	get_tree().create_timer(1).timeout.connect(func():
	#			if randf() > 0.5:
	#				var container_data = EndlessScrollerDataPortion.new()
	#				container_data.start_item = start_item
	#				container_data.total_in_query = 9999999
	#				container_data.data = ret_array
	#				ret_promise.set_result(container_data)
	#			else:
	#				ret_promise.set_error("Some erorr occured!!!!")
	#	)
	#	return ret_promise
	#
	#setup()


func _on_resized() -> void:
	if _lowest_known_scroll_position > size.y:
		_lowest_known_scroll_position = size.y
	_on_visibility_changed()


func _on_retry_button_pressed() -> void:
	fetch_and_populate()


func _on_visibility_changed() -> void:
	if not visible:
		return
	if not get_v_scroll_bar().visible and _configured:
		fetch_and_populate()


class EndlessScrollerDataPortion:
	var start_item: int
	var total_in_query: int
	# Array of Dictionaries containing data for each slot
	var data: Array
