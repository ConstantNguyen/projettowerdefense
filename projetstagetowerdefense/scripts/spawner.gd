extends Node3D

@export var path_node: Node3D
@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 0.00005 

@onready var timer = $Timer
var rng = RandomNumberGenerator.new()

func _ready():
	while not get_parent().started:
		await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(1.0).timeout 
	
	rng.randomize()
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()

	spawn_enemy()


func spawn_enemy():
	var count = rng.randi_range(1, 2)  
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		enemy.switch_path(path_node)
