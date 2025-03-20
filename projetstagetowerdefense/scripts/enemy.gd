extends CharacterBody3D

@export var vitesse: float = 0.5
@export var vie: int = 100  

@onready var barre_de_vie = $SubViewport/EnemyHealthBar  

var position_tour: Vector3 
var mort: bool = false  

func _ready():
	add_to_group("enemies")
	barre_de_vie.value = vie
	var main_scene = get_tree().current_scene  
	var tower = main_scene.get_node_or_null("TowerBasic")  
	if tower:
		position_tour = tower.position 
	else:
		print("⚠️ Erreur : La tour n'a pas été trouvée !")
		position_tour = Vector3(0,0,0)
	

func _physics_process(delta):
	if mort:
		return
	var direction = (position_tour - position).normalized()
	velocity = direction * vitesse 
	move_and_slide()


func take_damage(amount):
	vie -= amount
	barre_de_vie.value = vie  

	if vie <= 0:
		die()  

func die():
	mort = true
	queue_free()

func _on_area_2d_body_entered(body):
	if body.name == "Tower": 
		print("L'ennemi attaque la tour !") 
		queue_free()
