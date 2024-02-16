extends GutTest


const ENDLESS_SCROLL_CONTAINER = preload("res://ui/common/components/endless_scroll_flow_container.tscn")


func _simple_fetch(number_of_items: int, start_item: int, instance: Control, metadata: Dictionary) -> Promise:
	var ret_array: Array = []
	var ret_promise: Promise = Promise.new()
	for x in range(number_of_items):
		ret_array.append({"_id": str(x + start_item)})
	var container_data = instance.EndlessScrollerDataPortion.new()
	container_data.start_item = start_item
	container_data.total_in_query = 9999999
	container_data.data = ret_array
	ret_promise.set_result(container_data)
	metadata.fetch_called_cnt += 1
	metadata.last_number_of_items = number_of_items
	metadata.last_start_item = start_item
	return ret_promise


func test_call_fetch_on_setup():
	var fetch_metadata = {} # use dict as it is passed as reference
	fetch_metadata.fetch_called_cnt = 0
	var instance: EndlessScrollFlowContainer = ENDLESS_SCROLL_CONTAINER.instantiate()
	add_child_autoqfree(instance)
	instance.item_scene = preload("res://creator/common/asset_slot.tscn")
	instance.fetch_callable = _simple_fetch.bind(instance, fetch_metadata)
	assert_eq(fetch_metadata.fetch_called_cnt, 0, "Fetch not called before setup")
	instance.setup()
	assert_eq(fetch_metadata.fetch_called_cnt, 1, "Fetch called once on setup")


func test_call_correct_number_of_items_on_setup_forced():
	var forced_parent_size := Vector2(450, 450)
	var fetch_metadata: Dictionary = {} # use dict as it is passed as reference
	fetch_metadata.fetch_called_cnt = 0
	var instance: EndlessScrollFlowContainer = ENDLESS_SCROLL_CONTAINER.instantiate()
	add_child_autoqfree(instance)
	instance.item_scene = preload("res://creator/common/asset_slot.tscn")
	instance.fetch_callable = _simple_fetch.bind(instance, fetch_metadata)
	instance.preload_pages_in_advance = 2
	instance.setup(forced_parent_size)
	assert_eq(fetch_metadata.fetch_called_cnt, 1, "Fetch called once on setup")
	assert_gt(fetch_metadata.last_number_of_items, 0, "Fetch called once on setup")


func test_call_correct_number_of_items_on_setup():
	var forced_parent_size := Vector2(450, 450)
	var parent_control := Control.new()
	parent_control.custom_minimum_size = forced_parent_size
	add_child_autoqfree(parent_control)
	var fetch_metadata: Dictionary = {} # use dict as it is passed as reference
	fetch_metadata.fetch_called_cnt = 0
	var instance: EndlessScrollFlowContainer = ENDLESS_SCROLL_CONTAINER.instantiate()
	parent_control.add_child(instance)
	instance.item_scene = preload("res://creator/common/asset_slot.tscn")
	instance.fetch_callable = _simple_fetch.bind(instance, fetch_metadata)
	instance.preload_pages_in_advance = 2
	instance.setup()
	assert_eq(fetch_metadata.fetch_called_cnt, 1, "Fetch called once on setup")
	assert_gt(fetch_metadata.last_number_of_items, 0, "Fetch called once on setup")


func test_fetch_more_items():
	var forced_parent_size := Vector2(450, 450)
	var parent_control := Control.new()
	parent_control.custom_minimum_size = forced_parent_size
	add_child_autoqfree(parent_control)
	var fetch_metadata: Dictionary = {} # use dict as it is passed as reference
	fetch_metadata.fetch_called_cnt = 0
	var instance: EndlessScrollFlowContainer = ENDLESS_SCROLL_CONTAINER.instantiate()
	parent_control.add_child(instance)
	instance.item_scene = preload("res://creator/common/asset_slot.tscn")
	instance.fetch_callable = _simple_fetch.bind(instance, fetch_metadata)
	instance.preload_pages_in_advance = 2
	instance.setup()
	assert_eq(fetch_metadata.fetch_called_cnt, 1, "Fetch called once on setup")
	assert_gt(fetch_metadata.last_number_of_items, 0, "Fetch called once on setup")
	await get_tree().process_frame # setting scroll position does not work if it is done in the same frame as adding it as child node
	instance.set_deferred("scroll_vertical", 450)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(fetch_metadata.fetch_called_cnt, 2, "Fetch called second time")
	assert_gt(fetch_metadata.last_number_of_items, 0, "Fetch called after scroll")


func _simple_error_fetch(number_of_items: int, start_item: int, metadata: Dictionary) -> Promise:
	var ret_array: Array = []
	var ret_promise: Promise = Promise.new()
	ret_promise.set_error("Something went wrong but thats ok, it's a test!")
	metadata.fetch_called_cnt += 1
	return ret_promise


func test_call_fetch_error():
	var fetch_metadata = {} # use dict as it is passed as reference
	fetch_metadata.fetch_called_cnt = 0
	var instance: EndlessScrollFlowContainer = ENDLESS_SCROLL_CONTAINER.instantiate()
	add_child_autoqfree(instance)
	instance.item_scene = preload("res://creator/common/asset_slot.tscn")
	instance.fetch_callable = _simple_error_fetch.bind(fetch_metadata)
	instance.setup()
	await get_tree().process_frame
	assert_eq(fetch_metadata.fetch_called_cnt, 1, "Fetch called once on setup")
	assert_true(instance._retry_button.visible, "Retry button visible")
	# Make proper data avaible now...
	instance.fetch_callable = _simple_fetch.bind(instance, fetch_metadata)
	instance._retry_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(fetch_metadata.fetch_called_cnt, 2, "Fetch called second time")
	assert_true(instance._retry_button.visible == false, "Retry button is not visible")
