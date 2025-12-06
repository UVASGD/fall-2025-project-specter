extends RigidBody3D

var rock_scene: PackedScene = preload("res://Source/Scenes/Interactables/rock.tscn")

func _physics_process(_delta: float) -> void:
	if get_contact_count() and not sleeping:
		SoundManager.emit_sound(global_position, 7.0, self)
		return
	
	if sleeping:
		var rock: Interactable = rock_scene.instantiate()
		get_parent().add_child(rock)
		rock.global_position = global_position
		queue_free()
