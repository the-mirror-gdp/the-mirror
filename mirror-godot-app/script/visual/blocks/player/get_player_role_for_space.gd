extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player = inputs[0].value
	var is_valid_player: bool = is_instance_valid(player) and player is Player
	if not is_valid_player:
		outputs[0].value = ""
		outputs[1].value = 0
		return
	var role_level = Util.get_role_for_user(Zone.space, player.get_user_id())
	var extra_roles = ProjectSettings.get_setting("mirror/extra_roles", {})
	if extra_roles.has(role_level):
		outputs[0].value = extra_roles[role_level]
	else:
		outputs[0].value = Enums.ROLE.find_key(role_level)
	outputs[1].value = role_level


func get_script_block_type() -> String:
	return "get_player_role_for_space"
