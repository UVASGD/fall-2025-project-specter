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
@onready var noise_area = $Area3D/CollisionShape3D.shape
@onready var space_state = get_world_3d().direct_space_state
var crouch = false
var recovering = false
var holding_breath = false
var stamina = 100.0
var noise_level : float
var detections = {}
var soundTimer = 0;

enum {IDLE, CROUCH, CROUCH_SPRINT, WALK, SPRINT}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if soundTimer == 50:
		soundTimer=0
		causeSound()
	else:
		soundTimer+=1
	
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
		noise_level += (movement_state + 1)
	noise_area.radius = noise_level * 5
	
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
	
	if Input.is_action_just_pressed("testsoundray"):
		causeSound()
		
func causeSound():
	#var startingpoint = global_transform.origin
		#var endingpoint = startingpoint + -global_transform.basis.z * 1000
		#fire_ray(startingpoint, endingpoint, 25, [self])
		var visuals = false
		var duration = 10000
		
		var num_rays=32
		var num_levels = 3
		var startingpoint = global_transform.origin + Vector3(0, .25, 0)
		for j in range(num_levels):
			for i in range (num_rays):
				var angle = deg_to_rad((360/num_rays)*i)
				var pitchAngle = deg_to_rad(135+45*j)
				var rayDirection = Vector3(sin(angle)*cos(pitchAngle), sin(pitchAngle), cos(angle))
				var endingpoint = startingpoint + rayDirection.normalized() * 100
				fire_ray(startingpoint, endingpoint, 100, [self], visuals, false, duration)
		print("EndOfShootingRays")
		detections.clear()
		
func fire_ray(start, end, power, exclude, visuals, throughWall, duration):
	var rayQuery = PhysicsRayQueryParameters3D.create(start, end)
	rayQuery.exclude=exclude
	var rayResult = space_state.intersect_ray(rayQuery)
	if rayResult:
		if visuals:
			if throughWall==false:
				DebugDraw3D.draw_line(start, rayResult.position, Color(1, 1, 0), duration)
			else:
				DebugDraw3D.draw_line(start,  rayResult.position, Color(0, 1, 0), duration)
		#print("Ray hit: ", rayResult.collider.name, " at ", rayResult["rid"])
		
		var currentParentNode = rayResult.collider
		var hitEnemy = null
		while currentParentNode:
			if currentParentNode.has_method("get_signal"):
				print("Hit Enemy: ", currentParentNode.name)
				hitEnemy = currentParentNode
				break
			else:
				currentParentNode=currentParentNode.get_parent()
			
		if hitEnemy==null and power>15:
			var incomingAngle = (rayResult.position-start).normalized()
			var normalAngle = rayResult.normal.normalized()
			var newAngle = (incomingAngle-2 * incomingAngle.dot(normalAngle) * normalAngle).normalized()
			var reflectionStart = rayResult.position+newAngle*0.05
			fire_ray(reflectionStart,reflectionStart+(newAngle*100), power*(3.0/5), [self], visuals, throughWall, duration)
			var throughWallStart=rayResult.position+incomingAngle*0.05
			fire_ray(throughWallStart,throughWallStart+(incomingAngle*100), power*(1.0/5), [self], visuals, true, duration)
	else:
		#print("Ray hit nothing")
		if visuals:
			if throughWall==false:
				DebugDraw3D.draw_line(start, end, Color(1, 0, 0), duration)
			else:
				DebugDraw3D.draw_line(start, end, Color(0, 0, 1), duration)


	
	


func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	###DEBUGGING ONLY
	
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	


func _on_stamina_timer_timeout() -> void:
	recovering = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.HUNTING)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Enemy"):
		body.change_state(body.SEARCHING)
