extends Node3D

@export var path_node: Node3D
@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0 

@onready var timer = $Timer

func _ready():
	await get_tree().create_timer(3.0).timeout
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy_on_randomLvl)
	timer.start()
	spawn_enemy_on_randomLvl()

func spawn_enemy_on_randomLvl():
	if path_node == null or not path_node.curve or path_node.curve.get_point_count() < 2:
		push_error("Path non défini ou trop court")
		return

	var enemy = enemy_scene.instantiate()
	var baked_points = path_node.curve.get_baked_points()
	enemy.path_points = baked_points
	enemy.global_position = baked_points[0]

	if enemy.has_method("_manual_ready_path_logic"):
		enemy._manual_ready_path_logic()

	add_child(enemy)
