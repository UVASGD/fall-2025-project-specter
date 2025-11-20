class_name ConfidenceWrapper extends Node

var intervals : Array[ConfidenceInterval]
var enemy : CharacterBody3D

class ConfidenceInterval:
	var position: Vector3
	var confidence: float
	
	func _init(p : Vector3, strength : float) -> void:
		position = p
		confidence = strength / 3 #make calulation more robust
	
	func in_range(pos : Vector3) -> bool:
		return position.distance_to(pos) <= 0.1
		
	func update(sound_pos: Vector3, strength: float) -> void:
		position = sound_pos
		confidence += strength / 50 #make calulation more robust

func _init() -> void:
	intervals = []

func _physics_process(delta: float) -> void:
	pass

func update_interval(index: int, sound_pos: Vector3, strength: float):
	intervals[index].update(sound_pos, strength)
	while index > 0 and intervals[index].confidence > intervals[index-1].confidence:
		var temp = intervals[index]
		intervals[index] = intervals[index-1]
		intervals[index-1] = temp

func interval_check():
	var conf = intervals[0].confidence
	if conf >= 0.9:
		enemy.change_state(enemy.HUNTING)
	elif conf >= 0.3:
		enemy.change_state(enemy.SEARCHING)
	else:
		enemy.change_state(enemy.ROAMING)

func on_sound_heard(sound_pos: Vector3, strength: float, wall_count: int):
	for i in intervals.size():
		if intervals[i].in_range(sound_pos):
			update_interval(i, sound_pos, strength)
			interval_check()
			return
	
	var new_interval = ConfidenceInterval.new(sound_pos, strength)
	var i = intervals.size()
	while i > 0 and intervals[i-1].confidence <  new_interval.confidence:
		i -= 1
	intervals.insert(i, new_interval)
	interval_check()
	
	"""
	ls_pos = sound_pos
	ls_strength = strength
	ls_time = 0.0
	
	print("heard - strength: %.2f, walls: %d, dist: %.1fm" % [strength, wall_count, global_position.distance_to(sound_pos)])
	
	if strength >= 2.5:
		#print("Loud")
		change_state(HUNTING)
	elif strength >= 1.0:
		if current_state == ROAMING or current_state == IDLE:
			#print("medium sound")
			change_state(SEARCHING)
	elif strength >= 0.5:
		if current_state == ROAMING or current_state == IDLE:
			#print("quiet sound")
			search_pos = sound_pos

func change_state(state):
	if current_state == state:
		return
	current_state = state
	match state:
		IDLE:
			SPEED = 0.5
			roam_wait_time = randf_range(2.0, 4.0)
		ROAMING:
			SPEED = ROAM_SPEED
			set_new_roam_target()
		SEARCHING:
			SPEED = SEARCH_SPEED
			search_pos = ls_pos
			set_search_point()
		HUNTING:
			SPEED = HUNT_SPEED
	"""
