class_name ScriptMethodRegistration
extends Object


static func has_registered_method(method_name: StringName) -> bool:
	return _REGISTERED_METHODS.has(method_name)


static func get_registered_methods() -> Dictionary:
	return _REGISTERED_METHODS


static func get_method_description(method_name: StringName) -> String:
	if _REGISTERED_METHODS.has(method_name):
		return _REGISTERED_METHODS[method_name]["description"]
	return "No description."


const _REGISTERED_METHODS: Dictionary = {
	# SpaceObject
	&"get_model_node_by_name": {
		"category": "SpaceObject",
		"description": "Gets a model node of the SpaceObject by name. These are nodes imported from the GLTF file. Model nodes are guaranteed to have a unique name.",
		"sequenced": false,
		"inputs": [
			["Node Name", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Node Or Null", ScriptBlock.PortType.OBJECT, null]
		]
	},
	&"get_model_node_by_type": {
		"category": "SpaceObject",
		"description": "Gets a model node of the SpaceObject by type. These are nodes imported from the GLTF file. If multiple nodes of the same type exist, the first one found is returned.",
		"sequenced": false,
		"inputs": [
			["Node Type", ScriptBlock.PortType.STRING, ""]
		],
		"outputs": [
			["Node Or Null", ScriptBlock.PortType.OBJECT, null]
		]
	},
	&"center_model_offset": {
		"category": "SpaceObject",
		"description": "Adjusts the model offset of the SpaceObject so that the model's center is at the origin of the SpaceObject.",
		"sequenced": true,
	},
	&"get_space_object_asset_id": {
		"category": "SpaceObject",
		"description": "Gets the asset ID of the SpaceObject. This is the ID of the asset that was used to create the SpaceObject.",
		"sequenced": false,
		"outputs": [
			["Asset ID", ScriptBlock.PortType.STRING, ""]
		]
	},
	&"queue_update_network_object": {
		"category": "SpaceObject",
		"description": "Queues an update to the SpaceObject's network object. Many operations will automatically queue an update, but this can be used to force an update.",
		"sequenced": true,
	},
	# Player
	&"respawn_player": {
		"category": "Player",
		"description": "Respawns the player. This will teleport the player to a random spawn point on the player's team. If no spawn point for this team is found, a random spawn point for a different team will be picked. If the Space has no spawn points, the player will be teleported to the global world origin.",
		"sequenced": true,
	},
	&"get_player_team": {
		"category": "Player",
		"description": "Gets the player's team name.",
		"sequenced": false,
		"outputs": [
			["Team", ScriptBlock.PortType.STRING, ""],
		]
	},
	&"set_player_team": {
		"category": "Player",
		"description": "Sets the player's team using the team name and team color.",
		"sequenced": true,
		"inputs": [
			["Team", ScriptBlock.PortType.STRING, ""],
			["Color", ScriptBlock.PortType.COLOR, Color()],
		]
	},
	&"set_player_input_allowed": {
		"category": "Player",
		"description": "Sets whether the player is allowed to move and look around. Setting this to false will disallow and disable input. Setting this to true will allow but not necessarily enable input, because the player may have input disabled for other reasons, like being in a menu.",
		"sequenced": true,
		"inputs": [
			["Is Allowed", ScriptBlock.PortType.BOOL, false],
		]
	},
	&"is_player_input_allowed": {
		"category": "Player",
		"description": "Gets whether the player is allowed to move and look around.",
		"sequenced": false,
		"outputs": [
			["Is Allowed", ScriptBlock.PortType.BOOL, false],
		]
	},
	&"add_equipable": {
		"category": "Player",
		"description": "Adds an equipable to the player's hotbar. Asset ID must point to an asset with `MIRROR_equipable` metadata defined in the GLTF file.",
		"sequenced": true,
		"inputs": [
			["Asset ID", ScriptBlock.PortType.STRING, ""],
		]
	},
	&"clear_equipables": {
		"category": "Player",
		"description": "Clears the player's hotbar of all equipables.",
		"sequenced": true,
	},
	# Node3D
	&"to_global": {
		"category": "Advanced",
		"description": "Converts a local vector (relative to this node) to a global vector (relative to the world origin).",
		"sequenced": false,
		"inputs": [
			["Local", ScriptBlock.PortType.VECTOR3, Vector3()],
		],
		"outputs": [
			["Global", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	&"to_local": {
		"category": "Advanced",
		"description": "Converts a global vector (relative to the world origin) to a local vector (relative to this node).",
		"sequenced": false,
		"inputs": [
			["Global", ScriptBlock.PortType.VECTOR3, Vector3()],
		],
		"outputs": [
			["Local", ScriptBlock.PortType.VECTOR3, Vector3()],
		]
	},
	# Misc
	&"get_name": {
		"category": "Advanced",
		"description": "Deprecated: Use Get Friendly Name or Get Node Name Or ID instead.",
		"hidden": true,
		"sequenced": false,
		"outputs": [
			["Node Name", ScriptBlock.PortType.STRING, ""]
		]
	},
	# damageable
	&"damage": {
		"category": "Damageable",
		"description": "Damage the target object by the given amount. The object may be a SpaceObject or a Player. Amount should be positive, if you use a negative amount that will heal instead.",
		"sequenced": true,
		"inputs": [
			["Amount", ScriptBlock.PortType.FLOAT, 20.0],
			["Source Of Damage", ScriptBlock.PortType.STRING, DamageHandler.SCRIPT_ORIGIN],
		]
	},
	&"heal": {
		"category": "Damageable",
		"description": "Heal the target object by the given amount. The object may be a SpaceObject or a Player. Amount should be positive, if you use a negative amount that will damage instead.",
		"sequenced": true,
		"inputs": [
			["Amount", ScriptBlock.PortType.FLOAT, 20.0],
			["Source Of Healing", ScriptBlock.PortType.STRING, DamageHandler.SCRIPT_ORIGIN],
		]
	},
	&"revive": {
		"category": "Damageable",
		"description": "Revive the target object from death.",
		"sequenced": true,
	},
}
