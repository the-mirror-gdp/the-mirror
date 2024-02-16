extends Node


var _tests: Array = []
var _current_test: BaseIntegrationTest
var _start_time_ms: int


## Called when node is ready, gathers the integration tests and runs them one by one.
func _ready() -> void:
	var env_name: String = ProjectSettings.get_setting("mirror/env_name")
	if env_name == "prod":
		print("Bypassing integration tests on PROD client. Sensitive test information not embedded in release build.")
		get_tree().quit()
		return
	print("Begin Enviroment '%s' integration tests." % env_name)
	_tests.clear()
	_get_tests()
	_start_time_ms = Time.get_ticks_msec()
	_run_next_test()


## Gathers all BaseIntegrationTest entities that are children of this node.
func _get_tests() -> void:
	_tests.clear()
	for child in get_children():
		assert(child is BaseIntegrationTest)
		_tests.append(child)


## Runs the next integration test script.
func _run_next_test() -> void:
	var test = _tests.pop_front()
	if test:
		_run_integration_tests(test)
		return
	var time_now_ms = Time.get_ticks_msec()
	var time_elapsed = time_now_ms - _start_time_ms
	print("All integration tests completed in %s MS." % str(time_elapsed))
	get_tree().quit()


## Runs the tests of an integration test script.
func _run_integration_tests(test: BaseIntegrationTest) -> void:
	_current_test = test
	print("Running integration test %s" % test.name)
	_current_test.tests_completed.connect(_integration_tests_completed)
	_current_test.start_tests()


## Signal called when an integration test has completed.
func _integration_tests_completed(success: bool) -> void:
	print("%s Completed: %s" % [_current_test.name, "PASSED" if success else "FAILED"])
	_current_test.tests_completed.disconnect(_integration_tests_completed)
	_current_test = null
	_run_next_test()
