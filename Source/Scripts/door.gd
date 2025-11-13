extends AnimatableBody3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var can_open = true

func open():
	if(can_open):
		print("door opening")
		animation_player.play("door_open")
		can_open = false
