extends Node

class_name RS_Room

@export var Colliders : NodePath
@export var Nodes : NodePath

var CollidersParent: Node
var WaypointsParent: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CollidersParent = get_node(Colliders)
	WaypointsParent = get_node(Nodes)
