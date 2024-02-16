## Builds a script by creating blocks and connecting them together.
## The heavy lifting is done by the blocks themselves. This class also
## handles block deletion, JSON serialization, and evaluation resetting.
## Only blocks that affect execution are handled here (no comments).
class_name VisualScriptBuilder
extends Object


signal block_message(script_block: ScriptBlock, title: String, message: String, notify_type: Enums.NotifyStatus)
# Emitting this signal will send a network update.
signal contents_changed()
# Emitted when everything is deleted, but not emitted when
# the script was already empty (no deletion happened).
signal contents_deleted()

# The only reason Builder stores this is to give it to blocks that need it.
var attached_object: Object
var all_blocks: Array[ScriptBlock] = []
# Since it's common to need to access these externally, we track them separately.
var entry_blocks: Array[ScriptBlockEntryBase] = []


func _init(attached: Object) -> void:
	attached_object = attached


## Used before execution to reset the evaluation state of all blocks.
func reset_all_blocks_evaluation_state() -> void:
	for block in all_blocks:
		block.evaluated = false


## Used during execution if a sequenced/run block changes the state, and needs
## to inform the unsequenced/data blocks that they need to re-evaluate.
func reset_unsequenced_blocks_evaluation_state() -> void:
	for block in all_blocks:
		if not block is ScriptBlockSequenced:
			block.evaluated = false


## Creation/construction methods.
func create_blocks(script_json_array: Array) -> void:
	assert(all_blocks.is_empty())
	for item in script_json_array:
		create_block(item)
	for i in script_json_array.size():
		var block: ScriptBlock = all_blocks[i]
		var json: Dictionary = script_json_array[i]
		if block is ScriptBlockSequenced:
			_setup_block_flow_connections(block, json, all_blocks)
		_setup_block_input_connections(block, json, all_blocks)


func append_more_blocks(block_json_array: Array) -> Array[ScriptBlock]:
	var new_blocks: Array[ScriptBlock] = []
	for item in block_json_array:
		var block_instance = null
		if item is Dictionary and item.has("type"):
			if item["type"] != "entry": # Disallow pasting entries for safety reasons.
				block_instance = create_block(item)
		# If the item was not valid, still append null. We must not break the indices.
		new_blocks.append(block_instance)
	for i in block_json_array.size():
		var block: ScriptBlock = new_blocks[i]
		if block == null:
			continue
		var json: Dictionary = block_json_array[i]
		if block is ScriptBlockSequenced:
			_setup_block_flow_connections(block, json, new_blocks)
		_setup_block_input_connections(block, json, new_blocks)
	return new_blocks


func create_block(block_json: Dictionary) -> ScriptBlock:
	var block: ScriptBlock = _instantiate_block_class(block_json)
	if &"attached_object" in block:
		block.attached_object = attached_object
	if &"script_builder" in block:
		block.script_builder = self
	if &"scene_tree" in block:
		# We just need a reference to the SceneTree, get it from any AutoLoad.
		block.scene_tree = Notify.get_tree()
	block.setup(block_json)
	block.log_error.connect(_on_block_log_error.bind(block))
	if block.has_signal(&"print_notify"):
		block.print_notify.connect(_on_block_print_notify.bind(block))
	if block is ScriptBlockSequenced:
		block.request_reset_unsequenced_blocks_evaluation_state.connect(reset_unsequenced_blocks_evaluation_state)
	if block.get_script_block_type() == "broken":
		if not block.graph_name.ends_with("(Broken)"):
			block.graph_name += " (Broken)"
	all_blocks.append(block)
	return block


