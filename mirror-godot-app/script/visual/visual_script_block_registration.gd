class_name VisualScriptBlockRegistration
extends Object


const _ADDABLE_PROPERTY_TYPES = [
	ScriptBlock.PortType.INT,
	ScriptBlock.PortType.FLOAT,
	ScriptBlock.PortType.STRING,
	ScriptBlock.PortType.VECTOR2,
	ScriptBlock.PortType.VECTOR3,
]

const _MULTIPLIABLE_PROPERTY_TYPES = [
	ScriptBlock.PortType.INT,
	ScriptBlock.PortType.FLOAT,
	ScriptBlock.PortType.VECTOR2,
	ScriptBlock.PortType.VECTOR3,
]

const _TWEENABLE_PROPERTY_TYPES = [
	ScriptBlock.PortType.INT,
	ScriptBlock.PortType.FLOAT,
	ScriptBlock.PortType.VECTOR2,
	ScriptBlock.PortType.VECTOR3,
	ScriptBlock.PortType.COLOR,
]

const _TWEEN_PORTS = [
	["Duration", ScriptBlock.PortType.FLOAT, 1.0],
	["Transition", ScriptBlock.PortType.STRING, "Linear"],
	["Easing", ScriptBlock.PortType.STRING, "In Out"],
]


static func get_all_registered_script_blocks() -> Array[Dictionary]:
	var script_blocks: Array[Dictionary] = _REGISTERED_BLOCKS.duplicate(true)
	_add_feature_flagged_registered_blocks(script_blocks)
	_add_registered_methods_to_registered_blocks(script_blocks)
	_add_registered_struct_methods_to_registered_blocks(script_blocks)
	_add_registered_properties_to_registered_blocks(script_blocks)
	return script_blocks


static func get_api_dump_registered_script_blocks() -> Array[Dictionary]:
	var script_blocks: Array[Dictionary] = _REGISTERED_BLOCKS.duplicate(true)
	_add_registered_methods_to_registered_blocks(script_blocks)
	_add_registered_struct_methods_to_registered_blocks(script_blocks)
	return script_blocks


static func get_category_description(category_name: String) -> String:
	match category_name:
		"Misc":
			return "These blocks are very important, and so are top-level in the script block creation dialog, not tucked away in a category."
		"Flow":
			return "Flow blocks control the flow of execution in your script. They are used to run code in a specific order, or to run code when a condition is met."
		"Logic":
			return "Logic blocks are used to perform logic operations on data, like comparing numbers, matching values, or combining boolean values."
		"Math":
			return "Math blocks are used to perform math operations on numbers, like adding, subtracting, multiplying, or dividing."
		"Time":
			return "Time blocks are used to get the current time, convert between time formats, and format time values."
		"String":
			return "String blocks are used to perform string operations, like concatenating strings and formatting strings."
		"Color":
			return "Color blocks are used to perform color operations, like constructing colors and converting colors to strings."
		"Vector2":
			return "Vector2 blocks are used to perform 2D vector math operations."
		"Vector3":
			return "Vector3 blocks are used to perform 3D vector math operations."
		"Array":
			return "Array blocks are used to perform operations on lists of values."
		"Dictionary":
			return "Dictionary blocks are used to perform operations on key/value pairs."
		"SpaceObject":
			return "SpaceObject blocks are used to control SpaceObjects. All objects in your Space are SpaceObjects."
		"Player":
			return "Player blocks are used to perform operations on Players."
		"Animation":
			return "Animation blocks are used to control playing animations imported from GLTF files."
		"Audio":
			return "Audio blocks are used to control playing audio clips and audio nodes."
		"Physics":
			return "Physics blocks are used to manipulate physics objects."
		"Environment":
			return "Environment blocks are used to control the environment, like the sky, fog, and lighting."
		"Variables":
			return "Variable blocks are used to store and retrieve values. Variables may be global or per-object. All variables are reset when starting a new match."
		"Match":
			return "Match blocks are used to control the match and rounds, like starting/ending the match, or adding points to a team."
		"Space":
			return "Space blocks are for getting information about the Space."
		"Rotation Degrees":
			return "Rotation Degrees blocks are used to perform operations on Euler angle rotations in degrees."
		"Damageable":
			return "Damageable blocks are used to hurt or heal damageable objects and players."
		"Advanced":
			return "Advanced blocks are used to perform advanced operations."
	return category_name


static func _add_feature_flagged_registered_blocks(script_blocks: Array[Dictionary]) -> void:
	if ProjectSettings.get_setting("feature_flags/user_api_requests", false):
		script_blocks.append({
			"name": "API GET Request (Async)",
			"type": "api_get_request",
			"category": "Advanced",
			"description": "Makes an asynchronous GET request to the given URL. The response will be returned as a JSON string.",
			"sequenced": true,
			"inputs": [
				["Resource", ScriptBlock.PortType.STRING, ""],
			],
			"outputs": [
				["JSON", ScriptBlock.PortType.STRING, ""],
				["Code", ScriptBlock.PortType.INT, 0],
			]
		})
	if ProjectSettings.get_setting("feature_flags/os_shell", false):
		script_blocks.append({
			"name": "OS Shell Open",
			"type": "os_shell_open",
			"category": "Advanced",
			"description": "Opens the given URL or file path using the OS shell. This is equivalent to `OS.shell_open(URL)` in GDScript.",
			"sequenced": true,
			"inputs": [
				["URI", ScriptBlock.PortType.STRING, ""],
			]
		})
	if ProjectSettings.get_setting("feature_flags/os_shell", false):
		script_blocks.append({
			"name": "Detect Audio Input",
			"type": "audio_input_detect",
			"category": "Audio",
			"description": "Detects if user is actively speaking",
			"sequenced": false,
			"inputs": [
				["Player", ScriptBlock.PortType.OBJECT, null],
			],
			"outputs": [
				["Audio detected", ScriptBlock.PortType.BOOL, false],
			]
		})


static func _add_registered_methods_to_registered_blocks(script_blocks: Array[Dictionary]) -> void:
	var registered_methods: Dictionary = ScriptMethodRegistration.get_registered_methods()
	for method_name in registered_methods:
		# Set up the method name and if it's sequenced or not.
		var method_signature: Dictionary = Dictionary(registered_methods[method_name]).duplicate(false)
		if method_signature.get("hidden", false):
			continue
		method_signature["method"] = method_name
		method_signature["name"] = String(method_name).capitalize()
		var sequenced: bool = method_signature["sequenced"]
		if sequenced:
			method_signature["type"] = "sequenced_method"
		else:
			method_signature["type"] = "unsequenced_method"
		# Add an extra input at the beginning for the target object.
		var inputs: Array
		if method_signature.has("inputs"):
			inputs = method_signature["inputs"].duplicate(false)
		else:
			inputs = []
		inputs.push_front(["On Object", ScriptBlock.PortType.OBJECT, null])
		method_signature["inputs"] = inputs
		# Add an extra output at the beginning to pass the target object.
		var outputs: Array
		if method_signature.has("outputs"):
			outputs = method_signature["outputs"].duplicate(false)
		else:
			outputs = []
		outputs.push_front(["Pass", ScriptBlock.PortType.OBJECT, null])
		method_signature["outputs"] = outputs
		script_blocks.append(method_signature)


static func _add_registered_struct_methods_to_registered_blocks(script_blocks: Array[Dictionary]) -> void:
	var registered_methods: Dictionary = ScriptStructMethodRegistration.get_registered_methods()
	for method_name in registered_methods:
		# Set up the struct method name and if it's sequenced or not.
		var method_signature: Dictionary = Dictionary(registered_methods[method_name]).duplicate(false)
		method_signature["method"] = method_name
		var friendly_method_name: String = String(method_name).capitalize()
		var sequenced: bool = method_signature["sequenced"]
		if sequenced:
			method_signature["type"] = "sequenced_struct_method"
		else:
			method_signature["type"] = "unsequenced_struct_method"
		# Set up a copy of the struct method signature for each applicable struct type.
		var struct_types: Array = method_signature["struct_types"]
		var typed_output_name: String = method_signature.get("typed_output_name", "")
		method_signature.erase("struct_types") # Only needed in this method.
		for struct_type in struct_types:
			var for_struct_type: Dictionary = method_signature.duplicate(true)
			var struct_type_friendly_name: String = Serialization.type_enum_to_friendly_string(struct_type)
			for_struct_type["name"] = struct_type_friendly_name + " " + friendly_method_name
			for_struct_type["category"] = struct_type_friendly_name
			# If we have any math ports, convert them to the struct type.
			var inputs: Array = for_struct_type.get_or_set_default("inputs", [])
			for input in inputs:
				if input[1] == ScriptBlock.PortType.MATH:
					input[1] = struct_type
					input[2] = type_convert(input[2], struct_type)
			# Add one input port for the struct, and one output port to pass it through.
			var port: Array = [struct_type_friendly_name, struct_type, type_convert("", struct_type)]
			inputs.push_front(port)
			var outputs: Array = for_struct_type.get_or_set_default("outputs", [])
			if not typed_output_name.is_empty():
				port = port.duplicate(false)
				port[0] = typed_output_name
				outputs.push_front(port)
			# Special case: Length has different meanings for strings and vectors.
			if method_name == "length":
				if struct_type == ScriptBlock.PortType.STRING:
					for_struct_type["description"] = "Returns the amount of characters in the given string."
				else:
					for_struct_type["description"] = "Returns the magnitude of the given vector."
			# Does this block pass the input? If so, include that in the description.
			if outputs[0][0] == "Pass":
				for_struct_type["description"] += " The input data is passed through unchanged for convenience"
				if struct_type == ScriptBlock.PortType.ARRAY or struct_type == ScriptBlock.PortType.DICTIONARY:
					for_struct_type["description"] += " (this is not a copy)."
				else:
					for_struct_type["description"] += "." # Vectors etc are value types, and Strings are immutable.
			script_blocks.append(for_struct_type)


