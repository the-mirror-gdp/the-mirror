# # # # #
## This class can be very helpfull when writting asynchronous logic, it can be used to immediatelly
## return 'promise' object which in the future will contain result (or error)
class_name Promise
extends RefCounted


signal _fulfilled(result)

var _result = null
var _error_msg: String = ""
var _is_error: bool = false
var _is_fulfilled: bool = false
var _funcs_to_call_on_fulfill: Array[Callable] = []


func set_result(in_result):
	_result = in_result
	_fulfill()


func get_result():
	assert(not _is_error)
	return _result


func has_result():
	return _result != null and (not _is_error) and _is_fulfilled


func is_error():
	return _is_error


func set_error(error_message: String):
	_error_msg = error_message
	_is_error = true
	_fulfill()


func get_error_message() -> String:
	assert(_is_error)
	return _error_msg


## Usage:
## [codeblock]
## var promise = async_value_generator()
## promise.connect_func_to_fulfill(display_result.bind(promise))
##
## func display_result(promise):
##     if not promise.is_error():
##         print(promise.get_result())
## [/codeblock]
func connect_func_to_fulfill(func_to_call: Callable):
	if _is_fulfilled:
		func_to_call.call()
		return

	_funcs_to_call_on_fulfill.append(func_to_call)


## Usage:
## [codeblock]
## var promise = async_value_generator()
## var result = await promise.wait_till_fulfilled()
## if  promise.is_error():
##     print(promise.get_error_message())
##     return
## [/codeblock]
func wait_till_fulfilled() -> Signal:
	if _is_fulfilled:
		_emit_fulfilled.call_deferred()
	return _fulfilled


func _fulfill():
	if _is_fulfilled:
		return
	_emit_fulfilled()


func _emit_fulfilled():
	if not is_instance_valid(self):
		return
	_fulfilled.emit(_result)
	_is_fulfilled = true
	for callable in _fulfilled.get_connections():
		_fulfilled.disconnect(callable["callable"])
	for callable in _funcs_to_call_on_fulfill:
		if callable == null or not callable.is_valid():
			# Object that callable is attached to is probably no longer valid
			if callable:
				push_error("Promise error: Trying to call invalid Callable: %s" % callable.get_method())
			else:
				push_error("Promise error: Trying to call null Callable")
			continue
		callable.call()
	_funcs_to_call_on_fulfill.clear()
