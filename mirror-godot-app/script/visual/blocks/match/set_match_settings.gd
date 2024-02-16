extends ScriptBlockSequenced


const FRIENDLY_FIRE_ENUM_VALUES: Array = ["Enabled", "Disabled", "No Kills", "Reflect"]


func _execute_callback(_stack_count: int) -> Error:
	if inputs.size() == 2: # Compat.
		var freeze_time: float = inputs[0].value
		var score_needed_to_win: int = inputs[1].value
		Zone.script_network_sync.set_global_variable("match_settings/freeze_time", freeze_time)
		Zone.script_network_sync.set_global_variable("match_settings/win_conditions/score", score_needed_to_win)
		return OK
	var freeze_time: float = inputs[0].value
	var friendly_fire: String = inputs[1].value
	var score_needed_to_win: int = inputs[2].value
	if not friendly_fire in FRIENDLY_FIRE_ENUM_VALUES:
		log_error.emit("Invalid friendly fire value: " + friendly_fire + ", expected one of " + ", ".join(FRIENDLY_FIRE_ENUM_VALUES) + ".")
		return ERR_INVALID_PARAMETER
	Zone.script_network_sync.set_global_variable("match_settings/freeze_time", freeze_time)
	Zone.script_network_sync.set_global_variable("match_settings/friendly_fire", friendly_fire)
	Zone.script_network_sync.set_global_variable("match_settings/win_conditions/score", score_needed_to_win)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port.port_name == "Friendly Fire"


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return FRIENDLY_FIRE_ENUM_VALUES


func get_script_block_type() -> String:
	return "set_match_settings"
