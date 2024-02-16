extends GutTest


const JSON_FILE_PATH = "res://test/test_files/spaces.json"


func test_package_version() -> void:
	var version: String = Util.get_version_string()
	var split = version.split(".")
	assert_true(split.size() > 0)
	assert_true(str(split[0]).to_int() > 0)


func test_json_file() -> void:
	var json_value = TMFileUtil.load_json_file(JSON_FILE_PATH)
	assert_not_null(json_value)
	assert_true(json_value is Array)
	assert_false(json_value is Dictionary)


func test_json_parse() -> void:
	var test_json_str = '  { "numTest": 000484884,  "stringTest": "hello world" } '
	var json_value = JSON.new()
	json_value = TMFileUtil.parse_json_from_string(test_json_str)
	assert_not_null(json_value)
	assert_true(json_value is Dictionary)
	assert_false(json_value is Array)
	assert_eq(json_value["numTest"], 484884.0)
	assert_eq(json_value["stringTest"], "hello world")


func test_looks_like_json() -> void:
	assert_false(Util.looks_like_json("<test bad str> "))
	assert_false(Util.looks_like_json('{"test": "Testing a bad string"'))
	assert_false(Util.looks_like_json('"test": "Testing a bad string"}'))
	assert_false(Util.looks_like_json('{"test": "Testing a bad string"]'))
	assert_false(Util.looks_like_json('["test": "Testing a bad string"}'))
	assert_true(Util.looks_like_json('{"test": "Testing a good string"}'))
	assert_true(Util.looks_like_json('["Testing a good string"]'))
