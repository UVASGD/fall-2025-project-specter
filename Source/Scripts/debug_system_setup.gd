extends Node

# attach to a regular node as a child of Gameplay node 

@export var enable_debug: bool = true

func _ready():
	if not enable_debug:
		return
	_setup_debug_system.call_deferred()

func _setup_debug_system():
	var overlay = load("res://Source/Scenes/debug_overlay.tscn").instantiate()
	get_tree().root.add_child.call_deferred(overlay)
	
	var sound_viz = Node3D.new()
	sound_viz.name = "SoundDebugVisualizer"
	var sound_viz_script = load("res://Source/Scripts/sound_debug_visualizer.gd")
	sound_viz.set_script(sound_viz_script)
	get_tree().root.get_child(0).add_child.call_deferred(sound_viz)
	await get_tree().process_frame
	for enemy in get_tree().get_nodes_in_group("Enemy"): # q: will we have multiple enemies at any point
		var enemy_viz = Node3D.new()
		enemy_viz.name = "DebugVisualizer"
		var enemy_viz_script = load("res://Source/Scripts/enemy_debug_visualizer.gd")
		enemy_viz.set_script(enemy_viz_script)
		enemy.add_child.call_deferred(enemy_viz)
	
	#print("it workie")
