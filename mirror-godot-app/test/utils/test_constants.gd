extends Node


# A constant dictionary only prevents the variable from
# pointing to another dictionary, but the dictionary is
# still mutable. Because of that, to prevent unwanted modifications,
# if you need to use this, use it as a parameter for the Dictionary constructor
# Example:
# var test_constants = load("res://test/utils/test_constants.gd").new()
# var space_object_dictionary = test_constants.fake_space_object_dictionary.duplicate()
# space_object_dictionary["receipt"] = { "created_by_user": "test-user", "auto_select": true }
const fake_space_object_dictionary: Dictionary = {
	"_id": "62fa8c343ed1a6cd695b0232",
	"gravityScale": null,
	"massKg": null,
	"staticEnabled": null,
	"collisionEnabled": null,
	"position": [0.0, 0.0, 0.0],
	"rotation": [0.0, 0.0, 0.0],
	"scale": [1.0, 1.0, 1.0],
	"offset": [0.0, 0.0, 0.0],
	"space": "62ec0ec7bdd116f9f040c0bb",
	"asset": "62d20252deddd0883e1803e7",
	"name": "Test-Asset",
	"createdAt": "2022-08-15T18:11:00.981Z",
	"updatedAt": "2022-09-05T19:24:12.588Z",
	"__v": 0,
	"id": "62fa8c343ed1a6cd695b0232",
}
