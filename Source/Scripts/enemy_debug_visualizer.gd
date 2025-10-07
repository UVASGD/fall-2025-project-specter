extends Node3D
#DUDE
#NEEDTHAT
var enemy: Node3D
var state_label: Label3D
var detection_indicator: MeshInstance3D

var enabled: bool = true

func _ready():
	enemy = get_parent()
	if not enemy:
		push_warning("where my parent fr")
		return
	state_label = Label3D.new()
	state_label.name = "StateLabel3D"
	add_child(state_label)
	state_label.position = Vector3(0, 2.5, 0)
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	state_label.no_depth_test = true
	state_label.font_size = 32
	
	det_ball = MeshInstance3D.new()
	det_ball.name = "DetectionIndicator"
	add_child(det_ball)
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	det_ball.mesh = sphere
	det_ball.position = Vector3(0, 1.5, 0)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 1, 0, 0.5)
	det_ball.material_override = mat

func _input(event):
	if event.is_action_pressed("debug_toggle"):
		enabled = !enabled
		visible = enabled

func _process(_delta):
	if not enabled or not enemy:
		return

	var state_name = _get_state_name(enemy.current_state)
	var state_color = _get_state_color(enemy.current_state)
	state_label.modulate = state_color
	state_label.text = state_name
	
	var can_hear = enemy.last_sound_strength > 0.5 and enemy.time_since_last_sound < 1.0 #TODO: link this to actual enemy vars because you have to change this whenever you change the enemy vars
	var mat = detection_indicator.material_override as StandardMaterial3D
	if can_hear:
		mat.albedo_color = Color(1, 0, 0, 0.7)
		detection_indicator.scale = Vector3.ONE * (1.0 + enemy.last_sound_strength * 0.1)
	else:
		mat.albedo_color = Color(0, 1, 0, 0.3)
		detection_indicator.scale = Vector3.ONE

func _get_state_name(state: int) -> String:
	match state:
		0: return "IDLE"
		1: return "ROAMING"
		2: return "SEARCHING"
		3: return "HUNTING"
		_: return "UNKNOWN"

func _get_state_color(state: int) -> Color:
	match state:
		0: return Color.GRAY
		1: return Color.CYAN
		2: return Color.YELLOW
		3: return Color.RED
		_: return Color.WHITE
