extends GizmoHandle


@onready var _ring_highlight = $RotationRingHighlight


func _ready() -> void:
	desired_body_id = TMSceneSync.fetch_free_unsync_body_id()
	body_mode = JBody3D.KINEMATIC
	set_layer_name(&"GIZMO")
	create_body()
	hide_gizmo()


func start_highlight():
	super()
	_ring_highlight.visible = true


func stop_highlight():
	super()
	_ring_highlight.visible = false


func show_gizmo():
	set_layer_name(&"GIZMO")
	show()


func hide_gizmo():
	set_layer_name(&"")
	hide()
