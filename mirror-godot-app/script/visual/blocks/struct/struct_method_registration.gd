class_name ScriptStructMethodRegistration
extends Object


static func has_registered_method(method_name: StringName) -> bool:
	return _REGISTERED_STRUCT_METHODS.has(method_name)


static func get_registered_methods() -> Dictionary:
	return _REGISTERED_STRUCT_METHODS


static func get_method_description(method_name: StringName) -> String:
	if _REGISTERED_STRUCT_METHODS.has(method_name):
		return _REGISTERED_STRUCT_METHODS[method_name]["description"]
	return "No description."


const _REGISTERED_STRUCT_METHODS = {
	# Collections
	&"duplicate": {
		"struct_types": [ScriptBlock.PortType.DICTIONARY, ScriptBlock.PortType.ARRAY],
		"description": "Duplicates the given collection.",
		"sequenced": true,
		"typed_output_name": "Duplicated",
		"inputs": [
			["Deep", ScriptBlock.PortType.BOOL, false],
		]
	},
	&"is_empty": {
		"struct_types": [ScriptBlock.PortType.DICTIONARY, ScriptBlock.PortType.ARRAY],
		"description": "Returns true if the given collection is empty.",
		"sequenced": false,
		"typed_output_name": "Pass",
		"outputs": [
			["Is Empty", ScriptBlock.PortType.BOOL, true],
		]
	},
	&"size": {
		"struct_types": [ScriptBlock.PortType.DICTIONARY, ScriptBlock.PortType.ARRAY],
		"description": "Returns the size of the given collection.",
		"sequenced": false,
		"typed_output_name": "Pass",
		"outputs": [
			["Size", ScriptBlock.PortType.INT, 0],
		]
	},
	&"sort": {
		"struct_types": [ScriptBlock.PortType.DICTIONARY, ScriptBlock.PortType.ARRAY],
		"description": "Sorts the given collection. This sorts the original data, and passes it through for convenience (this is not a copy).",
		"sequenced": true,
		"typed_output_name": "Sorted",
	},
	&"shuffle": {
		"struct_types": [ScriptBlock.PortType.ARRAY],
		"description": "Shuffles the array such that the items will be in a random order. This shuffles the original data, and passes it through for convenience (this is not a copy).",
		"sequenced": true,
		"typed_output_name": "Shuffled",
	},
	# Vectors
	&"angle_to": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3],
		"description": "Returns the angle between two vectors, in degrees.",
		"sequenced": false,
		"inputs": [
			["To", ScriptBlock.PortType.MATH, Vector3.ZERO],
		],
		"outputs": [
			["Degrees", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	&"clamp": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3, ScriptBlock.PortType.COLOR],
		"description": "Clamps the given input between the given minimum and maximum.",
		"sequenced": false,
		"typed_output_name": "Clamped",
		"inputs": [
			["Minimum", ScriptBlock.PortType.MATH, Color.BLACK],
			["Maximum", ScriptBlock.PortType.MATH, Color.WHITE],
		]
	},
	&"distance_to": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3],
		"description": "Returns the distance between two vectors.",
		"sequenced": false,
		"inputs": [
			["To", ScriptBlock.PortType.MATH, Vector3.ZERO],
		],
		"outputs": [
			["Distance", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	&"length": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3, ScriptBlock.PortType.STRING],
		"description": "Returns the magnitude of the given vector or the amount of characters in the given string.",
		"sequenced": false,
		"typed_output_name": "Pass",
		"outputs": [
			["Length", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	&"move_toward": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3],
		"description": "Moves the first vector towards the given To target by the given amount.",
		"sequenced": false,
		"typed_output_name": "Moved",
		"inputs": [
			["To", ScriptBlock.PortType.MATH, Vector3.ZERO],
			["Delta", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	&"project": {
		"struct_types": [ScriptBlock.PortType.VECTOR2, ScriptBlock.PortType.VECTOR3],
		"description": "Projects the first vector onto the Onto vector.",
		"sequenced": false,
		"typed_output_name": "Projected",
		"inputs": [
			["Onto", ScriptBlock.PortType.MATH, Vector3.ZERO],
		]
	},
}
