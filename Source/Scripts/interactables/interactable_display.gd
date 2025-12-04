class_name InteractableDisplay
extends Interactable


@export var display: TextureRect


func _ready() -> void:
	super()
	if display:
		display.visible = false


func interact(player: Player) -> void:
	player.start_looking_at_display(display)
