extends Node3D

@onready var grid_map := $GridMap
@export var tower_scene: PackedScene

var blocked_positions: Dictionary = {}
var towers: Dictionary = {}
var placed_towers := 0
const MAX_TOWERS := 4

func _ready():
	pass

func _unhandled_input(event):
	pass

func get_cell_under_mouse() -> Vector3i:
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = ray_origin
	ray_params.to = ray_origin + ray_direction * 1000

	var result = get_world_3d().direct_space_state.intersect_ray(ray_params)

	if result.has("position"):
		var world_pos = result["position"]
		return grid_map.local_to_map(world_pos)

	return Vector3i(-1, -1, -1)  # ← retourne une valeur "nulle safe"

func is_cell_placeable(pos: Vector3i) -> bool:
	if pos == Vector3i(-1, -1, -1):
		return false

	var ground_pos = Vector3i(pos.x, 0, pos.z)
	var above_pos = Vector3i(pos.x, 1, pos.z)

	if blocked_positions.has(ground_pos):
		return false

	if grid_map.get_cell_item(above_pos) != -1:
		return false

	if towers.has(above_pos):
		return false

	return true

func place_tower(pos: Vector3i):
	var world_pos = grid_map.map_to_local(pos)
	var tower = tower_scene.instantiate()
	tower.global_position = world_pos
	add_child(tower)
	towers[pos] = tower

func can_place_tower() -> bool:
	return placed_towers < MAX_TOWERS

func notify_tower_placed():
	placed_towers += 1
	print("Tours placées :", placed_towers)
