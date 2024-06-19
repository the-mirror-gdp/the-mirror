extends VBoxContainer

const ITEMS_COUNT_FALLBACK = 3
const _CREATE_SPACE_DATA = {
	"name": "Create New Space",
	"description": "CREATE YOUR FIRST SPACE IN THE MIRROR.",
	"role": {
		"defaultRole": 700,
		"users": {},
		"owners": []
	}
}
const _LOCALHOST_DATA = {
	"_id": "LOCALHOST",
	"description": "LOCALHOST",
	"name": "LOCALHOST",
	"thumbnail": "Mars",
	"uuid": "LOCALHOST",
	"space": "localhost",
	"role": {
		"defaultRole": 700,
		"users": {},
		"owners": []
	}
}


enum SPACE_SOURCE {
	POPULAR,
	FAVORITES,
	RECENTS,
	MY_SPACES
}

@export var item_scene: PackedScene
@export var empty_item_scene: PackedScene
@export var window_margin: int = 74
@export var _data_source: SPACE_SOURCE
@export var _include_localhost_item: bool = false
@export var _include_new_space_item: bool = false

@onready var _items_container = %ItemsContainer
@onready var _title_bar = $TitleBar
@onready var _title_label = $TitleBar/TitleLabel
@onready var _audio_stream_player_click = $AudioStreamPlayerClick

var _item_dimensions: Vector2 = Vector2.ZERO:
	get:
		if _item_dimensions == Vector2.ZERO:
			var tmp_item: Control = item_scene.instantiate()
			_item_dimensions = tmp_item.size
		return _item_dimensions


func _fetch_data(_cnt_items_to_fetch: int) -> Array:
	var promise: Promise
	var params = Net.space_client.SpaceListRequestParameters.new()
	params.per_page = 20
	match _data_source:
		SPACE_SOURCE.FAVORITES:
			promise = Net.space_client.get_favorites_spaces()
		SPACE_SOURCE.RECENTS:
			promise = Net.space_client.get_recent_spaces()
		SPACE_SOURCE.MY_SPACES:
			promise = Net.space_client.get_current_user_spaces(params)
		_, SPACE_SOURCE.POPULAR:
			promise = Net.space_client.get_discover_spaces(params)
	var list = await promise.wait_till_fulfilled()
	if promise.is_error():
		push_error("Failed to retrieve spaces: ", promise.get_error_message())
		return []

	if list is Dictionary:
		list = list.get("data", [])

	if _include_localhost_item or _include_new_space_item:
		var items: Array
		var end_offset = 1 if _include_new_space_item else 0
		if OS.has_feature("editor") and _include_localhost_item:
			items = list.slice(0, _cnt_items_to_fetch - end_offset - 1)
			items.push_front(_LOCALHOST_DATA)
		else:
			items = list.slice(0, _cnt_items_to_fetch - end_offset)
		if _include_new_space_item:
			items.push_back(_CREATE_SPACE_DATA)
		return items
	return list


## This function calculates how many items can be fitted in parent container
## per row in the same time so all are visible. It takes into account spacing
func _calculate_max_per_row(forced_size = Vector2.ZERO) -> int:
	var window_size = DisplayServer.window_get_size()/DisplayServer.screen_get_scale()
	window_size /= Zone.get_viewport().content_scale_factor
	window_size.x = max(400, window_size.x - window_margin * 2)
	var parent_size = forced_size if forced_size != Vector2.ZERO else window_size
	var x_sep = _items_container.get_theme_constant("h_separation")
	return  int(parent_size.x + x_sep) / int(_item_dimensions.x + x_sep)


func _calculate_container_with(items_per_row: int) -> int:
	var x_sep = _items_container.get_theme_constant("h_separation")
	return int(_item_dimensions.x + x_sep) * items_per_row - x_sep


func fadeout_items() -> void:
	var tween = create_tween()
	for child in _items_container.get_children():
		tween = create_tween()
		tween.tween_property(child, "modulate", Color(1,1,1,0), 0.3)
	await tween.finished


func fadein_items() -> void:
	var tween = create_tween()
	for child in _items_container.get_children():
		child.modulate = Color(1,1,1,0)
		tween = create_tween()
		tween.tween_property(child, "modulate", Color(1,1,1,1), 0.3)
	await tween.finished


func _show_loading_items(items_per_row: int) -> void:
	for child in _items_container.get_children():
		child.queue_free()
		_items_container.remove_child(child)
	for index in range(items_per_row):
		var item: Control = empty_item_scene.instantiate()
		_items_container.add_child(item)
		item.show_loading()


func _populate_items(items_data: Array, max_items_number: int) -> void:
	await fadeout_items()
	for child in _items_container.get_children():
		child.queue_free()
		_items_container.remove_child(child)

	var max_items = min(items_data.size(), max_items_number)
	for index in range(max_items):
		var panel: Control = item_scene.instantiate()
		_items_container.add_child(panel)
		if panel.has_method(&"populate_item_slot"):
			panel.populate_item_slot(items_data[index])
		if panel.has_signal(&"create_pressed"):
			panel.create_pressed.connect(_on_create_pressed)
		if panel.has_signal("space_pressed"):
			panel.space_pressed.connect(_on_space_pressed)
	var empties = max(max_items_number-items_data.size(), 0)
	for index in range(empties):
		var item: Control = empty_item_scene.instantiate()
		_items_container.add_child(item)
	await fadein_items()


func _on_create_pressed() -> void:
	GameUI.instance.main_menu_ui.change_page(&"My_Spaces")
	GameUI.instance.main_menu_ui.change_subpage(&"SelectTemplate")
	_audio_stream_player_click.play()


func _on_space_pressed(space: Dictionary) -> void:
	GameUI.instance.main_menu_ui.change_subpage(&"ViewSpace", space)
	_audio_stream_player_click.play()

var _currently_populating = false

func fetch_and_populate(forced_start_size = Vector2.ZERO) -> void:
	if _currently_populating:
		return
	_currently_populating = true
	var items_per_row = max(_calculate_max_per_row(), 3)
	# uses a maximum number of items per row, not a returned number
	# This will make sure that items are always aligned to left
	var width = _calculate_container_with(items_per_row)
	_title_bar.custom_minimum_size.x = width
	_items_container.custom_minimum_size.x = width
	_show_loading_items(items_per_row)
	var items: Array = await _fetch_data(items_per_row)
	await _populate_items(items, items_per_row)
	_currently_populating = false


func _ready() -> void:
	match _data_source:
		SPACE_SOURCE.FAVORITES:
			_title_label.text = tr("Favorites")
		SPACE_SOURCE.RECENTS:
			_title_label.text = tr("Recent")
		SPACE_SOURCE.MY_SPACES:
			_title_label.text = tr("My spaces")
		_, SPACE_SOURCE.POPULAR:
			_title_label.text = tr("Popular")
	visibility_changed.connect(_on_visibility_changed, CONNECT_DEFERRED)
	get_tree().get_root().size_changed.connect(_on_resized)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	await fetch_and_populate()


func _on_resized() -> void:
	await _on_visibility_changed()
