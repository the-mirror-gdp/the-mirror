## Attach this node in the scene and it will process the array of constraint
## resources on either bones or nodes, whatever the constraints reference.
@tool
@icon("icons/bone_node_constraint_applier.svg")
class_name BoneNodeConstraintApplier
extends Node


@export var constraints: Array[BoneNodeConstraint] = []


func _ready() -> void:
	for constraint in constraints:
		constraint.set_node_references_from_paths(self)


func _process(_delta: float) -> void:
	for constraint in constraints:
		constraint.evaluate()
