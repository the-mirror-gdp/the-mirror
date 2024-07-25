extends Control

@onready var _reloadable_items = [
	$Pages/HomeSpaceSelect/VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/SpacesSectionPopular,
	$Pages/HomeSpaceSelect/VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/SpacesSectionRecents,
	$Pages/HomeSpaceSelect/VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/SpacesSectionFavorites,
	$Pages/HomeSpaceSelect/VBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer/SpacesSectionMy
]


func _on_view_my_spaces_pressed():
	GameUI.instance.main_menu_ui.change_page(&"My_Spaces")


func _on_reload_pressed():
	for home_page_section in _reloadable_items:
		home_page_section.fetch_and_populate()
