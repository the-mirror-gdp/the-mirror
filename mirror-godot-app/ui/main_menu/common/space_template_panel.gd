extends PanelContainer


signal template_selected

@export var hover_theme: Theme
@export var normal_theme: Theme

@onready var _preview_image = %Preview
@onready var _title = %Title
@onready var _description = %Description

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)


# Connects and disconnects the signals based on visibility
func _on_visibility_changed() -> void:
	if self.visible:
		_connect_signals()
	else:
		_disconnect_signals()


# Sets up the panel with the correct data
func setup_panel(template_data: Dictionary) -> void:
	_title.text = template_data.name
	_description.text = template_data.get("description" ,"")
	if template_data.has("images") and not template_data.images.is_empty():
		if template_data.images[0] != null:
			_preview_image.set_image_from_url(template_data.images[0])


# Connect the signals
func _connect_signals() -> void:
	if not self.mouse_entered.is_connected(_on_mouse_entered):
		self.mouse_entered.connect(_on_mouse_entered)
	if not self.mouse_exited.is_connected(_on_mouse_exited):
		self.mouse_exited.connect(_on_mouse_exited)
	if not self.gui_input.is_connected(_on_gui_input):
		self.gui_input.connect(_on_gui_input)


# Disconnect the signals
func _disconnect_signals() -> void:
	self.mouse_entered.disconnect(_on_mouse_entered)
	self.mouse_exited.disconnect(_on_mouse_exited)
	self.gui_input.disconnect(_on_gui_input)


# Sets the theme for the hover state
func _on_mouse_entered() -> void:
	set_theme(hover_theme)


# Resets the panel to the default
func _on_mouse_exited() -> void:
	set_theme(normal_theme)


# Triggers when there is a mouse click on this panel
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_mouse_exited()
			template_selected.emit()
