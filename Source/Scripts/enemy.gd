# https://www.youtube.com/watch?v=egedSO9vWH4
extends CharacterBody3D

enum {IDLE, ROAMING, SEARCHING, HUNTING}
@onready var current_state = IDLE

@onready var player = %Player
@onready var nav_agent = $NavigationAgent3D
@onready var sfx_kill = $sfx_kill
@onready var sfx_echo = $sfx_echo
@onready var timer = $Timer
@onready var rc = $RayCast3D

var target_pos : Vector3
var search_pos : Vector3
var SPEED = 5

func _physics_process(_delta: float) -> void:
	match current_state:
		IDLE:
			velocity = Vector3.ZERO
		ROAMING:
			# avoid obstacles
			nav_agent.target_position = target_pos
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point-global_position).normalized() * SPEED
		
			#look at player
			look_at(target_pos)
		
			move_and_slide()
		
			if global_position.distance_to(player.global_position) < 1.05:
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()
				
			if global_position.distance_to(target_pos) < 1.05 or velocity.length() < 2:
				change_state(IDLE)
		SEARCHING: 
			# avoid obstacles
			nav_agent.target_position = target_pos
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point-global_position).normalized() * SPEED
		
			#look at player
			look_at(target_pos)
		
			move_and_slide()
		
			if global_position.distance_to(player.global_position) < 1.05:
				current_state = IDLE
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()
				
			if global_position.distance_to(target_pos) < 1.05 or velocity.length() < 2:
				if not sfx_echo.playing and RandomNumberGenerator.new().randf() < 0.33:
					echolocate()
				set_search_point()
		HUNTING: 
			target_pos = player.global_position
		
			# avoid obstacles
			nav_agent.target_position = target_pos
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point-global_position).normalized() * SPEED
		
			#look at player
			look_at(target_pos)
		
			move_and_slide()
		
			if global_position.distance_to(target_pos) < 1.05:
				current_state = IDLE
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()


func change_state(state):
	current_state = state
	match state:
		IDLE:
			timer.stop()
		ROAMING:
			timer.stop()
		SEARCHING:
			SPEED = 2.5
			var timer_len = ((25 - global_position.distance_to(player.global_position)) * player.noise_level) #TODO balance values
			timer.start(timer_len)
			search_pos = target_pos
			set_search_point()
		HUNTING:
			SPEED = 5
			timer.stop()

func set_search_point():
	var rng = RandomNumberGenerator.new()
	var alpha = 2 * PI * rng.randf()
	var r = rng.randf_range(1, 5)
	var rand_pnt = Vector3(r * cos(alpha), 0, r * sin(alpha))
	
	target_pos = search_pos + rand_pnt

func _on_timer_timeout() -> void:
	change_state(ROAMING)
	
func echolocate():
	sfx_echo.play()
	
	var angle = global_position.signed_angle_to(player.global_position, Vector3.UP)
	if abs(global_position.signed_angle_to(player.global_position, Vector3.UP)) <= PI / 6  and global_position.distance_to(player.global_position) <= 10:
		rc.set_enabled(true)
		rc.target_position = player.global_position
		rc.force_raycast_update()
		if rc.get_collider() == player:
			target_pos = player.global_position
			set_search_point()
			target_pos = player.global_position
		rc.set_enabled(false)
		
func handle_noise(noise_level, noise_pos):
	# distance to sound -- sound level emitted to the point -- enemy calculates the sound level it hears
	var dist = global_position.distance_to(noise_pos)
	#player_noise.radius = noise_level * 5
	#var noise_val = noise_level*(20/global_position.distance_to(pos))
	
