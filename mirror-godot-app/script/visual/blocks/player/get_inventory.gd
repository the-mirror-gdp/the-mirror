extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player: Player
	if inputs[0].value is Player:
		player = inputs[0].value
	elif Zone.is_client() and PlayerData.has_local_player():
		player = PlayerData.get_local_player()
	else:
		outputs[0].value = null
		return
	# Get the saved items and return it as an Array.
	var saved_items: Dictionary
	if Zone.is_in_edit_mode():
		saved_items = player.data_store.get_value("saved_build_items", {})
	else:
		saved_items = player.data_store.get_value("saved_play_items", {})
	var items: Array = saved_items.values()
	outputs[0].value = items
	# Get the currently held item.
	var held_asset_id: String = player.equipable_controller.get_current_asset_id()
	outputs[1].value = held_asset_id


func get_script_block_type() -> String:
	return "get_player_inventory"
