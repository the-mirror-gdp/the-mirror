extends Control


signal request_change_subpage(subpage_name: StringName)

const _DEFAULT_TEMPLATE: String = "space_template"
const _DEFAULT_SPACE_NAME: String = "New Space"

@onready var _template_select: Control = $Pages/SelectTemplate
@onready var _finalize_create_space: Control = $Pages/CreateSpace


func _ready() -> void:
	_template_select.template_selected.connect(_on_template_selected)
	_template_select.cancel_pressed.connect(_on_template_cancel_pressed)
	_finalize_create_space.cancel_pressed.connect(_on_finalize_cancel_pressed)
	_finalize_create_space.create_pressed.connect(_on_finalize_create_pressed)


func _on_template_selected(template: Dictionary) -> void:
	GameUI.instance.main_menu_ui.change_page(&"My_Spaces")
	GameUI.instance.main_menu_ui.change_subpage(&"CreateSpace", template)


func _on_template_cancel_pressed() -> void:
	request_change_subpage.emit(&"MySpaceSelect")


func _on_new_button_pressed() -> void:
	request_change_subpage.emit(&"SelectTemplate")


func _on_finalize_cancel_pressed() -> void:
	request_change_subpage.emit(&"SelectTemplate")


func _on_finalize_create_pressed(data: Dictionary) -> void:
	if str(data.get("type", "")).is_empty():
		data["type"] = Enums.SPACE_TYPES.OPEN_WORLD
	if str(data.get("template", "")).is_empty():
		data["template"] = _DEFAULT_TEMPLATE
	if str(data.get("name", "")).is_empty():
		data["name"] = _DEFAULT_SPACE_NAME
	request_change_subpage.emit(&"MySpaceSelect")
	var promise: Promise
	if str(data.get("template_id")).is_empty():
		promise = Net.space_client.create_space(data)
	else:
		promise = Net.space_client.copy_from_template(
			data["template_id"],
			{"name": data["name"]}
		)
	GameUI.instance.main_menu_ui.hide()
	GameUI.instance.loading_ui.populate(data)
	GameUI.instance.loading_ui.populate_status("Creating space")
	GameUI.instance.loading_ui.show()
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error(tr("Space Creation Failed"), promise.get_error_message())
		GameUI.instance.loading_ui.hide()
		GameUI.instance.main_menu_ui.show()
		return
	Zone.client.quit_to_main_menu()
	GameUI.instance.loading_ui.populate_status("Joining space")
	Zone.client.start_join_zone_by_space_id(space_data["id"])
