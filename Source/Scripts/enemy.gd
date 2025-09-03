# https://www.youtube.com/watch?v=egedSO9vWH4
extends CharacterBody3D

enum {IDLE, ROAMING, SEARCHING, HUNTING}
@onready var current_state = IDLE

@export var SPEED = 5
@onready var player = %Player
@onready var nav_agent = $NavigationAgent3D
@onready var sfx_kill = $sfx_kill
var target_pos : Vector3

func _physics_process(_delta: float) -> void:
	if current_state == IDLE:
		# does nothing
		velocity = Vector3.ZERO
	else: 
		if current_state == HUNTING:
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
		
		# kill player on contact
		if global_position.distance_to(player.global_position) < 1.05:
			sfx_kill.play()
			await get_tree().create_timer(0.98).timeout
			get_tree().reload_current_scene()
			
	print(current_state)
