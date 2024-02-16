class_name EquipableWorldModel
extends EquipableModel


func _set_model(equipable: Node3D) -> void:
	super._set_model(equipable)
	## Rotate our world model to fit the player's hand
	_model.rotation_degrees = Vector3(90, 0, -90)
