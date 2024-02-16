extends Node

# Used to catch bad unregistering
var _all_registered_actions: Array = []

var _event_to_actions = {}

var _event_to_priority_inputs = {&"Escape (Physical)": []}
var _priority_input_to_events = {}


func is_action_pressed(action_name: StringName) -> bool:
	# Special case: The escape key also deselects Control nodes.
	if Input.is_action_just_pressed(action_name):
		if _event_to_priority_inputs[&"Escape (Physical)"].has(action_name):
			var focus_owner: Control = get_viewport().gui_get_focus_owner()
			if focus_owner != null:
				if focus_owner.has_method(&"deselect") and focus_owner.has_selection():
					focus_owner.call_deferred(&"deselect")
				else:
					focus_owner.call_deferred(&"release_focus")
				return false
	# Typical case: The action is pressed, but only return true when
	# the action has priority over other actions using the same key.
	var is_top_of_any_stack: bool = false
	if not _priority_input_to_events.has(action_name):
		return false
	for event_text in _priority_input_to_events[action_name]:
		if not _event_to_priority_inputs.has(event_text):
			continue
		if _event_to_priority_inputs[event_text].back() == action_name:
			is_top_of_any_stack = true
			break
	if is_top_of_any_stack:
		return Input.is_action_pressed(action_name)
	else:
		return false


# TODO: This method allows multiple action names as input, is it necessary?
# If it is, remove this comment. If it's not used in like a year, simplify it.
func register_actions(
	action_names: Array[StringName],
	enable_signal: Signal,
	disable_signal: Signal) -> void:

	if _all_registered_actions.has(action_names):
		# No need to register a second time.
		return
	_all_registered_actions.append(action_names)
	enable_signal.connect(_enable_actions.bind(action_names))
	disable_signal.connect(_disable_actions.bind(action_names))


# TODO: This method is unused, is it necessary?
func unregister_actions(
	action_names: Array[StringName],
	enable_signal: Signal,
	disable_signal: Signal) -> void:
	assert(_all_registered_actions.has(action_names), \
		"Please make sure that you have the same action_names array as for when you called register_actions.")

	_all_registered_actions.erase(action_names)
	enable_signal.disconnect(_enable_actions)
	disable_signal.disconnect(_disable_actions)


func _enable_actions(action_names: Array[StringName]) -> void:
	for action_name in action_names:
		_enable_action(action_name)


func _disable_actions(action_names: Array[StringName]) -> void:
	for action_name in action_names:
		_disable_action(action_name)


func _enable_action(action_name: StringName) -> void:
	var events = InputMap.action_get_events(action_name)
	if events.is_empty():
		printerr("PriorityInput: Tried to register '" + str(action_name) + "' but the input action was not found. Please check the spelling.")
	_priority_input_to_events[action_name] = (events.map(func (e): return StringName(e.as_text())))
	for event in events:
		var event_as_text := StringName(event.as_text())
		if _event_to_priority_inputs.has(event_as_text):
			if not _event_to_priority_inputs[event_as_text].has(action_name):
				_event_to_priority_inputs[event_as_text].append(action_name)
			else:
				printerr("PriorityInput: '" + str(action_name) + "' should not be enabled more than once before being disabled.")
		else:
			_event_to_priority_inputs[event_as_text] = [action_name]


func _disable_action(action_name: StringName) -> void:
	var events = InputMap.action_get_events(action_name)
	if not _priority_input_to_events.has(action_name):
		return
	for event in events:
		var event_as_text := StringName(event.as_text())
		if _event_to_priority_inputs.has(event_as_text):
			if _event_to_priority_inputs[event_as_text].has(action_name):
				_event_to_priority_inputs[event_as_text].erase(action_name)
			else:
				printerr("PriorityInput: " + str(action_name) + " should not be disabled more than once before being enabled again.")
		else:
			_event_to_priority_inputs.erase(event_as_text)
			_priority_input_to_events[action_name].erase(event_as_text)
	_priority_input_to_events.erase(action_name)
