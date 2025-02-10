extends Node2D

@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0 

@onready var timer = $Timer

func _ready():
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()

func spawn_enemy():
	var enemy = enemy_scene.instantiate() 
	enemy.position = Vector2(randi_range(100, 500), randi_range(50, 300))
	get_parent().add_child(enemy)
