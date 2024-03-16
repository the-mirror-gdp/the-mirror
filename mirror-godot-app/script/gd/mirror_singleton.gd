## This class is for binding to user GDScript code.
class_name Mirror
extends Object


static func get_global_variable(variable_name: String) -> Variant:
	return Zone.script_network_sync.get_global_variable(variable_name)


static func has_global_variable(variable_name: String) -> bool:
	return Zone.script_network_sync.has_global_variable(variable_name)


static func set_global_variable(variable_name: String, variable_value: Variant) -> void:
	Zone.script_network_sync.set_global_variable(variable_name, variable_value)


static func tween_global_variable(variable_name: String, to_value: Variant, duration: float, trans: Tween.TransitionType, easing: Tween.EaseType) -> void:
	Zone.script_network_sync.tween_global_variable(variable_name, to_value, duration, trans, easing)


static func get_object_variable(variable_object: Object, variable_name: String) -> Variant:
	var object_variables = variable_object.get_meta(&"MirrorScriptObjectVariables")
	return TMDataUtil.get_variable_by_json_path_string(object_variables, variable_name)


static func has_object_variable(variable_object: Object, variable_name: String) -> bool:
	if not variable_object.has_meta(&"MirrorScriptObjectVariables"):
		return false
	var object_variables = variable_object.get_meta(&"MirrorScriptObjectVariables")
	return TMDataUtil.has_variable_by_json_path_string(object_variables, variable_name)


static func set_object_variable(variable_object: Object, variable_name: String, variable_value: Variant) -> void:
	if variable_object is Node:
		# This will also set it locally immediately.
		Zone.script_network_sync.set_variable_on_node(variable_object, variable_name, variable_value)
	else:
		# Allow setting on non-Node objects, but only locally, since we don't
		# have a way to keep track of non-Node references over the network.
		if not variable_object.has_meta(&"MirrorScriptObjectVariables"):
			variable_object.set_meta(&"MirrorScriptObjectVariables", {})
		var object_variables: Dictionary = variable_object.get_meta(&"MirrorScriptObjectVariables")
		TMDataUtil.set_variable_by_json_path_string(object_variables, variable_name, variable_value)
		Zone.script_network_sync.object_variable_changed.emit(variable_object, variable_name, variable_value)


static func tween_object_variable(variable_node: Node, variable_name: String, to_value: Variant, duration: float, trans: Tween.TransitionType, easing: Tween.EaseType) -> void:
	# Note: Unlike setting a variable, this does not apply immediately.
	# Since tweening does not have an effect on the same frame anyway,
	# we can afford to wait for the server to only do a synced tween.
	Zone.script_network_sync.tween_variable_on_node(variable_node, variable_name, to_value, duration, trans, easing)
