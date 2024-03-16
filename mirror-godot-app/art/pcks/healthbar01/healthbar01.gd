extends JBody3D

@onready var sprite_3d = $Sprite3D


func _ready():
	sprite_3d.material_override = sprite_3d.material_override.duplicate()


func _process(delta):
	var current_so: SpaceObject = Util.get_space_object(self)
	if not is_instance_valid(current_so):
		return
	var so_name: String = current_so.get_space_object_name()
	# name of current space object is id of object to attach to
	var search = Zone.instance_manager.get_all_instances().filter(func(x): return so_name == x.name)
	if search.size() != 1 or not is_instance_valid(search[0]):
		return
	var target = search[0]
	var value = target.get_health()/100.0
	sprite_3d.material_override.set_shader_parameter("health", value)
