class_name RS_RoomRoam
extends RefCounted

var Room: RS_Room
var Start: Vector3
var Waypoints: Array[Node]

func _init(room: RS_Room, start: Vector3):
	print("New room roam for: ", room.name)
	self.Room = room
	self.Start = start
	self.Waypoints = room.WaypointsParent.get_children()
	
func GetNextTarget() -> Node:
	var closest_node: int = -1
	var closest_dist: float = INF
	for i in range(len(Waypoints)):
		if (Start.distance_squared_to(Waypoints[i].global_position) < closest_dist):
			closest_node = i
			closest_dist = Start.distance_squared_to(Waypoints[i].global_position)
	if (closest_node == -1): return null
	return Waypoints.pop_at(closest_node)
