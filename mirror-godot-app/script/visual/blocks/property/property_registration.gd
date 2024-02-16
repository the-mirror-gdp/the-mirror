class_name ScriptPropertyRegistration
extends Object


static func has_registered_property(property_name: StringName) -> bool:
	return _REGISTERED_PROPERTIES.has(property_name)


static func get_registered_properties() -> Dictionary:
	return _REGISTERED_PROPERTIES


static func get_property_description(property_name: StringName) -> String:
	if _REGISTERED_PROPERTIES.has(property_name):
		return _REGISTERED_PROPERTIES[property_name]["description"]
	return "No description."


const _REGISTERED_PROPERTIES: Dictionary = {
	# Physics
	&"collision_enabled": {
		"data_type": ScriptBlock.PortType.BOOL,
		"default_value": true,
		"category": "Physics",
		"description": "Whether or not the object will collide with other objects or players.",
	},
	&"physics_shape_type": {
		"data_type": ScriptBlock.PortType.STRING,
		"default_value": "Auto",
		"enum_values": ["Auto", "Convex", "Concave", "Model Shapes", "Multi Bodies"],
		"category": "Physics",
		"description": "The type of physics shape to use for the object.",
	},
	&"physics_body_type": {
		"data_type": ScriptBlock.PortType.STRING,
		"default_value": "Static",
		"enum_values": ["Static", "Kinematic", "Dynamic", "Trigger"],
		"category": "Physics",
		"description": "The type of physics body to use for the object.",
		"keywords": ["area", "sensor", "rigid"],
	},
	&"mass": {
		"data_type": ScriptBlock.PortType.FLOAT,
		"default_value": 1.0,
		"valid_values": "Greater than zero",
		"category": "Physics",
		"description": "The mass of the object in kilograms.",
		"keywords": ["weight", "gravity"],
	},
	&"gravity_scale": {
		"data_type": ScriptBlock.PortType.FLOAT,
		"default_value": 1.0,
		"category": "Physics",
		"description": "The scale of gravity applied to the object. A scale of 0 will disable gravity. A negative scale will invert gravity.",
		"keywords": ["weight", "gravity"],
	},
	&"angular_velocity": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"default_value": Vector3.ZERO,
		"category": "Physics",
		"description": "The angular velocity of the object in radians per second.",
		"keywords": ["rotation", "speed"],
	},
	&"linear_velocity": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"default_value": Vector3.ZERO,
		"category": "Physics",
		"description": "The linear velocity of the object in meters per second.",
		"keywords": ["motion", "speed"],
	},
	# SpaceObject
	&"model_offset": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"default_value": Vector3.ZERO,
		"description": "The offset of the model from the object's origin.",
	},
	&"model_scale": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"default_value": Vector3.ONE,
		"valid_values": "Non-zero",
		"description": "The scale of the model.",
	},
	&"space_object_name": {
		"data_type": ScriptBlock.PortType.STRING,
		"description": "The name of the SpaceObject.",
	},
	&"object_color": {
		"data_type": ScriptBlock.PortType.COLOR,
		"description": "The color of the SpaceObject.",
	},
	&"object_local_texture": {
		"data_type": ScriptBlock.PortType.OBJECT,
		"description": "The texture override of the SpaceObject."
	},
	&"material_id": {
		"data_type": ScriptBlock.PortType.STRING,
		"valid_values": "Valid ID",
		"description": "The material ID of the SpaceObject.",
	},
	&"object_texture_size": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"valid_values": "Greater than zero",
		"description": "The size of the SpaceObject's texture.",
	},
	&"object_texture_offset": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"description": "The offset of the SpaceObject's texture.",
	},
	&"player_height_multiplier": {
		"data_type": ScriptBlock.PortType.FLOAT,
		"description": "The height multiplier of the Player.",
		"hidden": true, # Registered for tweening, but has custom blocks.
	},
	# Node3D
	&"position": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"description": "The local position of the object.",
		"keywords": ["translation", "location", "point"],
	},
	&"global_position": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"description": "The global position of the object.",
		"keywords": ["translation", "location", "point"],
	},
	&"rotation_degrees": {
		"data_type": ScriptBlock.PortType.VECTOR3,
		"description": "The local rotation of the object in Euler angles in degrees.",
		"hidden": true, # Deprecated in favor of custom code.
	},
	&"visible": {
		"data_type": ScriptBlock.PortType.BOOL,
		"default_value": true,
		"description": "Whether or not the object is visible.",
	},
}
