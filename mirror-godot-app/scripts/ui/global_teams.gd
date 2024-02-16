class_name TeamWindow
extends Control


signal close_team_menu()

@onready var team_table : Table = $Control/body/VBoxContainer/table_container
@onready var add_team_button : Button = $Control/body/VBoxContainer/add_team_button/HBoxContainer/AddTeamTextboxButton/Panel/HBoxContainer/Button
@onready var line_edit_team_name : LineEdit = $Control/body/VBoxContainer/add_team_button/HBoxContainer/AddTeamTextboxButton/Panel/HBoxContainer/LineEdit
@onready var another_add_team_button : Button = $Control/body/VBoxContainer/add_team_button/HBoxContainer/AddTeamButton
@onready var play_mode_window = $"../TeamsWindowPlayMode"

var _highest_id = 0
var _cached_last_global_teams_value = null
var _configured = false
var _tables: Array[Table] = []



func _ready():
	_configured = false
	# The data mapping
	# This is used to extract the properties and reset the input row
	# An example is provided with the correct columns for teams
	team_table.default_data_mapping = {
		# specify the team name by the text mapping on the column "team_name"
		# when the "text_changed" signal is called bind the row and column information
		# and call the table changed signal
		"team_name": {
			"mapping": "value",
			"value_changed_signal" : "text_submitted", # line edit text changed
			"default_value": "", # used for resetting the column to the default state
		},
		# specify team color, and which column to take the data for the state
		# color changed is the signal used for when the state is updated
		# to push the row and column state to the parent component
		"team_color": {
			"mapping": "color",
			"value_changed_signal" : "color_changed",
			"default_value": Color.WHITE # used for resetting the column to the default state
		},
		# when the button is pressed map the pressed signal for the row to a row and column
		"join_team_button": {
			# calls the table changed event with one nuance the signal has less arguments, requires two signals to be bound.
			"internal_event" : "pressed"
		},
		"remove_row_button": {
			# calls the table changed event with one nuance the signal has less arguments, requires two signals to be bound.
			"internal_event" : "pressed"
		}
	}
	Zone.script_network_sync.variables_ready.connect(_space_vars_loaded)
	Zone.script_network_sync.received_variable_data_change.connect(_space_vars_loaded)
	team_table.table_data_changed.connect(_table_data_changed)
	team_table.table_added_row.connect(_table_added_new_row)
	team_table.table_removed_row.connect(_table_removed_row)
	add_team_button.pressed.connect(_add_team_by_name_button)
	another_add_team_button.pressed.connect(_add_team_by_name_button)
	visibility_changed.connect(_on_visibility_changed)
	# if this error's someone moved teams window play mode below teams window
	assert(play_mode_window != null)
	assert(play_mode_window.table)
	register_table_for_rendering(play_mode_window.table)
	register_table_for_rendering(team_table)


# register another table to contain the same data as the current team list
# this is only for play mode, but later we could make it general
# to prevent needing duplicate signals etc.
func register_table_for_rendering(table: Table) -> void:
	if not _tables.has(table):
		# ensure to pass button events uniformally to all tables
		if not table.table_event.is_connected(_table_button_pressed):
			table.table_event.connect(_table_button_pressed)
		_tables.push_back(table)


func _on_visibility_changed():
	if not visible:
		return
	render_table()


func render_all_tables(data):
	for table_node in _tables:
		render_table_rows(table_node, data)


func _add_team_by_name_button():
	if not _configured:
		return
	var team_name = line_edit_team_name.text
	var rand_color = Color.from_hsv((randi() % 32) / 32.0, 1, 1)
	var team_definition = {"id": _check_highest_id()+1, "team_name": team_name, "team_color": rand_color}
	#print("team definition: ", team_definition)
	var global_teams = _get_global_teams()
	global_teams.append(team_definition)
	#print("global teams: ", global_teams)
	_set_global_variable_teams(global_teams)
	render_all_tables(global_teams)
	line_edit_team_name.text = "" # reset


func _table_removed_row(external_row_id: int):
	var global_teams : Array = _get_global_teams()
	var teamIDX = get_team_array_index_by_id(global_teams, external_row_id)
	global_teams.pop_at(teamIDX)
	_set_global_variable_teams(global_teams)


func _check_highest_id():
	var global_teams = _get_global_teams()
	for team in global_teams:
		_highest_id = max(team.get("id", 0), _highest_id)
	return _highest_id


