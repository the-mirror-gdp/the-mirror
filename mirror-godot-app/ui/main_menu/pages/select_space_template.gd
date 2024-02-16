extends Control


signal template_selected(template: Dictionary)
signal cancel_pressed()

@export var template_panel: PackedScene
@onready var _grid = %Grid
@onready var _loading_spinner = %LoadingSpinner
@onready var _fill_to_parent_container = %FillToParentContainer


var _last_item_size = Vector2.ZERO

func _ready() -> void:
	await LoginUI.wait_till_login(get_tree())
	_load_template_spaces()
	get_window().size_changed.connect(_container_fit_to_templates)


func _container_fit_to_templates() -> void:
	_fill_to_parent_container.custom_minimum_size.y = 0
	_fill_to_parent_container.size_flags_horizontal = SIZE_FILL
	await get_tree().process_frame
	await get_tree().process_frame
	var parent_size = _fill_to_parent_container.get_parent_area_size()
	var grid_size = _grid.size
	var max_height = min(grid_size.y, parent_size.y)
	var max_width = min(grid_size.x, parent_size.x)
	if _last_item_size.y > 0:
		var _grid_separation = _grid.get("theme_override_constants/v_separation")
		# we add  _grid_separation to max_height to have an separtor per item for modulo operation
		var mod = (int(max_height + _grid_separation) % int(_last_item_size.y + _grid_separation))
		max_height = max_height - mod
		max_height = max(max_height, _last_item_size.y + _grid_separation)
		# Now do similar math for width
		var _grid_separation_w = _grid.get("theme_override_constants/h_separation")
		# we add  _grid_separation to max_height to have an separtor per item for modulo operation
		var mod_w = (int(max_width + _grid_separation_w) % int(_last_item_size.x + _grid_separation_w))
		max_width = max_width - mod_w
		max_width = max(max_width, _last_item_size.x + _grid_separation_w)
	_fill_to_parent_container.size_flags_horizontal = SIZE_SHRINK_CENTER
	_fill_to_parent_container.custom_minimum_size.y = max_height
	_fill_to_parent_container.custom_minimum_size.x = max_width


func _load_template_spaces() -> void:
	_loading_spinner.visible = true
	var promise = Net.space_client.get_space_templates()
	var spaces = await promise.wait_till_fulfilled()
	_loading_spinner.visible = false
	if promise.is_error():
		Notify.error(tr("Error on Template Spaces"), promise.get_error_message())
		return
	_add_templates_to_grid(spaces)
	_container_fit_to_templates()


# Sets up the space templates
func _add_templates_to_grid(spaces) -> void:
	for template in spaces:
		var panel = template_panel.instantiate()
		_grid.add_child(panel)
		panel.setup_panel(template)
		panel.template_selected.connect(_on_template_selected.bind(template))
		_last_item_size = panel.size


# Triggers when a template is selected
func _on_template_selected(template: Dictionary) -> void:
	template_selected.emit(template)


func _on_cancel_pressed():
	cancel_pressed.emit()


func _on_scroll_container_visibility_changed():
	_container_fit_to_templates()
