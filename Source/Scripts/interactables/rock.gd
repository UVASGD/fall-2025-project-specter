extends Interactable


func interact(player: Player) -> void:
	player.has_throwable = true
	player.hand.visible = true
	queue_free()
