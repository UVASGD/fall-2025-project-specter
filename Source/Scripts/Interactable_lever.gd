class_name InteractableLever
extends Interactable


signal lever_down
signal lever_up
@onready var noise_area: Area3D = $Noise

var is_down: bool = false

func interact(_player: Player) -> void:
	if is_down:
		lever_up.emit()
		is_down = false
	else:
		lever_down.emit()
		is_down = true
	
	print("NOISE ACTIVATED")
	noise_area.set_enabled(true)
	noise_area.update_noise_level(40)
	await get_tree().create_timer(1.0).timeout
	noise_area.update_noise_level(0)
	
