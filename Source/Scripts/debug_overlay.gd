extends CanvasLayer

@onready var debug_panel = $Panel
@onready var debug_label = $Panel/MarginContainer/VBoxContainer/DebugLabel

var player
var enemy: Node3D
var enabled: bool = true

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	enemy = get_tree().get_first_node_in_group("Enemy")

func _input(event):
	if event.is_action_pressed("debug_toggle"):
		enabled = !enabled
		debug_panel.visible = enabled

func _process(_delta):
	var debug_text = ""
	await get_tree().process_frame
	if not enabled or not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	await get_tree().process_frame
	# Player shit
	if is_instance_valid(player):
		debug_text += "[b]PLAYER[/b]\n"
		debug_text += "pos: %s\n" % _vec3_str(player.global_position)
		debug_text += "noise: %.2f\n" % player.noise_level
		debug_text += "movement type: %s\n" % _get_movement_state_name(player.movement_state)
		debug_text += "stamina: %.1f\n" % player.stamina
		debug_text += "holdign breath: %s\n" % ("YES" if player.holding_breath else "NO")
		debug_text += "\n"
	
	# Enemy shit
	if is_instance_valid(enemy):
		debug_text += "[b]SPIBER[/b]\n"
		debug_text += "pos: %s\n" % _vec3_str(enemy.global_position)
		debug_text += "state: [color=yellow]%s[/color]\n" % _get_enemy_state_name(enemy.current_state)
		debug_text += "speed: %.2f\n" % enemy.SPEED
		debug_text += "dist: %.2f m\n" % enemy.global_position.distance_to(player.global_position)
		debug_text += "\n"
	
		# sound
		debug_text += "[b]SOUND[/b]\n"
		debug_text += "last sound strength: %.2f\n" % enemy.ls_strength
		debug_text += "time since sound: %.2f s\n" % enemy.ls_time
	
	if player.noise_level > 0:
		var world = player.get_world_3d()
		if world:
			var physics_space = world.direct_space_state
			var result = SoundPropagationSystem.calculate_sound_at_listener(
				player.global_position,
				enemy.global_position,
				player.noise_level,
				physics_space
			)
			
			debug_text += "[color=cyan]detection info:[/color]\n"
			debug_text += "  can hear: [color=%s]%s[/color]\n" % ["green" if result.can_hear else "red", "YES" if result.can_hear else "NO"]
			debug_text += "  sound strength: %.2f\n" % result.strength
			debug_text += "  walls: %d\n" % result.wall_count
	else:
		debug_text += "[color=gray]bro quiet af[/color]\n"
	
	debug_text += "\n"
	
	debug_text += "[b]ECHOLOCATION[/b]\n"
	debug_text += "coldown: %.2f s\n" % max(0, enemy.echolocation_timer)
	debug_text += "range: %.1f m\n" % enemy.ECHOLOCATION_RANGE
	debug_text += "\n"
	
	debug_label.text = debug_text

func _vec3_str(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]

func _get_movement_state_name(state: int) -> String:
	match state:
		0: return "IDLE"
		1: return "CROUCH"
		2: return "CROUCH_SPRINT"
		3: return "WALK"
		4: return "SPRINT"
		5: return "READING"
		_: return "UNKNOWN"

func _get_enemy_state_name(state: int) -> String:
	match state:
		0: return "IDLE"
		1: return "ROAMING"
		2: return "SEARCHING"
		3: return "HUNTING"
		_: return "UNKNOWN"
