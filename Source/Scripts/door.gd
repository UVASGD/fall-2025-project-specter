extends AnimatableBody3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func open():
	print("door opening")
	animation_player.play("door_open")
	
