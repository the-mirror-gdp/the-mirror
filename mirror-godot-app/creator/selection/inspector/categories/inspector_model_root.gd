extends InspectorCategoryBase


signal model_name_updated()
signal request_convert_to_local()
signal request_save_local()

var target_node: Node3D = null

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _model_name = _property_list.get_node(^"ModelName")
@onready var _save_button = _property_list.get_node(^"SaveButton")
@onready var _local_button = _property_list.get_node(^"LocalButton")


func _ready() -> void:
	refresh()
	super()


func refresh() -> void:
	update_active_fields_by_permissions()
	_model_name.current_value = target_node.name
	var local: bool = target_node is ModelRoot
	_model_name.visible = local
	_save_button.visible = local
	_local_button.visible = not local


func _on_model_name_value_changed(new_value: String) -> void:
	target_node.name = Util.clean_string_for_model_file_path(new_value)
	model_name_updated.emit()


func _on_save_button_pressed() -> void:
	assert(target_node is ModelRoot)
	request_save_local.emit()


func _on_convert_to_local_button_pressed() -> void:
	# This button should only be visible on valid and fully loaded SpaceObjects.
	assert(target_node is SpaceObject)
	request_convert_to_local.emit()
