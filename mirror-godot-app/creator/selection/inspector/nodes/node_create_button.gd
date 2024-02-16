extends Button


# I would love to make the inspector an @export var here but it's buggy :(
@onready var _inspector: Control = $"../../../../../.."
@onready var _extra_node_creation_dialog: ConfirmationDialog = $ExtraNodeCreationDialog
@onready var _extra_node_creation_menu: Control = $ExtraNodeCreationDialog/ExtraNodeCreationMenu


func open_extra_node_create_dialog(parent_name: StringName = &"") -> void:
	assert(_inspector != null)
	var target_space_object = _inspector.get_single_selected_space_object()
	assert(target_space_object is SpaceObject)
	if parent_name.is_empty():
		var model_node = target_space_object.scaled_model.get_model_root_node()
		if model_node:
			parent_name = model_node.name
	_extra_node_creation_menu.populate_for_target(target_space_object, parent_name)
	_extra_node_creation_dialog.popup_centered()


func _on_extra_node_creation_dialog_confirmed():
	if not _extra_node_creation_menu.perform_desired_node_creation():
		_extra_node_creation_dialog.show()
