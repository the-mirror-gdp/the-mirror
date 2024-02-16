class_name EquipableModel
extends Node3D


var _equipable_controller: EquipableController = null
var _equipable_dict: Dictionary = {}
var _player: Player = null
var _model: Node3D = null

const _MUZZLE_FLASH: PackedScene = preload("res://player/equipable/gun/muzzle_flash/muzzle_flash.tscn")
var _muzzle_flash_animation: AnimationPlayer = null


func setup(equipable_controller: EquipableController) -> void:
	_equipable_controller = equipable_controller
	_equipable_controller.equipable_changed.connect(_on_equipable_changed)
	_equipable_controller.current_equipable_interacted.connect(_on_current_equipable_interacted)
	_player = _equipable_controller.player


func _on_equipable_changed(_equipable: Node) -> void:
	_clear_model()
	if not _equipable:
		return
	_set_model(_equipable)
	_equipable_dict = _equipable.get_meta(&"MIRROR_equipable")
	_setup_muzzle_flash_animation()


func _on_current_equipable_interacted(_equipable: Node) -> void:
	_play_muzzle_flash_animation()


func _set_model(equipable: Node3D) -> void:
	var model = equipable.duplicate(true)
	add_child(model)
	_model = model


func _clear_model() -> void:
	for child in get_children():
		child.queue_free()
	_model = null
	_muzzle_flash_animation = null


func _set_model_visibility(value: bool) -> void:
	for child in get_children():
		child.set_visible(value)


func _setup_muzzle_flash_animation() -> void:
	var gun_dict = _equipable_dict.get("gun")
	if gun_dict is Dictionary:
		if gun_dict.has("muzzle_flash"):
			var value = gun_dict["muzzle_flash"]
			if value is Vector3:
				var muzzle_flash = _MUZZLE_FLASH.instantiate()
				_model.add_child(muzzle_flash)
				muzzle_flash.position = value
				_muzzle_flash_animation = muzzle_flash.get_node(^"AnimationPlayer")


func _play_muzzle_flash_animation() -> void:
	if _muzzle_flash_animation:
		if _muzzle_flash_animation.is_playing():
			_muzzle_flash_animation.stop()
		_muzzle_flash_animation.play("flash")


func _look_for_child_node(path_or_name: String) -> Node:
	if not _model:
		return
	if _model.has_node(path_or_name):
		return _model.get_node(path_or_name)
	var child = _model.get_child(0)
	if child.has_node(path_or_name):
		return child.get_node(path_or_name)
	return _model.find_child(path_or_name)
