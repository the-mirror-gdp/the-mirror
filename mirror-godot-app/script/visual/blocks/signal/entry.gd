## A script entry point. Like a sequenced/run block but has no input flow.
## ScriptBlockEntry is the "general" case that works with most signals.
class_name ScriptBlockEntry
extends ScriptBlockEntryBase


func _get_callable_for_event_signal() -> Callable:
	var signal_parameter_count = parameters.get_signal_parameter_count()
	# There doesn't seem to be a way to just pass parameters as an array,
	# so unfortunately we have to use some repetitive code here.
	match signal_parameter_count:
		0:
			return _execute_niladic_signal
		1:
			return _execute_monadic_signal
		2:
			return _execute_dyadic_signal
		3:
			return _execute_triadic_signal
		4:
			return _execute_quadradic_signal
		5:
			return _execute_quintadic_signal
		6:
			return _execute_hexadic_signal
		7:
			return _execute_septadic_signal
		8:
			return _execute_octadic_signal
		9:
			return _execute_nonadic_signal
		_:
			@warning_ignore("assert_always_false")
			assert(false, "If you reach this assert, add more *adic methods.")
	# This is unreachable code, but GDScript isn't smart enough to detect it.
	return Callable()


# Execution methods.
func _execute_niladic_signal() -> void:
	if not script_instance.can_execute():
		return
	_execute()


func _execute_monadic_signal(arg0) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	_execute()


func _execute_dyadic_signal(arg0, arg1) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	_execute()


func _execute_triadic_signal(arg0, arg1, arg2) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	_execute()


func _execute_quadradic_signal(arg0, arg1, arg2, arg3) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	_execute()


func _execute_quintadic_signal(arg0, arg1, arg2, arg3, arg4) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	outputs[4].value = arg4
	_execute()


func _execute_hexadic_signal(arg0, arg1, arg2, arg3, arg4, arg5) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	outputs[4].value = arg4
	outputs[5].value = arg5
	_execute()


func _execute_septadic_signal(arg0, arg1, arg2, arg3, arg4, arg5, arg6) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	outputs[4].value = arg4
	outputs[5].value = arg5
	outputs[6].value = arg6
	_execute()


func _execute_octadic_signal(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	outputs[4].value = arg4
	outputs[5].value = arg5
	outputs[6].value = arg6
	outputs[7].value = arg7
	_execute()


func _execute_nonadic_signal(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) -> void:
	if not script_instance.can_execute():
		return
	outputs[0].value = arg0
	outputs[1].value = arg1
	outputs[2].value = arg2
	outputs[3].value = arg3
	outputs[4].value = arg4
	outputs[5].value = arg5
	outputs[6].value = arg6
	outputs[7].value = arg7
	outputs[8].value = arg8
	_execute()
