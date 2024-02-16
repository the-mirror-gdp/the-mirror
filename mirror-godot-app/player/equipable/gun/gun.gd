class_name EquipableGun
extends Equipable


## Whether we're currently aiming this gun.
var is_aiming: bool = false
## How far this gun should move back due to recoil, in meters.
var recoil_distance: float = 0.0
## How far this gun should be rotated due to recoil, in radians.
var recoil_rotation: float = 0.0
## The path to the sound files to randomly play when this gun is fired.
var shoot_sounds: Array = [
	"res://player/equipable/gun/firearm/sound/rifle/rifle_shoot_01.wav",
	"res://player/equipable/gun/firearm/sound/rifle/rifle_shoot_02.wav",
	"res://player/equipable/gun/firearm/sound/rifle/rifle_shoot_03.wav",
	"res://player/equipable/gun/firearm/sound/rifle/rifle_shoot_04.wav",
]


func gun_populate(gun_dict: Dictionary) -> void:
	if gun_dict.has("recoil_distance"):
		var value = gun_dict["recoil_distance"]
		if value is float:
			recoil_distance = value
	if gun_dict.has("recoil_rotation"):
		var value = gun_dict["recoil_rotation"]
		if value is float:
			recoil_rotation = value
	if gun_dict.has("shoot_sounds"):
		var value = gun_dict["shoot_sounds"]
		if value is Array:
			shoot_sounds = value


func interact() -> void:
	if _cooldown_time > 0.0:
		return
	_equipable_controller.play_sound.rpc(shoot_sounds.pick_random())
	super.interact()
