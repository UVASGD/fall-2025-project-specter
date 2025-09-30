class_name NoiseComponent extends Area3D

@onready var shape = $CollisionShape3D.shape
@onready var enabled = false

func set_enabled(b):
	enabled = b
	
func update_noise_level(noise_val):
	if enabled:
		shape.radius = noise_val
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.HUNTING)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.SEARCHING)
