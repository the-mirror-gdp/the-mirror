extends PanelContainer

signal create_new_play_server_request()

@onready var _table = %Table
@onready var _info_label: Label = %InfoLabel
@onready var _action_bar: Control = %ActionBar
@onready var _search_field = %ActionBar/SearchField
@onready var _sort_option_button: OptionButton = %ActionBar/SortOptionButton

var _space_id: String = ""
var _space_max_users: int = 0
var _play_servers_data: Array = []

@onready var refresh_spinner_player: AnimationPlayer = %RefreshSpinner/AnimationPlayer

enum SORT_OPTIONS {
	PLAYERS = 0,
	RECENT = 1,
	NAME = 2
}

func _ready():
	# The data mapping
	# This is used to extract the properties and reset the input row
	_table.default_data_mapping = {
		"server_id": {
			"mapping": &"value",
			"default_value": ""
		},
		"server_name": {
			"mapping": &"text",
		},
		"user": {
			"mapping": &"user_data"
		},
		"players_count": {
			"mapping": &"player_counter"
		},
		"join_button": {
			"internal_event" : &"button_pressed"
		},
	}
	_table.table_event.connect(_table_button_pressed)


func _sort_play_serves_list():
	_table.clear_table()

	var _sort: Callable
	print("Sorting called")

	var sort_id = _sort_option_button.get_item_id(_sort_option_button.selected)
	match sort_id:
		SORT_OPTIONS.NAME:
			_sort = func(a, b): return a.get("name", "") < b.get("name", "")
		SORT_OPTIONS.RECENT:
			_sort = func(a, b): return a.get("createdAt", "") > b.get("createdAt", "")
		_, SORT_OPTIONS.PLAYERS:
			_sort = func(a, b): return a.get("usersPresent", []).size() > b.get("usersPresent", []).size()
	_play_servers_data.sort_custom(_sort)
	for row in _play_servers_data:
		print(row.createdAt)
		var p_id = row.get("_id")
		var user_dict = row.get("owner", {})
		var user_data = {
			"name": user_dict.get("displayName", "Unknown"),
			"image": user_dict.get("profileImage", "")
		}
		var count_data = {"value": row.get("usersPresent", []).size(), "max_users": _space_max_users}
		_table.add_row({"id": p_id.hash(), "server_id": p_id,  "user": user_data, "server_name": row.get("name"), "players_count": count_data})
	# Apply search filter
	_table.search_for_text_recursive(_search_field.get_text(), "server_name")


func update_play_servers_data():
	if _space_id.is_empty():
		return
	refresh_spinner_player.play()
	var promise: Promise = Net.zone_client.get_play_servers_for_space_id(_space_id)
	var data = await promise.wait_till_fulfilled()
	refresh_spinner_player.stop()
	_table.clear_table()
	if promise.is_error():
		Notify.error("Play Servers Error", promise.get_error_message())
		return

	if data.size() == 0:
		_info_label.text = tr("There are currently no Play Servers available!\n" +
						"Please create a new one.")
		_info_label.visible = true
		#_table.visible = false
		return
	_info_label.visible = false
	_play_servers_data = data
	_sort_play_serves_list()


func populate(space: Dictionary):
	_space_id = space.get("_id", "")
	_space_max_users = space.get("maxUsers", 0)
	_search_field.clear_text()
	_table.clear_table()
	_sort_option_button.select(_sort_option_button.get_item_index(SORT_OPTIONS.PLAYERS))
	if space.get("activeSpaceVersion") == null:
		_info_label.text = tr("This Space is not published by creator.")
		_info_label.visible = true
		refresh_spinner_player.stop()
		_action_bar_enabled(false)
		return
	_action_bar_enabled(true)
	update_play_servers_data()


func _action_bar_enabled(value := true):
	for child in _action_bar.get_children():
		if "disabled" in child:
			child.disabled = not value


func _table_button_pressed(id: int, column_name: String):
	var row_data = _table.get_row_data(id)
	var zone_id = row_data.server_id
	if zone_id.is_empty():
		Notify.error("Join Error", "Couldn't retrive Play Server ID.")
		printerr("Zone ID is empty")
		return
	Zone.client.start_join_play_space_by_zone_id(zone_id)


func _on_create_new_button_pressed():
	create_new_play_server_request.emit()


func _on_refresh_servers_button_pressed():
	update_play_servers_data()


func _on_search_field_text_changed(new_text):
	_table.search_for_text_recursive(new_text, "server_name")


func _on_sort_option_button_item_selected(index):
	_sort_play_serves_list()


func _on_auto_refresh_timer_timeout():
	if not is_visible_in_tree():
		return
	update_play_servers_data()
