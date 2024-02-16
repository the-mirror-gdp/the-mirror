extends MarginContainer


signal on_template_selected(template: MirrorMaterial.SHADER_TYPE)


func _on_template_standard_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.STANDARD)


func _on_template_opacity_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.OPACITY_MASKED)


func _on_template_displaced_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.DISPLACED)


func _on_template_foliage_pressed() -> void:
	#TODO: Implement foliage type
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.STANDARD)


func _on_template_glass_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.GLASS)


func _on_template_water_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.WATER)


func _on_template_varnish_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.VARNISH)


func _on_template_fabric_pressed() -> void:
	# TODO: Implement fabric type
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.STANDARD)


func _on_template_shader_pressed() -> void:
	on_template_selected.emit(MirrorMaterial.SHADER_TYPE.CUSTOM_SHADER)
