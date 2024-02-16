extends HBoxContainer


var _is_expanded: bool = true

@onready var _variable_editor = $VariableEditor
@onready var _teams = $Teams
@onready var _users_present = $UsersPresent
@onready var _users_present_icon_down = $UsersPresent/HBoxContainer/IconDown
@onready var _teleport = $Teleport
@onready var _play_button = $PlayButton
@onready var _publish_button = $PublishButton
@onready var _version_button = %VersionButton


func set_expanded(is_expanded: bool) -> void:
	if _is_expanded == is_expanded:
		return
	_is_expanded = is_expanded
	_variable_editor.set_expanded(is_expanded)
	_teams.set_expanded(is_expanded)
	_users_present.set_expanded(is_expanded)
	_users_present_icon_down.visible = is_expanded
	_teleport.set_expanded(is_expanded)
	_play_button.set_expanded(is_expanded)
	_publish_button.set_expanded(is_expanded)
	_version_button.set_expanded(is_expanded)
