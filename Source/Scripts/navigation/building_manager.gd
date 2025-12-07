extends Node

class_name RS_Building

@export var Rooms : NodePath
@export var Doors : NodePath

var AllRooms: Array[RS_Room]	#Graph Nodes
var AllDoors: Array[RS_Door]	#Graph Edges

var ConnectionMap: Dictionary[Node, Array]






#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AllRooms = []
	for room in get_node(Rooms).get_children():
		if room is RS_Room: AllRooms.append(room)
	AllDoors = []
	for door in get_node(Doors).get_children():
		if door is RS_Door: AllDoors.append(door)
	
	print("Rooms: ", len(AllRooms), " Doors: ", len(AllDoors))
	
	#Making connection map
	for Room in AllRooms: ConnectionMap[Room] = []
	for Door in AllDoors:
		if (ConnectionMap[Door.RoomARef].has(Door.RoomBRef) == false): ConnectionMap[Door.RoomARef].append(Door.RoomBRef)
		if (ConnectionMap[Door.RoomBRef].has(Door.RoomARef) == false): ConnectionMap[Door.RoomBRef].append(Door.RoomARef)
		
	print("Connection Mapping: ", JSON.stringify(ConnectionMap, "   "))
		
	print("\n\n")
	GetPathToRoom(AllRooms[0], AllRooms[5])
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~








func CheckOverlap(Parent:Node, Point:Vector3):
	if (Parent == null): return false
	
	for Child in Parent.get_children():
		if Child is CSGBox3D:
			var colpos = Child.global_position
			var colext = Child.size * 0.5
			var pmin = colpos-colext
			var pmax = colpos+colext
			
			#print("\t\tBetween: ", pmin, " and ", pmax)
			if ((pmin.x <= Point.x and Point.x <= pmax.x) and (pmin.z <= Point.z and Point.z <= pmax.z)):
				return true
	return false

func GetRoom(Point:Vector3):
	#print("Get Room at point: ", Point)
	for Room in AllRooms:
		#print("\tRoom: ", Room.name)
		if (CheckOverlap(Room.CollidersParent, Point)): return Room
	return null
	
func GetRoomByName(Name: String) -> RS_Room:
	for Room in AllRooms:
		if (Room.name == Name): return Room
	return null
	
func GetPathToRoom(StartRoom: RS_Room, EndRoom: RS_Room):
	print("Path between: ", StartRoom.name, " and ", EndRoom.name)
	var Visited : Array[RS_Room] = []
	var VisitQueue : Array[RS_Room] = [StartRoom]
	var VisitQueueData : Array[Array] = [[]]
	while (len(VisitQueue) != 0):
		var curr = VisitQueue.pop_front()
		var currdata = VisitQueueData.pop_front()
		if (curr in Visited): continue
		if (curr == EndRoom):
			currdata += [curr] 
			print(currdata)
			return currdata
			 
		Visited.append(curr)
		for next in ConnectionMap[curr]:
			VisitQueue.append(next)
			VisitQueueData.append(currdata + [curr])
	return null
	
	
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
