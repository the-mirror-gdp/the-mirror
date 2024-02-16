## Dumps the visual scripting API to Markdown tables.
extends Node


const GODOT_DOCS_CLASS_URL: String = "https://docs.godotengine.org/en/stable/classes/class_"
const PROPERTY_TABLE_HEADER: PackedStringArray = ["Property Name", "Data Type", "Default Value", "Valid Values"]
const INPUT_TABLE_HEADER: PackedStringArray = ["Input Name", "Data Type", "Default Value"]
const OUTPUT_TABLE_HEADER: PackedStringArray = ["Output Name", "Data Type"]

const PAGE_HEADER: String = """---
sidebar_position: 3.9
note: This page is auto-generated from the script API, do not manually edit it. See res://addons/mirror_internal/script_api_dumper/script_api_dumper.gd in the Godot app.
---

# API Reference

This page contains a reference of the entire visual scripting API available to you in The Mirror.
"""

const SIGNAL_SECTION_HEADER: String = """
## Entry Signals

These signals can be used as entry points for your script (the first run blocks that are executed). Some come from SpaceObject, some come from subnodes, and some are global signals. Global scripts may only use global signals. Object scripts may use all signals.
"""

const BLOCK_SECTION_HEADER: String = """
## Script Blocks

Regular script blocks. These allow you to perform actions (run blocks) or gather information (data blocks).
"""

const PROPERTY_SECTION_HEADER: String = """
## Properties

Properties all share a similar API. Properties can be get, set, and sometimes tweened, added to, and multiplied. If properties are set on the server, they will be synced to clients.
"""


func _ready() -> void:
	var signals: Dictionary = ScriptSignalRegistration.get_mirror_registered_signals().duplicate(true)
	var meta_signals: Dictionary = ScriptSignalRegistration.get_mirror_registered_meta_signals()
	var script_blocks: Array[Dictionary] = VisualScriptBlockRegistration.get_api_dump_registered_script_blocks()
	var properties: Dictionary = ScriptPropertyRegistration.get_registered_properties()
	# Clean up the data.
	var spaceobj_signals: Array = signals["SpaceObject"]
	for signal_signature in spaceobj_signals:
		if signal_signature["signal"] == &"custom_signal":
			spaceobj_signals.erase(signal_signature)
			break
	signals.erase("Physics") # Redundant, we already document player_interact in other places.
	for block_signature in script_blocks:
		if block_signature["type"] == "entry":
			script_blocks.erase(block_signature)
			break
	# Convert to Markdown tables.
	var page: String = PAGE_HEADER
	page += SIGNAL_SECTION_HEADER
	page += all_signal_classes_to_markdown(signals)
	page += all_signal_classes_to_markdown(meta_signals)
	page += BLOCK_SECTION_HEADER
	page += all_script_blocks_to_markdown(script_blocks)
	page += PROPERTY_SECTION_HEADER
	page += all_properties_to_markdown(properties)
	var file := FileAccess.open("res://addons/mirror_internal/script_api_dumper/api_reference.mdx", FileAccess.WRITE)
	file.store_string(page)
	file.close()
	get_tree().quit()


static func all_signal_classes_to_markdown(signals: Dictionary) -> String:
	var ret: String = ""
	for signal_category in signals:
		ret += "\n### " + signal_category + "\n\n"
		ret += ScriptSignalRegistration.get_category_description(signal_category) + "\n"
		var signals_for_cat: Array = signals[signal_category]
		for signal_for_cat in signals_for_cat:
			ret += signal_to_markdown(signal_category, signal_for_cat)
	return ret


static func signal_to_markdown(signal_class: String, signal_for_class: Dictionary) -> String:
	var ret: String = "\n#### On "
	if not signal_for_class.has("path"):
		if signal_class.begins_with("OMI"):
			ret += signal_class
		else:
			ret += signal_class.capitalize()
		ret += " "
	ret += String(signal_for_class["signal"]).capitalize() + "\n"
	if signal_for_class.has("description"):
		ret += "\n" + signal_for_class["description"]
		if signal_for_class.get("path", "").begins_with("/root"):
			ret += " This is a global signal, it can be used from any script."
		ret += "\n"
	var parameters: Dictionary = signal_for_class.get("signalParameters", {})
	parameters.merge(signal_for_class.get("inspectorParameters", {}))
	var rows: Array[PackedStringArray] = []
	for param_name in parameters:
		var type_enum: int = parameters[param_name][0]
		rows.append(script_output_port_to_friendly_strings(param_name, type_enum))
	if not rows.is_empty():
		ret += generate_markdown_table(OUTPUT_TABLE_HEADER, rows)
	return ret


static func all_script_blocks_to_markdown(script_blocks: Array[Dictionary]) -> String:
	var blocks_by_category: Dictionary = {}
	for block in script_blocks:
		var category_name: String = block.get("category", "Misc")
		var category_blocks: Array = blocks_by_category.get_or_set_default(category_name, [])
		category_blocks.append(block)
	var ret: String = ""
	for category_name in blocks_by_category:
		ret += "\n### " + category_name + "\n\n"
		ret += VisualScriptBlockRegistration.get_category_description(category_name) + "\n"
		for block_in_category in blocks_by_category[category_name]:
			var block_name: String = block_in_category["name"]
			ret += script_block_to_markdown(block_name, block_in_category)
	return ret