func _instantiate_block_class(block_json: Dictionary) -> ScriptBlock:
	var block_type: String = str(block_json.get("type"))
	match block_type:
		# Misc high priority
		"entry":
			var block: ScriptBlockEntryBase = _instantiate_entry_class(block_json)
			entry_blocks.append(block)
			return block
		"print_chat": return preload("res://script/visual/blocks/misc/print_chat.gd").new()
		"print_notify": return preload("res://script/visual/blocks/misc/print_notify.gd").new()
		"print": return preload("res://script/visual/blocks/misc/print_notify.gd").new() # Compatibility, remove in the future.
		# Signals
		"emit_signal": return preload("res://script/visual/blocks/signal/emit_signal.gd").new()
		"run_event": return preload("res://script/visual/blocks/signal/emit_signal.gd").new() # Compatibility, remove in a few months.
		# Methods
		"sequenced_method": return preload("res://script/visual/blocks/method/sequenced_method.gd").new()
		"unsequenced_method": return preload("res://script/visual/blocks/method/unsequenced_method.gd").new()
		"sequenced_struct_method": return preload("res://script/visual/blocks/struct/sequenced_struct_method.gd").new()
		"unsequenced_struct_method": return preload("res://script/visual/blocks/struct/unsequenced_struct_method.gd").new()
		# Properties
		"get_property": return preload("res://script/visual/blocks/property/get_property.gd").new()
		"set_property": return preload("res://script/visual/blocks/property/set_property.gd").new()
		"add_property": return preload("res://script/visual/blocks/property/add_property.gd").new()
		"multiply_property": return preload("res://script/visual/blocks/property/multiply_property.gd").new()
		"tween_property": return preload("res://script/visual/blocks/property/tween_property.gd").new()
		# Flow
		"branch": return preload("res://script/visual/blocks/flow/branch.gd").new()
		"if": return preload("res://script/visual/blocks/flow/if.gd").new()
		"if_equals": return preload("res://script/visual/blocks/flow/if_equals.gd").new()
		"loop": return preload("res://script/visual/blocks/flow/loop.gd").new()
		"while": return preload("res://script/visual/blocks/flow/while.gd").new()
		"match_flow": return preload("res://script/visual/blocks/flow/match_flow.gd").new()
		"wait": return preload("res://script/visual/blocks/flow/wait.gd").new()
		# Logic
		"if_value": return preload("res://script/visual/blocks/logic/if_value.gd").new()
		"match_value": return preload("res://script/visual/blocks/logic/match_value.gd").new()
		"and": return preload("res://script/visual/blocks/logic/and.gd").new()
		"equals": return preload("res://script/visual/blocks/logic/equals.gd").new()
		"greater": return preload("res://script/visual/blocks/logic/greater_than.gd").new()
		"less": return preload("res://script/visual/blocks/logic/less_than.gd").new()
		"not": return preload("res://script/visual/blocks/logic/not.gd").new()
		"or": return preload("res://script/visual/blocks/logic/or.gd").new()
		# Math
		"add": return preload("res://script/visual/blocks/math/add.gd").new()
		"clamp": return preload("res://script/visual/blocks/math/clamp.gd").new()
		"constant_math_expression": return preload("res://script/visual/blocks/math/constant_expression.gd").new()
		"divide": return preload("res://script/visual/blocks/math/divide.gd").new()
		"modulus": return preload("res://script/visual/blocks/math/modulus.gd").new()
		"multiply": return preload("res://script/visual/blocks/math/multiply.gd").new()
		"subtract": return preload("res://script/visual/blocks/math/subtract.gd").new()
		"random_number": return preload("res://script/visual/blocks/math/random_number.gd").new()
		"looking_at": return preload("res://script/visual/blocks/math/looking_at.gd").new()
		# Time
		"get_unix_time_utc": return preload("res://script/visual/blocks/time/get_unix_time_utc.gd").new()
		"datetime_string_to_unix_time": return preload("res://script/visual/blocks/time/datetime_string_to_unix_time.gd").new()
		"datetime_values_to_unix_time": return preload("res://script/visual/blocks/time/datetime_values_to_unix_time.gd").new()
		"unix_time_to_datetime_string": return preload("res://script/visual/blocks/time/unix_time_to_datetime_string.gd").new()
		"unix_time_to_datetime_values": return preload("res://script/visual/blocks/time/unix_time_to_datetime_values.gd").new()
		# String
		"string_equals_case_insensitive": return preload("res://script/visual/blocks/string/equals_insensitive.gd").new()
		"concatenate_string": return preload("res://script/visual/blocks/string/concat.gd").new()
		"join_string": return preload("res://script/visual/blocks/string/join.gd").new()
		"to_string": return preload("res://script/visual/blocks/string/to_string.gd").new()
		"to_json": return preload("res://script/visual/blocks/string/to_json.gd").new()
		"format_string_array": return preload("res://script/visual/blocks/string/format_string_array.gd").new()
		"format_string": return preload("res://script/visual/blocks/string/format_string.gd").new()
		"get_json_key": return preload("res://script/visual/blocks/string/get_json_key.gd").new()
		"json_merge": return preload("res://script/visual/blocks/string/json_merge.gd").new()
		# Color
		"color_construct": return preload("res://script/visual/blocks/color/color_construct.gd").new()
		"color_from_hsv": return preload("res://script/visual/blocks/color/color_from_hsv.gd").new()
		"color_from_string": return preload("res://script/visual/blocks/color/color_from_string.gd").new()
		"color_split": return preload("res://script/visual/blocks/color/color_split.gd").new()
		# Vector
		"vector2_construct": return preload("res://script/visual/blocks/vector/vector2_construct.gd").new()
		"vector2_from_angle": return preload("res://script/visual/blocks/vector/vector2_from_angle.gd").new()
		"vector2_split": return preload("res://script/visual/blocks/vector/vector2_split.gd").new()
		"vector3_construct": return preload("res://script/visual/blocks/vector/vector3_construct.gd").new()
		"vector3_split": return preload("res://script/visual/blocks/vector/vector3_split.gd").new()
		# Array
		"array_construct": return preload("res://script/visual/blocks/array/array_construct.gd").new()
		"array_get": return preload("res://script/visual/blocks/array/array_get.gd").new()
		"array_set": return preload("res://script/visual/blocks/array/array_set.gd").new()
		"array_contains": return preload("res://script/visual/blocks/array/array_contains.gd").new()
		"array_for_each": return preload("res://script/visual/blocks/array/array_for_each.gd").new()
		"array_pick_random": return preload("res://script/visual/blocks/array/array_pick_random.gd").new()
		# Dictionary
		"dictionary_construct": return preload("res://script/visual/blocks/dictionary/dictionary_construct.gd").new()
		"dictionary_get": return preload("res://script/visual/blocks/dictionary/dictionary_get.gd").new()
		"dictionary_set": return preload("res://script/visual/blocks/dictionary/dictionary_set.gd").new()
		"dictionary_for_each": return preload("res://script/visual/blocks/dictionary/dictionary_for_each.gd").new()
		"dictionary_pick_random": return preload("res://script/visual/blocks/dictionary/dictionary_pick_random.gd").new()
		# SpaceObject instance
		"self": return preload("res://script/visual/blocks/space_object/self.gd").new()
		"create_space_object": return preload("res://script/visual/blocks/space_object/create.gd").new()
		"delete_space_object": return preload("res://script/visual/blocks/space_object/delete.gd").new()
		"get_space_object": return preload("res://script/visual/blocks/space_object/get.gd").new()
		"is_other_space_object": return preload("res://script/visual/blocks/space_object/is_other.gd").new()
		"bbcode_to_texture": return preload("res://script/visual/blocks/space_object/bbcode_to_texture.gd").new()
		"scroll_texture": return preload("res://script/visual/blocks/space_object/scroll_texture.gd").new()
		"npc_move_to": return preload("res://script/visual/blocks/space_object/npc_move_to.gd").new()
		"damage_using_capsule": return preload("res://script/visual/blocks/space_object/damage_using_capsule.gd").new()
		"is_dead": return preload("res://script/visual/blocks/space_object/is_dead.gd").new()
		# Player
		"get_all_players": return preload("res://script/visual/blocks/player/get_all_players.gd").new()
		"get_players_on_team": return preload("res://script/visual/blocks/player/get_players_on_team.gd").new()
		"get_local_player": return preload("res://script/visual/blocks/player/get_local.gd").new()
		"get_player_by_id": return preload("res://script/visual/blocks/player/get_player_by_id.gd").new()
		"get_player_in_range": return preload("res://script/visual/blocks/player/get_player_in_range.gd").new()
		"get_player_role_for_space": return preload("res://script/visual/blocks/player/get_player_role_for_space.gd").new()
		"get_player_inventory": return preload("res://script/visual/blocks/player/get_inventory.gd").new()
		"get_player_head": return preload("res://script/visual/blocks/player/get_head.gd").new()
		"get_player_height": return preload("res://script/visual/blocks/player/get_height.gd").new()
		"set_player_height": return preload("res://script/visual/blocks/player/set_height.gd").new()
		"set_player_avatar": return preload("res://script/visual/blocks/player/set_avatar.gd").new()
		"tween_player_height": return preload("res://script/visual/blocks/player/tween_height.gd").new()
		"is_valid_player": return preload("res://script/visual/blocks/player/is_valid.gd").new()
		"user_profile_request": return preload("res://script/visual/blocks/player/user_profile_request.gd").new()
		# Animation
		"play_animation": return preload("res://script/visual/blocks/animation/play.gd").new()
		"is_animation_playing": return preload("res://script/visual/blocks/animation/is_playing.gd").new()
		"get_animation_speed": return preload("res://script/visual/blocks/animation/get_speed.gd").new()
		# Audio
		"play_audio_clip": return preload("res://script/visual/blocks/audio/play_clip.gd").new()
		"play_audio_node_custom": return preload("res://script/visual/blocks/audio/play_node_custom.gd").new()
		"play_audio_node_same": return preload("res://script/visual/blocks/audio/play_node_same.gd").new()
		"is_audio_node_playing": return preload("res://script/visual/blocks/audio/is_node_playing.gd").new()
		"stop_audio_node": return preload("res://script/visual/blocks/audio/stop_node.gd").new()
		"audio_input_detect": return preload("res://script/visual/blocks/audio/audio_input_detect.gd").new()
		# Physics
		"apply_force_impulse": return preload("res://script/visual/blocks/physics/apply_force_impulse.gd").new()
		"apply_force_over_time": return preload("res://script/visual/blocks/physics/apply_force_over_time.gd").new()
		"move_and_collide": return preload("res://script/visual/blocks/physics/move_and_collide.gd").new()
		"get_physics_material_properties": return preload("res://script/visual/blocks/physics/get_material.gd").new()
		"set_physics_material_properties": return preload("res://script/visual/blocks/physics/set_material.gd").new()
		"physics_raycast": return preload("res://script/visual/blocks/physics/raycast.gd").new()
		# Environment
		"get_environment_sun": return preload("res://script/visual/blocks/environment/get_sun.gd").new()
		"set_environment_fog": return preload("res://script/visual/blocks/environment/set_fog.gd").new()
		"set_environment_properties": return preload("res://script/visual/blocks/environment/set_properties.gd").new()
		"set_environment_sky_color": return preload("res://script/visual/blocks/environment/set_sky_color.gd").new()
		# Variables
		"get_global_variable": return preload("res://script/visual/blocks/variable/global_get.gd").new()
		"has_global_variable": return preload("res://script/visual/blocks/variable/global_has.gd").new()
		"set_global_variable": return preload("res://script/visual/blocks/variable/global_set.gd").new()
		"tween_global_variable": return preload("res://script/visual/blocks/variable/global_tween.gd").new()
		"get_object_variable": return preload("res://script/visual/blocks/variable/object_get.gd").new()
		"has_object_variable": return preload("res://script/visual/blocks/variable/object_has.gd").new()
		"set_object_variable": return preload("res://script/visual/blocks/variable/object_set.gd").new()
		"tween_object_variable": return preload("res://script/visual/blocks/variable/object_tween.gd").new()
		# Match
		"match_start": return preload("res://script/visual/blocks/match/match_start.gd").new()
		"match_end": return preload("res://script/visual/blocks/match/match_end.gd").new()
		"match_terminate": return preload("res://script/visual/blocks/match/match_terminate.gd").new()
		"is_match_running": return preload("res://script/visual/blocks/match/is_match_running.gd").new()
		"round_start": return preload("res://script/visual/blocks/match/round_start.gd").new()
		"round_end": return preload("res://script/visual/blocks/match/round_end.gd").new()
		"round_terminate": return preload("res://script/visual/blocks/match/round_terminate.gd").new()
		"is_round_running": return preload("res://script/visual/blocks/match/is_round_running.gd").new()
		"set_match_settings": return preload("res://script/visual/blocks/match/set_match_settings.gd").new()
		"set_win_conditions": return preload("res://script/visual/blocks/match/set_win_conditions.gd").new()
		"add_score_to_team": return preload("res://script/visual/blocks/match/add_score_to_team.gd").new()
		"get_score_for_team": return preload("res://script/visual/blocks/match/get_score_for_team.gd").new()
		"set_score_for_team": return preload("res://script/visual/blocks/match/set_score_for_team.gd").new()
		"set_scoreboard_title": return preload("res://script/visual/blocks/match/set_scoreboard_title.gd").new()
		"show_scoreboard": return preload("res://script/visual/blocks/match/show_scoreboard.gd").new()
		"hide_scoreboard": return preload("res://script/visual/blocks/match/hide_scoreboard.gd").new()
		# API
		"api_get_request": return preload("res://script/visual/blocks/api/get_request.gd").new()
		# Space
		"get_space_id": return preload("res://script/visual/blocks/space/get_space_id.gd").new()
		# Rotation Degrees
		"get_rotation_degrees": return preload("res://script/visual/blocks/rotation/get_rotation_degrees.gd").new()
		"set_rotation_degrees": return preload("res://script/visual/blocks/rotation/set_rotation_degrees.gd").new()
		"tween_rotation_degrees": return preload("res://script/visual/blocks/rotation/tween_rotation_degrees.gd").new()
		# Misc low priority
		"get_friendly_name": return preload("res://script/visual/blocks/misc/get_friendly_name.gd").new()
		"get_node_name": return preload("res://script/visual/blocks/misc/get_node_name.gd").new()
		"attach_script": return preload("res://script/visual/blocks/misc/attach_script.gd").new()
		"gdscript_code": return preload("res://script/visual/blocks/misc/gdscript_code.gd").new()
		"is_server": return preload("res://script/visual/blocks/misc/is_server.gd").new()
		"evaluate_now": return preload("res://script/visual/blocks/misc/evaluate_now.gd").new()
		"reset_unsequenced": return preload("res://script/visual/blocks/misc/reset_unsequenced.gd").new()
		"os_shell_open": return preload("res://script/visual/blocks/os/shell_open.gd").new()
	# If we get here and we don't have a specific class for this block type, we
	# still want to always create a block, so that block indices stay correct.
	printerr("Block type '" + block_type + "' is unknown. Creating an empty block (no-op) as a placeholder.")
	return preload("res://script/visual/blocks/script_block.gd").new()


