extends Interactable

signal start_dialogue(text_array: Array[String])

var is_open = false
var dist = 0

func _physics_process(delta: float) -> void:
	if is_open:
		var move = 3*delta
		dist += move
		translate(Vector3(0, move, 0))
		
		if dist >= 9: queue_free()

func open():
	is_open = true

func interact(_player: Player) -> void:
	print("Interacted")
	if !is_open:
		var arr: Array[String] = ["It's locked, I have to find a way to open it."]
		start_dialogue.emit(arr)
