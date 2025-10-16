class_name SoundPropagationSystem
extends Node

## tuning guide for testers:
## - BASE_ATTENUATION: Higher = sound drops off faster with distance
## - WALL_ATTENUATION: Higher = walls block more sound (1.0 max means no sound passes) 
## - MAX_WALL_PENETRATIONS: Num walls sound can pass throuh (1 = suond goes through 1 wall, not 2)
## - CORNER_SEARCH_RADIUS: Larger = sound can go around bigger obstacles
## - MIN_AUDIBLE_SOUND: Threshold for what enemy can hear

const SOUND_SPEED = 343.0  # meters per second (not used for instant detection, but for reference)
const BASE_ATTENUATION = 0.03
const WALL_ATTENUATION = 0.7
const MAX_WALL_PENETRATIONS = 1
const CORNER_SEARCH_RADIUS = 3.0
const MIN_AUDIBLE_SOUND = 0.3

const MAX_CORNER_CHECKS = 8
const RAYCAST_COLLISION_MASK = 1  # Collision layer for walls (match wall layer)

static func calculate_sound_at_listener(source_pos: Vector3, listener_pos: Vector3, sound_level: float, phys_space: PhysicsDirectSpaceState3D) -> Dictionary:
	var result = {"strength": 0.0, "position": source_pos, "can_hear": false, "wall_count": 0}
	var distance = source_pos.distance_to(listener_pos)
	
	var direct_result = _check_path(source_pos, listener_pos, sound_level, distance, phys_space)
	if direct_result.can_hear:
		result = direct_result
		return result

	elif direct_result.wall_count > MAX_WALL_PENETRATIONS:
		var corner_result = _check_corner_paths(source_pos, listener_pos, sound_level, phys_space)
		if corner_result.can_hear and corner_result.strength > direct_result.strength:
			result = corner_result
			return result
		else:
			# Return better of two
			result = corner_result if corner_result.strength > direct_result.strength else direct_result
	else:
		result = direct_result
	
	return result

static func _check_path(source_pos: Vector3, listener_pos: Vector3, sound_level: float, distance: float, phys_space: PhysicsDirectSpaceState3D) -> Dictionary:
	var result = {"strength": 0.0, "position": source_pos, "can_hear": false, "wall_count": 0}
	# who up applying they attenuation
	var distance_factor = 1.0 / (1.0 + distance * BASE_ATTENUATION)
	var attenuated = sound_level * distance_factor
	var wall_count = _count_walls_between(source_pos, listener_pos, phys_space)
	result.wall_count = wall_count
	for i in range(wall_count):
		attenuated *= (1.0 - WALL_ATTENUATION)
	result.strength = attenuated
	result.can_hear = attenuated >= MIN_AUDIBLE_SOUND and wall_count <= MAX_WALL_PENETRATIONS
	
	return result

static func _check_corner_paths(source_pos: Vector3, listener_pos: Vector3, sound_level: float, phys_space: PhysicsDirectSpaceState3D) -> Dictionary:
	var best = {"strength": 0.0, "position": source_pos, "can_hear": false, "wall_count": 999}
	var direction = (listener_pos - source_pos).normalized()
	var distance = source_pos.distance_to(listener_pos)
	#  circle of points around midpoint to go around corners
	var midpoint = source_pos + direction * (distance * 0.5)
	var angle_step = (2.0 * PI) / MAX_CORNER_CHECKS
	for i in range(MAX_CORNER_CHECKS):
		var angle = i * angle_step
		var offset = Vector3(cos(angle) * CORNER_SEARCH_RADIUS, 0, sin(angle) * CORNER_SEARCH_RADIUS)
		var corner_point = midpoint + offset

		var walls_to_corner = _count_walls_between(source_pos, corner_point, phys_space)
		var walls_from_corner = _count_walls_between(corner_point, listener_pos, phys_space)
		var total_walls = walls_to_corner + walls_from_corner
		
		if total_walls <= MAX_WALL_PENETRATIONS:
			var total_distance = source_pos.distance_to(corner_point) + corner_point.distance_to(listener_pos)
			var path_result = _check_path(source_pos, corner_point, sound_level, total_distance, phys_space)

			path_result.strength *= 0.9 # little bit of attenuation for corners
			path_result.wall_count = total_walls
			path_result.can_hear = path_result.strength >= MIN_AUDIBLE_SOUND
			
			if path_result.strength > best.strength:
				best = path_result
	
	return best

static func _count_walls_between(from: Vector3, to: Vector3, phys_space: PhysicsDirectSpaceState3D) -> int:
	if phys_space == null:
		return 0
	var wall_count = 0
	var ray_query = PhysicsRayQueryParameters3D.create(from, to)
	ray_query.collision_mask = RAYCAST_COLLISION_MASK
	ray_query.hit_from_inside = false
	var current_pos = from
	var max_iterations = 10
	for i in range(max_iterations):
		ray_query.from = current_pos
		ray_query.to = to
		var result = phys_space.intersect_ray(ray_query)
		if result.is_empty():
			break
		wall_count += 1
		var hit_point = result.position
		var direction = (to - current_pos).normalized()
		current_pos = hit_point + direction * 0.1
		if current_pos.distance_to(to) < 0.2:
			break
	return max(wall_count-1, 0)

# static func emit_sound(source_pos: Vector3, sound_level: float, world: World3D, listener_group: String = "Enemy") -> Array:

# 	var phys_space = world.direct_space_state
# 	var listeners = []
	
# 	# TODO: Get listeners
	
# 	return listeners
