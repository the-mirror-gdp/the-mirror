extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	assert(inputs.size() == 2) # Should be exactly two inputs, reference object and range.
	# Get the target position we are comparing the player's distance to.
	var target_position := Vector3()
	if inputs[0].connected_block == null:
		target_position = attached_object.global_position
	else:
		var target_object = type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)
		if is_instance_valid(target_object) and target_object is Node3D:
			target_position = target_object.global_position
		else:
			log_error.emit("The target object is not a valid 3D node.")
			outputs[0].value = null
			outputs[1].value = []
			return
	# Find the players within the range. The closest players are at the front of the array.
	var range: float = inputs[1].value
	var range_sq: float = range * range
	var players_in_range: Array = []
	var player_distances_sq: Array = []
	for player in Zone.social_manager.get_all_players():
		var distance_sq: float = player.global_position.distance_squared_to(target_position)
		if distance_sq < range_sq:
			_insert_player_with_distance(players_in_range, player_distances_sq, player, distance_sq)
	if players_in_range.is_empty():
		outputs[0].value = null
	else:
		outputs[0].value = players_in_range[0]
	if outputs.size() > 1:
		outputs[1].value = players_in_range


func _insert_player_with_distance(players: Array, distances: Array, player: Player, distance: float) -> void:
	for i in range(players.size()):
		if distance < distances[i]:
			players.insert(i, player)
			distances.insert(i, distance)
			return
	players.append(player)
	distances.append(distance)


func get_script_block_type() -> String:
	return "get_player_in_range"
