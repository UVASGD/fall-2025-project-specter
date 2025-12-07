extends Interactable


signal lever_down
signal lever_up

var is_down: bool = false


func interact(_player: Player) -> void:
	rotate_y(PI)
	if is_down:
		lever_up.emit()
		is_down = false
	else:
		lever_down.emit()
		is_down = true
	
	# make sound w new system
	SoundManager.emit_sound(global_position, 25.0, self)
	
