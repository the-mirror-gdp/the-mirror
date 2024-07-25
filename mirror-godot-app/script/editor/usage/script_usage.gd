extends HBoxContainer


var _script_instance: ScriptInstance

@onready var _usage_count_label: Label = $UsageCountLabel
@onready var _clone_script = $CloneScript


func _process(_delta: float) -> void:
	if not is_instance_valid(_script_instance):
		return
	var usage_count: int = Net.script_client.get_script_id_usage_count(_script_instance.script_id)
	if usage_count < 2:
		hide()
	else:
		show()
		_usage_count_label.text = tr("This script is used by ") + str(usage_count) + tr(" objects")


func setup_for_script_instance(script_instance: ScriptInstance) -> void:
	_script_instance = script_instance


func set_script_toolbar_editable(is_editable: bool) -> void:
	_clone_script.visible = is_editable


func _on_view_script_users_pressed() -> void:
	GameUI.instance.creator_ui.search_node_tree("script_id=" + _script_instance.script_id)


func _on_clone_script_pressed() -> void:
	Net.script_client.request_clear_script_editor.emit()
	Net.script_client.client_clone_script_entity(_script_instance)
	var target_node: Node = _script_instance.target_node
	_script_instance.cleanup_script_instance()
	_script_instance.target_node = target_node
