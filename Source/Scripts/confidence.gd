class_name ConfidenceWrapper extends Node

var intervals : Array[ConfidenceInterval]
var enemy : CharacterBody3D
var cur_interval : ConfidenceInterval

const HUNTING_THRESHOLD = 0.9
const SEARCHING_THRESHOLD = 0.3

class ConfidenceInterval:
	var position: Vector3
	var confidence: float
	
	func _init(p : Vector3, strength : float) -> void:
		position = p
		confidence = strength / 3 #make calulation more robust
	
	func in_range(pos : Vector3) -> bool:
		return position.distance_to(pos) <= 0.25
		
	func decay(delta: float):
		confidence -= 0.025 * delta
		
	func update(sound_pos: Vector3, strength: float) -> void:
		position = sound_pos
		confidence += strength / 500 #make calulation more robust
		
	func searched() -> void:
		confidence *= (2/3)

func _init() -> void:
	intervals = []

func interval_decay(delta: float) -> void:
	for val in intervals:
		val.decay(delta)
	interval_check()
	
	while intervals.size() > 0 and intervals.back().confidence < 0.1:
		intervals.pop_back()

func update_interval(index: int, sound_pos: Vector3, strength: float):
	intervals[index].update(sound_pos, strength)
	while index > 0 and intervals[index].confidence > intervals[index-1].confidence:
		var temp = intervals[index]
		intervals[index] = intervals[index-1]
		intervals[index-1] = temp

func interval_check():
	if intervals.is_empty(): 
		enemy.change_state(enemy.ROAMING)
		return

	var conf = intervals[0].confidence
	if conf >= HUNTING_THRESHOLD:
		enemy.change_state(enemy.HUNTING)
	elif conf >= SEARCHING_THRESHOLD:
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

func get_interval(state):
	var threshold
	match state:
		enemy.ROAMING:
			cur_interval = null
			return cur_interval
		enemy.SEARCHING:
			threshold = SEARCHING_THRESHOLD
		enemy.HUNTING:
			threshold = HUNTING_THRESHOLD
	
	var i = 0
	var ints = []
	while i < intervals.size() and intervals[i].confidence >= threshold:
		ints.append(intervals[i])
		i += 1
	
	match ints.size():
		0: 
			print("ERROR: No Intervals")
			cur_interval = null
			return cur_interval
		1:
			cur_interval = ints[0]
			return cur_interval.position
		_:
			var total = 0
			for con in ints:
				total += con.confidence
			
			var running = 0
			var rand = randf_range(0, total)
			for con in ints:
				running += con.confidence
				if rand <= running: 
					cur_interval = con
					return con.position
			
			print("This shouldn't happen... error somewhere")
			cur_interval = ints[0].position
			return cur_interval.position

func get_cur_interval_pos():
	return cur_interval.position

func new_interval():
	if cur_interval:
		cur_interval.searched()
	interval_check()
