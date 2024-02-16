extends ScriptBlockVariableEntryBase


func _get_callable_for_event_signal() -> Callable:
	return _on_global_variable_changed


func _on_global_variable_changed(variable_name: String, variable_value: Variant) -> void:
	if not script_instance.can_execute():
		return
	if inputs.size() > 0:
		if inputs[0].value and variable_name != inputs[0].value:
			var split_changed_name: PackedStringArray = TMDataUtil.split_json_path_string(variable_name)
			var depth: int = TMDataUtil.match_depth_json_path(split_changed_name, listening_for_variable_path)
			if depth == -1:
				return
			elif depth > 0:
				if variable_value is Dictionary or variable_value is Array:
					var subset: PackedStringArray = listening_for_variable_path.slice(listening_for_variable_path.size() - depth)
					variable_value = TMDataUtil.get_variable_by_json_path(variable_value, subset)
					if is_signaling_null(variable_value):
						variable_value = null
	outputs[0].value = variable_name
	outputs[1].value = variable_value
	_execute()