static func _add_registered_properties_to_registered_blocks(script_blocks: Array[Dictionary]) -> void:
	var registered_properties: Dictionary = ScriptPropertyRegistration.get_registered_properties()
	for property_name in registered_properties:
		var property_name_str := String(property_name)
		var property_signature: Dictionary = Dictionary(registered_properties[property_name_str]).duplicate(false)
		if property_signature.get("hidden", false):
			continue
		property_signature["property"] = property_name # StringName
		property_signature["category"] = property_name_str.capitalize()
		var capitalized_property_name: String = property_name_str.capitalize()
		var data_type: ScriptBlock.PortType = property_signature["data_type"]
		var default_value = type_convert(property_signature.get("default_value"), data_type)
		var pass_output_port: Array = ["Pass", ScriptBlock.PortType.OBJECT, null]
		var property_data_port: Array = [capitalized_property_name, data_type, default_value]
		var concatable_desc: String = _make_first_letter_lowercase(property_signature["description"])
		# The non-instance get/set have an object port as their first input.
		var object_port = ["On Object", ScriptBlock.PortType.OBJECT, null]
		# Register getter.
		var getter: Dictionary = property_signature.duplicate(false)
		getter["name"] = "Get " + capitalized_property_name
		getter["type"] = "get_property"
		getter["sequenced"] = false
		getter["inputs"] = [object_port]
		getter["outputs"] = [pass_output_port, property_data_port]
		getter["description"] = "Get " + concatable_desc
		script_blocks.append(getter)
		# Register setter.
		var setter: Dictionary = property_signature.duplicate(false)
		setter["name"] = "Set " + capitalized_property_name
		setter["type"] = "set_property"
		setter["sequenced"] = true
		setter["inputs"] = [object_port, property_data_port]
		setter["outputs"] = [pass_output_port]
		setter["description"] = "Set " + concatable_desc
		script_blocks.append(setter)
		# Register operations.
		if property_signature.has("enum_values"):
			continue
		if not data_type in ScriptBlockMath.MATH_PORT_TYPES:
			continue
		var operation_signature: Dictionary = property_signature.duplicate(false)
		operation_signature["sequenced"] = true
		var input_value_port: Array = property_data_port.duplicate(false)
		input_value_port[0] = "Amount"
		operation_signature["inputs"] = [object_port, input_value_port]
		var output_updated_value_port: Array = property_data_port.duplicate(false)
		output_updated_value_port[0] = "Updated Value"
		operation_signature["outputs"] = [pass_output_port, output_updated_value_port]
		if data_type in _ADDABLE_PROPERTY_TYPES:
			var adder: Dictionary = operation_signature.duplicate(false)
			adder["name"] = "Add To " + capitalized_property_name
			adder["type"] = "add_property"
			adder["description"] = "Add to " + concatable_desc
			script_blocks.append(adder)
		if data_type in _MULTIPLIABLE_PROPERTY_TYPES:
			var multiplier: Dictionary = operation_signature.duplicate(false)
			multiplier["name"] = "Multiply " + capitalized_property_name
			multiplier["type"] = "multiply_property"
			multiplier["description"] = "Multiply " + concatable_desc
			script_blocks.append(multiplier)
		if data_type in _TWEENABLE_PROPERTY_TYPES:
			var tweener: Dictionary = operation_signature.duplicate(false)
			tweener["name"] = "Tween " + capitalized_property_name
			tweener["type"] = "tween_property"
			tweener["outputs"] = [pass_output_port]
			var tween_value_port = input_value_port.duplicate(false)
			tween_value_port[0] = "Final Value"
			var tween_inputs: Array = [object_port, tween_value_port]
			tween_inputs.append_array(_TWEEN_PORTS)
			tweener["inputs"] = tween_inputs
			tweener["description"] = "Tween " + concatable_desc
			script_blocks.append(tweener)


static func _make_first_letter_lowercase(input: String) -> String:
	return input[0].to_lower() + input.substr(1)


