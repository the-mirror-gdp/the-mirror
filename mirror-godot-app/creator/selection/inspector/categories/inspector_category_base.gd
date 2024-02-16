# @abstract
class_name InspectorCategoryBase
extends VBoxContainer


signal inspected_object_updated()
signal refresh_inspected_nodes()

const PROPERTY_BASE = preload("res://creator/selection/inspector/primitive/inspector_property_base.gd")

func _ready() -> void:
	var parent = self.target_node.get_parent()
	# Any target node whose parent has this method defined means that this
	# node has a parent that wants to be updated when this node changes.
	if parent and parent.has_method(&"request_change_from_children"):
		inspected_object_updated.connect(self.target_node.get_parent().request_change_from_children)
	# By setting the Y size to zero, we shrink to the minimum Y size.
	$Properties/MarginContainer.set_deferred("size.y", 0.0)
	# HACK: Due to Godot's bad ordering of @onready vars, derived classes are
	# set up first. This means that we need to duplicate _property_list in
	# each derived class, but we also need it available here in the base.
	# Proper solution: Fix Godot's initialization order of @onready vars.
	assert(&"_property_list" in self)


## This method should only be called once per instance during setup.
func set_custom_suffix(custom_suffix) -> void:
	var title_label = $CategoryTitle/ToggleButton/Name/Text
	title_label.text += custom_suffix
	name = StringName(title_label.text)


## This method should only be called once per instance during setup.
func set_visible_to_maximum_size() -> void:
	var toggle = $CategoryTitle/ToggleButton
	toggle._ready()
	toggle.set_category_visible(true)
	toggle.set_size_y(toggle.get_maximum_size_y())


func cleanup_and_delete() -> void:
	# HACK: See above, when that is resolved we can remove `self.`
	for property in self._property_list.get_children():
		if property.has_method(&"cleanup_and_delete"):
			property.cleanup_and_delete()
	queue_free()


func _inspected_object_updated(updated_node: Node) -> void:
	if updated_node is SpaceObject:
		updated_node.queue_update_network_object()
	inspected_object_updated.emit()


func update_active_fields_by_permissions() -> bool:
	var all_controls = find_children("*", "Control", true, false)
	var can_edit = Util.can_edit_object_in_space(self.target_node)
	for control in all_controls:
		if not control is PROPERTY_BASE:
			continue
		if &"enabled" in control:
			control.enabled = can_edit
		if &"_reset_button" in control:
			control._reset_button.disabled = not can_edit
	return can_edit
