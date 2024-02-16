class_name SocialManager
extends Node


signal player_connected(player: Player)
signal player_disconnected(player: Player)
signal player_killed_by_player(victim_player: Player, killer_player: Player, victim_team: String, killer_team: String, friendly_fire: bool)
signal player_spawned(player: Player)

@export var player_prefab: PackedScene = load("res://player/player.tscn")

## Container for players.
@onready var players: Node = $players

var _player_build_transforms: Dictionary = {}


func _ready() -> void:
	DamageMaster.death.connect(_on_death)


func clear_children() -> void:
	for player in players.get_children():
		player.cleanup_and_delete()


func prepare_players_for_play_mode():
	if not Zone.is_host():
		return
	_player_build_transforms.clear()
	for player in players.get_children():
		_player_build_transforms[player] = player.global_transform
		player.setup_play_mode()
		player.set_random_player_team()
		player.respawn_player()
	Cursors.set_cursor()


func prepare_players_for_build_mode():
	if not Zone.is_host():
		return
	for player in players.get_children():
		player.setup_build_mode()
		if _player_build_transforms.has(player):
			var t: Transform3D = _player_build_transforms[player]
			player.teleport.rpc(t.origin, t.basis.get_euler())


######
## Players
@rpc("call_remote", "authority", "reliable")
func spawn_player(player_data: Dictionary) -> Node:
	print("Player Connected: ", player_data.user_id)
	var player: Player = player_prefab.instantiate()
	player.populate_from_player_data(player_data)
	players.add_child(player)
	if player_data.has("team_name"):
		player.set_player_team(player_data.team_name, player_data.team_color)
	player_connected.emit(player)
	return player


@rpc("call_remote", "any_peer", "reliable")
func remove_player(in_user_id: String):
	print("Player removed ", in_user_id)
	var player_node = get_player(in_user_id)
	if is_instance_valid(player_node):
		player_node.cleanup_and_delete()
		player_disconnected.emit(player_node)


func has_player(in_user_id: String) -> bool:
	return players.has_node(in_user_id)


func get_player(in_user_id: String) -> Player:
	return players.get_node_or_null(in_user_id)


func find_player_by_peer(peer: int) -> Player:
	for i in range(players.get_child_count()):
		var p = players.get_child(i)
		if p.get_multiplayer_authority() == peer:
			return p
	return null


func get_all_players() -> Array:
	return players.get_children()


func get_all_users_ids() -> Array[StringName]:
	var user_ids: Array[StringName] = []
	for player in players.get_children():
		user_ids.append(player.get_user_id())
	return user_ids


func _on_death(victim_player: Node, event_origin: String) -> void:
	if not victim_player is Player:
		return
	var killer_player = get_player(event_origin)
	if not killer_player is Player:
		return
	var victim_team: String = victim_player.get_player_team()
	var killer_team: String = killer_player.get_player_team()
	player_killed_by_player.emit(victim_player, killer_player, victim_team, killer_team, victim_team == killer_team)
