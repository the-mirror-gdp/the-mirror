class_name SpaceScene
extends Node


const TEMPLATES_DIRECTORY: String = "res://prefabs/space/templates/"
const SPACE_TEMPLATE: PackedScene = preload("res://prefabs/space/templates/space_template.tscn")

# these should be populated from space data
var lower_y_limit: int = -200

var _spawn_points: Array[Node3D] = []
var _current_template: SpaceTemplate


func _init():
	Zone.Scene = self


func is_ready() -> bool:
	return _current_template != null


func _ready() -> void:
	Net.zone_socket.space_received.connect(_zone_client_space_received)
	Net.zone_socket.terrain_received.connect(_zone_client_terrain_received)


func _zone_client_space_received(space_data: Dictionary) -> void:
	Zone.space = space_data
	if space_data.has("scriptIds"):
		Net.script_client.load_script_entities_for_ids(space_data["scriptIds"])
	spawn_template(true, space_data)


func _zone_client_terrain_received(terrain_data: Dictionary) -> void:
	Zone.space["terrain_data"] = terrain_data


func spawn_template(is_host: bool, space_data: Dictionary) -> void:
	if _current_template:
		return
	_current_template = SPACE_TEMPLATE.instantiate()
	if not _current_template is SpaceTemplate:
		push_error("Invalid template %s" % str(_current_template))
		return
	var template: SpaceTemplate = _current_template as SpaceTemplate
	template.populate_space_template(is_host, space_data)
	#template.template_ready.connect(_handle_template_ready, CONNECT_ONE_SHOT)
	lower_y_limit = _current_template.lower_y_limit
	print("SETUP TEMPLATE %s" % str(is_host))
	self.add_child(_current_template)


func _handle_template_ready() -> void:
	Zone.Voxels = _current_template.voxel_terrain
	if Zone.is_host():
		Net.zone_client.get_space_voxels(Zone.space["_id"])


func get_space_template() -> SpaceTemplate:
	return _current_template


# Spawn point methods.
func register_spawn_point(spawn_point_node: Node) -> void:
	assert(spawn_point_node.has_meta(&"OMI_spawn_point"))
	_spawn_points.append(spawn_point_node)


func register_spawn_points(root: Node) -> void:
	var spawn_points = Util.recursive_find_nodes_with_meta(root, &"OMI_spawn_point")
	_spawn_points.append_array(spawn_points)


func _validate_spawn_points() -> void:
	_spawn_points = _spawn_points.filter(func(node): return is_instance_valid(node))


func get_spawn_point_teams() -> Array:
	_validate_spawn_points()
	var teams: Array = []
	for point in _spawn_points:
		var omi_sp = point.get_meta(&"OMI_spawn_point")
		assert(omi_sp is Dictionary)
		var team = omi_sp.get("team")
		if not teams.has(team):
			teams.append(team)
	return teams


func get_spawn_points_for_team(team: String) -> Array[Node3D]:
	_validate_spawn_points()
	var team_points: Array[Node3D] = []
	for point in _spawn_points:
		var omi_sp = point.get_meta(&"OMI_spawn_point")
		assert(omi_sp is Dictionary)
		var omi_sp_team = omi_sp.get("team")
		if not omi_sp_team is String:
			omi_sp_team = ""
		if omi_sp_team.to_lower() == team:
			team_points.append(point)
	return team_points


func get_spawn_point_random(team: String) -> NodePath:
	var team_points: Array[Node3D] = get_spawn_points_for_team(team)
	if not team_points.is_empty():
		return team_points.pick_random().get_path()
	# If there are no spawn points for the team, return a random spawn point.
	if not _spawn_points.is_empty():
		return _spawn_points.pick_random().get_path()
	return ^""


## This method is used to BLOCK actually functionality of mutliple heightmaps
## This can be removed when we imrpove UX for maps
func update_heightmap(asset_data: AssetDataMap) -> void:
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role < Enums.ROLE.CONTRIBUTOR:
		Notify.error("Space Error", "You do not have permission to edit this space")
		return
	var space_objects: Array = Zone.instance_manager.get_all_instances()
	var old_instances := space_objects.filter(
			func(s_obj: SpaceObject): return s_obj.asset_type == Enums.ASSET_TYPE.MAP
	)
	if old_instances.size() == 0:
		var properties: Dictionary = {
			"asset": asset_data.asset_id,
			"position": Serialization.vector3_to_array(Vector3.ZERO),
			"rotation": Serialization.vector3_to_array(Vector3.ZERO),
			"scale": Serialization.vector3_to_array(Vector3.ONE),
			"preloadBeforeSpaceStarts": true,
		}
		var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
		Zone.client_send_create_space_object(properties, receipt)
		Analytics.track_event_client(AnalyticsEvent.TYPE.OBJECT_PLACED)
	else:
		var map: SpaceObject = old_instances[0]
		var old_asset_id = map.asset_id
		map.asset_id = asset_data.asset_id
		map.space_object_data["asset"] = asset_data.asset_id
		var asset_update_dict = {
			"asset": asset_data.asset_id,
			"force_reload_asset": true
		}
		# This will force update the space object on client, without waiting for network update
		map.apply_from_dictionary(asset_update_dict)
		map.record_property_changed(&"asset_id", old_asset_id, map.asset_id)
		map.queue_update_network_object()