func _instantiate_entry_class(block_json: Dictionary) -> ScriptBlockEntryBase:
	var entry_signal: String = str(block_json.get("signal"))
	match entry_signal:
		"global_variable_changed": return preload("res://script/visual/blocks/signal/variable/global_changed.gd").new()
		"global_variable_tweened": return preload("res://script/visual/blocks/signal/variable/global_tweened.gd").new()
		"object_variable_changed": return preload("res://script/visual/blocks/signal/variable/object_changed.gd").new()
		"object_variable_tweened": return preload("res://script/visual/blocks/signal/variable/object_tweened.gd").new()
	# ScriptBlockEntry is the "general" case used for most signals.
	return preload("res://script/visual/blocks/signal/entry.gd").new()


func _setup_block_flow_connections(block: ScriptBlock, json: Dictionary, block_array: Array[ScriptBlock]) -> void:
	if not json.has("flows"):
		return
	var json_flows = json["flows"]
	for i in mini(block.flows.size(), json_flows.size()):
		var connected_block_index: int = json_flows[i]
		if connected_block_index < 0:
			continue # This one isn't connected.
		assert(connected_block_index < block_array.size())
		block.flows[i].connected_block = block_array[connected_block_index]


func _setup_block_input_connections(block: ScriptBlock, json: Dictionary, block_array: Array[ScriptBlock]) -> void:
	if not json.has("inputs"):
		return
	var json_inputs = json["inputs"]
	for i in mini(block.inputs.size(), json_inputs.size()):
		var input_json: Array = json_inputs[i]
		if input_json.size() < 5:
			continue
		var input_port = block.inputs[i]
		var connected_block_index: int = input_json[3]
		if connected_block_index < 0:
			continue
		assert(connected_block_index < block_array.size())
		input_port.connected_block = block_array[connected_block_index]
		if input_port.connected_block != null:
			input_port.connected_output = input_json[4]


