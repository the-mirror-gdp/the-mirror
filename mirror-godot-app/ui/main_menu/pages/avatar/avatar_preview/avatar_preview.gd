extends Node3D


@onready var _player_model: Node3D = $PlayerModel
@onready var _loading_node: Node3D = $LoadingLabel


func set_avatar_with_node(avatar: Node3D) -> void:
	if is_instance_valid(avatar):
		_loading_node.hide()
		_player_model.show()
		_player_model.set_avatar_with_node(avatar)


func set_avatar_with_resource_path(resource_path: String) -> void:
	_loading_node.hide()
	_player_model.show()
	_player_model.set_avatar_with_resource_path(resource_path)


func show_loading() -> void:
	_player_model.hide()
	_loading_node.show()
