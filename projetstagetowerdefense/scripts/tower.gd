extends StaticBody2D

signal vie_mise_a_jour(nouvelle_vie)

@export var vie: int = 200
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  
@export var tour_morte_texture: Texture  

var enemy_target: Node2D = null
var list_enemies = []
var mort: bool = false  

@onready var barre_vie_tour = $ProgressBar  
@onready var timer = $Timer  
@onready var detection_area = $Area2D  
@onready var affichageTour = $Sprite2D

func _ready():
	barre_vie_tour.value = vie
	timer.wait_time = shoot_interval  
	timer.timeout.connect(shoot_projectile)  
	timer.start()  
	
	detection_area.body_entered.connect(_on_enemy_entered)
	detection_area.body_exited.connect(_on_enemy_exited)

func _on_enemy_entered(enemy):
	list_enemies.append(enemy)
	if enemy_target == null:  
		change_target()
		
func _on_enemy_exited(enemy):
	list_enemies.erase(enemy)
	change_target()

func change_target():
	if list_enemies.size() > 0 :
		enemy_target = list_enemies[0]
	else :
		enemy_target = null
	
func shoot_projectile():
	if enemy_target and projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.position = position
		projectile.target = enemy_target
		projectile.speed = 300

func take_damage(amount):
	vie -= amount
	vie = max(vie, 0) 
	barre_vie_tour.value = vie  
	emit_signal("vie_mise_a_jour", vie) 

	if vie <= 0:
		die() 

func die():
	mort = true
	barre_vie_tour.visible = false
	if tour_morte_texture:
		affichageTour.texture = tour_morte_texture
	timer.stop() 
	get_parent().game_over()
