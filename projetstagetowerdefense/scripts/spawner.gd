extends Node3D

@export var path_node: Node3D
@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0 

@onready var timer = $Timer

func _ready():
	await get_tree().create_timer(3.0).timeout
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()
	spawn_enemy()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.switch_path(path_node)