func duplicate_script_blocks(old_blocks: Array[ScriptBlock], offset: Vector2) -> Array[ScriptBlock]:
	var new_blocks: Array[ScriptBlock] = []
	# Create new blocks from each old block.
	for old_block in old_blocks:
		assert(is_instance_valid(old_block))
		# Go through JSON to ensure all properties are correctly saved.
		var json_dict: Dictionary = old_block.serialize_to_dictionary()
		var new_block: ScriptBlock = create_block(json_dict)
		new_block.graph_position += offset
		new_blocks.append(new_block)
	# Rewire new blocks to be connected to the other new blocks.
	for block_index in range(old_blocks.size()):
		var old_block: ScriptBlock = old_blocks[block_index]
		var new_block: ScriptBlock = new_blocks[block_index]
		if old_block is ScriptBlockSequenced:
			for flow_index in old_block.flows.size():
				var old_flow = old_block.flows[flow_index]
				var new_flow = new_block.flows[flow_index]
				if old_flow.connected_block in old_blocks:
					var new_array_index: int = old_blocks.find(old_flow.connected_block)
					new_flow.connected_block = new_blocks[new_array_index]
				else:
					new_flow.connected_block = old_flow.connected_block
		for input_index in old_block.inputs.size():
			var old_input = old_block.inputs[input_index]
			var new_input = new_block.inputs[input_index]
			new_input.connected_output = old_input.connected_output
			if old_input.connected_block in old_blocks:
				var new_array_index: int = old_blocks.find(old_input.connected_block)
				new_input.connected_block = new_blocks[new_array_index]
			else:
				new_input.connected_block = old_input.connected_block
	return new_blocks


