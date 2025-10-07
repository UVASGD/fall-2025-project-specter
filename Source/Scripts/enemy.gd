extends CharacterBody3D

enum {IDLE, ROAMING, SEARCHING, HUNTING}
@onready var current_state = ROAMING

# for debug
func _enter_tree():
	add_to_group("Enemy")

@onready var player = %Player
@onready var nav_agent = $NavigationAgent3D
@onready var sfx_kill = $sfx_kill
@onready var sfx_echo = $sfx_echo
@onready var timer = $Timer
@onready var rc = $RayCast3D

var target_pos : Vector3
var search_pos : Vector3
var roam_target : Vector3
var SPEED = 3.0
const ROAM_SPEED = 2.0
const SEARCH_SPEED = 2.5
const HUNT_SPEED = 5.0

#ls = last sound
var ls_pos : Vector3
var ls_strength : float = 0.0
var memory : float = 5.0
var ls_time : float = 999.0


const ECHOLOCATION_RANGE = 15.0
const ECHOLOCATION_ANGLE = PI / 4
const ECHOLOCATION_COOLDOWN = 3.0
const ECHOLOCATION_COOLDOWN_SEARCHING = 1.5
const ECHOLOCATION_COOLDOWN_HUNTING = 1.0
var echolocation_timer : float = 0.0

const ROAM_RADIUS = 10.0
const PLAYER_BIAS = 0.3
var roam_wait_time : float = 0.0

func _ready():
	SoundManager.register_enemy(self) #give bro ears
	roam_target = global_position
	set_new_roam_target()
	sfx_kill.volume_db = -14

func _exit_tree():
	SoundManager.unregister_enemy(self)

func _physics_process(delta: float) -> void:
	ls_time += delta
	echolocation_timer -= delta
	roam_wait_time -= delta
	if global_position.distance_to(player.global_position) < 2:
		kill_player()
		return
	
	match current_state:
		IDLE:
			velocity = Vector3.ZERO
			if roam_wait_time <= 0:
				change_state(ROAMING)
		
		ROAMING:
			if global_position.distance_to(roam_target) < 2.0 or roam_wait_time <= 0:
				set_new_roam_target()
				roam_wait_time = randf_range(3.0, 6.0)
			nav_agent.target_position = roam_target
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * SPEED
			if velocity.length() > 0.1:
				look_at(global_position + velocity.normalized())
			
			move_and_slide()
			
			# sometimes echolocate when roamig
			if echolocation_timer <= 0 and randf() < 0.1:
				echolocate()

		SEARCHING:
			if global_position.distance_to(target_pos) < 1.5:
				set_search_point()
			nav_agent.target_position = target_pos
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * SPEED
			if velocity.length() > 0.1:
				look_at(global_position + velocity.normalized())
			move_and_slide()
			
			if echolocation_timer <= 0:
				echolocate()
			if ls_time > memory:
				change_state(ROAMING)
		HUNTING:
			target_pos = ls_pos
			nav_agent.target_position = target_pos
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * SPEED	
			if velocity.length() > 0.1:
				look_at(global_position + velocity.normalized())
			
			move_and_slide()
			
			if echolocation_timer <= 0:
				echolocate()
			if global_position.distance_to(target_pos) < 2.0 or ls_time > 3.0:
				change_state(SEARCHING)


func change_state(state):
	if current_state == state:
		return
	current_state = state
	match state:
		IDLE:
			SPEED = 0.5
			roam_wait_time = randf_range(2.0, 4.0)
		ROAMING:
			SPEED = ROAM_SPEED
			set_new_roam_target()
		SEARCHING:
			SPEED = SEARCH_SPEED
			search_pos = ls_pos
			set_search_point()
		HUNTING:
			SPEED = HUNT_SPEED

func set_search_point():
	var angle = randf() * 2 * PI
	var radius = randf_range(2.0, 5.0)
	var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	target_pos = search_pos + offset

func set_new_roam_target():
	var bias = randf()
	if bias < PLAYER_BIAS:
		var to_player = (player.global_position - global_position).normalized()
		var angle_offset = randf_range(-PI/3, PI/3)  # +/- 60 degrees
		var rotated = to_player.rotated(Vector3.UP, angle_offset)
		var distance = randf_range(5.0, ROAM_RADIUS)
		roam_target = global_position + rotated * distance
	else:
		var angle = randf() * 2 * PI
		var radius = randf_range(5.0, ROAM_RADIUS)
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		roam_target = global_position + offset

	roam_target.y = global_position.y

func _on_timer_timeout() -> void:
	if current_state == SEARCHING:
		change_state(ROAMING)

func echolocate():
	if echolocation_timer > 0:
		return
	sfx_echo.play()
	match current_state:
		HUNTING:
			echolocation_timer = ECHOLOCATION_COOLDOWN_HUNTING
		SEARCHING:
			echolocation_timer = ECHOLOCATION_COOLDOWN_SEARCHING
		_:
			echolocation_timer = ECHOLOCATION_COOLDOWN
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()
	
	if distance > ECHOLOCATION_RANGE:
		#print("echo too far (%.1fm)" % distance)
		return
	var in_zone = false
	
	if current_state == SEARCHING:
		in_zone = true
	else:
		var forward = -transform.basis.z
		var plangle = forward.angle_to(direction)
		in_zone = plangle <= ECHOLOCATION_ANGLE
	
	if in_zone:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0, 1, 0),
			player.global_position + Vector3(0, 1, 0)
		)
		query.collision_mask = 1
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			ls_pos = player.global_position
			ls_strength = 100.0
			ls_time = 0.0
			if current_state != HUNTING:
				change_state(HUNTING)
		elif result.collider == player:
			ls_pos = player.global_position
			ls_strength = 100.0
			ls_time = 0.0
			if current_state != HUNTING:
				change_state(HUNTING)
		else:
			#print(" blocked - %s" % result.collider.name)
			return

func on_sound_heard(sound_pos: Vector3, strength: float, wall_count: int):
	ls_pos = sound_pos
	ls_strength = strength
	ls_time = 0.0
	
	print("heard - strength: %.2f, walls: %d, dist: %.1fm" % [strength, wall_count, global_position.distance_to(sound_pos)])
	
	if strength >= 2.5:
		#print("Loud")
		change_state(HUNTING)
	elif strength >= 1.0:
		if current_state == ROAMING or current_state == IDLE:
			#print("medium sound")
			change_state(SEARCHING)
	elif strength >= 0.5:
		if current_state == ROAMING or current_state == IDLE:
			#print("quiet sound")
			search_pos = sound_pos

func kill_player():
	sfx_kill.play()
	current_state = IDLE
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.98).timeout
	if get_tree():
		get_tree().reload_current_scene()

func handle_noise(noise_level, noise_pos):

	pass
	
