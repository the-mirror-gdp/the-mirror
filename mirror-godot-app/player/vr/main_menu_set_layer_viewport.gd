extends OpenXRCompositionLayerQuad


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layer_viewport = await GameUI.get_sub_viewport()
	print("Configured viewport")
