# TODO refactor this into TMCharacter C++ class.

class_name PlayerMovementController
extends Node

@onready var seat_controller: SeatController = $SeatController


var _player: Player = null


func setup(player: Player, is_local: bool = true) -> void:
	_player = player
	seat_controller.setup(_player, self, is_local)
