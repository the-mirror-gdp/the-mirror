extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	if Zone.is_host():
		log_error.emit("Cannot get local player on the server.")
		return
	if PlayerData.has_local_player():
		outputs[0].value = PlayerData.get_local_player()
	else:
		outputs[0].value = null


func get_script_block_type() -> String:
	return "get_local_player"
