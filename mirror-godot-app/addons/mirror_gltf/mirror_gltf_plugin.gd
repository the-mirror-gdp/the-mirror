@tool
extends EditorPlugin


func _enter_tree():
	# NOTE: Be sure to also instance and register at runtime.
	# This editor plugin script won't run in the actual game.
	var ext = GLTFDocumentExtensionMirrorModelPrimitive.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionMirrorEquipable.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionVRMNodeConstraint.new()
	GLTFDocument.register_gltf_document_extension(ext)
