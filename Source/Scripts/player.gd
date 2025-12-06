class_name Player
extends CharacterBody3D


enum {IDLE, CROUCH, CROUCH_SPRINT, WALK, SPRINT, READING, LOOKING_AT_DISPLAY}

# for debug
func _enter_tree():
	add_to_group("Player")


@export var SPEED = 5.0
@export var SPRINT_SPEED = 1.5
@export var CROUCH_SPEED = 0.5
@export var JUMP_VELOCITY = 4.5
@export var SENSITIVITY = 0.005
@export var debug_topdown_mode = false


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var ray_cast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hand: Node3D = $Head/Camera3D/Hand
@onready var stamina_timer = $StaminaTimer
@onready var hud = %HUD

@onready var bflyscene:PackedScene = preload("res://Source/Scenes/bfly.tscn")
@onready var throwable_scene: PackedScene = preload("res://Source/Scenes/thrown_rock.tscn")

var movement_state
var crouch = false
var recovering = false
var holding_breath = false
var stamina = 100.0
var noise_level : float
var eggstack = []
var eggtimer = 0

var has_throwable: bool = false


func _ready():
	if not debug_topdown_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	eggtimer += delta
	if movement_state == LOOKING_AT_DISPLAY:
		return
	
	movement_state = IDLE
	
	if Input.is_action_just_released("pee"):
		eggstack.push_front(0)
	elif Input.is_action_just_released("bee"):
		eggstack.push_front(1)
	if eggstack == [1,0,1,0,1,0] or eggtimer >= 10:
		eggtimer = 0
		if eggstack == [1,0,1,0,1,0]:
			var bfly = bflyscene.instantiate()
			get_tree().root.add_child(bfly)
			var player_transform = get_global_transform()
			var forward_vector = -player_transform.basis.z
			bfly.rotation.z = self.rotation.z
			
			bfly.position = self.position + forward_vector * 3
			
		eggstack = []

	var used_stamina = false
	noise_level = 0.0
	
	if Input.is_action_just_pressed("crouch"):
		if crouch:
			crouch = false
			head.position.y += 0.5 #TODO add tween
		else:
			crouch = true
			head.position.y -= 0.5
	
	if Input.is_action_just_pressed("hold"):
		if not holding_breath and stamina > 0:
			holding_breath = true
		else:
			holding_breath = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and stamina > 0:
		velocity.y = JUMP_VELOCITY
		used_stamina = true
		#TODO balance values
		if holding_breath:
			stamina -= 5
		else:
			make_noise(2)
			stamina -= 3

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction: Vector3
	
	if debug_topdown_mode:
		direction = Vector3(input_dir.y, 0, -input_dir.x).normalized()
	else:
		direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if velocity.x != 0 or velocity.z != 0:
		movement_state = WALK
		if Input.is_action_pressed("sprint"): movement_state = SPRINT
		if crouch:
			if movement_state == SPRINT: movement_state = CROUCH_SPRINT
			else: movement_state = CROUCH

	if movement_state == SPRINT and stamina == 0:
		movement_state = WALK
		used_stamina = true
	if movement_state == CROUCH and stamina == 0:
		movement_state = CROUCH
		used_stamina = true
	
	var movement_multiplier = 1
	match movement_state:
		SPRINT:
			used_stamina = true
			movement_multiplier = SPRINT_SPEED
		CROUCH_SPRINT:
			used_stamina = true
			movement_multiplier = (CROUCH_SPEED * SPRINT_SPEED)
		CROUCH:
			movement_multiplier = CROUCH_SPEED

	velocity.x *= movement_multiplier
	velocity.z *= movement_multiplier

	move_and_slide()
	
	#TODO balance values
	if not holding_breath:
		make_noise( (movement_state + 1) )
	
	#TODO balance values
	match movement_state:
		IDLE:
			if holding_breath: stamina -= 1 * delta
		CROUCH:
			if holding_breath: stamina -= 2 * delta
		CROUCH_SPRINT:
			if holding_breath: stamina -= 5 * delta
			else: stamina -= 1 * delta
		WALK:
			if holding_breath: stamina -= 3 * delta
		SPRINT: 
			if holding_breath: stamina -= 10 * delta
			else: stamina -= 5 * delta
	
	if holding_breath:
		recovering = false
		stamina_timer.stop()
	elif used_stamina:
		recovering = false
		stamina_timer.stop()
	elif recovering:
		stamina += 5 * delta
		if stamina >= 100:
			stamina = 100
			recovering = false
	elif stamina_timer.is_stopped() and stamina < 100:
		stamina_timer.start()
		
	hud.vars = [stamina, noise_level]
	
	if stamina < 0:
		stamina = 0
		holding_breath = false

func make_noise(noise_val):
	noise_level += noise_val
	# Use new sound system
	SoundManager.emit_sound(global_position, noise_val, self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not movement_state == LOOKING_AT_DISPLAY and not debug_topdown_mode:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event.is_action_pressed("interact"):
		if movement_state == LOOKING_AT_DISPLAY:
			stop_looking_at_display()
			return
		
		var collider: Object = ray_cast.get_collider()
		
		if collider is Interactable:
			collider.interact(self)
	
	if event.is_action_pressed("throw_item") and has_throwable:
		has_throwable = false
		hand.visible = false
		var throwable: RigidBody3D = throwable_scene.instantiate()
		get_parent().add_child(throwable)
		throwable.global_position = camera.global_position
		throwable.apply_central_impulse(-camera.global_basis.z * 10)


func start_looking_at_display(display: TextureRect) -> void:
	if not display:
		return
	
	hud.interactable_display = display
	hud.interactable_display.visible = true
	movement_state = LOOKING_AT_DISPLAY
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)


func stop_looking_at_display() -> void:
	hud.interactable_display.visible = false
	movement_state = IDLE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_stamina_timer_timeout() -> void:
	recovering = true


func contains_subarray(main_array: Array, sub_array: Array) -> bool:
	if sub_array.is_empty():
		return true  # An empty subarray is considered to be contained in any array.
	if main_array.size() < sub_array.size():
		return false # The main array cannot contain a larger subarray.

	var sub_array_size = sub_array.size()
	for i in range(main_array.size() - sub_array_size + 1):
		var slice = main_array.slice(i, i + sub_array_size - 1)
		if slice == sub_array:
			return true
	return false
