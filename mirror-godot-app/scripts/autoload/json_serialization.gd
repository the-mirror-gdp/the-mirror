class_name Serialization


static func array_to_vector2(array: Array) -> Vector2:
	return Vector2(array[0], array[1])


static func vector2_to_array(vector: Vector2) -> Array:
	return [vector.x, vector.y]


static func array_to_vector3(array: Array) -> Vector3:
	return Vector3(array[0], array[1], array[2])


static func vector3_to_array(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]


static func array_to_color(array: Array) -> Color:
	var alpha: float = 1.0 if array.size() < 4 else array[3]
	return Color(array[0], array[1], array[2], alpha)


static func color_to_array(color: Color) -> Array:
	# Only save 3 digits of precision for Color. 3 is plenty for storing
	# standard color precision. Any more than 5 is useless even for HDR.
	var array = [
		snapped(color.r, 0.001),
		snapped(color.g, 0.001),
		snapped(color.b, 0.001),
		snapped(color.a, 0.001),
	]
	if is_equal_approx(array[3], 1.0):
		array.remove_at(3)
	return array


static func type_convert_any(value: Variant, type: ScriptBlock.PortType) -> Variant:
	if type == ScriptBlock.PortType.ANY_DATA:
		return value
	return type_convert(value, type)


static func type_convert_to_json(value: Variant) -> Variant:
	if typeof(value) == TYPE_OBJECT:
		# Must use typeof(), NOT "is Object" to handle Godot <Object#null> (a Variant
		# of type Object) which is different from regular null (a Variant of type Nil).
		return null
	if value is Color:
		return color_to_array(value)
	if value is Vector2:
		return vector2_to_array(value)
	if value is Vector3:
		return vector3_to_array(value)
	if value is Array:
		return serialize_array_to_json(value)
	if value is Dictionary:
		return serialize_dictionary_to_json(value)
	return value


static func type_convert_from_json(value: Variant, type: int) -> Variant:
	if type == TYPE_OBJECT:
		return null
	if value is Array:
		if type == TYPE_COLOR:
			return array_to_color(value)
		if type == TYPE_VECTOR2:
			return array_to_vector2(value)
		if type == TYPE_VECTOR3:
			return array_to_vector3(value)
		if type == TYPE_ARRAY:
			value = load_serialized_json_as_array(value)
		if type == TYPE_DICTIONARY:
			value = load_serialized_json_as_dictionary(value)
	if type == TYPE_NIL:
		return value
	return type_convert(value, type)


static func serialize_dictionary_to_json(source_dict: Dictionary) -> Array:
	var serialized: Array = []
	for key in source_dict:
		var value: Variant = source_dict[key]
		var type: int = typeof(value)
		var serialized_value: Variant = type_convert_to_json(value)
		var serialized_item = [key, type, serialized_value]
		if not key is String: # Unlikely
			serialized_item.append(typeof(key))
			serialized_item[0] = type_convert_to_json(key)
		serialized.append(serialized_item)
	return serialized


static func serialize_array_to_json(source_array: Array) -> Array:
	var serialized: Array = []
	for value in source_array:
		var type: int = typeof(value)
		var serialized_value: Variant = type_convert_to_json(value)
		serialized.append([type, serialized_value])
	return serialized


static func load_serialized_json_as_dictionary(serialized_data: Array) -> Dictionary:
	var dict: Dictionary = {}
	for item in serialized_data:
		var value: Variant = type_convert_from_json(item[2], item[1])
		var key = item[0]
		if item.size() > 3:
			key = type_convert_from_json(item[0], item[3])
		dict[key] = value
	return dict


static func load_serialized_json_as_array(serialized_data: Array) -> Array:
	var array: Array = []
	for item in serialized_data:
		var value: Variant = type_convert_from_json(item[1], item[0])
		array.append(value)
	return array


static func convert_any_data_string_to_value(any_data_str: String) -> Variant:
	if any_data_str == "<null>":
		return null
	elif any_data_str == "true":
		return true
	elif any_data_str == "false":
		return false
	elif any_data_str.is_valid_int():
		return any_data_str.to_int()
	elif any_data_str.is_valid_float():
		return any_data_str.to_float()
	return any_data_str


static func type_string_to_enum(type_string: String) -> int:
	match type_string:
		"ANY": return TYPE_NIL
		"BOOL": return TYPE_BOOL
		"INT": return TYPE_INT
		"FLOAT": return TYPE_FLOAT
		"STRING": return TYPE_STRING
		"VECTOR2": return TYPE_VECTOR2
		"VECTOR3": return TYPE_VECTOR3
		"COLOR": return TYPE_COLOR
		"OBJECT": return TYPE_OBJECT
		"DICTIONARY": return TYPE_DICTIONARY
		"ARRAY": return TYPE_ARRAY
	return -1


static func type_enum_to_string(type_enum: int) -> String:
	match type_enum:
		TYPE_NIL: return "ANY"
		TYPE_BOOL: return "BOOL"
		TYPE_INT: return "INT"
		TYPE_FLOAT: return "FLOAT"
		TYPE_STRING: return "STRING"
		TYPE_STRING_NAME: return "STRING"
		TYPE_VECTOR2: return "VECTOR2"
		TYPE_VECTOR3: return "VECTOR3"
		TYPE_COLOR: return "COLOR"
		TYPE_OBJECT: return "OBJECT"
		TYPE_DICTIONARY: return "DICTIONARY"
		TYPE_ARRAY: return "ARRAY"
	assert(false)
	return ""


## Uses the same names as the type names in GDScript.
## This isn't critical, so use Variant as a fallback, instead of assert false.
static func type_enum_to_friendly_string(type_enum: int) -> String:
	match type_enum:
		ScriptBlock.PortType.BOOL:
			return "bool"
		ScriptBlock.PortType.INT:
			return "int"
		ScriptBlock.PortType.FLOAT:
			return "float"
		ScriptBlock.PortType.STRING:
			return "String"
		ScriptBlock.PortType.VECTOR2:
			return "Vector2"
		ScriptBlock.PortType.VECTOR3:
			return "Vector3"
		ScriptBlock.PortType.COLOR:
			return "Color"
		ScriptBlock.PortType.OBJECT:
			return "Object"
		ScriptBlock.PortType.DICTIONARY:
			return "Dictionary"
		ScriptBlock.PortType.ARRAY:
			return "Array"
	return "Variant"
