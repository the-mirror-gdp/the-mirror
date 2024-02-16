# ScriptSignalRegistration
extends Node


var _user_signal_signatures = {}


func get_mirror_registered_signals() -> Dictionary:
	return _REGISTERED_SIGNALS_FOR_NODE_TYPE


func get_mirror_registered_meta_signals() -> Dictionary:
	return _REGISTERED_SIGNALS_FOR_METADATA


func is_builtin_signal_unregistered(signal_name: StringName) -> bool:
	return _get_signature_from_builtin_signal_name(signal_name).is_empty()


func get_user_signal_names() -> Array:
	return _user_signal_signatures.keys()


func get_signature_from_user_signal_name(signal_name: StringName) -> Dictionary:
	if signal_name in _user_signal_signatures:
		return _user_signal_signatures[signal_name]
	return {}


func register_user_signal_signature(signal_dict: Dictionary) -> bool:
	var signal_name: StringName = signal_dict["signal"]
	if signal_name in _user_signal_signatures:
		var signal_signature: Dictionary = _user_signal_signatures[signal_name]
		if signal_dict.hash() == signal_signature.hash():
			return true
		elif str(signal_dict) == str(signal_signature):
			return true # Godot is being stupid, the Dictionaries are identical but hash differently.
		else:
			var message = "The signal name " + signal_name + " has two signatures. Only one will show up in Event autocomplete."
			Notify.warning("Conflicting signal signature", message)
			printerr(message, " The signatures are:\n", signal_dict, "\n", signal_signature)
			return false
	_user_signal_signatures[signal_name] = signal_dict
	return true


func is_mirror_registered_signal(signal_name: StringName) -> bool:
	return not _get_signature_from_builtin_signal_name(signal_name).is_empty()


func get_builtin_signal_description(signal_name: StringName) -> String:
	if signal_name == &"player_interact":
		return "Emitted when a player interacts with an object."
	var signal_signature: Dictionary = _get_signature_from_builtin_signal_name(signal_name)
	return signal_signature.get("description", "No description.")


func get_category_description(category_name: String) -> String:
	match category_name:
		"SpaceObject":
			return "Signals emitted when a player interacts with a SpaceObject."
		"Physics":
			return "Signals emitted when physics events happen to non-trigger physics bodies."
		"Trigger":
			return "Signals emitted when physics trigger events happen, like bodies entering triggers."
		"Animation":
			return "Signals emitted when an AnimationPlayer node finishes playing an animation."
		"Audio":
			return "Signals emitted when an audio player node finishes playing its audio."
		"Timer":
			return "Signals emitted when a Timer node finishes counting down."
		"New Timer":
			return "Signals emitted when a Timer node finishes counting down. Selecting this will create a new Timer node."
		"Player":
			return "Global signals emitted when events happen to players."
		"Variables":
			return "Global signals emitted when variables are changed."
		"Match":
			return "Global signals emitted when a match or round starts or ends."
		"Global":
			return "Misc global signals not covered by other categories."
		"OMI_seat":
			return "Signals emitted from a seat as defined by [OMI_seat](https://github.com/omigroup/gltf-extensions/tree/main/extensions/2.0/OMI_seat)."
		"OMI_spawn_point":
			return "Signals emitted from a spawn point as defined by [OMI_spawn_point](https://github.com/omigroup/gltf-extensions/tree/main/extensions/2.0/OMI_spawn_point)."
	return category_name


func _get_signature_from_builtin_signal_name(signal_name: StringName) -> Dictionary:
	for type in _REGISTERED_SIGNALS_FOR_NODE_TYPE:
		var type_signals: Array = _REGISTERED_SIGNALS_FOR_NODE_TYPE[type]
		for signal_signature in type_signals:
			if signal_signature["signal"] == signal_name:
				return signal_signature
	for meta_key in _REGISTERED_SIGNALS_FOR_METADATA:
		var meta_signals: Array = _REGISTERED_SIGNALS_FOR_METADATA[meta_key]
		for signal_signature in meta_signals:
			if signal_signature["signal"] == signal_name:
				return signal_signature
	return {}


func is_signal_valid_on_node(signal_name: StringName, target_object: Object) -> bool:
	# Check base node types.
	if signal_name == &"player_interact":
		return target_object is Node3D
	if signal_name == &"timeout":
		return target_object is Timer
	# Check metadata.
	for metadata_key in _REGISTERED_SIGNALS_FOR_METADATA:
		var metadata_array: Array = _REGISTERED_SIGNALS_FOR_METADATA[metadata_key]
		for metadata_item in metadata_array:
			if metadata_item["signal"] == signal_name:
				return target_object.has_meta(metadata_key)
	return true


