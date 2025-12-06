class_name RigidDoor
extends RigidBody3D


func get_center() -> Vector3:
	return $LockerWall3.global_position


func move_to_handd(target_pos: Vector3) -> void:
	var curr_pos: Vector3 = $LockerWall3.global_position
	var dir: Vector3 = curr_pos.direction_to(target_pos)
	
	apply_central_force(dir)
