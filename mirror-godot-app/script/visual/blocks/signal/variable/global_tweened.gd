extends ScriptBlockVariableEntryBase


func _get_callable_for_event_signal() -> Callable:
	return _on_global_variable_tweened


func _on_global_variable_tweened(variable_name: String, from_value: Variant, to_value: Variant, duration: float) -> void:
	if inputs.size() > 0:
		if inputs[0].value and variable_name != inputs[0].value:
			var split_changed_name: PackedStringArray = TMDataUtil.split_json_path_string(variable_name)
			var depth: int = TMDataUtil.match_depth_json_path(split_changed_name, listening_for_variable_path)
			if depth == -1:
				return
			elif depth > 0:
				var subset: PackedStringArray = listening_for_variable_path.slice(listening_for_variable_path.size() - depth)
				if from_value is Dictionary or from_value is Array:
					from_value = TMDataUtil.get_variable_by_json_path(from_value, subset)
					if is_signaling_null(from_value):
						from_value = null
				if to_value is Dictionary or to_value is Array:
					to_value = TMDataUtil.get_variable_by_json_path(to_value, subset)
					if is_signaling_null(to_value):
						to_value = null
	if not script_instance.can_execute():
		return
	outputs[0].value = variable_name
	outputs[1].value = from_value
	outputs[2].value = to_value
	outputs[3].value = duration
	_execute()
