extends Area3D

signal start_dialogue(text_array: Array[String])

@export var dialogue : Array[String] = []
@onready var player = %Player

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		start_dialogue.emit(dialogue)
		queue_free()
