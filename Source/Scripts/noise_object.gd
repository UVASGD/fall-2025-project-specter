extends CollisionShape3D

func update_noise_level(noise_val):
	shape.radius = noise_val

func _on_noise_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.HUNTING)

func _on_noise_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.SEARCHING)
