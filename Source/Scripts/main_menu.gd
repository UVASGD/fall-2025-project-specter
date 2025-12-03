extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Source/Scenes/gameplay.tscn")

func _on_credits_pressed() -> void:
	print("... we don't have credits yet")
