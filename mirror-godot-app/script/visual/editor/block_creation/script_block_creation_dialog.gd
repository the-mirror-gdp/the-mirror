extends KeyboardGrabbingConfirmationDialog


signal create_block(block_json: Dictionary)
signal request_reload_script_editor()
signal request_show_entry_creation_dialog()

const _GET_SPACE_OBJECT = preload("res://script/visual/blocks/space_object/get.gd")
const _UNSEQUENCED_METHOD = preload("res://script/visual/blocks/method/unsequenced_method.gd")

var _script_instance: ScriptInstance

@onready var _script_block_creation_menu: ScriptBlockCreationMenu = $ScriptBlockCreationMenu


func request_block_creation(constraint: int, data_type: int) -> void:
	popup_centered()
	_script_block_creation_menu.create_tree_items()
	_script_block_creation_menu.set_constraints(constraint, data_type)


func setup_for_script_instance(script_instance: ScriptInstance) -> void:
	_script_instance = script_instance
	_script_block_creation_menu.target_node = _script_instance.target_node


func create_block_from_data_drop(block_position: Vector2, data: Dictionary):
	var block_json: Dictionary
	var drag_type: String = data["drag_type"]
	if drag_type == "dragged_asset":
		if data["asset_type"] == "AUDIO":
			block_json = _script_block_creation_menu.get_registered_block_json("Play Audio Clip")
		else:
			block_json = _script_block_creation_menu.get_registered_block_json("Create Space Object (Async)")
	elif drag_type == "dragged_model_node":
		block_json = _script_block_creation_menu.get_registered_block_json("Get Model Node By Name")
	elif drag_type == "dragged_space_object":
		block_json = _script_block_creation_menu.get_registered_block_json("Get Space Object")
	elif drag_type == "dragged_global_variable":
		if Input.is_action_pressed(&"script_editor_modifier"):
			block_json = _script_block_creation_menu.get_registered_block_json("Set Global Variable")
		else:
			block_json = _script_block_creation_menu.get_registered_block_json("Get Global Variable")
	elif drag_type == "dragged_node_variable":
		if Input.is_action_pressed(&"script_editor_modifier"):
			block_json = _script_block_creation_menu.get_registered_block_json("Set Object Variable")
		else:
			block_json = _script_block_creation_menu.get_registered_block_json("Get Object Variable")
	var block_inputs: Array = block_json["inputs"]
	for block_input in block_inputs:
		if block_input[1] == ScriptBlock.PortType.STRING:
			block_input[2] = data["string_to_drop"]
			break
	block_json["position"] = Serialization.vector2_to_array(block_position)
	_create_and_connect_new_block_if_needed(block_json, block_position, data)


func _create_and_connect_new_block_if_needed(block_json: Dictionary, block_position: Vector2, data: Dictionary) -> void:
	var space_object_script_block: ScriptBlock
	if data.has("connect_to_space_object"):
		var space_object_node_name = data["connect_to_space_object"]
		if not (_script_instance.target_node is SpaceObject and _script_instance.target_node.name == space_object_node_name):
			for script_block in _script_instance.script_builder.all_blocks:
				if is_instance_of(script_block, _GET_SPACE_OBJECT):
					if script_block.inputs[0].value == space_object_node_name:
						space_object_script_block = script_block
						break
			if space_object_script_block == null:
				var space_object_block_json: Dictionary = _script_block_creation_menu.get_registered_block_json("Get Space Object")
				var input_port: Array = space_object_block_json["inputs"][0]
				input_port[2] = space_object_node_name
				create_block.emit(space_object_block_json)
				space_object_script_block = _script_instance.script_builder.all_blocks.back()
				space_object_script_block.graph_position = block_position + \
						Vector2(-1200.0 if data.has("connect_to_model_node") else -700.0, 0.0)
	var model_node_script_block: ScriptBlock
	if data.has("connect_to_model_node"):
		var model_node_name = data["connect_to_model_node"]
		for script_block in _script_instance.script_builder.all_blocks:
			if is_instance_of(script_block, _UNSEQUENCED_METHOD):
				if script_block.method_name == &"get_model_node_by_name":
					if script_block.inputs[1].value == model_node_name:
						if script_block.inputs[0].connected_block == space_object_script_block:
							model_node_script_block = script_block
							break
		if model_node_script_block == null:
			var model_block_json: Dictionary = _script_block_creation_menu.get_registered_block_json("Get Model Node By Name")
			var input_port: Array = model_block_json["inputs"][1]
			input_port[2] = model_node_name
			create_block.emit(model_block_json)
			model_node_script_block = _script_instance.script_builder.all_blocks.back()
			model_node_script_block.graph_position = block_position + Vector2(-500.0, 0.0)
			if space_object_script_block != null:
				model_node_script_block.inputs[0].connected_block = space_object_script_block
				model_node_script_block.inputs[0].connected_output = 0
	create_block.emit(block_json)
	var new_script_block = _script_instance.script_builder.all_blocks.back()
	if model_node_script_block != null:
		new_script_block.inputs[0].connected_block = model_node_script_block
		new_script_block.inputs[0].connected_output = 0
	elif space_object_script_block != null:
		new_script_block.inputs[0].connected_block = space_object_script_block
		new_script_block.inputs[0].connected_output = 0
	if data.has("value_to_set"):
		var value: Variant = data["value_to_set"]
		new_script_block.set_primary_port_type_and_value(value)
	_script_instance.script_data_contents_changed()
	request_reload_script_editor.emit()


func _on_confirmed():
	var desired_block_json: Dictionary = _script_block_creation_menu.get_desired_block_json()
	if desired_block_json.is_empty():
		return
	if desired_block_json["type"] == "entry" and desired_block_json["signal"] == &"custom_signal":
		request_show_entry_creation_dialog.emit()
		return
	create_block.emit(desired_block_json)
