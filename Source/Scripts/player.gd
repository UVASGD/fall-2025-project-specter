extends CharacterBody3D

@export var SPEED = 5.0
@export var SPRINT_SPEED = 1.5
@export var CROUCH_SPEED = 0.5
@export var JUMP_VELOCITY = 4.5
@export var SENSITIVITY = 0.005

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var stamina_timer = $StaminaTimer
@onready var hud = %HUD
@onready var crouch = false
@onready var recovering = false
@onready var holding_breath = false
@onready var stamina = 100.0

enum {IDLE, CROUCH, CROUCH_SPRINT, WALK, SPRINT}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var used_stamina = false
	var noise_level = 0
	
	if Input.is_action_just_pressed("crouch"):
		if crouch:
			crouch = false
			head.position.y += 0.5 #ADD TWEEN
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
		#BALANCE VALUES
		if holding_breath:
			stamina -= 5
		else:
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
	
	#BALANCE VALUES
	if not holding_breath:
		noise_level += (movement_state + 1)
	
	#BALANCE VALUES
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _on_stamina_timer_timeout() -> void:
	recovering = true
