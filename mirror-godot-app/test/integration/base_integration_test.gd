class_name BaseIntegrationTest
extends Node


var _current_test: StringName
var _test_queue: Array = []

signal tests_completed(success)


## Starts the tests by executing the next (first) action.
func start_tests() -> void:
	_execute_next_test()


## Executes the next test.
func _execute_next_test() -> void:
	if _test_queue.is_empty():
		tests_completed.emit(true)
		return
	_current_test = _test_queue.pop_front()
	print("Running test %s.%s" % [name, _current_test])
	call(_current_test)


## Called on a success method when an integration test passes.
func test_passed(payload = null) -> void:
	print("PASSED: %s.%s: %s " % [name, _current_test, str(payload)])
	_execute_next_test()


## Called on a failure method when an integration test fails.
func test_failed(payload = null) -> void:
	# do whatever we have to do before starting next test
	print("FAILED: %s: %s.%s " % [name, _current_test, str(payload)])
	get_tree().quit(1)