## These registered visual script block signatures are the "default"
## when instancing a new block, they are not necessarily unchangeable.
## For example, the math methods can have their data types changed.
## This is separate from the block classes themselves, because those can
## be designed to handle different data types and sometimes input counts.
const _REGISTERED_BLOCKS: Array[Dictionary] = [
	# Misc high priority
	{
		"name": "Print In Chat (Say/Shout/Global)",
		"type": "print_chat",
		"description": "Prints a Message to the chat. If ran on a script attached to an object, it will make that object \"talk\". If the Range is 0 or less, it will be global. If the range is less than 2, it will be a whisper. If the range is less than 40, it will be a say. If the range is 40 or greater, it will be a shout.",
		"sequenced": true,
		"keywords": ["talk", "speak", "whisper"],
		"inputs": [
			["Message", ScriptBlock.PortType.ANY_DATA, ""],
			["Range", ScriptBlock.PortType.FLOAT, 20.0],
		]
	},
	{
		"name": "Print Notify",
		"type": "print_notify",
		"description": "Prints a Message to the notification area. The Notify Status can be Info, Success, Warning, or Error.",
		"sequenced": true,
		"keywords": ["notification", "global", "info", "success", "warning", "error"],
		"inputs": [
			["Title", ScriptBlock.PortType.STRING, "Script Notification"],
			["Message", ScriptBlock.PortType.ANY_DATA, ""],
			["Notify Status", ScriptBlock.PortType.STRING, "Info"],
		]
	},
	# Signal
	{
		"name": "Entry",
		"type": "entry",
		"description": "Entry Signals are used as entry points for your script (the first run blocks that are executed).",
		"sequenced": true,
		"keywords": ["signal", "emit", "event", "execute", "run", "interact", "timer", "timeout", "start", "ready", "process", "update", "changed", "tweened", "on", "when"],
		# This will be intercepted by the dialog, not used directly.
	},
	{
		"name": "Emit Signal",
		"type": "emit_signal",
		"description": "Emits a custom user-defined signal on an object. The Signal Name must be a signal with an entry block already defined elsewhere in your Space. If the Object is null, the signal will emit on the object the script is attached to.",
		"sequenced": true,
		"inputs": [
			["Signal Name", ScriptBlock.PortType.STRING, ""],
			["Object", ScriptBlock.PortType.OBJECT, null],
		]
	},
	# Flow
	{
		"name": "Branch",
		"type": "branch",
		"category": "Flow",
		"description": "Branches the flow of execution based on a Condition. If the Condition is true, it will execute the True flow. If the Condition is false, it will execute the False flow.",
		"sequenced": true,
		"inputs": [
			["Condition", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "If",
		"type": "if",
		"category": "Flow",
		"description": "Executes the True flow if the Condition is true. If the Condition is false, it will execute the False flow. After executing the True or False flow, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Condition", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "If Equals",
		"type": "if_equals",
		"category": "Flow",
		"description": "Executes the True flow if the Left value equals the Right value. If the values are not equal, it will execute the False flow. This is equivalent to `if Left == Right:` in GDScript. After executing the True or False flow, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Left", ScriptBlock.PortType.ANY_DATA, ""],
			["Right", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Loop",
		"type": "loop",
		"category": "Flow",
		"description": "Loops the given number of Times and executes Action each time. Index starts at 0 and is exclusive at the end (if Times is 3, Index will be 0, 1, then 2). The Action flow may only run at most 1000 times. This is equivalent to `for i in range(times)` in GDScript. After finishing the loop, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Times", ScriptBlock.PortType.INT, 5],
		],
		"outputs": [
			["Index", ScriptBlock.PortType.INT, 0]
		]
	},
	{
		"name": "While",
		"type": "while",
		"category": "Flow",
		"description": "Loops while the Condition is true. This is equivalent to `while Condition:` in GDScript. The True flow may only run at most 1000 times. After finishing the loop, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Condition", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Match Flow",
		"type": "match_flow",
		"category": "Flow",
		"description": "If the Input matches a Case, the Flow with the same number will be executed. If no flow matches, it will execute the Default flow. After executing the matched or Default flow, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Input", ScriptBlock.PortType.ANY_DATA, ""],
			["Case 1", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Wait (Async)",
		"type": "wait",
		"category": "Flow",
		"description": "Pauses the script execution for the given number of seconds.",
		"sequenced": true,
		"inputs": [
			["Seconds", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	# Logic
	{
		"name": "If Value",
		"type": "if_value",
		"category": "Logic",
		"description": "If Condition is true, Output is set to the True value. Otherwise, Output is set to the False value. This is equivalent to `Output = True if Condition else False` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Condition", ScriptBlock.PortType.BOOL, false],
			["True", ScriptBlock.PortType.ANY_DATA, ""],
			["False", ScriptBlock.PortType.ANY_DATA, ""],
		],
		"outputs": [
			["Output", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Match Value",
		"type": "match_value",
		"category": "Logic",
		"description": "If Input matches a Case, the Value with the same number will be set as the Output. Otherwise, the Output will be set to Default.",
		"sequenced": false,
		"inputs": [
			["Input", ScriptBlock.PortType.ANY_DATA, ""],
			["Default", ScriptBlock.PortType.ANY_DATA, ""],
			["Case 1", ScriptBlock.PortType.ANY_DATA, ""],
			["Value 1", ScriptBlock.PortType.ANY_DATA, ""],
		],
		"outputs": [
			["Output", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "And",
		"type": "and",
		"category": "Logic",
		"description": "If both Left and Right are true, Result will be true. Otherwise, Result will be false. This is equivalent to `Left and Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.BOOL, false],
			["Right", ScriptBlock.PortType.BOOL, false]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Equals",
		"type": "equals",
		"category": "Logic",
		"description": "If Left equals Right, Result will be true. Otherwise, Result will be false. This is equivalent to `Left == Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.ANY_DATA, ""],
			["Right", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Greater Than",
		"type": "greater",
		"category": "Logic",
		"description": "If Left is greater than Right, Result will be true. Otherwise, Result will be false. This is equivalent to `Left > Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.FLOAT, 0.0],
			["Right", ScriptBlock.PortType.FLOAT, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Less Than",
		"type": "less",
		"category": "Logic",
		"description": "If Left is less than Right, Result will be true. Otherwise, Result will be false. This is equivalent to `Left < Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.FLOAT, 0.0],
			["Right", ScriptBlock.PortType.FLOAT, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Not",
		"type": "not",
		"category": "Logic",
		"description": "If Input is true, Result will be false. If Input is false, Result will be true. This is equivalent to `not Input` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Input", ScriptBlock.PortType.BOOL, false]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Or",
		"type": "or",
		"category": "Logic",
		"description": "If either Left or Right is true, Result will be true. Otherwise, Result will be false. This is equivalent to `Left or Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.BOOL, false],
			["Right", ScriptBlock.PortType.BOOL, false]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	# Math
	{
		"name": "Add",
		"type": "add",
		"category": "Math",
		"description": "Adds Left and Right together. This is equivalent to `Left + Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Value 1", ScriptBlock.PortType.MATH, 0.0],
			["Value 2", ScriptBlock.PortType.MATH, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Clamp",
		"type": "clamp",
		"category": "Math",
		"description": "Clamps Value between Minimum and Maximum. This is equivalent to `clamp(Value, Minimum, Maximum)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Value", ScriptBlock.PortType.MATH, 0.0],
			["Minimum", ScriptBlock.PortType.MATH, 0.0],
			["Maximum", ScriptBlock.PortType.MATH, 1.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Divide",
		"type": "divide",
		"category": "Math",
		"description": "Divides Left by Right. This is equivalent to `Left / Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.MATH, 0.0],
			["Right", ScriptBlock.PortType.MATH, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Modulus",
		"type": "modulus",
		"category": "Math",
		"description": "Returns the modulus of Left and Right. For integers, this is equivalent to `posmod(Left, Right)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.MATH, 0.0],
			["Right", ScriptBlock.PortType.MATH, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Multiply",
		"type": "multiply",
		"category": "Math",
		"description": "Multiplies Left and Right together. This is equivalent to `Left * Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.MATH, 0.0],
			["Right", ScriptBlock.PortType.MATH, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Subtract",
		"type": "subtract",
		"category": "Math",
		"description": "Returns Left minus Right. This is equivalent to `Left - Right` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Left", ScriptBlock.PortType.MATH, 0.0],
			["Right", ScriptBlock.PortType.MATH, 0.0]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.MATH, 0.0]
		]
	},
	{
		"name": "Constant Math Expression",
		"type": "constant_math_expression",
		"category": "Math",
		"description": "Evaluates the given math expression at compile time, using the Expression class provided by Godot.",
		"sequenced": false,
		"inputs": [
			["Expression", ScriptBlock.PortType.STRING, "TAU / 4"],
		],
		"outputs": [
			["Result", ScriptBlock.PortType.FLOAT, TAU / 4],
		]
	},
	{
		"name": "Random Number",
		"type": "random_number",
		"category": "Math",
		"description": "Returns a random number between Minimum and Maximum, with a multiple of Step. This is inclusive on both sides, so it may return Minimum or Maximum.",
		"sequenced": false,
		"inputs": [
			["Minimum", ScriptBlock.PortType.FLOAT, 0.0],
			["Maximum", ScriptBlock.PortType.FLOAT, 1.0],
			["Step", ScriptBlock.PortType.FLOAT, 0.0],
		],
		"outputs": [
			["Number", ScriptBlock.PortType.FLOAT, 0.0]
		]
	},
	{
		"name": "Rotation Looking At",
		"type": "looking_at",
		"category": "Math",
		"description": "Returns a rotation such that the +Z axis points towards Positive and the -Z axis points towards Negative. Positive and Negative may not be equal or vertically on top of each other.",
		"sequenced": false,
		"inputs": [
			["Positive", ScriptBlock.PortType.OBJECT, null],
			["Negative", ScriptBlock.PortType.OBJECT, null],
			["Up Direction", ScriptBlock.PortType.VECTOR3, Vector3.UP],
		],
		"outputs": [
			["Euler Angles Degrees", ScriptBlock.PortType.VECTOR3, Vector3()]
		]
	},
	# Time
	{
		"name":"Get Current Unix Time In UTC",
		"type": "get_unix_time_utc",
		"category": "Time",
		"description": "Returns the current Unix timestamp in seconds based on the system time in UTC. This method always returns the time in UTC.",
		"sequenced": false,
		"outputs": [
			["Unix Timestamp", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	{
		"name":"Date/Time String To Unix Timestamp",
		"type": "datetime_string_to_unix_time",
		"category": "Time",
		"description": "Converts the given ISO 8601 date and/or time string to a Unix timestamp. The string can contain a date only, a time only, or both.",
		"sequenced": false,
		"inputs": [
			["ISO 8601 Date/Time", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Unix Timestamp", ScriptBlock.PortType.INT, 0],
		]
	},
	{
		"name":"Date/Time Values To Unix Timestamp",
		"type": "datetime_values_to_unix_time",
		"category": "Time",
		"description": "Converts the given date/time values to a Unix timestamp.",
		"sequenced": false,
		"inputs": [
			["Year", ScriptBlock.PortType.INT, 1970],
			["Month", ScriptBlock.PortType.INT, 1],
			["Day", ScriptBlock.PortType.INT, 1],
			["Hour", ScriptBlock.PortType.INT, 0],
			["Minute", ScriptBlock.PortType.INT, 0],
			["Second", ScriptBlock.PortType.INT, 0],
		],
		"outputs": [
			["Unix Timestamp", ScriptBlock.PortType.INT, 0],
		]
	},
	{
		"name": "Unix Timestamp To Date/Time String",
		"type": "unix_time_to_datetime_string",
		"category": "Time",
		"description": "Converts the given Unix timestamp to an ISO 8601 date/time string.",
		"sequenced": false,
		"inputs": [
			["Unix Timestamp", ScriptBlock.PortType.INT, 0],
		],
		"outputs": [
			["ISO 8601 Date/Time", ScriptBlock.PortType.STRING, ""],
		]
	},
	{
		"name": "Unix Timestamp To Date/Time Values",
		"type": "unix_time_to_datetime_values",
		"category": "Time",
		"description": "Converts the given Unix timestamp to date/time values.",
		"sequenced": false,
		"inputs": [
			["Unix Timestamp", ScriptBlock.PortType.INT, 0],
		],
		"outputs": [
			["Year", ScriptBlock.PortType.INT, 1970],
			["Month", ScriptBlock.PortType.INT, 1],
			["Day", ScriptBlock.PortType.INT, 1],
			["Hour", ScriptBlock.PortType.INT, 0],
			["Minute", ScriptBlock.PortType.INT, 0],
			["Second", ScriptBlock.PortType.INT, 0],
		]
	},
	# String
	{
		"name": "String Case Insensitive Equals",
		"type": "string_equals_case_insensitive",
		"category": "String",
		"description": "Performs a case-insensitive equality check on the given Strings. For example, \"RED\", \"red\", and \"Red\" would all be considered equal to each other.",
		"sequenced": false,
		"keywords": ["ignore", "equality", "case-insensitive", "lowercase", "uppercase", "capital"],
		"inputs": [
			["Left", ScriptBlock.PortType.STRING, ""],
			["Right", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Result", ScriptBlock.PortType.BOOL, false]
		]
	},
	{
		"name": "Concatenate Strings",
		"type": "concatenate_string",
		"category": "String",
		"description": "Concatenates the given strings together (also known as adding or appending the strings).",
		"sequenced": false,
		"inputs": [
			["Value 1", ScriptBlock.PortType.STRING, ""],
			["Value 2", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Join Strings",
		"type": "join_string",
		"category": "String",
		"description": "Joins the given strings together with the given Joiner in between each string. This is equivalent to `Joiner.join(PackedStringArray([Value1, Value2]))` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Joiner", ScriptBlock.PortType.STRING, ", "],
			["Value 1", ScriptBlock.PortType.STRING, ""],
			["Value 2", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Result", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Convert To String",
		"type": "to_string",
		"category": "String",
		"description": "Converts the given Input value to a string. This is equivalent to `str(Input)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Input", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["String", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Convert To JSON",
		"type": "to_json",
		"category": "String",
		"description": "Converts the given Key and Value to JSON as `{Key: Value}`.",
		"sequenced": false,
		"inputs": [
			["Key", ScriptBlock.PortType.STRING, "name"],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["JSON", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Format String Using Array",
		"type": "format_string_array",
		"category": "String",
		"description": "Formats the given Template string using the given Values array. This is equivalent to `Template % Values` in GDScript.",
		"sequenced": false,
		"inputs": [
			["Template", ScriptBlock.PortType.STRING, ""],
			["Values", ScriptBlock.PortType.ARRAY, []],
		],
		"outputs": [
			["String", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Format String Using JSON",
		"type": "format_string",
		"category": "String",
		"description": "Formats the given Template string using the given JSON. This is equivalent to `Template.format(JSON)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["JSON", ScriptBlock.PortType.STRING, "{}"],
			["Template", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["String", ScriptBlock.PortType.STRING, ""]
		]
	},
	{
		"name": "Get JSON key Value",
		"type": "get_json_key",
		"category": "String",
		"description": "Returns the Value for the given Key in the given JSON. If the Key does not exist, it will return null. This is equivalent to `JSON.get(Key)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["JSON", ScriptBlock.PortType.STRING, "{}"],
			["Key", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Merge JSONs",
		"type": "json_merge",
		"category": "String",
		"description": "Merges the given JSONs together. If the same key exists in both, the value from JSON1 will be used. This is equivalent to `JSON1.merge(JSON2)` in GDScript.",
		"sequenced": false,
		"inputs": [
			["JSON1", ScriptBlock.PortType.STRING, "{}"],
			["JSON2", ScriptBlock.PortType.STRING, "{}"]
		],
		"outputs": [
			["Output", ScriptBlock.PortType.STRING, "{}"]
		]
	},
	# Color
	{
		"name": "Color Construct",
		"type": "color_construct",
		"category": "Color",
		"description": "Constructs a Color from the given Red, Green, Blue, and Opacity values, on a range of 0 to 1.",
		"sequenced": false,
		"inputs": [
			["Red", ScriptBlock.PortType.FLOAT, 0.0],
			["Green", ScriptBlock.PortType.FLOAT, 0.0],
			["Blue", ScriptBlock.PortType.FLOAT, 0.0],
			["Opacity", ScriptBlock.PortType.FLOAT, 1.0]
		],
		"outputs": [
			["Color", ScriptBlock.PortType.COLOR, Color()]
		]
	},
	{
		"name": "Color From HSV",
		"type": "color_from_hsv",
		"category": "Color",
		"description": "Constructs a Color from the given Hue, Saturation, Value, and Opacity values, on a range of 0 to 1.",
		"sequenced": false,
		"inputs": [
			["Hue", ScriptBlock.PortType.FLOAT, 0.0],
			["Saturation", ScriptBlock.PortType.FLOAT, 0.0],
			["Value", ScriptBlock.PortType.FLOAT, 0.0],
			["Opacity", ScriptBlock.PortType.FLOAT, 1.0]
		],
		"outputs": [
			["Color", ScriptBlock.PortType.COLOR, Color()]
		]
	},
	{
		"name": "Color From String",
		"type": "color_from_string",
		"category": "Color",
		"description": "Constructs a Color from the given String. The String can be a friendly name (like red) or a hex color code (like #f00 or #ff0000). Returns Default if the String cannot be converted into a color.",
		"sequenced": false,
		"inputs": [
			["String", ScriptBlock.PortType.STRING, ""],
			["Default", ScriptBlock.PortType.COLOR, Color()],
		],
		"outputs": [
			["Color", ScriptBlock.PortType.COLOR, Color()]
		]
	},
	{
		"name": "Color Split",
		"type": "color_split",
		"category": "Color",
		"description": "Splits the given Color into its Red, Green, Blue, and Opacity values, on a range of 0 to 1.",
		"sequenced": false,
		"inputs": [
			["Color", ScriptBlock.PortType.COLOR, Color()]
		],
		"outputs": [
			["Red", ScriptBlock.PortType.FLOAT, 0.0],
			["Green", ScriptBlock.PortType.FLOAT, 0.0],
			["Blue", ScriptBlock.PortType.FLOAT, 0.0],
			["Opacity", ScriptBlock.PortType.FLOAT, 1.0]
		]
	},
	# Vector2
	{
		"name": "Vector2 Construct",
		"type": "vector2_construct",
		"category": "Vector2",
		"description": "Constructs a Vector2 from the given X and Y values.",
		"sequenced": false,
		"inputs": [
			["X", ScriptBlock.PortType.FLOAT, 0.0],
			["Y", ScriptBlock.PortType.FLOAT, 0.0]
		],
		"outputs": [
			["Vector", ScriptBlock.PortType.VECTOR2, Vector2()]
		]
	},
	{
		"name": "Vector2 From Angle (Sin/Cos)",
		"type": "vector2_from_angle",
		"category": "Vector2",
		"description": "Constructs a Vector2 from the given angle in degrees. The X value will be the cosine of the angle, and the Y value will be the sine of the angle. The X and Y values are also provided separately, so this script block can be used as Sin and Cos as well, or the values can be wired into a Vector3 Construct block.",
		"sequenced": false,
		"inputs": [
			["Degrees", ScriptBlock.PortType.FLOAT, 0.0],
		],
		"outputs": [
			["Vector", ScriptBlock.PortType.VECTOR2, Vector2()],
			["X (Cos)", ScriptBlock.PortType.FLOAT, 0.0],
			["Y (Sin)", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	{
		"name": "Vector2 Split",
		"type": "vector2_split",
		"category": "Vector2",
		"description": "Splits the given Vector2 into its X and Y values.",
		"sequenced": false,
		"inputs": [
			["Vector", ScriptBlock.PortType.VECTOR2, Vector2()]
		],
		"outputs": [
			["X", ScriptBlock.PortType.FLOAT, 0.0],
			["Y", ScriptBlock.PortType.FLOAT, 0.0]
		]
	},
	# Vector3
	{
		"name": "Vector3 Construct",
		"type": "vector3_construct",
		"category": "Vector3",
		"description": "Constructs a Vector3 from the given X, Y, and Z values.",
		"sequenced": false,
		"inputs": [
			["X", ScriptBlock.PortType.FLOAT, 0.0],
			["Y", ScriptBlock.PortType.FLOAT, 0.0],
			["Z", ScriptBlock.PortType.FLOAT, 0.0]
		],
		"outputs": [
			["Vector", ScriptBlock.PortType.VECTOR3, Vector3()]
		]
	},
	{
		"name": "Vector3 Split",
		"type": "vector3_split",
		"category": "Vector3",
		"description": "Splits the given Vector3 into its X, Y, and Z values.",
		"sequenced": false,
		"inputs": [
			["Vector", ScriptBlock.PortType.VECTOR3, Vector3()]
		],
		"outputs": [
			["X", ScriptBlock.PortType.FLOAT, 0.0],
			["Y", ScriptBlock.PortType.FLOAT, 0.0],
			["Z", ScriptBlock.PortType.FLOAT, 0.0]
		]
	},
	# Array
	{
		"name": "Array Construct",
		"type": "array_construct",
		"category": "Array",
		"description": "Constructs an Array from the given values.",
		"sequenced": false,
		"inputs": [
			["Index 0", ScriptBlock.PortType.ANY_DATA, ""],
			["Index 1", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["Array", ScriptBlock.PortType.ARRAY, []]
		]
	},
	{
		"name": "Array Get",
		"type": "array_get",
		"category": "Array",
		"description": "Returns the Value at the given Index in the given Array. If the Index is out of bounds, Value will be set to the default for the selected data type. The input array is passed through unchanged for convenience.",
		"sequenced": false,
		"inputs": [
			["Array", ScriptBlock.PortType.ARRAY, []],
			["Index", ScriptBlock.PortType.INT, 0]
		],
		"outputs": [
			["Pass", ScriptBlock.PortType.ARRAY, []],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Array Set",
		"type": "array_set",
		"category": "Array",
		"description": "Sets the Value at the given Index in the given Array. If the Index is out of bounds, the Array will be extended to fit the Index, up to a maximum size of 1000. The input array is passed through for convenience (this is not a copy).",
		"sequenced": true,
		"inputs": [
			["Array", ScriptBlock.PortType.ARRAY, []],
			["Index", ScriptBlock.PortType.INT, 0],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["Pass", ScriptBlock.PortType.ARRAY, []]
		]
	},
	{
		"name": "Array Contains / Find",
		"type": "array_contains",
		"category": "Array",
		"description": "If the given Array contains the given Value, Found will be true, and Index will be set to the index of the first occurrence. If Value is not in the Array, Found will be false and Index will be -1.",
		"sequenced": false,
		"inputs": [
			["Array", ScriptBlock.PortType.ARRAY, []],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
		],
		"outputs": [
			["Pass", ScriptBlock.PortType.ARRAY, []],
			["Found", ScriptBlock.PortType.BOOL, false],
			["Index", ScriptBlock.PortType.INT, -1],
		]
	},
	{
		"name": "Array For Each",
		"type": "array_for_each",
		"category": "Array",
		"description": "Loops through each value in the given Array. This is equivalent to `for value in array:` in GDScript. After finishing the loop, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Array", ScriptBlock.PortType.ARRAY, []]
		],
		"outputs": [
			["Index", ScriptBlock.PortType.INT, 0],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Array Pick Random",
		"type": "array_pick_random",
		"category": "Array",
		"description": "Picks a random Value from the given Array and its Index.",
		"sequenced": false,
		"inputs": [
			["Array", ScriptBlock.PortType.ARRAY, []]
		],
		"outputs": [
			["Index", ScriptBlock.PortType.INT, -1],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	# Dictionary
	{
		"name": "Dictionary Construct",
		"type": "dictionary_construct",
		"category": "Dictionary",
		"description": "Constructs a Dictionary from the given Key and Value pairs.",
		"sequenced": false,
		"inputs": [
			["Key", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
			["Key 2", ScriptBlock.PortType.STRING, ""],
			["Value 2", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["Dictionary", ScriptBlock.PortType.DICTIONARY, {}]
		]
	},
	{
		"name": "Dictionary Get",
		"type": "dictionary_get",
		"category": "Dictionary",
		"description": "Returns the Value at the given Key in the given Dictionary. If the Key does not exist, Value will be set to the default for the selected data type. The input dictionary is passed through unchanged for convenience.",
		"sequenced": false,
		"inputs": [
			["Dictionary", ScriptBlock.PortType.DICTIONARY, {}],
			["Key", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Pass", ScriptBlock.PortType.DICTIONARY, {}],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Dictionary Set",
		"type": "dictionary_set",
		"category": "Dictionary",
		"description": "Sets the Value at the given Key in the given Dictionary. The input dictionary is passed through for convenience (this is not a copy).",
		"sequenced": true,
		"inputs": [
			["Dictionary", ScriptBlock.PortType.DICTIONARY, {}],
			["Key", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		],
		"outputs": [
			["Pass", ScriptBlock.PortType.DICTIONARY, {}]
		]
	},
	{
		"name": "Dictionary For Each",
		"type": "dictionary_for_each",
		"category": "Dictionary",
		"description": "Loops through each key and value in the given Dictionary. This is equivalent to `for key in dictionary: var value = dictionary[key]` in GDScript. After finishing the loop, it will execute the Done flow.",
		"sequenced": true,
		"inputs": [
			["Dictionary", ScriptBlock.PortType.DICTIONARY, {}]
		],
		"outputs": [
			["Key", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	{
		"name": "Dictionary Pick Random",
		"type": "dictionary_pick_random",
		"category": "Dictionary",
		"description": "Picks a random Key and Value from the given Dictionary.",
		"sequenced": false,
		"inputs": [
			["Dictionary", ScriptBlock.PortType.DICTIONARY, {}]
		],
		"outputs": [
			["Key", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""]
		]
	},
	# SpaceObject instance
	{
		"name": "Get Self",
		"type": "self",
		"category": "SpaceObject",
		"description": "Returns the SpaceObject that this script is attached to, or the global scripts singleton if a global script. Note that you usually do not need this script block, as you can leave the Object port blank on most script blocks and it will use Self automatically.",
		"sequenced": false,
		"outputs": [
			["Self", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Create Space Object (Async)",
		"type": "create_space_object",
		"category": "SpaceObject",
		"description": "Creates a new SpaceObject with the given parameters. By default, the transform parameters are relative, the new object will spawn near the object the script is on. The new object will appear in the Space after a very short delay (a fraction of a second). This script block is async, it will pause execution until the SpaceObject finishes being created.",
		"sequenced": true,
		"inputs": [
			["Asset ID", ScriptBlock.PortType.STRING, ""],
			["Name", ScriptBlock.PortType.STRING, ""],
			["Position", ScriptBlock.PortType.VECTOR3, Vector3.UP],
			["Rotation Degrees", ScriptBlock.PortType.VECTOR3, Vector3.ZERO],
			["Relative", ScriptBlock.PortType.BOOL, true],
			["Scale", ScriptBlock.PortType.VECTOR3, Vector3.ONE],
			["Offset", ScriptBlock.PortType.VECTOR3, Vector3.ZERO],
			["Collision", ScriptBlock.PortType.BOOL, true],
			["Shape Type", ScriptBlock.PortType.STRING, "Auto"],
			["Body Type", ScriptBlock.PortType.STRING, "Static"],
			["Mass", ScriptBlock.PortType.FLOAT, 1.0],
			["Gravity Scale", ScriptBlock.PortType.FLOAT, 1.0],
			["Damageable", ScriptBlock.PortType.BOOL, false],
		],
		"outputs": [
			["SpaceObject", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Delete Space Object",
		"type": "delete_space_object",
		"category": "SpaceObject",
		"description": "Deletes the given SpaceObject.",
		"sequenced": true,
		"inputs": [
			["SpaceObject", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Get Space Object",
		"type": "get_space_object",
		"category": "SpaceObject",
		"description": "Gets the SpaceObject with the given Name or ID. If no object is found, it will return null.",
		"sequenced": false,
		"inputs": [
			["Name or ID", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["SpaceObject", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Is Other Space Object",
		"type": "is_other_space_object",
		"category": "SpaceObject",
		"description": "If the given Object is a SpaceObject and is not the current SpaceObject, Is Other will be true and SpaceObject will be set to the object. If the given Object is not a SpaceObject or is the current SpaceObject, Is Other will be false and SpaceObject will be set to null.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Is Other", ScriptBlock.PortType.BOOL, false],
			["Space Object", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "BBCode To SpaceObject Texture (Async)",
		"type": "bbcode_to_texture",
		"category": "SpaceObject",
		"description": "Takes the given SpaceObject (On Object) and renders a texture with the given BBCode and background color. The texture will be rendered after a very short delay (a few frames).",
		"sequenced": true,
		"inputs": [
			["On Object", ScriptBlock.PortType.OBJECT, null],
			["BBCode", ScriptBlock.PortType.STRING, ""],
			["BG Color", ScriptBlock.PortType.COLOR, Color.BLACK],
		]
	},
	{
		"name": "Scroll Texture",
		"type": "scroll_texture",
		"category": "SpaceObject",
		"description": "Scrolls the texture on the given SpaceObject (On Object) by the given Scroll Offset over the given Duration with the specified Transition and Easing.",
		"sequenced": true,
		"inputs": [
			["On Object", ScriptBlock.PortType.OBJECT, null],
			["Scroll Offset", ScriptBlock.PortType.VECTOR2, Vector2(1.0, 0.0)],
			["Duration", ScriptBlock.PortType.FLOAT, 2.0],
			["Transition", ScriptBlock.PortType.STRING, "Linear"],
			["Easing", ScriptBlock.PortType.STRING, "In Out"],
		]
	},
	{
		"name": "NPC Move to",
		"type": "npc_move_to",
		"category": "SpaceObject",
		"description": "Move the NPC toward the specified location. Returns: ON_TARGET, MOVING_TO_TARGET, MOVING_TO_BASE, ON_BASE",
		"sequenced": true,
		"inputs": [
			["On Object", ScriptBlock.PortType.OBJECT, null],
			["Target Location", ScriptBlock.PortType.VECTOR3, Vector3(0.0, 0.0, 0.0)],
			["Acceleration", ScriptBlock.PortType.FLOAT, 40.0],
			["Deceleration", ScriptBlock.PortType.FLOAT, 25.0],
			["Max Speed", ScriptBlock.PortType.FLOAT, 9.0],
			["Step Height", ScriptBlock.PortType.FLOAT, 0.2],
			["Max Push Force", ScriptBlock.PortType.FLOAT, 5000000.0],
			["Supporting Height", ScriptBlock.PortType.FLOAT, 0.2],
			["Gravity", ScriptBlock.PortType.FLOAT, 9.8],
			["Min Distance From Target", ScriptBlock.PortType.FLOAT, 2.0],
			["Max Distance From Target", ScriptBlock.PortType.FLOAT, -1.0],
			["Base Location", ScriptBlock.PortType.VECTOR3, Vector3(0.0, 0.0, 0.0)],
			["Steering Ray Offset", ScriptBlock.PortType.VECTOR3, Vector3(0.0, 1.0, 0.0)],
			["Steering Ray Length", ScriptBlock.PortType.FLOAT, 10.0],
			["Steering Ray Radius", ScriptBlock.PortType.FLOAT, 0.5],
			["Steering Ignore", ScriptBlock.PortType.ARRAY, []],
			["Rotation offset", ScriptBlock.PortType.FLOAT, 0.0],
		],
		"outputs": [
			["Result", ScriptBlock.PortType.STRING, "ON_BASE"]
		]
	},
	{
		"name": "Damage Using Capsule",
		"type": "damage_using_capsule",
		"category": "SpaceObject",
		"description": "Cast a capsule and damage anything within that capsule.",
		"sequenced": true,
		"inputs": [
			["On Object", ScriptBlock.PortType.OBJECT, null],
			["Damage", ScriptBlock.PortType.FLOAT, 10.0],
			["Impulse", ScriptBlock.PortType.FLOAT, 0.0],
			["Can Damage Teams", ScriptBlock.PortType.ARRAY, []],
			["Can Damage Self", ScriptBlock.PortType.BOOL, false],
			["Ignore", ScriptBlock.PortType.ARRAY, []],
			["Collider Offset", ScriptBlock.PortType.VECTOR3, Vector3(0.0, 0.0, 0.0)],
			["Height", ScriptBlock.PortType.FLOAT, 2.0],
			["Radius", ScriptBlock.PortType.FLOAT, 1.0],
		],
		"outputs": [
			["Damaged", ScriptBlock.PortType.ARRAY, []]
		]
	},
	{
		"name": "Is dead",
		"type": "is_dead",
		"category": "SpaceObject",
		"description": "Returns true when the SpaceObject or Character is dead.",
		"sequenced": false,
		"inputs": [
			["On Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Is Dead", ScriptBlock.PortType.BOOL, false]
		]
	},
	# Player
	{
		"name": "Get All Players",
		"type": "get_all_players",
		"category": "Player",
		"description": "Gets all Players in the Space as an Array. You can loop over this with the Array For Each script block.",
		"sequenced": false,
		"outputs": [
			["Players", ScriptBlock.PortType.ARRAY, []],
		]
	},
	{
		"name": "Get Players On Team",
		"type": "get_players_on_team",
		"category": "Player",
		"description": "Gets all Players on the given Team as an Array. You can loop over this with the Array For Each script block.",
		"sequenced": false,
		"inputs": [
			["Team Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Players", ScriptBlock.PortType.ARRAY, []],
		]
	},
	{
		"name": "Get Local Player (Client-Side)",
		"type": "get_local_player",
		"category": "Player",
		"description": "Gets the local Player. This script block may only be run on client-side scripts. If ran on the server, an error will be printed.",
		"sequenced": false,
		"local_only": true,
		"outputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Get Player By ID",
		"type": "get_player_by_id",
		"category": "Player",
		"description": "Gets a player by their User ID. If found, it is set to Player, and Is Valid will be true. If no player is found, Player will be null, and Is Valid will be false.",
		"sequenced": false,
		"inputs": [
			["User ID", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
			["Is Valid", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Get Players In Range",
		"type": "get_player_in_range",
		"category": "Player",
		"description": "Gets players in a given range. If multiple players are in range, Closest Player will be the nearest one. If no players are in range, Closest Player will be null and the array will be empty.",
		"sequenced": false,
		"inputs": [
			["Relative To", ScriptBlock.PortType.OBJECT, null],
			["Range", ScriptBlock.PortType.FLOAT, 5.0],
		],
		"outputs": [
			["Closest Player", ScriptBlock.PortType.OBJECT, null],
			["Players In Range", ScriptBlock.PortType.ARRAY, []],
		]
	},
	{
		"name": "Get Player Role For Space",
		"type": "get_player_role_for_space",
		"category": "Player",
		"description": "Gets the role of the given Player. Return values include but are not limited to OWNER, MANAGER, CONTRIBUTOR, and OBSERVER. Role ID is a number from 0 to 1000 that reflects the permissions level, 1000 means all permissions and 0 means no permissions.",
		"sequenced": false,
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Role Name", ScriptBlock.PortType.STRING, ""],
			["Role ID", ScriptBlock.PortType.INT, 0],
		]
	},
	{
		"name": "Get Player Inventory",
		"type": "get_player_inventory",
		"category": "Player",
		"description": "Gets the inventory of the given Player. This includes the currently held item and all items. The inventory array is a copy, any writes will not affect the player.",
		"sequenced": false,
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Inventory", ScriptBlock.PortType.ARRAY, []],
			["Held Item", ScriptBlock.PortType.STRING, null],
		]
	},
	{
		"name": "Get Player Head",
		"type": "get_player_head",
		"category": "Player",
		"description": "Gets the head of the given Player. This can be used to get the position or rotation of the player's viewpoint. This node's transform may only be read, any writes will be ignored and overwritten.",
		"sequenced": false,
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Head", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Get Player Height",
		"type": "get_player_height",
		"category": "Player",
		"description": "Gets the height of the given Player. The height can either be retrieved in Meters or as a Multiplier of the player's model height.",
		"sequenced": false,
		"keywords": ["scale", "size", "tall", "huge", "giant", "short", "small", "tiny", "macro", "micro"],
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
			["Height Type", ScriptBlock.PortType.STRING, "Meters"],
		],
		"outputs": [
			["Height", ScriptBlock.PortType.FLOAT, 1.75],
		]
	},
	{
		"name": "Set Player Height",
		"type": "set_player_height",
		"category": "Player",
		"description": "Sets the height of the given Player. This can be used to make the player tiny or giant. The height can either be set in Meters or as a Multiplier of the player's model height. For competitive games, you would likely want to set all players to the same height in meters.",
		"sequenced": true,
		"keywords": ["scale", "size", "tall", "huge", "giant", "short", "small", "tiny", "macro", "micro"],
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
			["Height", ScriptBlock.PortType.FLOAT, 1.75],
			["Height Type", ScriptBlock.PortType.STRING, "Meters"],
		],
	},
	{
		"name": "Set Player Avatar",
		"type": "set_player_avatar",
		"category": "Player",
		"description": "Sets the Player's avatar to the specified URL. This can be used to create an avatar world where users interact\nwith objects to switch to avatars, or to enforce a specific appearance in competitive or class-based games.\nThe Avatar input must be a URL to the avatar GLB file, such as an avatar from Ready Player Me.\n\nFor competitive or class-based games, set Lock to true to prevent players from switching to another avatar in their menu.\nIf your game is not competitive but you still want to ensure players are a similar size, consider using Set Player Height\ninstead, as custom avatars are a very fun form of self-expression; most users want to play as themselves.",
		"sequenced": true,
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
			["Avatar", ScriptBlock.PortType.STRING, ""],
			["Lock", ScriptBlock.PortType.BOOL, false],
			["Height", ScriptBlock.PortType.FLOAT, 1.0],
			["Height Type", ScriptBlock.PortType.STRING, "Multiplier"],
		],
	},
	{
		"name": "Tween Player Height",
		"type": "tween_player_height",
		"category": "Player",
		"description": "Tweens the height of the given Player. The height can either be tweened in Meters or as a Multiplier of the player's model height.",
		"sequenced": true,
		"keywords": ["scale", "size", "tall", "huge", "giant", "short", "small", "tiny", "macro", "micro"],
		"inputs": [
			["Player", ScriptBlock.PortType.OBJECT, null],
			["Height", ScriptBlock.PortType.FLOAT, 1.75],
			["Height Type", ScriptBlock.PortType.STRING, "Meters"],
			["Duration", ScriptBlock.PortType.FLOAT, 1.0],
			["Transition", ScriptBlock.PortType.STRING, "Linear"],
			["Easing", ScriptBlock.PortType.STRING, "In Out"],
		],
	},
	{
		"name": "Is Valid Player",
		"type": "is_valid_player",
		"category": "Player",
		"description": "If the given Object is a Player, Is Valid will be true and Player will be set to the player. If the given Object is not a Player, Is Valid will be false and Player will be set to null.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Is Valid", ScriptBlock.PortType.BOOL, false],
			["Player", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "User Profile Request (Async)",
		"type": "user_profile_request",
		"category": "Player",
		"description": "Requests the user profile for the given User ID. The profile will be returned after a short delay (a fraction of a second).",
		"sequenced": true,
		"inputs": [
			["User ID", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["JSON", ScriptBlock.PortType.STRING, ""],
		]
	},
	# Animation
	{
		"name": "Play Animation",
		"type": "play_animation",
		"category": "Animation",
		"description": "Plays the given animation on the given Node with the given speed. The node can either be an AnimationPlayer or the ancestor of one; this allows you to play an animation on a SpaceObject and it will automatically find the AnimationPlayer for you. The animation name can be one of the animations supplied by the GLTF model file, or it can be special names `stop` or `pause` to stop or pause the animation. If the animation does not exist, it will print an error and script execution will be stopped.",
		"sequenced": true,
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
			["Name", ScriptBlock.PortType.STRING, "stop"],
			["Speed", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	{
		"name": "Is Animation Playing",
		"type": "is_animation_playing",
		"category": "Animation",
		"description": "Returns true if the given animation is playing on the given Node. The animation name can be one of the animations supplied by the GLTF model file, or it can be empty to check for any animation playing. The node can either be an AnimationPlayer or the ancestor of one; this allows you to check if an animation is playing on a SpaceObject and it will automatically find the AnimationPlayer for you.",
		"sequenced": false,
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
			["Name Or Empty", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Is Playing", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Get Animation Speed",
		"type": "get_animation_speed",
		"category": "Animation",
		"description": "Returns the speed of animation playback on the given Node. The node can either be an AnimationPlayer or the ancestor of one; this allows you to get the speed of an animation playing on a SpaceObject and it will automatically find the AnimationPlayer for you.",
		"sequenced": false,
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Speed", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	# Audio
	{
		"name": "Play Audio Clip",
		"type": "play_audio_clip",
		"category": "Audio",
		"description": "Plays the given Asset ID containing audio as a one-shot audio clip with the given settings. Audio clips are not connected to a persistent audio player node, they are for when you 'just want to play audio' without worrying about nodes. Audio clips cannot be tracked or stopped once started, and may have multiple playing at once, they are best used for short sound effects.",
		"sequenced": true,
		"keywords": ["sound", "music"],
		"inputs": [
			["Asset ID", ScriptBlock.PortType.STRING, ""],
			["Volume", ScriptBlock.PortType.FLOAT, 100.0],
			["Speed", ScriptBlock.PortType.FLOAT, 1.0],
			["Speed Randomness", ScriptBlock.PortType.FLOAT, 0.0],
			["Is Spatial", ScriptBlock.PortType.BOOL, true],
			["Spatial Range", ScriptBlock.PortType.FLOAT, 0.0],
			["Spatial Max Volume", ScriptBlock.PortType.FLOAT, 150.0],
		]
	},
	{
		"name": "Play Audio Node (Same Settings)",
		"type": "play_audio_node_same",
		"category": "Audio",
		"description": "Plays the given audio player node with the same settings as it was last played with. Audio player nodes allow you to persistently keep track of audio playback, including stopping it later, or running a signal when it finishes. Audio nodes may only have one audio playback playing at a time, they are best used for music or game-critical audio like performing an action when the final boss's monologue ends. The node can either be an audio player or the ancestor of one; this allows you to play audio on a SpaceObject and it will automatically find the audio player node for you.",
		"sequenced": true,
		"keywords": ["sound", "music"],
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Play Audio Node (Custom Settings)",
		"type": "play_audio_node_custom",
		"category": "Audio",
		"description": "Plays the given audio player node with the given settings. Audio player nodes allow you to persistently keep track of audio playback, including stopping it later, or running a signal when it finishes. Audio nodes may only have one audio playback playing at a time, they are best used for music or game-critical audio like performing an action when the final boss's monologue ends. The node can either be an audio player or the ancestor of one; this allows you to play audio on a SpaceObject and it will automatically find the audio player node for you.",
		"sequenced": true,
		"keywords": ["sound", "music"],
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
			["Loop", ScriptBlock.PortType.BOOL, false],
			["Volume", ScriptBlock.PortType.FLOAT, 100.0],
			["Speed", ScriptBlock.PortType.FLOAT, 1.0],
			["Speed Randomness", ScriptBlock.PortType.FLOAT, 0.0],
			["Is Spatial", ScriptBlock.PortType.BOOL, true],
			["Spatial Range", ScriptBlock.PortType.FLOAT, 0.0],
			["Spatial Max Volume", ScriptBlock.PortType.FLOAT, 150.0],
		]
	},
	{
		"name": "Is Audio Node Playing",
		"type": "is_audio_node_playing",
		"category": "Audio",
		"description": "Returns true if the given audio player node is currently playing audio. The node can either be an audio player or the ancestor of one; this allows you to check if a SpaceObject is playing audio and it will automatically find the audio player node for you.",
		"sequenced": false,
		"keywords": ["sound", "music"],
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Is Playing", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Stop Playing Audio Node",
		"type": "stop_audio_node",
		"category": "Audio",
		"description": "Stops the given audio player node from playing audio. The node can either be an audio player or the ancestor of one; this allows you to stop playing audio on a SpaceObject and it will automatically find the audio player node for you.",
		"sequenced": true,
		"keywords": ["sound", "music"],
		"inputs": [
			["Node", ScriptBlock.PortType.OBJECT, null],
		]
	},
	# Physics
	{
		"name": "Apply Force Impulse",
		"type": "apply_force_impulse",
		"category": "Physics",
		"description": "Applies an Impulse force to the given Physics Body. This is a one-time force with a unit of Newton-seconds (kg⋅m/s). The physics body must be set to Dynamic to use this block.",
		"sequenced": true,
		"inputs": [
			["Physics Body", ScriptBlock.PortType.OBJECT, null],
			["Impulse", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	{
		"name": "Apply Force Over Time",
		"type": "apply_force_over_time",
		"category": "Physics",
		"description": "Applies a Force to the given Physics Body over a period of time specified by Duration. This is a continuous force with a unit of Newtons (kg⋅m/s²). The physics body must be set to Dynamic to use this block.",
		"sequenced": true,
		"inputs": [
			["Physics Body", ScriptBlock.PortType.OBJECT, null],
			["Force", ScriptBlock.PortType.VECTOR3, Vector3()],
			["Duration", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	{
		"name": "Move And Collide",
		"type": "move_and_collide",
		"category": "Physics",
		"description": "Moves the given Physics Body by the given Movement Amount. This is not recommended if other blocks will work in its place, but is useful for moving a SpaceObject in well-defined steps when you want to have fine control over movement. The physics body must not be Static, but may be Kinematic, Dynamic, or Trigger.",
		"sequenced": true,
		"inputs": [
			["Physics Body", ScriptBlock.PortType.OBJECT, null],
			["Movement Amount", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	{
		"name": "Get Physics Material Properties",
		"type": "get_physics_material_properties",
		"category": "Physics",
		"description": "Gets the Physics Material Properties of the given Physics Body: Friction and Bounciness (also known as restitution).",
		"sequenced": false,
		"keywords": ["friction", "bounce", "bouncy", "bounciness", "restitution", "roughness", "absorbent", "absorbency"],
		"inputs": [
			["Physics Body", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Friction", ScriptBlock.PortType.FLOAT, 0.2],
			["Bounciness", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	{
		"name": "Set Physics Material Properties",
		"type": "set_physics_material_properties",
		"category": "Physics",
		"description": "Sets the Physics Material Properties of the given Physics Body: Friction and Bounciness (also known as restitution).",
		"sequenced": true,
		"inputs": [
			["Physics Body", ScriptBlock.PortType.OBJECT, null],
			["Friction", ScriptBlock.PortType.FLOAT, 0.2],
			["Bounciness", ScriptBlock.PortType.FLOAT, 0.0],
		]
	},
	{
		"name": "Physics Raycast",
		"type": "physics_raycast",
		"category": "Physics",
		"description": "Performs a raycast from the From vector in the Direction vector. If Length is negative, the size of Direction is used as the length. If Sphere Radius is 0 then perform a raycast, otherwise this is the radius of the sphere to use as a shape cast. Hit Triggers allows controlling if the raycast hits triggers, if false only solid objects will be hit. The Ignore inputs allow ignoring self or other objects.\n\nThe outputs correspond to the closest hit object. Body is the node that was hit. One of Depth or Fraction will be zero. If the cast started inside of the hit shape, Depth will correspond to the amount of penetration depth. If the cast started outside of the hit shape, Fraction is the ratio of the cast distance which the cast travels to hit it. Normal is the direction of contact, and Position is the location of contact, both in global world space.\n\nAll Hits is an Array of Dictionaries that contains \"body\", \"depth\", \"fraction\", \"normal\", and \"position\" like the other outputs, but for all hits. When Has Hit is false, All Hits is empty. When Has Hit is true, index 0 is the same data as the outputs. All Hits may zero or one result for raycasts. All Hits may have zero, one, or many results for shape casts.",
		"sequenced": true,
		"inputs": [
			["From", ScriptBlock.PortType.VECTOR3, Vector3()],
			["Direction", ScriptBlock.PortType.VECTOR3, Vector3()],
			["Length", ScriptBlock.PortType.FLOAT, -1.0],
			["Sphere Radius", ScriptBlock.PortType.FLOAT, 0.0],
			["Hit Triggers", ScriptBlock.PortType.BOOL, false],
			["Ignore Self", ScriptBlock.PortType.BOOL, true],
			["Ignore Objects", ScriptBlock.PortType.ARRAY, []],
		],
		"outputs": [
			["Has Hit", ScriptBlock.PortType.BOOL, false],
			["Body", ScriptBlock.PortType.OBJECT, null],
			["Depth", ScriptBlock.PortType.FLOAT, -1.0],
			["Fraction", ScriptBlock.PortType.FLOAT, -1.0],
			["Normal", ScriptBlock.PortType.VECTOR3, Vector3()],
			["Position", ScriptBlock.PortType.VECTOR3, Vector3()],
			["All Hits", ScriptBlock.PortType.ARRAY, []],
		]
	},
	# Environment
	{
		"name": "Get Environment Sun",
		"type": "get_environment_sun",
		"category": "Environment",
		"description": "Gets the sun with the given index from the environment. You may have between 0 and 4 suns in your game. If the requested index does not exist, the script block will show error.",
		"sequenced": false,
		"inputs": [
			["Index", ScriptBlock.PortType.INT, 0],
		],
		"outputs": [
			["Sun", ScriptBlock.PortType.OBJECT, null],
		]
	},
	{
		"name": "Set Environment Fog",
		"type": "set_environment_fog",
		"category": "Environment",
		"description": "Sets the environment's fog settings to the given parameters.",
		"sequenced": true,
		"inputs": [
			["Enabled", ScriptBlock.PortType.BOOL, false],
			["Volumetric", ScriptBlock.PortType.BOOL, false],
			["Density", ScriptBlock.PortType.FLOAT, 0.01],
			["Color", ScriptBlock.PortType.COLOR, Color(0.8, 0.9, 1.0)],
		]
	},
	{
		"name": "Set Environment Properties",
		"type": "set_environment_properties",
		"category": "Environment",
		"description": "Sets the environment's Sun Count and Global Illumination to the given values. You may have between 0 and 4 suns in your game.",
		"sequenced": true,
		"inputs": [
			["Sun Count", ScriptBlock.PortType.INT, 1],
			["Global Illumination", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Set Environment Sky Color",
		"type": "set_environment_sky_color",
		"category": "Environment",
		"description": "Sets the environment's sky colors to the given colors.",
		"sequenced": true,
		"inputs": [
			["Top Color", ScriptBlock.PortType.COLOR, Color(0.38, 0.45, 0.55)],
			["Horizon Color", ScriptBlock.PortType.COLOR, Color(0.65, 0.65, 0.67)],
			["Bottom Color", ScriptBlock.PortType.COLOR, Color(0.2, 0.17, 0.13)],
		]
	},
	# Variables
	{
		"name": "Get Global Variable",
		"type": "get_global_variable",
		"category": "Variables",
		"sequenced": false,
		"description": "Gets the value of the global variable with the given name or path. The variable will be of the type specified by the script block. Variables may be accessed by name or by JSON pointer path. For example, `a/b` and `a.b` both refer to `\"a\": {\"b\": \"this value\"}`. Variables are for user-defined data and are automatically synced over the network.",
		"inputs": [
			["Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Has Global Variable",
		"type": "has_global_variable",
		"category": "Variables",
		"description": "Returns true if the global variable with the given name or path exists, false otherwise. Variables may be accessed by name or by JSON pointer path. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": false,
		"inputs": [
			["Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Has Variable", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Set Global Variable",
		"type": "set_global_variable",
		"category": "Variables",
		"description": "Sets the value of the global variable with the given name or path. Variables may be accessed by name or by JSON pointer path. For example, `a/b` and `a.b` both refer to `\"a\": {\"b\": \"this value\"}`. If the path does not exist, it will be created. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": true,
		"inputs": [
			["Name", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Tween Global Variable",
		"type": "tween_global_variable",
		"category": "Variables",
		"description": "Tweens the global variable with the given name or path with the given settings. Variables may be accessed by name or by JSON pointer path. For example, `a/b` and `a.b` both refer to `\"a\": {\"b\": \"this value\"}`. If the path does not exist, it will be created. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": true,
		"inputs": [
			["Name", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
			["Duration", ScriptBlock.PortType.FLOAT, 1.0],
			["Transition", ScriptBlock.PortType.STRING, "Linear"],
			["Easing", ScriptBlock.PortType.STRING, "In Out"],
		]
	},
	{
		"name": "Get Object Variable",
		"type": "get_object_variable",
		"category": "Variables",
		"description": "Gets the value of the object variable with the given name or path. Variables may be accessed by name or by JSON pointer path. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Has Object Variable",
		"type": "has_object_variable",
		"category": "Variables",
		"description": "Returns true if the object variable with the given name or path exists, false otherwise. Variables may be accessed by name or by JSON pointer path. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Has Variable", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Set Object Variable",
		"type": "set_object_variable",
		"category": "Variables",
		"description": "Sets the value of the object variable with the given name or path. Variables may be accessed by name or by JSON pointer path. If the path does not exist, it will be created. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": true,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Name", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	{
		"name": "Tween Object Variable",
		"type": "tween_object_variable",
		"category": "Variables",
		"description": "Tweens the object variable with the given name or path with the given settings. Variables may be accessed by name or by JSON pointer path. If the path does not exist, it will be created. Variables are for user-defined data and are automatically synced over the network.",
		"sequenced": true,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Name", ScriptBlock.PortType.STRING, ""],
			["Value", ScriptBlock.PortType.ANY_DATA, ""],
			["Duration", ScriptBlock.PortType.FLOAT, 1.0],
			["Transition", ScriptBlock.PortType.STRING, "Linear"],
			["Easing", ScriptBlock.PortType.STRING, "In Out"],
		]
	},
	# Match
	{
		"name": "Start Match",
		"type": "match_start",
		"category": "Match",
		"description": "Start a new match and freeze players for the given time. If a match is already running, a new match will override the old one.",
		"sequenced": true,
		"inputs": [
			["Freeze Time", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	{
		"name": "End Match",
		"type": "match_end",
		"category": "Match",
		"description": "Ends the current match, declares the given team as the winner, and force-shows the scoreboard. If no match is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
		"inputs": [
			["Winning Team Name", ScriptBlock.PortType.STRING, ""],
		]
	},
	{
		"name": "Terminate Match",
		"type": "match_terminate",
		"category": "Match",
		"description": "Terminates the current match and does not declare a winner. This block will work even when no match is running.",
		"sequenced": true,
	},
	{
		"name": "Is Match Running",
		"type": "is_match_running",
		"category": "Match",
		"description": "Returns true if a match is currently running.",
		"sequenced": false,
		"outputs": [
			["Is Running", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Start Round",
		"type": "round_start",
		"category": "Match",
		"description": "Start a new round and freeze players for the given time. If a round is already running, a new round will override the old one. If no match is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
		"inputs": [
			["Freeze Time", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	{
		"name": "End Round",
		"type": "round_end",
		"category": "Match",
		"description": "Ends the current round and adds 1 point to this round's winning team. If no round is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
		"inputs": [
			["Winning Team Name", ScriptBlock.PortType.STRING, ""],
			["Auto Start Next", ScriptBlock.PortType.BOOL, true],
			["Auto Start Wait Time", ScriptBlock.PortType.FLOAT, 3.0],
			["Auto Start Freeze Time", ScriptBlock.PortType.FLOAT, 1.0],
		]
	},
	{
		"name": "Terminate Round",
		"type": "round_terminate",
		"category": "Match",
		"description": "Terminates the current round without declaring a winner. The next round will not automatically start and no On Round End signal will be emitted. For normal gameplay loops, use End Round instead. If no match is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
	},
	{
		"name": "Is Round Running",
		"type": "is_round_running",
		"category": "Match",
		"description": "Returns true if a round is currently running, false otherwise.",
		"sequenced": false,
		"outputs": [
			["Is Running", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Set Match Settings",
		"type": "set_match_settings",
		"category": "Match",
		"description": "Sets the match settings for the current match to the given Freeze Time, Friendly Fire, and Win Score settings. The settings will be saved to Space Variables. Friendly Fire may be set to \"Enabled\", \"Disabled\", \"No Kills\", or \"Reflect\".",
		"sequenced": true,
		"keywords": ["winning", "score", "round", "freeze", "time", "limit", "end", "victory", "lose", "loss", "draw", "tie"],
		"inputs": [
			["Freeze Time", ScriptBlock.PortType.FLOAT, 1.0],
			["Friendly Fire", ScriptBlock.PortType.STRING, "Enabled"],
			["Win Score", ScriptBlock.PortType.INT, 3],
		]
	},
	{
		"name": "Add Score To Team",
		"type": "add_score_to_team",
		"category": "Match",
		"description": "Adds the given Score to the given team's score. If the Team Name does not correspond to any team, no score will be set on a team, but if the score is high enough a victory will be triggered anyway. If no match is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
		"inputs": [
			["Team Name", ScriptBlock.PortType.STRING, ""],
			["Score", ScriptBlock.PortType.INT, 1],
		]
	},
	{
		"name": "Get Score For Team",
		"type": "get_score_for_team",
		"category": "Match",
		"description": "Gets the score of the given team. If the Team Name does not correspond to any team, -1 will be returned. This block may run even if no match is running.",
		"sequenced": false,
		"inputs": [
			["Team Name", ScriptBlock.PortType.STRING, ""],
		],
		"outputs": [
			["Score", ScriptBlock.PortType.INT, 0],
		]
	},
	{
		"name": "Set Score For Team",
		"type": "set_score_for_team",
		"category": "Match",
		"description": "Sets the given team's score to the given New Score. If the Team Name does not correspond to any team, no score will be set on a team, but if the score is high enough a victory will be triggered anyway. If no match is running, a warning will be shown and the block will do nothing.",
		"sequenced": true,
		"inputs": [
			["Team Name", ScriptBlock.PortType.STRING, ""],
			["New Score", ScriptBlock.PortType.INT, 0],
		]
	},
	{
		"name": "Set Scoreboard Title",
		"type": "set_scoreboard_title",
		"category": "Match",
		"description": "Sets the title of the scoreboard to the given text.",
		"sequenced": true,
		"inputs": [
			["Title", ScriptBlock.PortType.STRING, "Scoreboard"],
		]
	},
	{
		"name": "Show Scoreboard",
		"type": "show_scoreboard",
		"category": "Match",
		"description": "Shows the scoreboard for players. If Player Or All is not specified, the scoreboard is shown for all players. Note: In Build mode, at least one button will always be shown, to prevent soft-locking yourself.",
		"sequenced": true,
		"inputs": [
			["Player Or All", ScriptBlock.PortType.OBJECT, null],
			["Allow Close", ScriptBlock.PortType.BOOL, true],
			["Allow New Match", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Hide Scoreboard",
		"type": "hide_scoreboard",
		"category": "Match",
		"description": "Hides the scoreboard for players. If Player Or All is not specified, the scoreboard is hidden for all players.",
		"sequenced": true,
		"inputs": [
			["Player Or All", ScriptBlock.PortType.OBJECT, null],
		]
	},
	# Space
	{
		"name": "Get Space ID",
		"type": "get_space_id",
		"category": "Space",
		"description": "Gets the ID of the current Space. This is a unique identifier that can be used to identify the Space.",
		"sequenced": false,
		"outputs": [
			["Space ID", ScriptBlock.PortType.STRING, ""],
		]
	},
	# Rotation Degrees
	{
		"name": "Get Rotation Degrees",
		"type": "get_rotation_degrees",
		"category": "Rotation Degrees",
		"description": "Gets the rotation in the form of Euler angles in degrees.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Rotation Degrees", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	{
		"name": "Set Rotation Degrees",
		"type": "set_rotation_degrees",
		"category": "Rotation Degrees",
		"description": "Sets the rotation in the form of Euler angles in degrees.",
		"sequenced": true,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Rotation Degrees", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	{
		"name": "Tween Rotation Degrees",
		"type": "tween_rotation_degrees",
		"category": "Rotation Degrees",
		"description": "Tweens the rotation in the form of Euler angles in degrees over the given Duration with the given Transition and Easing.",
		"sequenced": true,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
			["Rotation Degrees", ScriptBlock.PortType.VECTOR3, Vector3()],
			["Duration", ScriptBlock.PortType.FLOAT, 1.0],
			["Transition", ScriptBlock.PortType.STRING, "Linear"],
			["Easing", ScriptBlock.PortType.STRING, "In Out"],
		]
	},
	# Misc low priority
	{
		"name": "Get Friendly Name",
		"type": "get_friendly_name",
		"category": "Advanced",
		"description": "Gets the friendly name of the given Object. For SpaceObject, this will get the name shown in the inspector. For Player, this will get the player's display name.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Friendly Name", ScriptBlock.PortType.STRING, ""],
		]
	},
	{
		"name": "Get Node Name Or ID",
		"type": "get_node_name",
		"category": "Advanced",
		"description": "Gets the raw name of the given node. For SpaceObject and Player, this will return their unique ID.",
		"sequenced": false,
		"inputs": [
			["Object", ScriptBlock.PortType.OBJECT, null],
		],
		"outputs": [
			["Node Name or ID", ScriptBlock.PortType.STRING, ""],
		]
	},
	{
		"name": "Attach Script",
		"type": "attach_script",
		"category": "Advanced",
		"description": "Attaches the given Space script entity to the given SpaceObject. The Script Name must be the name of a script already present in the Space. If the script is already attached, this block will silently exit and do nothing.",
		"sequenced": true,
		"inputs": [
			["Space Object", ScriptBlock.PortType.OBJECT, null],
			["Script Name", ScriptBlock.PortType.STRING, ""],
			["Run In Build Mode", ScriptBlock.PortType.BOOL, true],
			["Run On Client", ScriptBlock.PortType.BOOL, false],
			["Run On Server", ScriptBlock.PortType.BOOL, true],
		]
	},
	#{
	#	"name": "GDScript Code",
	#	"type": "gdscript_code",
	#	"sequenced": true,
	#	"description": "Allows you to run GDScript code inside of a visual script.",
	#},
	{
		"name": "Is Server",
		"type": "is_server",
		"category": "Advanced",
		"description": "Returns true if the script is running on the server, false otherwise.",
		"sequenced": false,
		"outputs": [
			["Is Server", ScriptBlock.PortType.BOOL, false],
		]
	},
	{
		"name": "Evaluate Now",
		"type": "evaluate_now",
		"category": "Advanced",
		"description": "Evaluates the given data script block(s) immediately. This is useful for controlling the evaluation order of data blocks. The connected input must be data block, not a run block. All inputs must be connected.",
		"sequenced": true,
		"inputs": [
			["Input 1", ScriptBlock.PortType.CONNECTION, null],
		],
		"outputs": [
			["Output 1", ScriptBlock.PortType.ANY_DATA, ""],
		]
	},
	#{
	#	"name": "Reset Data Blocks",
	#	"type": "reset_unsequenced",
	#	"category": "Advanced",
	#	"description": "Reset the evaluated state of all data blocks.",
	#	"sequenced": true,
	#},
]
