extends Node3D

@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0 

@onready var timer = $Timer

func _ready():
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()
	spawn_enemy()
	

func spawn_enemy():
	print('spawn')
	var enemy = enemy_scene.instantiate() 
	enemy.position = Vector3(randi_range(1, 5), 0, randi_range(1, 5))
	get_parent().add_child.call_deferred(enemy)
