extends CharacterBody3D

@export var SPEED = 5.0
@export var SPRINT_SPEED = 1.5
@export var CROUCH_SPEED = 0.5
@export var JUMP_VELOCITY = 4.5
@export var SENSITIVITY = 0.005

@onready var head = $Head
@onready var stamina_timer = $StaminaTimer
@onready var hud = %HUD

var crouch = false
var recovering = false
var holding_breath = false
var stamina = 100.0
var noise_level : float

enum {IDLE, CROUCH, CROUCH_SPRINT, WALK, SPRINT}

func _ready():
	head.rotate_y(PI / 2)

func _physics_process(delta: float) -> void:
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
			SoundManager.emit_sound(global_position, 2.0, self)
			noise_level += 2
			stamina -= 3

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	var movement_state = IDLE
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
		var movement_noise = float(movement_state + 1)
		noise_level += movement_noise
		SoundManager.emit_sound(global_position, movement_noise, self)
	
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

func _on_stamina_timer_timeout() -> void:
	recovering = true
