extends Control

@export var items_container_path: NodePath
@export var item_width: int = 100


func _ready():
	resized.connect(_resized)
	get_window().size_changed.connect(_resized)
	_resized()


func _resized():
	var mod_width = max(int(size.x) / item_width, 1)
	var items_container = get_node(items_container_path)
	if is_instance_valid(items_container):
		items_container.custom_minimum_size.x = mod_width * item_width
