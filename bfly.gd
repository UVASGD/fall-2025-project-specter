extends Node3D

@onready var leftwing: MeshInstance3D = $Sketchfab_Scene/Sketchfab_model/root/GLTF_SceneRootNode/Cube_021_19/leftwing
@onready var rightwing: MeshInstance3D = $Sketchfab_Scene/Sketchfab_model/root/GLTF_SceneRootNode/Cube_002_20/rightwing

var wingcolor = Color("35bcfd")
var deathtime = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randi_range(0,1) == 1:
		wingcolor = Color("ffbcfd")
	var mat = StandardMaterial3D.new()
	mat.albedo_color = wingcolor
	leftwing.set_surface_override_material(0,mat)
	rightwing.set_surface_override_material(0,mat)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position.y += 1 * delta
	deathtime -= 1 * delta 
	if deathtime <= 0:
		deathtime = 1000
		queue_free()
