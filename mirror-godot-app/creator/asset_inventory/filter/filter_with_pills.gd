extends HBoxContainer

@onready var filter_button = %FilterButton
@onready var _sort_pill_badge = %SortPillBadge
@onready var _category_pill_badge = %CategoryPillBadge
@onready var _graphics_pill_badge = %GraphicsPillBadge
@onready var _asset_type_pill_badge = %AssetTypePillBadge


# Called when the node enters the scene tree for the first time.
func _ready():
	filter_button.filter_menu.changed.connect(_on_filter_changed)


func _on_filter_changed(sort_by, order, tags, asset_type):
	_sort_pill_badge.visible = sort_by != "updatedAt" or order != 'desc'
	_sort_pill_badge.text = filter_button.filter_menu.get_sort_by_name()

	_category_pill_badge.visible = tags.size() > 0
	if tags.size() > 0:
		var tag_names = filter_button.filter_menu.get_tags_names()
		_category_pill_badge.text = str(tag_names[0])

	_asset_type_pill_badge.visible = filter_button.filter_menu.filter_asset_type and asset_type != 'MESH,AUDIO,IMAGE'
	_asset_type_pill_badge.text = filter_button.filter_menu.get_asset_type_name()


func _on_sort_pill_badge_close_pressed():
	filter_button.filter_menu.reset_sort_by()


func _on_category_pill_badge_close_pressed():
	filter_button.filter_menu.reset_category()


func _on_asset_type_pill_badge_close_pressed():
	filter_button.filter_menu.reset_asset_type()


func _on_visibility_changed():
	_asset_type_pill_badge.visible = filter_button.filter_menu.filter_asset_type and  filter_button.filter_menu.get_asset_type() != 'MESH,AUDIO,IMAGE'


func _on_badge_pressed():
	filter_button.show_menu()
