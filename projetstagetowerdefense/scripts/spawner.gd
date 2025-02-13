extends Node2D

@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0  
@export var spawn_radius: float = 200.0  

@onready var timer = $Timer
@onready var tower = get_tree().current_scene.get_node_or_null("Tower")


var spawning_enabled = false

func _ready():
	timer.wait_time = spawn_interval 
	timer.timeout.connect(spawn_enemy)
	timer.stop() 

func start_spawn():
	spawning_enabled = true 
	timer.start() 


func stop_spawn():
	spawning_enabled = false 
	timer.stop()  


func spawn_enemy():
	if tower == null:
		print("⚠️ Erreur : Tour introuvable !")
		return
		
	if !spawning_enabled:
		return  
		
	var angle = randf_range(0, TAU)
	var spawn_position = tower.position + Vector2(spawn_radius * cos(angle), spawn_radius * sin(angle))
	var enemy = enemy_scene.instantiate() 
	enemy.position = spawn_position  
	get_parent().add_child(enemy) 
