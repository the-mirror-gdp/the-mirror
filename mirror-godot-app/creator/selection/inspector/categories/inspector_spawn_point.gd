extends "inspector_category_base.gd"

@onready var team_selector = $Properties/MarginContainer/PropertyList/TeamSelection
@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _edit_teams_button = $Properties/MarginContainer/PropertyList/EditTeams

var target_node: Node3D = null


func _ready() -> void:
	super()
	var can_edit = update_active_fields_by_permissions()
	_edit_teams_button.disabled = not can_edit
	var teams = Zone.get_global_teams()
	if teams:
		print("Teams: ", teams)
		var space_object: SpaceObject = Util.get_space_object(target_node)
		if not space_object._is_setup:
			await space_object.setup_done
		var current_selection_meta = target_node.get_meta("OMI_spawn_point")
		var id = 0
		for team in teams:
			team_selector.add_item(team.team_name)
		var current_selection_id = _get_team_selection_id(current_selection_meta.get("team", ""), teams)
		if current_selection_id != -1:
			team_selector.current_value = current_selection_id


func _get_team_selection_id(team_name: String, teams : Array) -> int:
	var id = 0
	for team in teams:
		if team_name == team.team_name.to_lower():
			print("current selection is ", team_name)
			return id
		id += 1
	return -1


func _select_new_team(value):
	assert(target_node)
	var space_object: SpaceObject = Util.get_space_object(target_node)
	if not space_object._is_setup:
		await space_object.setup_done
	var spawn_point = target_node.get_meta("OMI_spawn_point").duplicate()
	var team_name = team_selector.values[value].to_lower()
	space_object.space_object_name = "Spawn: " + team_name
	spawn_point["team"] = team_name
	target_node.set_meta("OMI_spawn_point", spawn_point)

	# duplicate or diff fails
	var spawn_points: Dictionary = space_object.spawn_points.duplicate()
	spawn_points[str(space_object.get_path_to(target_node))] = spawn_point
	space_object.spawn_points = spawn_points
	space_object.queue_update_network_object()


func _edit_teams_button_pressed():
	GameUI.instance.teams_handler.toggle_teams_editor()
