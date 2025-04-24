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
	if path_node == null:
		push_error("Path node non assigné.")
		return

	var path_follow = preload("res://scripts/RandomLevel/EnemyPathFollow.gd").new()
	path_follow.rotation_mode = PathFollow3D.ROTATION_Y
	path_follow.progress = 0.0

	var enemy = enemy_scene.instantiate()

	path_follow.add_child(enemy)
	path_node.add_child(path_follow)

	path_follow.set_progress(0.0)
