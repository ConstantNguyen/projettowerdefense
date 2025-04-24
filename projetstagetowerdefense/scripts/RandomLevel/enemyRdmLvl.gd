extends Node3D

@onready var grid_map := $GridMap
@onready var tower_scene = preload("res://scenes/tower.tscn")
@onready var spawner_scene: PackedScene = preload("res://scenes/enemy/spawner.tscn")

const GRID_SIZE = Vector3i(31, 1, 15)
const GROUND_ID = 0
const SPECIAL_CENTER_ID = 3
const BORDER_ID = 1
const NUM_DECORATIONS = 35
const SPAWNER_ID = 2
const MAX_SPAWNERS = 3

var selected_tower_scene: PackedScene = null
var spawn_points: Array[Vector3i] = []
var firewall_pos: Vector3i
var path_gen: PathGenerator
var blocked_positions: Dictionary = {}
var towers: Dictionary = {}
var DECORATION_IDS = range(8, 10)
var tile_score_to_id := {
	10: 5, 5: 5,
	3: 6, 6: 6, 12: 6, 9: 6,
	7: 7, 11: 7, 13: 7, 14: 7,
	15: 11
}

func _ready():
	fill_ground()
	place_special_center()
	blocked_positions.clear()
	block_center_radius(3)
	place_border_spawn_zone()
	place_enemy_spawners()
	generate_paths_from_spawners_to_firewall()
	create_path3d_from_path(path_gen.get_path())
	place_random_decorations()
	generate_functional_elements()
	selected_tower_scene = tower_scene

func fill_ground():
	for x in range(GRID_SIZE.x):
		for z in range(GRID_SIZE.z):
			grid_map.set_cell_item(Vector3i(x, 0, z), GROUND_ID)

func place_special_center():
	firewall_pos = Vector3i(GRID_SIZE.x / 2, 0, GRID_SIZE.z / 2)
	grid_map.set_cell_item(firewall_pos, SPECIAL_CENTER_ID)
	blocked_positions[firewall_pos] = true

func block_center_radius(radius: int):
	var center = firewall_pos
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var pos = center + Vector3i(dx, 0, dz)
			if pos.x >= 0 and pos.x < GRID_SIZE.x and pos.z >= 0 and pos.z < GRID_SIZE.z:
				blocked_positions[pos] = true

func place_border_spawn_zone():
	for x in range(GRID_SIZE.x):
		for z in [0, GRID_SIZE.z - 1]:
			var pos = Vector3i(x, 0, z)
			grid_map.set_cell_item(pos, BORDER_ID)
			blocked_positions[pos] = true
	for z in range(1, GRID_SIZE.z - 1):
		for x in [0, GRID_SIZE.x - 1]:
			var pos = Vector3i(x, 0, z)
			grid_map.set_cell_item(pos, BORDER_ID)
			blocked_positions[pos] = true

func place_enemy_spawners():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var placed = 0
	var tries = 0
	var used_z = []
	var num_spawners = rng.randi_range(1, MAX_SPAWNERS)

	while placed < num_spawners and tries < 200:
		var x = rng.randi_range(0, 5)
		var z = rng.randi_range(1, GRID_SIZE.z - 2)
		var pos = Vector3i(x, 0, z)

		if not blocked_positions.has(pos) and not used_z.any(func(i): abs(z - i) <= 1):
			grid_map.set_cell_item(pos, SPAWNER_ID)
			blocked_positions[pos] = true
			spawn_points.append(pos)
			used_z.append(z)
			placed += 1
		tries += 1

	print("Spawners placés :", placed)

func get_rotation_from_score(score: int) -> float:
	match score:
		5: return 0.0
		10: return 90.0
		3: return 180.0
		6: return 90.0
		9: return 270.0
		12: return 0.0
		7: return 0.0
		11: return 180.0
		13: return 270.0
		14: return 90.0
		15: return 0.0
		_: return 0.0

func place_rotated_tile(id: int, pos: Vector3i, rotation_deg: float):
	var tile = MeshInstance3D.new()
	tile.mesh = grid_map.mesh_library.get_item_mesh(id)
	var local_pos = grid_map.map_to_local(pos)
	local_pos.y += 0.07
	tile.global_transform.origin = local_pos
	tile.rotate_y(deg_to_rad(rotation_deg))
	add_child(tile)
	blocked_positions[pos] = true

func place_path_from_generator(path: Array[Vector2i]):
	for pos2d in path:
		var score = path_gen.get_tile_score(pos2d)
		if tile_score_to_id.has(score):
			var tile_id = tile_score_to_id[score]
			var rotation_deg = get_rotation_from_score(score)
			var pos = Vector3i(pos2d.x, 0, pos2d.y)
			if pos != firewall_pos:
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

func create_path3d_from_path(path: Array[Vector2i]):
	var path_node = Path3D.new()
	var curve = Curve3D.new()
	for i in range(path.size() - 1, -1, -1):
		var point = path[i]
		var pos = Vector3(point.x, 0, point.y)
		curve.add_point(pos)
	path_node.curve = curve
	path_node.name = "EnemyPath"
	add_child(path_node)

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

func generate_functional_elements():
	var tile_path = path_gen.get_path()
	var world_path: Array[Vector3] = []
	for point in tile_path:
		var cell_pos = Vector3i(point.x, 0, point.y)
		var world_pos = grid_map.map_to_local(cell_pos) + Vector3(0.5, 0, 0.5)
		world_path.append(world_pos)

	world_path.reverse()

	for pos in spawn_points:
		for tower_pos in towers.keys():
			if tower_pos == pos:
				towers[tower_pos].queue_free()
				towers.erase(tower_pos)
				break

		var spawner_pos = grid_map.map_to_local(pos) + Vector3(0.5, 0, 0.5)
		var path = Path3D.new()
		var curve = Curve3D.new()

		var start_index = 0
		var min_distance = INF
		for i in range(world_path.size()):
			var d = spawner_pos.distance_to(world_path[i])
			if d < min_distance:
				min_distance = d
				start_index = i

		var partial_path = world_path.slice(start_index, world_path.size())
		if partial_path.size() < 2:
			if world_path.size() >= 2:
				print("Path trop court, fallback complet pour spawner :", spawner_pos)
				partial_path = world_path.duplicate()
			else:
				print("Chemin inutilisable. Aucun ennemi ne sera spawn ici :", spawner_pos)
				continue

		for point in partial_path:
			curve.add_point(point)

		path.curve = curve
		add_child(path)

		var spawner = spawner_scene.instantiate()
		spawner.position = spawner_pos
		spawner.enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		spawner.path_node = path
		add_child(spawner)

	if has_node("game_timer"):
		$game_timer.start()
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = true

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
		var result = get_world_3d().direct_space_state.intersect_ray(ray_params)

		if result.size() > 0:
			var position = result["position"]
			var grid_pos = grid_map.world_to_map(position)
			var world_pos = grid_map.map_to_world(grid_pos)
			var tower = selected_tower_scene.instantiate()
			tower.global_transform.origin = world_pos
			add_child(tower)
			selected_tower_scene = null