# Serialization/saving methods.
func serialize_to_json() -> Array[Dictionary]:
	return serialize_some_blocks_to_json(all_blocks)


func serialize_some_blocks_to_json(blocks_to_serialize: Array[ScriptBlock]) -> Array[Dictionary]:
	var ret: Array[Dictionary] = []
	for block in blocks_to_serialize:
		var block_dict: Dictionary = block.serialize_to_dictionary()
		assert(block_dict.has("type"))
		ret.append(block_dict)
	# Once each block has its JSON started, serialize the connections.
	for block_index in blocks_to_serialize.size():
		var block: ScriptBlock = blocks_to_serialize[block_index]
		var block_json = ret[block_index]
		for input_index in block.inputs.size():
			var input = block.inputs[input_index]
			var connected_index = blocks_to_serialize.find(input.connected_block)
			if connected_index < 0:
				continue
			var input_json = block_json["inputs"][input_index]
			input_json.append(connected_index)
			input_json.append(input.connected_output)
		if block is ScriptBlockSequenced:
			for flow_index in block.flows.size():
				var flow = block.flows[flow_index]
				block_json["flows"].append(blocks_to_serialize.find(flow.connected_block))
	return ret


func save_executed_sequenced_outputs(except: ScriptBlockAsync) -> Dictionary:
	var ret: Dictionary = {}
	for block in all_blocks:
		if block == except:
			continue
		if not block.evaluated:
			continue
		if not block is ScriptBlockSequenced:
			continue
		if block.outputs.size() == 0:
			continue
		# Save the outputs of evaluted/executed sequenced/run blocks.
		var saved_outputs: Array = []
		for o in block.outputs:
			saved_outputs.append(o.value)
		ret[block] = saved_outputs
	return ret


