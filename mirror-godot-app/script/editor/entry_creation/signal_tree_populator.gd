class_name ScriptEntrySignalTreePopulator
extends Node


# Remember that Godot only allows String in Dictionary keys, not StringName :(
const _META_KEY_MAP_TO_FRIENDLY_SUFFIX: Dictionary = {
	"OMI_seat": " (Seat)",
	"OMI_spawn_point": " (Spawn Point)",
}

@onready var _registered_signals: Dictionary = ScriptSignalRegistration.get_mirror_registered_signals()
@onready var _registered_meta_signals: Dictionary = ScriptSignalRegistration.get_mirror_registered_meta_signals()


func populate_tree_item_with_signals(tree_item: TreeItem, tree: Tree, target_node: Node) -> void:
	# Gather available signals. This includes signals on sub-nodes.
	var available_signals: Dictionary = {}
	available_signals["SpaceObject"] = Array(_registered_signals["SpaceObject"]).duplicate(true)
	if target_node:
		_append_existing_subnode_signals(target_node, available_signals, "Timer", Timer)
		if target_node is SpaceObject:
			_append_space_object_subnode_signals(target_node, available_signals)
		_append_always_available_new_subnode_signals(target_node, available_signals, "Timer")
	_append_global_signals(available_signals)
	# Set up tree items for the signals.
	for key in available_signals.keys():
		var node_type: TreeItem = tree.create_item(tree_item)
		node_type.set_text(0, key)
		node_type.set_tooltip_text(0, ScriptSignalRegistration.get_category_description(key))
		node_type.set_selectable(0, false)
		var node_signals: Array = available_signals[key]
		for signal_dict in node_signals:
			_finish_setting_up_signal_dict(signal_dict)
			var signal_item: TreeItem = tree.create_item(node_type)
			signal_item.set_text(0, String(signal_dict["signal"]).capitalize())
			signal_item.set_tooltip_text(0, signal_dict["description"])
			signal_item.set_metadata(0, signal_dict)


func _append_existing_subnode_signals(root: Node, signals: Dictionary, type_name: String, type, valid_condition = null) -> void:
	var subnodes: Array = TMNodeUtil.recursive_find_nodes_by_type(root, type)
	for subnode in subnodes:
		if valid_condition is Callable:
			var valid = valid_condition.call(subnode)
			if valid is bool and not valid:
				continue
		if subnode.name.begins_with("_"):
			continue
		var path = TMNodeUtil.get_relative_node_path_string(root, subnode)
		if path.contains("@"):
			Notify.error("Broken Node Path", "The path '" + path + "' contains '@' (an unnamed node in the model file).")
			continue
		var subnode_signals: Array = Array(_registered_signals[type_name]).duplicate(true)
		for subnode_signal in subnode_signals:
			subnode_signal["path"] = path
		var friendly_path: String = _get_friendly_node_path_or_name(path) + " (" + type_name + " node)"
		signals[friendly_path] = subnode_signals


func _append_existing_subnode_meta_signals(root: Node, signals: Dictionary, meta_key: StringName) -> void:
	var subnodes: Array = Util.recursive_find_nodes_with_meta(root, meta_key)
	var suffix: String = _META_KEY_MAP_TO_FRIENDLY_SUFFIX.get(meta_key, "")
	for subnode in subnodes:
		var path: String = TMNodeUtil.get_relative_node_path_string(root, subnode)
		var friendly_path: String = _get_friendly_node_path_or_name(path)
		var subnode_signals: Array = _find_or_get_and_set_subnode_signals(signals, friendly_path, suffix)
		var meta_signals: Array = _registered_meta_signals[meta_key]
		for meta_signal in meta_signals:
			var new_signal = meta_signal.duplicate(true)
			new_signal["path"] = path
			subnode_signals.append(new_signal)


func _find_or_get_and_set_subnode_signals(signals: Dictionary, friendly_path: String, suffix: String) -> Array:
	var path_and_suffix: String = friendly_path + suffix
	if signals.has(path_and_suffix):
		return signals[path_and_suffix]
	var subnode_signals: Array = []
	signals[path_and_suffix] = subnode_signals
	return subnode_signals


func _append_space_object_subnode_signals(target_space_object: SpaceObject, signals: Dictionary) -> void:
	_append_existing_subnode_signals(target_space_object, signals, "Physics", JBody3D, _is_jbody_not_trigger)
	_append_existing_subnode_signals(target_space_object, signals, "Trigger", JBody3D, _is_jbody_trigger)
	_append_existing_subnode_signals(target_space_object, signals, "Animation", AnimationPlayer)
	_append_existing_subnode_signals(target_space_object, signals, "Audio", AudioStreamPlayer)
	_append_existing_subnode_signals(target_space_object, signals, "Audio", AudioStreamPlayer3D)
	_append_existing_subnode_meta_signals(target_space_object, signals, &"OMI_seat")
	_append_existing_subnode_meta_signals(target_space_object, signals, &"OMI_spawn_point")


func _is_jbody_trigger(jbody: JBody3D) -> bool:
	return jbody.get_layer_name() != &"NO_COLLIDE" and jbody.is_sensor()


func _is_jbody_not_trigger(jbody: JBody3D) -> bool:
	return jbody.get_layer_name() != &"NO_COLLIDE" and not jbody.is_sensor()


func _append_global_signals(signals: Dictionary) -> void:
	signals["Physics"] = Array(_registered_signals["Physics"]).duplicate(true)
	signals["Player"] = Array(_registered_signals["Player"]).duplicate(true)
	signals["Variables"] = Array(_registered_signals["Variables"]).duplicate(true)
	signals["Match"] = Array(_registered_signals["Match"]).duplicate(true)
	signals["Global"] = Array(_registered_signals["Global"]).duplicate(true)


func _append_always_available_new_subnode_signals(root: Node, signals: Dictionary, type_name: String, parameters: Array = []) -> void:
	var registered_type_signals := Array(_registered_signals[type_name])
	var unique_name: String = TMNodeUtil.get_unique_child_name(root, type_name)
	var new_signals: Array = []
	for registered_type_signal in registered_type_signals:
		var new_signal: Dictionary = registered_type_signal.duplicate(true)
		new_signal["path"] = unique_name
		if not parameters.is_empty():
			new_signal["parameters"] = parameters
		new_signals.append(new_signal)
	signals["New " + type_name] = new_signals


func _finish_setting_up_signal_dict(signal_dict: Dictionary) -> void:
	var friendly_path: String = _get_friendly_node_path_or_name(signal_dict["path"])
	var friendly_signal: String = String(signal_dict["signal"]).capitalize()
	signal_dict["name"] = "On " + friendly_path + friendly_signal
	signal_dict["entry_id"] = _get_unique_entry_id_from_signal_dict(signal_dict)
	signal_dict["type"] = "entry"
	signal_dict["sequenced"] = true


func _get_friendly_node_path_or_name(path: String) -> String:
	if path == "self":
		# Hide the self path for simplicity.
		return ""
	if path.begins_with("/"):
		# Use friendly names for global signals, hide where they came from.
		return ""
	# TODO: Delete this trim prefix line after SpaceObject refactor.
	path = path.trim_prefix("_ScaledModel/")
	if path.length() < 30 or not path.contains("/"):
		return path + " "
	return ".../" + path.get_slice("/", path.get_slice_count("/") - 1) + " "


func _get_unique_entry_id_from_signal_dict(signal_dict: Dictionary) -> String:
	var path_and_signal: String = signal_dict["path"] + "_" + signal_dict["signal"]
	return path_and_signal + "_" + str(randi() % 1000000)
