class_name InteractableReading
extends Interactable


@export var reading: CompressedTexture2D


func interact(player: Player) -> void:
	player.start_reading(reading)