func load_block_outputs(saved_data: Dictionary) -> void:
	for block in saved_data:
		block.evaluated = true
		var saved_outputs: Array = saved_data[block]
		assert(saved_outputs.size() == block.outputs.size())
		for i in block.outputs.size():
			block.outputs[i].value = saved_outputs[i]


func validate_inputs_connected_to_block(connected_script_block: ScriptBlock) -> void:
	for block in all_blocks:
		for input in block.inputs:
			if input.connected_block == connected_script_block:
				if input.connected_output >= connected_script_block.outputs.size():
					input.connected_block = null
					input.connected_output = -1


func sync_blocks() -> void:
	for block in all_blocks:
		if block is ScriptBlockEvaluateNow:
			for i in range(block.inputs.size()):
				var input: ScriptBlock.ScriptBlockInputPort = block.inputs[i]
				var connected_block: ScriptBlock = input.connected_block
				if connected_block and input.connected_output < connected_block.outputs.size():
					var output_port: ScriptBlock.ScriptBlockDataPort = connected_block.outputs[input.connected_output]
					block.outputs[i].port_type = output_port.port_type
					block.outputs[i].value = output_port.value
				else:
					block.outputs[i].port_type = ScriptBlock.PortType.ANY_DATA
				block.graph_node.reset_ports()


