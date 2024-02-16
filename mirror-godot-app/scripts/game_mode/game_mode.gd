class_name GameMode
extends Node


signal game_mode_changed(new_game_mode, previous_game_mode)

signal entering_inspect_mode()
signal exiting_inspect_mode()

enum Mode {
	NORMAL = 0,
	INSPECT,
	BUILD
}

var _current_game_mode: Mode = Mode.NORMAL


func _enter_tree() -> void:
	PriorityInput.register_actions([&"inspect_mode_exit"], entering_inspect_mode, exiting_inspect_mode)


func _unhandled_input(input_event) -> void:
	if Zone.is_in_play_mode():
		return
	if input_event.is_pressed():
		var should_toggle_build_tools = (
				not GameUI.is_keyboard_needed_for_ui()
				and input_event.is_action(&"build_mode_toggle")
		)
		if _current_game_mode == Mode.NORMAL:
			if should_toggle_build_tools:
				set_game_mode(Mode.BUILD)
				get_viewport().set_input_as_handled()
			elif input_event.is_action(&"inspect_mode_toggle"):
				entering_inspect_mode.emit()
				set_game_mode(Mode.INSPECT)
				get_viewport().set_input_as_handled()
		elif _current_game_mode == Mode.INSPECT:
			if should_toggle_build_tools:
				exiting_inspect_mode.emit()
				set_game_mode(Mode.BUILD)
				get_viewport().set_input_as_handled()
			elif input_event.is_action(&"inspect_mode_toggle") or \
					PriorityInput.is_action_pressed(&"inspect_mode_exit"):
				exiting_inspect_mode.emit()
				set_game_mode(Mode.NORMAL)
				get_viewport().set_input_as_handled()
		elif _current_game_mode == Mode.BUILD:
			if should_toggle_build_tools:
				set_game_mode(Mode.NORMAL)
				get_viewport().set_input_as_handled()


func set_game_mode(new_game_mode: Mode, force: bool = false) -> void:
	if not ProjectSettings.get_setting("feature_flags/enable_build_shortcuts", true):
		_current_game_mode = Mode.NORMAL
		return
	if not force and new_game_mode == _current_game_mode:
		return
	var previous_game_mode = _current_game_mode
	_current_game_mode = new_game_mode
	game_mode_changed.emit(new_game_mode, previous_game_mode)


func get_current_mode() -> int:
	return _current_game_mode