# Called when the scene has no teams
func add_default_teams() -> Array:
	# Note position is not ID.
	# The position could change if a team is removed.
	# ergo you must supply an ID
	var teams = [
		{"id": 0, "team_name": "RED" , "team_color": Color.RED},
		{"id": 1, "team_name": "BLUE", "team_color": Color.BLUE}
	]
	return teams


func close_button_pressed() -> void:
	close_team_menu.emit()


# this returns the row not the array
static func get_team_by_id(teams: Array, id: int) -> Dictionary:
	for team in teams:
		if team.id == id:
			return team
	return Dictionary()


# this returns the row not the array
static func get_team_array_index_by_id(teams: Array, id: int) -> int:
	for idx in range(teams.size()):
		var team = teams[idx]
		if team.id == id:
			return idx
	return -1 # invalid could not find team by id


# note: internal id is a specific internal id not the same as others.
# this is pretty much the only place you're allowed the internal id.
func _table_added_new_row(internal_id: int):
	var global_teams : Array = _get_global_teams()
	var additional_team_row = team_table.get_row_data(internal_id)
	additional_team_row.id = _highest_id + 1
	team_table.set_row_external_id(internal_id, additional_team_row.id)
	_highest_id += 1
	#print("New row added: ", additional_team_row)
	global_teams.push_back(additional_team_row)
	_set_global_variable_teams(global_teams)


# Pressed has two arguments and signal bind is sensitive to argument count
# we take advantage of this and use this for button events
# for input fields in tables we use _table_data_changed, but notice
# they both use the same signal with different arg counts
func _table_button_pressed(id, column_name):
	#print("pressed id ", id)
	var global_teams = _get_global_teams()
	var team = get_team_by_id(global_teams, id)
	if column_name == "join_team_button":
		# set current player to this team
		#print("Join team: ", team)
		var local_player: Player = PlayerData.get_local_player()
		if local_player == null:
			return
		local_player.set_player_team(team.get("team_name"), team.get("team_color"))
		local_player.respawn_player()
		close_team_menu.emit()
	if column_name == "remove_row_button":
		for table in _tables:
			table.remove_row(id)


func _table_data_changed(id, column_name, value):
	#print("changed id ", id, "value: ", value)
	var teams = _get_global_teams().duplicate(true)
	var team = get_team_by_id(teams, id)
	if team.has(column_name):
		team[column_name] = value
		# update teams
		# note team above is passed by reference.
		_set_global_variable_teams(teams)
	else:
		push_error("invalid team specified or team data is broken")


func _get_global_teams() -> Variant:
	return Zone.get_global_teams()


func _set_global_variable_teams(arr: Array) -> void:
	Zone.set_global_variable_teams(arr)


static func render_table_rows(table: Table, new_data: Array):
	var valid_ids = []
	#print("render called: ", Zone.get_instance_type(), " rendering new data:\n", new_data)
	for team in new_data:
		var row_id = team.get("id")
		if not valid_ids.has(row_id):
			valid_ids.push_back(row_id)
		var row = table.get_row(row_id)
		if row == Array():
			table.add_row(team)
		# write mapping values
		var row_new_data = table.get_row_data(row_id)
		#print("apply row data: ", row_id, " data: ", team)
		table.apply_row_data(row_id, team)
	# remove old rows
	for team_id in table.get_rows():
		if not valid_ids.has(team_id):
			var row = table.get_row(team_id)[0]
			var row_data = table.get_row_data(team_id)
			#print("removing team data table: ", row_data)
			#print("row info external_id:", row.get_meta("external_id"), "internal_id: ", row.get_meta("internal_id"))
			table.remove_row(team_id, false) # do not fire the signal to prevent recursion


func _space_vars_loaded():
#	if _get_global_teams() == Array():
#		assert(false)
	#print("vars loaded: ", _get_global_teams(), " origin: ", Zone.get_instance_type())
	_configured = true
	render_table()


# when the global variables are made ready
func render_table():
	if not _configured:
		return

	var global_teams = _get_global_teams()
	var empty_teams: bool = global_teams is Array and global_teams.size() == 0
	var team_type_invalid: bool = not (global_teams is Array)
	if team_type_invalid or empty_teams:
		#print("invalid teams in teams table, re-adding new teams")
		global_teams = add_default_teams()
		_set_global_variable_teams(global_teams)
	_check_highest_id()
	render_all_tables(global_teams)
