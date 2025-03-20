extends Node3D

@export var max_pv: float = 200.0
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  
@export var dead_tower: PackedScene

var enemy_target: Node3D = null
var list_enemies = []
var is_dead = false
var pv : float = max_pv

@onready var tour_health_bar = $SubViewport/TowerHealthBar
@onready var body = $MeshInstance3D/StaticBody3D
@onready var timer = $Timer  
@onready var detection_area = $Area3D 
@onready var mesh_instance = $MeshInstance3D

func _ready():
	body.add_to_group("towers")
	tour_health_bar.value = pv/max_pv * 100
	#timer.wait_time = shoot_interval  
	#timer.timeout.connect(shoot_projectile)  
	#timer.start()  
	
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
		
func take_damage(amount):
	pv -= amount
	pv = max(pv, 0) 
	tour_health_bar.value = pv/max_pv * 100

	if pv <= 0:
		die() 

func die():
	is_dead = true
	tour_health_bar.visible = false
	body.remove_from_group("towers")
	body.queue_free()
	detection_area.queue_free()
	visible = false
	
	# Instancie et ajoute le modèle de la tour morte
	if dead_tower:
		mesh_instance.mesh = null
	timer.stop() 
	get_parent().game_over()
