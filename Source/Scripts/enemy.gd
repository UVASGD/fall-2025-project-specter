# https://www.youtube.com/watch?v=egedSO9vWH4
extends CharacterBody3D

enum {IDLE, ROAMING, SEARCHING, HUNTING}
@onready var current_state = IDLE

@export var SPEED = 5
@onready var player = %Player
@onready var nav_agent = $NavigationAgent3D
@onready var sfx_kill = $sfx_kill
@onready var sfx_echo = $sfx_echo
@onready var timer = $Timer
var target_pos : Vector3
var search_pos : Vector3

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
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()
				
			if global_position.distance_to(target_pos) < 1.05 or velocity.length() < 2:
				#TODO Add echolocate
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
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()
	
	if not timer.is_stopped(): print(timer.time_left)

func change_state(state):
	current_state = state
	
	if state == SEARCHING:
		var timer_len = ((25 - global_position.distance_to(player.global_position)) * player.noise_level) #TODO balance values
		timer.start(timer_len)
		search_pos = target_pos
		set_search_point()
	else:
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
