extends EquipableGun


const _DECAL_OFFSET: float = 0.01 # Meters
const _DECAL_SCENE_PATH: String = "res://player/equipable/gun/firearm/bullet_hole/bullet_hole.tscn"
const _BLOOD_PARTICLES_SCENE_PATH: String = "res://player/equipable/gun/firearm/blood/blood_particles.tscn"

## If this gun leaves bullet holes, how big they are.
var bullet_hole_size: float = 0.0
## If this gun uses bullets, what kind they use. Example: "6.8x51mm"
var bullet_type: String = ""
## If this gun is a shotgun, how many pellets it shoots at once.
var bullets_per_shot: int = 1
## If this gun uses bullets, how much spread from the crosshair it has by default.
var bullet_spread_base: float = 0.4
## The maximum amount of spread from the crosshair this gun can have.
var bullet_spread_max: float = 8.0
## How much spread from the crosshair this gun adds with each shot.
var bullet_spread_increase: float = 2.5
## How fast this gun's spread recovers.
var bullet_spread_recovery: float = 16.0
## The current amount of spread from the crosshair this gun has.
var _current_bullet_spread: float:
	set(value):
		_current_bullet_spread = clampf(value, bullet_spread_base, bullet_spread_max)
var _recoil_scale: float = 1.0
## If this gun uses bullets, how much damage each bullet does.
var bullet_damage: int = 15
## If this gun uses bullets, how much knockback each bullet does.
var bullet_knockback: float = 500.0
## If this gun uses bullets, the number of bullets in one magazine.
var magazine_ammo: int = 0
## If this gun uses bullets, how long it takes to reload them.
var reload_time: float = 0.0


func _process(delta) -> void:
	super._process(delta)
	_current_bullet_spread -= bullet_spread_recovery * delta
	# Recoil scaling
	_recoil_scale = 1.0
	var player: Player = _equipable_controller.player
	if not player.is_on_floor():
		_recoil_scale += 1.0
	_recoil_scale += inverse_lerp(0.0, 9.0, player.get_local_movement_velocity().length())
	if is_aiming and not player.is_intent_to_run():
		_recoil_scale *= 0.7


func bullet_populate(bullet_dict: Dictionary) -> void:
	if bullet_dict.has("bullet_hole_size"):
		var value = bullet_dict["bullet_hole_size"]
		if value is float:
			bullet_hole_size = value
	if bullet_dict.has("bullet_type"):
		var value = bullet_dict["bullet_type"]
		if value is String:
			bullet_type = value
	if bullet_dict.has("magazine_ammo"):
		var value = bullet_dict["magazine_ammo"]
		# Remember, JSON only has "number" which is the same as GDScript "float".
		if value is float:
			magazine_ammo = int(value)
	if bullet_dict.has("reload_time"):
		var value = bullet_dict["reload_time"]
		if value is float:
			reload_time = value
	if bullet_dict.has("bullets_per_shot"):
		var value = bullet_dict["bullets_per_shot"]
		if value is float:
			bullets_per_shot = value
	if bullet_dict.has("bullet_spread_base"):
		var value = bullet_dict["bullet_spread_base"]
		if value is float:
			bullet_spread_base = value
	if bullet_dict.has("bullet_spread_max"):
		var value = bullet_dict["bullet_spread_max"]
		if value is float:
			bullet_spread_max = value
	if bullet_dict.has("bullet_spread_increase"):
		var value = bullet_dict["bullet_spread_increase"]
		if value is float:
			bullet_spread_increase = value
	if bullet_dict.has("bullet_spread_recovery"):
		var value = bullet_dict["bullet_spread_recovery"]
		if value is float:
			bullet_spread_recovery = value
	if bullet_dict.has("bullet_damage"):
		var value = bullet_dict["bullet_damage"]
		if value is float:
			bullet_damage = value
	if bullet_dict.has("bullet_knockback"):
		var value = bullet_dict["bullet_knockback"]
		if value is float:
			bullet_knockback = value


func interact() -> void:
	if _cooldown_time > 0.0:
		return
	for i in range(bullets_per_shot):
		shoot()
	_current_bullet_spread += bullet_spread_increase
	super.interact()


func shoot() -> void:
	var raycast_dict: Dictionary = _equipable_controller.get_raycast(get_bullet_spread())
	var hit_position = raycast_dict.get("position")
	var hit_object = raycast_dict.get("collider")
	if hit_object:
		var hit_normal: Vector3 = -raycast_dict.get("normal")
		if hit_object.has_method("damage"):
			hit_object.damage(bullet_damage, _equipable_controller.player.get_user_id())
			if hit_object is Player:
				create_blood_particles(hit_object, hit_position)
				GameUI.crosshair.show_hitmarker()
				return
		if hit_object.has_method("server_add_impulse_at_position"):
			if hit_object.is_dynamic():
				var direction: Vector3 = (hit_position - _equipable_controller.player.get_global_eyes_position()).normalized()
				hit_object.server_add_impulse_at_position.rpc_id(Zone.SERVER_PEER_ID, direction * bullet_knockback, hit_position)
		create_bullet_hole(hit_object, hit_position, hit_normal)


func create_blood_particles(hit_object: Node3D, hit_pos: Vector3) -> void:
	var transform = Transform3D(Basis(), hit_pos)
	var parent: NodePath = hit_object.get_path()
	_equipable_controller.instantiate_object.rpc(_BLOOD_PARTICLES_SCENE_PATH, transform, parent)


func create_bullet_hole(hit_object: Node3D, hit_pos: Vector3, hit_normal: Vector3) -> void:
	if bullet_hole_size <= 0.0:
		return
	var actual_pos: Vector3 = hit_pos + hit_normal * ((randf() + 0.1) * _DECAL_OFFSET)
	var dot: float = hit_normal.dot(Vector3.UP)
	var up = Vector3.UP if dot < 0.5 and dot > -0.5 else Vector3.FORWARD
	var decal_basis = Basis.looking_at(hit_normal, up) * (bullet_hole_size * 64)
	var decal_transform = Transform3D(decal_basis, actual_pos)
	decal_transform = decal_transform.rotated_local(Vector3.FORWARD, deg_to_rad(randf_range(-180, 180)))
	var parent: NodePath = hit_object.get_path()
	_equipable_controller.instantiate_object.rpc(_DECAL_SCENE_PATH, decal_transform, parent)


func get_bullet_spread() -> float:
	return _current_bullet_spread * _recoil_scale
