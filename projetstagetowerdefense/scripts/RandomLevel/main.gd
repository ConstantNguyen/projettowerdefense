extends Node3D

@onready var grid_map := $GridMap
@onready var tower_scene = preload("res://scenes/tower.tscn")

@onready var timer_label = $CanvasLayer/timer_label
@onready var game_timer = $game_timer
@onready var bouton_start = $CanvasLayer/start_button

@onready var bouton_pause = $CanvasLayer/button_pause
@onready var pause_menu = $CanvasLayer/Pause
@onready var continue_button = $CanvasLayer/Pause/ContinueButton
@onready var restart_button = $CanvasLayer/Pause/RestartButton
@onready var quit_button = $CanvasLayer/Pause/QuitButton

var seconds_passed = 0
var is_paused = false
var started = false

var selected_tower_scene: PackedScene = null

const GRID_SIZE = Vector3i(31, 1, 15)
const GROUND_ID = 0
const SPECIAL_CENTER_ID = 3
const BORDER_ID = 1
const NUM_DECORATIONS = 35
const SPAWNER_ID = 2
const MAX_SPAWNERS = 3

var spawn_points: Array[Vector3i] = []
var firewall_pos: Vector3i
var path_gen: PathGenerator
var blocked_positions: Dictionary = {}
var towers: Dictionary = {}
var DECORATION_IDS = range(8, 10)

var tile_score_to_id := {
	10: 5,  # gauche + droite
	5: 5,   # haut + bas
	
	3: 6,   # haut + droite
	6: 6,   # droite + bas
	12: 6,  # bas + gauche
	9: 6,   # gauche + haut
	
	7: 7,   # T haut-droite-bas
	11: 7,  # T haut-droite-gauche
	13: 7,  # T haut-bas-gauche
	14: 7,  # T droite-bas-gauche
	
	15: 11   # croix (pas implémenter mais la par sécurité pour un ajout futur potentiel)
}

