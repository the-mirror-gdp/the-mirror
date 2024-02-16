extends Node


signal vr_started
signal vr_ended


var vr_interface: XRInterface
var vr_is_active: bool = false


func _ready() -> void:
	vr_interface = XRServer.find_interface('OpenXR')
	if not vr_interface:
		return
	if not vr_interface.is_initialized():
		print("OpenXR: Initializing interface")
		if not vr_interface.initialize():
			print("OpenXR: Failed to initialize")
			return
	vr_interface.connect("session_focussed", _on_vr_enter)
	vr_interface.connect("session_visible", _on_vr_exit)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_vr_enter() -> void:
	if Zone.is_host():
		return
	if not vr_is_active:
		vr_is_active = true
		vr_started.emit()
		print("OpenXR: VR started (on_vr_enter)")


func _on_vr_exit() -> void:
	if Zone.is_host():
		return
	if vr_is_active:
		vr_is_active = false
		vr_ended.emit()
		print("OpenXR: VR ended (on_vr_exit)")
