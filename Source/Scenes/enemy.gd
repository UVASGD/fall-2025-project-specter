# https://www.youtube.com/watch?v=egedSO9vWH4
extends CharacterBody3D

enum {IDLE, HUNTING}
var current_state

var player : CharacterBody3D
@export var SPEED = 5
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var sfx_kill = $sfx_kill
var count = 0

func _ready() -> void:
	player = get_node(player_path)
	current_state = HUNTING

func _physics_process(delta: float) -> void:
	match current_state:
		IDLE:
			# does nothing
			velocity = Vector3.ZERO
		HUNTING:
			# follow player
			# avoid obstacles
			nav_agent.target_position = player.global_position
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point-global_position).normalized() * SPEED
			
			#look at player
			look_at(player.global_position)
		
			move_and_slide()	
			
			# kill player on contact
			if global_position.distance_to(player.global_position) < 1.05:
				current_state = IDLE
				sfx_kill.play()
				await get_tree().create_timer(0.98).timeout
				get_tree().reload_current_scene()