func _ready():
	
	fill_ground()
	
	place_special_center()
	blocked_positions.clear()
	block_center_radius(3)
	
	place_border_spawn_zone()
	
	place_enemy_spawners()
	generate_paths_from_spawners_to_firewall()
	
	place_random_decorations()
	
	game_timer.timeout.connect(_on_game_timer_timeout)
	bouton_pause.pressed.connect(_on_pause_button_pressed)
	game_timer.start()
	update_timer_display()
	
	generate_functional_elements()
	
	bouton_pause.pressed.connect(_on_pause_button_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	pause_menu.visible = false
	
	selected_tower_scene = preload("res://scenes/tower.tscn")
	
	bouton_start.pressed.connect(_on_start_button_pressed)
	bouton_start.visible = true
	game_timer.stop() 

func _on_start_button_pressed():
	started = true
	bouton_start.visible = false
	game_timer.start()
	
	# Démarrer tous les spawners
	for spawner in get_tree().get_nodes_in_group("spawners"):
		spawner.start_spawning()


func fill_ground():
	for x in range(GRID_SIZE.x):
		for z in range(GRID_SIZE.z):
			grid_map.set_cell_item(Vector3i(x, 0, z), GROUND_ID)

func place_special_center():
	firewall_pos = Vector3i(GRID_SIZE.x / 2, 0, GRID_SIZE.z / 2)
	grid_map.set_cell_item(firewall_pos, SPECIAL_CENTER_ID)
	blocked_positions[firewall_pos] = true

func block_center_radius(radius: int):
	var center = Vector3i(GRID_SIZE.x / 2, 0, GRID_SIZE.z / 2)
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var pos = center + Vector3i(dx, 0, dz)
			if pos.x >= 0 and pos.x < GRID_SIZE.x and pos.z >= 0 and pos.z < GRID_SIZE.z:
				blocked_positions[pos] = true

func place_border_spawn_zone():
	for x in range(GRID_SIZE.x):
		var top = Vector3i(x, 0, 0)
		var bottom = Vector3i(x, 0, GRID_SIZE.z - 1)
		grid_map.set_cell_item(top, BORDER_ID)
		grid_map.set_cell_item(bottom, BORDER_ID)
		blocked_positions[top] = true
		blocked_positions[bottom] = true

	for z in range(1, GRID_SIZE.z - 1):
		var left = Vector3i(0, 0, z)
		var right = Vector3i(GRID_SIZE.x - 1, 0, z)
		grid_map.set_cell_item(left, BORDER_ID)
		grid_map.set_cell_item(right, BORDER_ID)
		blocked_positions[left] = true
		blocked_positions[right] = true

func place_enemy_spawners():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var num_spawners = rng.randi_range(1, MAX_SPAWNERS)
	var placed = 0
	var tries = 0
	var used_z = []

	while placed < num_spawners and tries < 200:
		var x = rng.randi_range(0, 5)
		var z = rng.randi_range(1, GRID_SIZE.z - 2)
		var pos = Vector3i(x, 0, z)

		var is_z_conflict = false
		for uz in used_z:
			if abs(z - uz) <= 1:
				is_z_conflict = true
				break

		if not is_z_conflict and not blocked_positions.has(pos):
			grid_map.set_cell_item(pos, SPAWNER_ID)
			blocked_positions[pos] = true
			spawn_points.append(pos)
			used_z.append(z)
			placed += 1

		tries += 1

	print("Spawners placés :", placed)

func get_rotation_from_score(score: int) -> float:
	match score:
		#Ligne
		5: return 0.0 
		10: return 90.0
		
		#Angle
		3: return 180.0
		6: return 90.0
		9: return 270.0
		12: return 0.0
		
		#T
		7: return 0.0
		11: return 180.0
		13: return 270.0
		14: return 90.0
		
		#Other
		15: return 0.0
		_: return 0.0

func place_rotated_tile(id: int, pos: Vector3i, rotation_deg: float):
	var tile = MeshInstance3D.new()
	tile.mesh = grid_map.mesh_library.get_item_mesh(id)

	var local_pos = grid_map.map_to_local(pos)
	local_pos.y += 0.07 #TEMPORAIRE

	tile.global_transform.origin = local_pos
	tile.rotate_y(deg_to_rad(rotation_deg))
	add_child(tile)

	blocked_positions[pos] = true

func place_path_from_generator(path: Array[Vector2i]):
	for pos2d in path:
		var score = path_gen.get_tile_score(pos2d)
		if not tile_score_to_id.has(score):
			continue

		var tile_id = tile_score_to_id[score]
		var rotation_deg = get_rotation_from_score(score)
		var pos = Vector3i(pos2d.x, 0, pos2d.y)

		if pos == firewall_pos:
			continue

		place_rotated_tile(tile_id, pos, rotation_deg)

func generate_paths_from_spawners_to_firewall():
	path_gen = PathGenerator.new(GRID_SIZE.x, GRID_SIZE.z)

	for spawn in spawn_points:
		var path = build_path_to_firewall(spawn)
		path_gen.add_path_segment(path)

	place_path_from_generator(path_gen.get_path())

func build_path_to_firewall(start: Vector3i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = Vector2i(start.x, start.z)
	var end = Vector2i(firewall_pos.x, firewall_pos.z)

	path.append(current)

	while current.x != end.x:
		current.x += signi(end.x - current.x)
		path.append(current)

	while current.y != end.y:
		current.y += signi(end.y - current.y)
		path.append(current)

	return path

func place_random_decorations():
	var used_positions = {}
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var tries = 0
	while used_positions.size() < NUM_DECORATIONS and tries < 200:
		var x = rng.randi_range(0, GRID_SIZE.x - 1)
		var z = rng.randi_range(0, GRID_SIZE.z - 1)
		var pos = Vector3i(x, 0, z)

		if not used_positions.has(pos) and not blocked_positions.has(pos):
			used_positions[pos] = true
			var deco_id = DECORATION_IDS[rng.randi_range(0, DECORATION_IDS.size() - 1)]
			grid_map.set_cell_item(pos, deco_id)

		tries += 1

func _on_tower_button_pressed():
	selected_tower_scene = tower_scene

func _unhandled_input(event):
	if selected_tower_scene and event is InputEventMouseButton and event.pressed:
		var camera = $CameraRig/CameraPivot/Camera3D
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

		var ray_params = PhysicsRayQueryParameters3D.new()
		ray_params.from = from
		ray_params.to = to

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(ray_params)

		if result.size() > 0:
			var position = result["position"]
			print("Raycast hit at: ", position)

			var grid_pos = $GridMap.world_to_map(position)
			var world_pos = $GridMap.map_to_world(grid_pos)

			var tower = selected_tower_scene.instantiate()
			tower.global_transform.origin = world_pos
			add_child(tower)

			print("Tour placée à :", world_pos)
			selected_tower_scene = null
			
	# Quand on appuie sur la touche "échap" le menu pause apparait
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()

# --- AJOUT : logique fonctionnelle du niveau ---
@onready var spawner_scene: PackedScene = preload("res://scenes/enemy/spawnerRdmLvl.tscn")
var path_points: Array[Vector3] = []

func _toggle_pause_menu():
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func _on_pause_button_pressed():
	is_paused = not is_paused
	get_tree().paused = is_paused
	bouton_pause.text = "Reprendre" if is_paused else "Pause"

func _on_continue_pressed():
	is_paused = false
	get_tree().paused = false
	pause_menu.visible = false

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
	get_tree().root.add_child(menu_scene)
	queue_free()

func _on_game_timer_timeout():
	if not is_paused:
		seconds_passed += 1
		update_timer_display()

func update_timer_display():
	var minutes = seconds_passed / 60
	var seconds = seconds_passed % 60
	var formatted_time = "%02d:%02d" % [minutes, seconds]
	timer_label.text = formatted_time
	
func generate_functional_elements():
	var tile_size = 1.0
	var enemy_scene = preload("res://scenes/enemy/EnemyRdmLvl.tscn")
	var spawner_scene = preload("res://scenes/enemy/spawnerRdmLvl.tscn")
	
	for spawner_tile in spawn_points:
		var full_path: Array[Vector3] = []
		
		#Du spawner au firewall
		var path_to_firewall = build_path_to_firewall(spawner_tile)
		for point in path_to_firewall:
			full_path.append(Vector3(point.x * tile_size, 0.5, point.y * tile_size))
		
		# Depuis firewall vers les 4 tours alliées (ATTENTION: TEMPORAIRE A MODIFIER)
		var firewall_2d = Vector2i(firewall_pos.x, firewall_pos.z)
		var middle_split_pos = firewall_2d + Vector2i(2, 0)
		var split_targets = [
			Vector2i(GRID_SIZE.x - 1, 2),
			Vector2i(GRID_SIZE.x - 1, 5),
			Vector2i(GRID_SIZE.x - 1, 8),
			Vector2i(GRID_SIZE.x - 1, 11),
		]
		
		#Choix de la target random par un spawner:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var target = split_targets[rng.randi_range(0, split_targets.size() - 1)]

		var path_from_firewall = []
		var current = firewall_2d
		
		# Split des chemin à partir du firewall (ATTENTION: A MODIFIER AUSSI)
		while current.x < middle_split_pos.x:
			current.x += 1
			path_from_firewall.append(current)
		while current.y != target.y:
			current.y += signi(target.y - current.y)
			path_from_firewall.append(current)
		while current.x != target.x:
			current.x += signi(target.x - current.x)
			path_from_firewall.append(current)
		
		for point in path_from_firewall:
			full_path.append(Vector3(point.x * tile_size, 0.5, point.y * tile_size))

		# Création de Path3D
		var path = Path3D.new()
		var curve = Curve3D.new()
		for point in full_path:
			curve.add_point(point)
		path.curve = curve
		add_child(path)

		# Créer le spawner lié à CE chemin précis
		var spawner = spawner_scene.instantiate()
		spawner.position = Vector3(spawner_tile.x + 0.5, 0.5, spawner_tile.z + 0.5)
		spawner.enemy_scene = enemy_scene
		spawner.path_node = path
		spawner.add_to_group("spawners")
		add_child(spawner)
		
	if has_node("game_timer"):
		$game_timer.start()
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = true
