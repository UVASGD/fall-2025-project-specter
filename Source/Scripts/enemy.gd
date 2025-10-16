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
var menace_gauges = []
var SPEED = 5

class menace_gauge:
	var value : float
	var pos : Vector3
	
	func _init(noise_level, noise_position) -> void:
		value = (noise_level * 10)
		pos = noise_position
	
	func increase(num, new_pos = null):
		value += num
		if value > 100: value = 100
		if new_pos: pos = new_pos
	
	func reduce(num) -> bool:
		value -= num
		return value > 0

func _physics_process(_delta: float) -> void:
	get_room_points(AABB(Vector3(0,0,0), Vector3(150, 1, 150)), 10, 1.0)
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

func hear_sound(noise_level : float, pos : Vector3):
	var to_delete = []
	for i in range(menace_gauges.size()):
		if !menace_gauges[i].reduce(10): to_delete.append(i)
	for i in to_delete:
		menace_gauges.erase(i)
	
	menace_gauges.append(menace_gauge.new(noise_level, pos))

func get_room_points(area_aabb: AABB, max_attempts = 10, tolerance = 1.0):
	var RADIUS = 15
	var output = []
	var t = Time.get_ticks_usec()
	
	var nav_map = nav_agent.get_navigation_map()
	var num_cycles = ceil((area_aabb.size.x * area_aabb.size.z) / ((2*RADIUS) ** 2))
	for i in range(num_cycles):
		for j in range(max_attempts):
			var rand_x = randf_range(area_aabb.position.x, area_aabb.position.x + area_aabb.size.x)
			var rand_z = randf_range(area_aabb.position.z, area_aabb.position.z + area_aabb.size.z)
			
			var test_point = Vector3(rand_x, area_aabb.position.y, rand_z)
			var nav_point = NavigationServer3D.map_get_closest_point(nav_map, test_point)
			
			var too_close = false
			if output.size() > 0:
				too_close = true
				for p in output:
					if nav_point.distance_to(p) > tolerance:
						too_close = false
						break
				
			if !too_close and Vector2(nav_point.x, nav_point.z).distance_to(Vector2(rand_x, rand_z)) < tolerance:
				output.append(nav_point)
				break;
	
	print(num_cycles, " ", output.size(), " ", (Time.get_ticks_usec() - t))
	return output
