extends Node

signal sound_emitted(position: Vector3, level: float)

var enemies: Array[Node3D] = []

func _ready():
	pass

## lets enemy hear sound
func register_enemy(enemy: Node3D):
	if not enemies.has(enemy):
		enemies.append(enemy)

## unsubscribe from sounds
func unregister_enemy(enemy: Node3D):
	enemies.erase(enemy)

func emit_sound(source_pos: Vector3, sound_level: float, source_node: Node3D = null):
	if sound_level <= 0:
		return
	sound_emitted.emit(source_pos, sound_level)
	var world = source_node.get_world_3d() if source_node else null
	var phys = world.direct_space_state
	for enemy in enemies:
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var result = SoundPropagationSystem.calculate_sound_at_listener(source_pos, enemy.global_position, sound_level, phys)
		if result.can_hear:
			if enemy.has_method("on_sound_heard"):
				enemy.on_sound_heard(source_pos, result.strength, result.wall_count)
