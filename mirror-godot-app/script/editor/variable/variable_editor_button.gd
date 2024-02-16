extends Button


func _ready():
	var role = Util.get_role_for_user(Zone.space, Net.user_id)
	disabled = role < Enums.ROLE.MANAGER
