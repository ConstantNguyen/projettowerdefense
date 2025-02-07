extends Node2D

@export var vie: int = 200
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  

var enemie_cible: Node2D = null
var liste_ennemi = []

@onready var barre_vie_tour = $ProgressBar  
@onready var timer = $Timer  
@onready var detection_area = $Area2D  

func _ready():
	barre_vie_tour.value = vie
	timer.wait_time = shoot_interval  
	timer.timeout.connect(shoot_projectile)  
	timer.start()  
	
	detection_area.body_entered.connect(_on_enemy_entered)
	detection_area.body_exited.connect(_on_enemy_exited) 

func _on_enemy_entered(enemy):
	if enemy.is_in_group("enemies"): 
		enemie_cible = enemy  
		liste_ennemi.append(enemy)
		#print(liste_ennemi) POUR MES TESTS MAIS CA FONCTIONNE PAS DUTOUT JAI ESSAYE UNE LOGIQUE MAUVAISE JE PENSE
		

func _on_enemy_exited(enemy):
	if enemy == enemie_cible:  
		enemie_cible = null

func shoot_projectile():
	if enemie_cible and projectile_scene:
		print("La tour tire sur l'ennemi")
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.position = position
		projectile.target_position = enemie_cible.position
		projectile.direction = (enemie_cible.position - position).normalized()
		projectile.speed = 300
