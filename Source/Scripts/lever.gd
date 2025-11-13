extends Interactable


signal lever_down
signal lever_up

var is_down: bool = false
@onready var door_2: AnimatableBody3D = $Door2

func interact(_player: Player) -> void:
	if is_down:
		lever_up.emit()
		is_down = false
	else:
		lever_down.emit()
		is_down = true
	
	# make sound w new system
	SoundManager.emit_sound(global_position, 25.0, self)
	door_2.open()
