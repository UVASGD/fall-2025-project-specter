extends Marker3D

class_name RS_Door

@export var RoomA : NodePath
@export var RoomB : NodePath

var RoomARef: RS_Room
var RoomBRef: RS_Room

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RoomARef = get_node(RoomA)
	RoomBRef = get_node(RoomB)
