extends MarginContainer

@onready var _name_label = %NameLabel
@onready var _tab_pages_buttons = %TabPagesButtons
@onready var _tabs_scroll_container = %TabsScrollContainer
@onready var _publish_space_window = $PublishSpaceWindow

var _space: Dictionary


func _ready():
	for tab_button in _tab_pages_buttons.get_children():
		if tab_button.disabled:
			continue
		var tab = _tabs_scroll_container.find_child(tab_button.name, false)
		if tab == null:
			continue
		tab_button.pressed.connect(_on_tab_button_pressed.bind(tab_button, tab))


func populate(space: Dictionary) -> void:
	_space = space
	_name_label.text = space.get("name", "")
	for tab in _tabs_scroll_container.get_children():
		if tab and tab.has_method("populate"):
			tab.populate(space)
	_publish_space_window.hide()
	_publish_space_window.populate(space)


func _on_back_button_pressed():
	GameUI.instance.main_menu_ui.history_go_back()


func _on_tab_button_pressed(button: Button, switch_to_tab: Container):
	for tab in _tabs_scroll_container.get_children():
		tab.visible = tab == switch_to_tab
	for tab_button in _tab_pages_buttons.get_children():
		tab_button.set_pressed_no_signal(tab_button == button)


func _on_basic_space_settings_publish_space_request():
	_publish_space_window.show()
