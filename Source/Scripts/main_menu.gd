extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Source/Scenes/House_Level.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Source/Scenes/credits.tscn")
