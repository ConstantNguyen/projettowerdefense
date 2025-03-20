extends Node3D

@export var vie: int = 200
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  

var enemy_target: Node3D = null
var list_enemies = []

@onready var barre_vie_tour = $SubViewport/TowerHealthBar
@onready var timer = $Timer  
@onready var detection_area = $Area3D  

func _ready():
	barre_vie_tour.value = vie
	timer.wait_time = shoot_interval  
	timer.timeout.connect(shoot_projectile)  
	timer.start()  
	
	detection_area.body_entered.connect(_on_enemy_entered)
	detection_area.body_exited.connect(_on_enemy_exited)

func _on_enemy_entered(enemy):
	if enemy is CharacterBody3D:
		list_enemies.append(enemy)
		if enemy_target == null:  
			change_target()

func _on_enemy_exited(enemy):
	list_enemies.erase(enemy)
	change_target()

func change_target():
	if list_enemies.size() > 0:
		enemy_target = list_enemies[0]
	else:
		enemy_target = null

func shoot_projectile():
	if enemy_target == null:
		return

	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.target = enemy_target
		get_parent().add_child(projectile)
		projectile.position = position
