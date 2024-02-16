class_name BaseBrowserSection
extends VBoxContainer


signal section_toggled()

@export var _section_name: String
var _asset_browser: AssetBrowser
var _asset_browser_sections: Control

@onready var _hide_timer: Timer = $HideTimer
@onready var _show_scroll_bar_timer: Timer = $ShowScrollBarTimer

@onready var _section_header_name = %Header
@onready var _section_name_label: Label = _section_header_name.get_node(^"SectionNameLabel")
@onready var _category_plus: Control = _section_header_name.get_node(^"Plus")
@onready var _category_minus: Control = _section_header_name.get_node(^"Minus")

@onready var _section_holder: ScrollContainer = get_node(^"%SectionHolder")
@onready var _section_container: VBoxContainer = get_node(^"%SectionContainer")


func _ready() -> void:
	_section_name_label.text = _section_name
	_hide_timer.timeout.connect(hide_content)
	_show_scroll_bar_timer.timeout.connect(show_scroll_bar)


func setup(asset_browser: AssetBrowser, sections: Control) -> void:
	_asset_browser = asset_browser
	_asset_browser_sections = sections


func reset() -> void:
	assert(false, "This method must be overridden in derived classes.")


func set_is_expanded(is_expanded: bool) -> void:
	_category_plus.visible = not is_expanded
	_category_minus.visible = is_expanded
	if is_expanded:
		self.show_content()
		_hide_timer.stop()
	else:
		_hide_timer.start()
		# Hides the scrollbar right away
		# This is less jarring
		_section_holder.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER


func hide_content() -> void:
	_section_holder.hide()
	# This is so that it also works on startup,
	# _hide_timer is autostart after-all
	_section_holder.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER


func show_content() -> void:
	_section_holder.show()
	# Shows the scrollbar only when near to fully uncollapsed
	# This is less jarring
	# For comparison/rational,
	# see https://github.com/the-mirror-megaverse/mirror-godot-app/pull/1393#issuecomment-1601877422
	_show_scroll_bar_timer.start()


func show_scroll_bar() -> void:
	_section_holder.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func _on_toggle_collapse_pressed() -> void:
	section_toggled.emit()
