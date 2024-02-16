extends Container


signal section_expanded()

var _free_space: float
var _active_section: BaseBrowserSection

@onready var _sections: Array[BaseBrowserSection] = []


func _ready() -> void:
	Zone.client.join_server_complete.connect(reset_sections)
	for child in get_children():
		assert(child is BaseBrowserSection)
		_sections.append(child)
		child.section_toggled.connect(toggle_active_section.bind(child))


func _process(delta: float) -> void:
	_resize_sections(delta * 10.0)
	_layout_top_to_bottom()


func setup(asset_browser: AssetBrowser) -> void:
	for section in _sections:
		section.setup(asset_browser, self)


func clear_active_section() -> void:
	_active_section = null
	for section in _sections:
		section.set_is_expanded(false)


func expand_first_section() -> void:
	_active_section = _sections[0]
	_active_section.set_is_expanded(true)
	for i in range(1, _sections.size()):
		_sections[i].set_is_expanded(false)


func toggle_active_section(toggled_section: BaseBrowserSection) -> void:
	for section in _sections:
		section.set_is_expanded(false)
	if _active_section == toggled_section:
		_active_section = null
	else:
		_active_section = toggled_section
		_active_section.set_is_expanded(true)
		section_expanded.emit()


func reset_sections() -> void:
	for section in _sections:
		section.reset()


func _resize_sections(weight: float) -> void:
	var available_space: float = size.y
	for section in _sections:
		if section == _active_section:
			continue
		section.size.y = lerpf(section.size.y, section.custom_minimum_size.y, weight)
		available_space -= section.size.y
	if _active_section:
		_free_space = lerpf(_free_space, 0.0, weight)
		_active_section.size.y = available_space - _free_space
	else:
		_free_space = available_space


func _layout_top_to_bottom() -> void:
	var pos := Vector2.ZERO
	for section in _sections:
		section.position = pos
		pos.y += section.size.y
