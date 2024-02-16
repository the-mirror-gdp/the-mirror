extends VBoxContainer


# Keep this in sync with the options in the node type selection button.
enum NodeSelectionOptions {
	TRIGGER_SHAPE = 0,
	PHYSICS_SHAPE = 1,
	SEAT = 2,
	SPAWN_POINT = 3,
}

var _target_object: SpaceObject

@onready var _parent_node_name: LineEdit = $ParentNodeName/ParentNodeName
@onready var _type_selection_button: OptionButton = $TypeSelection/NodeTypeSelectionButton
@onready var _new_node_name: LineEdit = $NewNodeName/NewNodeName


func populate_for_target(target_space_object: SpaceObject, parent_name: StringName) -> void:
	_target_object = target_space_object
	_parent_node_name.text = parent_name
	_new_node_name.text = ""


## Returns true if a node was created, false if nothing was created.
func perform_desired_node_creation() -> bool:
	var parent: Node = _target_object.get_model_node_by_name(StringName(_parent_node_name.text))
	if not _check_parent_and_name(parent):
		return false
	var extra_node_json: Dictionary = _create_node_json_as_dict()
	_set_node_json_transform(extra_node_json, parent)
	# Add the new extra node data to the SpaceObject.
	_target_object.add_extra_node(extra_node_json)
	return true


func _create_node_json_as_dict() -> Dictionary:
	var extensions = {}
	# See the type button's items for possible values and what they represent.
	# Hard-coding numbers is a bit unfortunate, but it's the easiest way to do this.
	var type: int = _type_selection_button.selected
	if type == NodeSelectionOptions.SPAWN_POINT:
		extensions["OMI_spawn_point"] = {
			"team": "",
		}
	else:
		var is_trigger: bool = type != NodeSelectionOptions.PHYSICS_SHAPE
		extensions["OMI_physics_shape"] = {
			"isTrigger": is_trigger,
			"type": "box",
		}
		if type == NodeSelectionOptions.SEAT:
			extensions["OMI_seat"] = {
				"back": [0.0, 0.0, -0.3],
				"foot": [0.0, -0.5, 0.3],
				"knee": [0.0, 0.0, 0.3],
			}
	return {
		"parent": _parent_node_name.text,
		"name": _new_node_name.text,
		"extensions": extensions,
	}


func _check_parent_and_name(parent: Node) -> bool:
	# Get the parent node and ensure it is valid.
	if _parent_node_name.text.is_empty():
		Notify.error("Cannot Create Node", "Parent is empty.")
		return false
	if not parent:
		Notify.error("Cannot Create Node", "Parent is invalid.")
		return false
	# Ensure the desired name is valid.
	if _new_node_name.text.is_empty():
		Notify.error("Cannot Create Node", "Node name is empty.")
		return false
	var existing: Node = _target_object.get_model_node_by_name(StringName(_new_node_name.text))
	if existing:
		Notify.error("Cannot Create Node", "Node name is not unique.")
		return false
	return true


func _set_node_json_transform(extra_node_json: Dictionary, parent: Node) -> void:
	# Calculate the inverse transform of the parent relative to the SpaceObject.
	var relative_basis: Basis = TMNodeUtil.get_relative_transform(_target_object, parent).basis
	var inverted_basis: Basis = relative_basis.inverse()
	# Set the rotation and scale to the inverse transform to prevent
	# the parent's potentially weird transform from affecting the node.
	var inv_quat: Quaternion = inverted_basis.get_rotation_quaternion()
	extra_node_json["rotation"] = [inv_quat.x, inv_quat.y, inv_quat.z, inv_quat.w]
	extra_node_json["scale"] = Serialization.vector3_to_array(inverted_basis.get_scale())
	# Set the translation to be half a meter up as an arbitrary friendly
	# default to try and avoid the node being inside the object center.
	var pos: Vector3 = inverted_basis * Vector3(0.0, 0.5, 0.0)
	extra_node_json["translation"] = Serialization.vector3_to_array(pos)


func _on_parent_node_name_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	var parent: Node = _target_object.get_model_node_by_name(StringName(new_text))
	if parent:
		_parent_node_name.add_theme_color_override(&"font_color", Color.WHITE)
	else:
		_parent_node_name.add_theme_color_override(&"font_color", Color.RED)


func _on_new_node_name_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	var existing: Node = _target_object.get_model_node_by_name(StringName(new_text))
	if existing:
		_new_node_name.add_theme_color_override(&"font_color", Color.RED)
	else:
		_new_node_name.add_theme_color_override(&"font_color", Color.WHITE)
