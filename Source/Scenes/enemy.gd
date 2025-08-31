# https://www.youtube.com/watch?v=egedSO9vWH4
extends CharacterBody3D

enum {IDLE, HUNTING}
var current_state

var player : CharacterBody3D
@export var SPEED = 5
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	
	nav_agent.target_position = player.global_position
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point-global_position).normalized() * SPEED
	
	move_and_slide()
	
# idle
	# does nothing

# hunting
	# follow player
	# avoid obstacles
	# kill player on contact
	
