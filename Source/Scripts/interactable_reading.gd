class_name InteractableReading
extends Interactable


@export var reading: PackedScene


func interact(player: Player) -> void:
	player.start_reading(reading)
