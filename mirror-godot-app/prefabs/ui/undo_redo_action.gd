class_name UndoRedoAction extends RefCounted


## Bundle of property changes that can be undone and redone together, at the same time
## It is an array because we support multi-selection and multi-editing
## So most UndoRedoAction is a size 1 array of that single recorded property change


var _records: Array[UndoRedoRecord] = []


func add_new_record(object_node: Node3D, property_name: StringName, old_value, new_value) -> void:
	var new_record = UndoRedoRecord.new(object_node, property_name, old_value, new_value)
	add_record(new_record)

func add_record(record: UndoRedoRecord) -> void:
	_records.append(record)
	print_verbose("Current Undo Stack: %s" % _records)


## Returns an action over the same objects as this, but with all records inverted
func get_inverse_action() -> UndoRedoAction:
	var result: UndoRedoAction = UndoRedoAction.new()
	for record in _records:
		if not is_instance_valid(record.object_node):
			continue
		result.add_record(record.get_inverse_record())
	return result


func execute_undo_redo_action() -> Array:
	var modified_objects: Array = []
	for record in _records:
		var node = record.object_node
		if not is_instance_valid(node):
			# This is called when the node was deleted.
			continue
		if record.property_name == &"scale":
			if node is SpaceObject:
				node.set_model_scale(record.old_value)
			elif node.has_method(&"apply_scale"):
				node.apply_scale(record.old_value)
		elif record.property_name == &"model_offset":
			assert(node is SpaceObject)
			node.set_model_offset(record.old_value)
		else:
			node.set(record.property_name, record.old_value)
		if node.has_method(&"serialize_to_dictionary"):
			modified_objects.append(record.object_node.serialize_to_dictionary())
	return modified_objects


func print_summary() -> void:
	if _records.is_empty():
		print("UndoRedoAction is empty")
	else:
		print("Modified %s on %s objects" % [_records[0].property_name, str(_records.size())])


func _to_string() -> String:
	var text = ""
	for rec in _records:
		text += rec.to_string()
		text += ",\n"
	return text


class UndoRedoRecord extends RefCounted:
	var object_node: Node3D
	var property_name: StringName
	var old_value: Variant
	var new_value: Variant

	func _init(in_object_node: Node3D, in_property_name: StringName, in_old_value, in_new_value):
		object_node = in_object_node
		property_name = in_property_name
		old_value = in_old_value
		new_value = in_new_value


	func get_inverse_record() -> UndoRedoRecord:
		return UndoRedoRecord.new(object_node, property_name, new_value, old_value)

	func _to_string():
		return str(
			"%s, \"%s\", %s"
			 % [
			property_name,
			( object_node.space_object_name
				if is_instance_valid(object_node) and "space_object_name" in object_node
				else "Deleted Object" ),
			{
				old = old_value,
				new = new_value
			}
		])
