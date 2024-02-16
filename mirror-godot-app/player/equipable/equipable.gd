class_name Equipable
extends Node


signal interacted()


## Automatic means that if the mouse is held, the item is used continuously.
var automatic: bool = false
## How much the camera should be pushed around when using this item. Meters/radians.
var camera_punch: float = 0.0
## How long does it take to deploy this equipable?
## NOTE 2023-08-20: Unused for now, but could be used as the time from item selected to item usable in hand.
var deploy_time: float = 1.0
## Does this equipable interact with triggers? If false, only interact with solid objects.
## Could be useful for "key" equipables that unlock doors, treasure chests, etc.
var hit_triggers: bool = false
## How quickly can this weapon be used, in seconds.
## For guns, this is the fire rate (time between bullets).
var use_rate: float = 0.0

## How long until this item can be used again?
var _cooldown_time: float = 0.0
## Reference to the EquipableController that owns this item.
var _equipable_controller: EquipableController = null


func setup(equipable_controller: EquipableController) -> void:
	_equipable_controller = equipable_controller
	set_process(true)


func _process(delta: float) -> void:
	_cooldown_time -= delta


func equipable_populate(equipable_dict: Dictionary) -> void:
	if equipable_dict.has("automatic"):
		var value = equipable_dict["automatic"]
		if value is bool:
			automatic = value
	if equipable_dict.has("hit_triggers"):
		var value = equipable_dict["hit_triggers"]
		if value is bool:
			hit_triggers = value
	if equipable_dict.has("camera_punch"):
		var value = equipable_dict["camera_punch"]
		if value is float:
			camera_punch = value
	if equipable_dict.has("deploy_time"):
		var value = equipable_dict["deploy_time"]
		if value is float:
			deploy_time = value
	if equipable_dict.has("use_rate"):
		var value = equipable_dict["use_rate"]
		if value is float:
			use_rate = value


func interact() -> void:
	if _cooldown_time > 0.0:
		return
	_cooldown_time = use_rate
	interacted.emit()