# Deletion/destruction methods.
func cleanup_for_deletion() -> void:
	attached_object = null
	delete_all_blocks()


func delete_all_blocks() -> void:
	if all_blocks.is_empty():
		return # Nothing to delete.
	for block in all_blocks:
		block.cleanup_script_block_for_deletion()
		block.free()
	all_blocks.clear()
	entry_blocks.clear()
	contents_deleted.emit()


func delete_script_block(script_block: ScriptBlock) -> void:
	all_blocks.erase(script_block)
	entry_blocks.erase(script_block)
	# Loop through all other blocks to delete any connections to this block.
	disconnect_script_block_outputs(script_block)
	for block in all_blocks:
		if block is ScriptBlockSequenced:
			for flow in block.flows:
				if flow.connected_block == script_block:
					flow.connected_block = null
	script_block.cleanup_script_block_for_deletion()
	script_block.free()


func disconnect_script_block_outputs(script_block: ScriptBlock) -> void:
	# Loop through all other blocks to delete any connections to this block.
	for block in all_blocks:
		for input in block.inputs:
			if input.connected_block == script_block:
				if is_instance_valid(block.graph_node):
					block.graph_node.disconnect_input(input)
				else:
					input.connected_block = null
					input.connected_output = -1


# Logging signals.
func _on_block_log_error(error_text: String, script_block: ScriptBlock) -> void:
	block_message.emit(script_block, "Script Error", error_text, Enums.NotifyStatus.ERROR)


func _on_block_print_notify(title: String, message: String, notify_status: Enums.NotifyStatus, script_block: ScriptBlock) -> void:
	block_message.emit(script_block, title, message, notify_status)