static func script_block_to_markdown(block_name: String, block_signature: Dictionary) -> String:
	var ret: String = "\n#### " + block_name + "\n"
	assert(block_signature.has("description"))
	if block_signature.has("description"):
		ret += "\n" + block_signature["description"] + "\n"
	ret += inputs_and_outputs_to_markdown(block_signature)
	return ret


static func script_struct_method_to_markdown(block_name: String, block_signature: Dictionary) -> String:
	var ret: String = "### " + block_name.capitalize()
	assert(block_signature.has("description"))
	if block_signature.has("description"):
		ret += "\n" + block_signature["description"]
		if block_signature.get("typed_output_name", "") == "Pass":
			ret += " The input data is passed through unchanged for convenience."
	ret += " This block is available for the "
	var struct_types: Array = block_signature["struct_types"]
	for i in range(struct_types.size()):
		var struct_type: int = struct_types[i]
		ret += type_enum_to_godot_docs_markdown(struct_type)
		if i < struct_types.size() - 2:
			ret += ", "
		elif i == struct_types.size() - 2:
			ret += ", and "
		elif i == struct_types.size() - 1:
			ret += " data type"
			ret += "s.\n" if struct_types.size() > 1 else ".\n"
	ret += inputs_and_outputs_to_markdown(block_signature)
	return ret


static func inputs_and_outputs_to_markdown(block_signature: Dictionary) -> String:
	var ret: String = ""
	if block_signature.has("inputs"):
		var rows: Array[PackedStringArray] = []
		var inputs: Array = block_signature["inputs"]
		for input in inputs:
			rows.append(script_input_port_to_friendly_strings(input[0], input[1], input[2]))
		ret += generate_markdown_table(INPUT_TABLE_HEADER, rows)
	if block_signature.has("outputs"):
		var rows: Array[PackedStringArray] = []
		var outputs: Array = block_signature["outputs"]
		for output in outputs:
			rows.append(script_output_port_to_friendly_strings(output[0], output[1]))
		ret += generate_markdown_table(OUTPUT_TABLE_HEADER, rows)
	return ret


static func all_properties_to_markdown(properties: Dictionary) -> String:
	var rows: Array[PackedStringArray] = []
	for property_name in properties:
		var property_signature: Dictionary = properties[property_name]
		if property_signature.has("hidden"):
			continue
		rows.append(property_to_markdown(property_name, property_signature))
	return generate_markdown_table(PROPERTY_TABLE_HEADER, rows)


static func property_to_markdown(property_name: String, property_signature: Dictionary) -> PackedStringArray:
	var data_type: int = property_signature["data_type"]
	var default_value: Variant = property_signature.get("default_value", type_convert("", data_type))
	var port_type: String = type_enum_to_godot_docs_markdown(data_type)
	var valid_values: String = ""
	if property_signature.has("valid_values"):
		valid_values = property_signature["valid_values"]
	elif property_signature.has("enum_values"):
		valid_values = '"' + ('", "'.join(PackedStringArray(property_signature["enum_values"]))) + '"'
	return [property_name.capitalize(), port_type, value_to_friendly_string(default_value), valid_values]


static func script_input_port_to_friendly_strings(port_name: String, port_type_enum: int, default: Variant) -> PackedStringArray:
	var port_type: String = type_enum_to_godot_docs_markdown(port_type_enum)
	return [port_name, port_type, value_to_friendly_string(default)]


static func script_output_port_to_friendly_strings(port_name: String, port_type_enum: int) -> PackedStringArray:
	var port_type: String = type_enum_to_godot_docs_markdown(port_type_enum)
	return [port_name, port_type]


static func generate_markdown_table(header: PackedStringArray, rows: Array[PackedStringArray]) -> String:
	var lengths := PackedInt32Array()
	for i in range(header.size()):
		var length: int = header[i].length()
		for row in rows:
			length = maxi(row[i].length(), length)
		lengths.append(length)
	var ret: String = "\n" + generate_markdown_row(header, lengths)
	ret += generate_markdown_header_separator(lengths)
	for row in rows:
		ret += generate_markdown_row(row, lengths)
	return ret


static func generate_markdown_row(row: PackedStringArray, lengths: PackedInt32Array) -> String:
	var ret: String = "|"
	for i in range(row.size()):
		ret += " " + row[i].rpad(lengths[i]) + " |"
	return ret + "\n"


static func generate_markdown_header_separator(lengths: PackedInt32Array) -> String:
	var ret: String = "|"
	for length in lengths:
		ret += " " + "-".repeat(length) + " |"
	return ret + "\n"


static func type_enum_to_godot_docs_markdown(type_enum: int) -> String:
	if type_enum == ScriptBlock.PortType.MATH:
		return "Math"
	if type_enum == ScriptBlock.PortType.CONNECTION:
		return "Connection (special)"
	assert(type_enum < 100, "Only Godot types should link to the Godot docs.")
	var type_string: String = Serialization.type_enum_to_friendly_string(type_enum)
	var url: String = GODOT_DOCS_CLASS_URL + type_string.to_lower() + ".html"
	return "[" + type_string + "](" + url + ")"


static func value_to_friendly_string(value: Variant) -> String:
	if typeof(value) == TYPE_NIL or typeof(value) == TYPE_OBJECT:
		return "null"
	if typeof(value) == TYPE_STRING:
		return '"' + value + '"'
	if typeof(value) == TYPE_FLOAT:
		if value == int(value):
			return str(value) + ".0"
	if typeof(value) == TYPE_DICTIONARY:
		return "{ }"
	return type_convert(value, TYPE_STRING)
