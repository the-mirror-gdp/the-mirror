extends AudioStreamPlayer

@export var _target_node_paths: Array[NodePath] = []

var _target_nodes: Array[Node]


func _ready():
	for node_path in _target_node_paths:
		var node = get_node(node_path)
		if not node:
			continue
		_target_nodes.append(node)
		# call is deferred to allow all node visibility to be finalized
		node.visibility_changed.connect(check_update_stream, ConnectFlags.CONNECT_DEFERRED)
		# That previous connection will be taken care of automatically by the engine on the node being freed.


func check_update_stream() -> void:
	# only play if there is no active scene and our target menus are visible
	var any_node_visible: bool = _target_nodes.any(
		func (node):
			return is_instance_valid(node) and node.visible
	)
	var should_play: bool = any_node_visible and not Zone.Scene
	# if shouldn't be playing, stop it
	if not should_play:
		stop()
		return
	# if already playing, no action
	if is_playing():
		return
	# otherwise play
	play()
