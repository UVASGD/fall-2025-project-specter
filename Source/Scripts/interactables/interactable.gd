class_name Interactable
extends StaticBody3D


func _ready() -> void:
	# set_collision_layer_value(1, false)
	set_collision_layer_value(2, true)


func interact(_player: Player) -> void:
	pass
