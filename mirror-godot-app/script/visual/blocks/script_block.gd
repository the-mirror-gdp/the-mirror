# Important: The classes in this file should not know about any of our other classes!
class_name ScriptBlock
extends Object


## We can make up our own numbers for this, but we should keep it a
## superset of Godot's Variant type to allow using those values.
## * 000 to 099 are Godot's Variant type enum.
## * 100 to 199 are custom data types.
## * 200 to 255 are special non-data types.
enum PortType {
	ANY_DATA = TYPE_NIL,
	BOOL = TYPE_BOOL,
	INT = TYPE_INT,
	FLOAT = TYPE_FLOAT,
	STRING = TYPE_STRING,
	VECTOR2 = TYPE_VECTOR2,
	VECTOR3 = TYPE_VECTOR3,
	COLOR = TYPE_COLOR,
	OBJECT = TYPE_OBJECT,
	DICTIONARY = TYPE_DICTIONARY,
	ARRAY = TYPE_ARRAY,
	ASSET = 100, # Unused. Could later be a wrapper for String.
	SPACE_OBJECT = 101, # Unused. Could later be a wrapper for Object.
	SEQUENCE = 200,
	MATH = 201, # Placeholder for "math type" when creating a new block. Not a data type itself.
	CONNECTION = 202, # This port can connect to any data port, but does not contain data. It is only a connection.
}


# We define this class inside of script_block.gd to avoid GDScript circular reference bugs.
class ScriptBlockDataPort extends Object:
	var port_name: String = "Unnamed Port"
	var port_type: PortType = PortType.ANY_DATA
	var value: Variant

	func setup(port_data: Array) -> void:
		# A port with data: `["test", ANY_DATA, "Default Value"]`
		# Is like this GDScript: `var test: Variant = "Default Value"`
		if port_data.size() > 0:
			port_name = port_data[0]
		if port_data.size() > 1:
			port_type = port_data[1]
		if port_data.size() > 2:
			value = Serialization.type_convert_from_json(port_data[2], port_type)

	func serialize() -> Array:
		var serialized: Variant = Serialization.type_convert_to_json(value)
		if port_type == PortType.ANY_DATA and typeof(serialized) == TYPE_ARRAY:
			# Special case: If the port's type is "any data" and the serialized
			# value has an ambiguous type, we cannot save that value inside
			# of the port, otherwise we can end up with an infinite loop
			# of arrays trying to serialize themselves as arrays.
			serialized = null
		return [port_name, port_type, serialized]

	func duplicate() -> ScriptBlockDataPort:
		var ret = ScriptBlockDataPort.new()
		ret.port_name = port_name
		ret.port_type = port_type
		ret.value = value
		return ret

	## Use this method when you want the value to be automatically changed.
	func set_port_type(new_port_type: PortType) -> void:
		port_type = new_port_type
		if port_type == ScriptBlock.PortType.ANY_DATA:
			value = ""
		else:
			value = type_convert("", port_type)


class ScriptBlockInputPort extends ScriptBlockDataPort:
	var connected_block: ScriptBlock
	var connected_output: int = -1

	func duplicate() -> ScriptBlockDataPort:
		var ret = ScriptBlockInputPort.new()
		ret.port_name = port_name
		ret.port_type = port_type
		ret.value = value
		ret.connected_block = connected_block
		ret.connected_output = connected_output
		return ret


signal log_error(error_text: String)

var evaluated: bool = false
var inputs: Array[ScriptBlockInputPort] = []
var outputs: Array[ScriptBlockDataPort] = []

# Used by the script editor.
var graph_position := Vector2.ZERO
var graph_name: String = "<Error>"
var graph_node: GraphNode


func setup(block_json: Dictionary) -> void:
	_setup_base(block_json)


func _setup_base(block_json: Dictionary) -> void:
	if block_json.has("inputs"):
		_setup_inputs(block_json["inputs"])
	if block_json.has("outputs"):
		_setup_outputs(block_json["outputs"])
	if block_json.has("position"):
		graph_position = Serialization.array_to_vector2(block_json["position"])
	if block_json.has("name"):
		graph_name = block_json["name"]
	elif block_json.has("signal"):
		graph_name = "On " + String(block_json["signal"]).capitalize()
	else:
		graph_name = String(block_json["type"]).capitalize()


func _setup_inputs(input_data: Array) -> void:
	for port_data in input_data:
		if port_data is Array:
			_setup_new_input(port_data)


func _setup_new_input(port_data: Array) -> void:
	var input_port = ScriptBlockInputPort.new()
	input_port.setup(port_data)
	inputs.append(input_port)


func _setup_outputs(output_data: Array) -> void:
	for port_data in output_data:
		if port_data is Array:
			_setup_new_output(port_data)


func _setup_new_output(port_data: Array) -> void:
	var output_port = ScriptBlockDataPort.new()
	output_port.setup(port_data)
	outputs.append(output_port)


func evaluate() -> void:
	evaluate_inputs()
	# Children should override this method if they need to add functionality.


func evaluate_inputs() -> void:
	# Technically, this is the start of the evaluation process, but we are
	# setting this to true in anticipation of the block evaluation being
	# completed shortly. Setting here also helps prevent infinite loops.
	evaluated = true
	for i in range(inputs.size()):
		var input: ScriptBlockInputPort = inputs[i]
		var block: ScriptBlock = input.connected_block
		if not is_instance_valid(block):
			continue
		if not block.evaluated:
			block.evaluate()
		if input.connected_output >= block.outputs.size():
			printerr("This input was connected to an invalid output! This should not happen, and means there is a bug somewhere else.")
			input.connected_block = null
			input.connected_output = -1
			continue
		var output_value = block.outputs[input.connected_output].value
		if input.port_type == ScriptBlock.PortType.ANY_DATA:
			input.value = output_value
		else:
			input.value = type_convert(output_value, input.port_type)


func get_script_block_type() -> String:
	return "broken"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if graph_node != null:
		assert(is_instance_valid(graph_node), "If it's non-null, it should be valid. ScriptBlockGraphNode should set this to null when cleaning itself up for deletion.")
		graph_position = graph_node.position_offset
	ret["position"] = Serialization.vector2_to_array(graph_position)
	ret["name"] = graph_name
	ret["type"] = get_script_block_type()
	if inputs.size() > 0:
		var json: Array[Array] = []
		for input in inputs:
			json.append(input.serialize())
		ret["inputs"] = json
	if outputs.size() > 0:
		var json: Array[Array] = []
		for output in outputs:
			json.append(output.serialize())
		ret["outputs"] = json
	return ret


func cleanup_script_block_for_deletion() -> void:
	for input in inputs:
		input.free()
	for output in outputs:
		output.free()
