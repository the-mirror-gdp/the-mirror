extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player = inputs[0].value
	var is_valid_player: bool = is_instance_valid(player) and player is Player
	outputs[0].value = is_valid_player
	outputs[1].value = player if is_valid_player else null


func get_script_block_type() -> String:
	return "is_valid_player"
