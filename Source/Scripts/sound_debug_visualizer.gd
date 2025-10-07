extends Node3D


var enabled: bool = true
var events: Array = []
var lifetime: float = 2.0

var immediate_mesh: ImmediateMesh
var mesh_instance: MeshInstance3D

func _ready():
	immediate_mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true  # dont know/care what this is but we need it 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)
	if SoundManager:
		SoundManager.sound_emitted.connect(_on_sound_emitted)

func _input(event):
	if event.is_action_pressed("debug_toggle"):
		enabled = !enabled
		mesh_instance.visible = enabled

func _process(delta):
	if not enabled:
		return
	for event in events:
		event.lifetime += delta
	events = events.filter(func(e): return e.lifetime < lifetime)
	_draw_sound_paths()

func _on_sound_emitted(position: Vector3, level: float):
	if not enabled:
		return
	events.append({
		"position": position,
		"level": level,
		"lifetime": 0.0
	})

func _draw_sound_paths():
	immediate_mesh.clear_surfaces()
	if events.is_empty():
		return
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	#thank you sam altman
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for event in events:
		var alpha = 1.0 - (event.lifetime / lifetime)
		var source_pos = event.position
		_draw_sphere(source_pos, event.level * 0.2, Color(1, 1, 0, alpha * 0.5))
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var enemy_pos = enemy.global_position
			var world = get_world_3d()
			
			if not world:
				continue
			
			var physics_space = world.direct_space_state
			var result = SoundPropagationSystem.calculate_sound_at_listener(
				source_pos,
				enemy_pos,
				event.level,
				physics_space
			)
			
			var line_color: Color

			#if event.lifetime < 0.1:
				#print("strength %.2f, walls %d, heard: %s" % [result.strength, result.wall_count, result.can_hear])
			
			#update all this stuff to use actual enemy vars because you have to change this whenever you change the enemy vars
			var would_trigger = result.strength >= 0.5
			
			if would_trigger:
				if result.strength >= 2.5:
					line_color = Color(1, 0, 0, alpha)
				elif result.strength >= 1.0:
					line_color = Color(1, 0.5, 0, alpha)
				else:
					line_color = Color(1, 1, 0, alpha)
			elif result.wall_count > SoundPropagationSystem.MAX_WALL_PENETRATIONS:
				line_color = Color(0.5, 0.5, 0.5, alpha * 0.3)
			else:
				line_color = Color(0, 1, 0, alpha * 0.5)

			immediate_mesh.surface_set_color(line_color)
			immediate_mesh.surface_add_vertex(source_pos)
			immediate_mesh.surface_add_vertex(enemy_pos)
	
	immediate_mesh.surface_end()

func _draw_sphere(center: Vector3, radius: float, color: Color):
	var segments = 8
	var angle_step = (2.0 * PI) / segments
	
	for i in range(segments):
		var angle1 = i * angle_step
		var angle2 = (i + 1) * angle_step
		
		var p1 = center + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var p2 = center + Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
		
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_add_vertex(p2)

	for i in range(segments):
		var angle1 = i * angle_step
		var angle2 = (i + 1) * angle_step
		
		var p1 = center + Vector3(cos(angle1) * radius, sin(angle1) * radius, 0)
		var p2 = center + Vector3(cos(angle2) * radius, sin(angle2) * radius, 0)
		
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_add_vertex(p2)
