## Class for displaying notifications on the UI.
## NOTE: You should NEVER use this directly. Use the Notify singleton instead.
## The Notify singleton calls into NotificationsUI when it is available.
class_name NotificationsUI
extends Control


const _NOTIFICATION_POPUP: PackedScene = preload("res://ui/notifications/popup/notification_popup.tscn")
const _STATIC_POPUP: PackedScene = preload("res://ui/notifications/popup/static_popup.tscn")
const _STATIC_POPUP_LARGE: PackedScene = preload("res://ui/notifications/popup/static_popup_large.tscn")

@onready var _game_ui: Node = get_parent()
@onready var _regular_notifications_parent: VBoxContainer = %RegularNotifications
@onready var _static_notifications_parent: VBoxContainer = %StaticNotifications
@onready var _use_large_font: bool = ProjectSettings.get_setting("feature_flags/large_text_size", false)

func _process(delta: float) -> void:
	var safe_area: Rect2 = _game_ui.get_safe_area()
	position.x = safe_area.end.x - size.x
	var lerp_factor = clamp(delta * 10.0, 0.0, 1.0)
	position.y = lerp(position.y, safe_area.position.y, lerp_factor)


func is_hovering_any_notification() -> bool:
	if get_child_count() == 0:
		return false
	# get the rect of the node that is the bottomest on the scree
	var rect: Rect2 = get_child(-1).get_global_rect()
	# expand it to the left right corner of notifications_ui
	rect = rect.expand(self.global_position)
	# Check if the mouse is inside that rectangle
	return rect.has_point(get_viewport().get_mouse_position())


## Use for generic notifications.
func notify(title: String, description: String, click_callable, is_static: bool = false, is_closable: bool = true, clickable_url = null) -> Control:
	return _notify(title, description, click_callable, is_static, is_closable, clickable_url)


## Use for success messages.
func notify_success(title: String, description: String, click_callable, clickable_url = null) -> void:
	var notification_popup: Control = _notify(title, description, click_callable, false, true, clickable_url)
	notification_popup.set_notification_theme(Color(0.333, 1.0, 0.833), preload("popup/success_icon.svg"))


## Use for warning messages.
func notify_warning(title: String, description: String, click_callable, clickable_url = null) -> void:
	var notification_popup: Control = _notify(title, description, click_callable, false, true, clickable_url)
	notification_popup.set_notification_theme(Color(1.0, 0.866, 0.333), preload("popup/warning_icon.png"))


## Use for error messages.
func notify_error(title: String, description: String, click_callable, is_static: bool = false, is_closable: bool = true, clickable_url = null) -> void:
	var notification_popup: Control = _notify(title, description, click_callable, is_static, is_closable, clickable_url)
	notification_popup.set_notification_theme(Color(1.0, 0.415, 0.333), preload("popup/alert_icon.svg"))


## Specify notify status type by enum value.
func notify_status(title: String, description: String, status: Enums.NotifyStatus, click_callable) -> void:
	var notification_popup: Control = _notify(title, description, click_callable)
	match status:
		Enums.NotifyStatus.SUCCESS:
			notification_popup.set_notification_theme(Color(0.333, 1.0, 0.833), preload("popup/success_icon.svg"))
		Enums.NotifyStatus.WARNING:
			notification_popup.set_notification_theme(Color(1.0, 0.866, 0.333), preload("popup/warning_icon.png"))
		Enums.NotifyStatus.ERROR:
			notification_popup.set_notification_theme(Color(1.0, 0.415, 0.333), preload("popup/alert_icon.svg"))


func _notify(title: String, description: String, click_callable, is_static: bool = false, is_closable: bool = true, clickable_url = null) -> Control:
	self.show()
	var static_popup_res = _STATIC_POPUP_LARGE if _use_large_font else _STATIC_POPUP
	var popup: Control = static_popup_res.instantiate() if is_static else _NOTIFICATION_POPUP.instantiate()
	var parent: VBoxContainer = _static_notifications_parent if is_static else _regular_notifications_parent
	parent.add_child(popup)
	parent.move_child(popup, 0)
	popup.create_popup(title, description, is_closable)
	if click_callable:
		popup.notification_clicked.connect(click_callable)
	if clickable_url:
		popup.description_label.meta_clicked.connect(clickable_url)
	return popup
