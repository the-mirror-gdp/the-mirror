extends GutTest


const _TEST_ASSET: Dictionary = {
	"test_array": [
		"value1",
		"value2",
		Vector2(1.2, 3.4),
		{
			"dict_in_array": Color.RED,
			"nested_array": [
				"hi"
			],
			Color.GREEN: "non-string as key edge case"
		}
	],
	"test_dictionary": {
		"test": "hi"
	},
	"test_vector3": Vector3(5.6, 6.7, 8.9),
}


func test_json_file() -> void:
	var serialized_dict: Array = Serialization.serialize_dictionary_to_json(_TEST_ASSET)
	var back_dict: Dictionary = Serialization.load_serialized_json_as_dictionary(serialized_dict)
	assert_eq(back_dict, _TEST_ASSET)
	var serialized_arr: Array = Serialization.serialize_array_to_json([_TEST_ASSET])
	var back_arr: Array = Serialization.load_serialized_json_as_array(serialized_arr)
	assert_eq(back_arr, [_TEST_ASSET])
	var serialized_generic: Variant = Serialization.type_convert_to_json(_TEST_ASSET)
	var back_generic: Variant = Serialization.type_convert_from_json(serialized_generic, TYPE_DICTIONARY)
	assert_eq(back_generic, _TEST_ASSET)