const _REGISTERED_SIGNALS_FOR_NODE_TYPE = {
	"SpaceObject": [{
		"signal": &"player_interact",
		"description": "Emitted when a player interacts with a SpaceObject.",
		"path": "self",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}, {
		"signal": &"custom_signal",
		"description": "A custom user-defined signal. Create this with your desired signature, and it will only run when your own script calls it. Signatures must be unique per signal name.",
		"path": "self",
		"keywords": ["call", "emit", "event", "execute", "fire", "run", "trigger"],
	}],
	"Physics": [{ # Non-trigger bodies.
		"signal": &"player_interact",
		"description": "Emitted when a player interacts with a body.",
		"path": "self",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}],
	"Trigger": [{ # Trigger bodies.
		"signal": &"player_interact",
		"description": "Emitted when a player interacts with a trigger.",
		"path": "self",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}, {
		"signal": &"body_entered_trigger",
		"description": "Emitted when a physics body is of type Trigger and another body enters it.",
		"path": "self",
		"signalParameters": {
			"Body": [ScriptBlock.PortType.OBJECT, null],
		},
	}, {
		"signal": &"body_exited_trigger",
		"description": "Emitted when a physics body is of type Trigger and another body exits it.",
		"path": "self",
		"signalParameters": {
			"Body": [ScriptBlock.PortType.OBJECT, null],
		},
	}],
	"Animation": [{
		"signal": &"animation_finished",
		"description": "Emitted when an AnimationPlayer node finishes playing an animation. This signal requires an AnimationPlayer subnode.",
		"signalParameters": {
			"Animation Name": [ScriptBlock.PortType.STRING, ""],
		},
	}],
	"Audio": [{
		"signal": &"finished",
		"description": "Emitted when an audio player node finishes playing an audio file. This signal requires an AudioStreamPlayer(3D) subnode.",
		"keywords": ["end", "stop"],
	}],
	"Timer": [{
		"signal": &"timeout",
		"description": "Emitted when a Timer node finishes counting down. This signal requires a Timer subnode. Note: The duration is an input that you can adjust in the inspector, it is not supplied by the signal.",
		"inspectorParameters": {
			"Duration": [ScriptBlock.PortType.FLOAT, 2.0]
		},
	}],
	"Player": [{
		"signal": &"player_connected",
		"description": "Emitted when a player connects to the server.",
		"path": "/root/Zone/SocialManager",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}, {
		"signal": &"player_disconnected",
		"description": "Emitted when a player disconnects from the server.",
		"path": "/root/Zone/SocialManager",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}, {
		"signal": &"player_killed_by_player",
		"description": "Emitted when a player is killed by another player.",
		"path": "/root/Zone/SocialManager",
		"signalParameters": {
			"Victim Player": [ScriptBlock.PortType.OBJECT, null],
			"Killer Player": [ScriptBlock.PortType.OBJECT, null],
			"Victim Team": [ScriptBlock.PortType.STRING, ""],
			"Killer Team": [ScriptBlock.PortType.STRING, ""],
			"Friendly Fire": [ScriptBlock.PortType.BOOL, false],
		},
	}, {
		"signal": &"player_spawned",
		"description": "Emitted when a player spawns.",
		"path": "/root/Zone/SocialManager",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}],
	"Variables": [{
		"signal": &"global_variable_changed",
		"description": "Emitted when any global variable is changed. To avoid infinite loops, this is deferred until the end of the frame.",
		"path": "/root/Zone/ScriptNetworkSync",
		"signalParameters": {
			"Variable Name": [ScriptBlock.PortType.STRING, ""],
			"Variable Value": [ScriptBlock.PortType.ANY_DATA, null],
		},
		"inputs": [
			["Variable Name", ScriptBlock.PortType.STRING, ""]
		],
	}, {
		"signal": &"global_variable_tweened",
		"description": "Emitted when any global variable is tweened. To avoid infinite loops, this is deferred until the end of the frame.",
		"path": "/root/Zone/ScriptNetworkSync",
		"signalParameters": {
			"Variable Name": [ScriptBlock.PortType.STRING, ""],
			"From Value": [ScriptBlock.PortType.ANY_DATA, null],
			"To Value": [ScriptBlock.PortType.ANY_DATA, null],
			"Duration": [ScriptBlock.PortType.FLOAT, 1.0],
		},
		"inputs": [
			["Variable Name", ScriptBlock.PortType.STRING, ""]
		],
	}, {
		"signal": &"object_variable_changed",
		"description": "Emitted when any object variable is changed. To avoid infinite loops, this is deferred until the end of the frame.",
		"path": "/root/Zone/ScriptNetworkSync",
		"signalParameters": {
			"Object": [ScriptBlock.PortType.OBJECT, null],
			"Variable Name": [ScriptBlock.PortType.STRING, ""],
			"Variable Value": [ScriptBlock.PortType.ANY_DATA, null],
		},
		"inputs": [
			["Variable Name", ScriptBlock.PortType.STRING, ""]
		],
	}, {
		"signal": &"object_variable_tweened",
		"description": "Emitted when any object variable is tweened. To avoid infinite loops, this is deferred until the end of the frame.",
		"path": "/root/Zone/ScriptNetworkSync",
		"signalParameters": {
			"Object": [ScriptBlock.PortType.OBJECT, null],
			"Variable Name": [ScriptBlock.PortType.STRING, ""],
			"From Value": [ScriptBlock.PortType.ANY_DATA, null],
			"To Value": [ScriptBlock.PortType.ANY_DATA, null],
			"Duration": [ScriptBlock.PortType.FLOAT, 1.0],
		},
		"inputs": [
			["Variable Name", ScriptBlock.PortType.STRING, ""]
		],
	}],
	"Match": [{
		"signal": &"match_start",
		"description": "Emitted when a match starts.",
		"path": "/root/Zone/MatchRoundSystem",
		"signalParameters": {
			"Freeze Time": [ScriptBlock.PortType.FLOAT, 0.0],
		},
		"keywords": ["round"],
	}, {
		"signal": &"match_end",
		"description": "Emitted when a match ends (but not when it's terminated).",
		"path": "/root/Zone/MatchRoundSystem",
		"signalParameters": {
			"Winning Team Name": [ScriptBlock.PortType.STRING, ""],
		},
		"keywords": ["round"],
	}, {
		"signal": &"round_start",
		"description": "Emitted when a round starts.",
		"path": "/root/Zone/MatchRoundSystem",
		"signalParameters": {
			"Freeze Time": [ScriptBlock.PortType.FLOAT, 0.0],
		},
		"keywords": ["match"],
	}, {
		"signal": &"round_end",
		"description": "Emitted when a round ends (but not when it's terminated).",
		"path": "/root/Zone/MatchRoundSystem",
		"signalParameters": {
			"Winning Team Name": [ScriptBlock.PortType.STRING, ""],
		},
		"keywords": ["match"],
	}, {
		"signal": &"team_score_changed",
		"description": "Emitted when a team's score changes. This signal will only emit for valid teams.",
		"path": "/root/Zone/MatchRoundSystem",
		"signalParameters": {
			"Team Name": [ScriptBlock.PortType.STRING, ""],
			"Team Score": [ScriptBlock.PortType.INT, 0],
		},
		"keywords": ["match", "round", "points"],
	}],
	"Global": [{
		"signal": &"game_start",
		"description": "Emitted when the game starts after all SpaceObjects have loaded.",
		"path": "/root/Zone",
		"keywords": ["ready"],
	}, {
		"signal": &"process_every_frame",
		"description": "Emitted every frame. Please avoid using this signal if possible, as it can be very expensive.",
		"path": "/root/Zone",
		"signalParameters": {
			"Delta Time": [ScriptBlock.PortType.FLOAT, 0.01],
		},
		"keywords": ["update"],
	}, {
		"signal": &"death",
		"description": "Emitted when a player dies.",
		"path": "/root/DamageMaster",
		"signalParameters": {
			"Target Object": [ScriptBlock.PortType.OBJECT, null],
			"Event Origin": [ScriptBlock.PortType.STRING, DamageHandler.SCRIPT_ORIGIN],
		},
		"keywords": ["died", "killed"],
	}, {
		"signal": &"server_revive",
		"description": "Emitted when a player is revived by the server.",
		"path": "/root/DamageMaster",
		"signalParameters": {
			"Target Object": [ScriptBlock.PortType.OBJECT, null],
			"Event Origin": [ScriptBlock.PortType.STRING, DamageHandler.SCRIPT_ORIGIN],
		},
		"keywords": ["respawn"],
	}, {
		"signal": &"health_changed",
		"description": "Emitted when a player's health changes.",
		"path": "/root/DamageMaster",
		"signalParameters": {
			"Target Object": [ScriptBlock.PortType.OBJECT, null],
			"New Health": [ScriptBlock.PortType.FLOAT, 0],
			"Old Health": [ScriptBlock.PortType.FLOAT, 0],
			"Event Origin": [ScriptBlock.PortType.STRING, DamageHandler.SCRIPT_ORIGIN],
		},
	}],
}

const _REGISTERED_SIGNALS_FOR_METADATA = {
	&"OMI_seat": [{
		"signal": &"player_sit_here",
		"description": "Emitted when a player sits on a seat as defined by OMI_seat. This signal requires an OMI_seat subnode.",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
		"keywords": ["seated", "sat", "mount", "enter"],
	}, {
		"signal": &"player_unsit_here",
		"description": "Emitted when a player stops sitting on a seat as defined by OMI_seat. This signal requires an OMI_seat subnode.",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
		"keywords": ["unseated", "stand", "unmount", "exit", "leave"],
	}],
	&"OMI_spawn_point": [{
		"signal": &"player_spawned_here",
		"description": "Emitted when a player spawns at a spawn point as defined by OMI_spawn_point. This signal requires an OMI_spawn_point subnode.",
		"signalParameters": {
			"Player": [ScriptBlock.PortType.OBJECT, null],
		},
	}],
}
