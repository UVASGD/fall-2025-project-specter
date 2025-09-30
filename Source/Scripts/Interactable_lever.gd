class_name InteractableLever
extends Interactable


var is_down: bool = false


func interact(_player: Player) -> void:
	if is_down:
		lever_pulled_down()
		is_down = false
	else:
		lever_pulled_up()
		is_down = true


func lever_pulled_down() -> void:
	pass


func lever_pulled_up() -> void:
	pass
