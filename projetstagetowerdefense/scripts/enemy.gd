extends CharacterBody2D

@export var vitesse: float = 90.0 
@export var vie: int = 100  
@export var damage: int = 10
@export var attack_interval: float = 1.0  

var position_tour: Vector2 
var mort: bool = false   
var tour: StaticBody2D = null 
var is_attacking: bool = false  

@onready var barre_de_vie = $ProgressBar  
@onready var attack_timer = Timer.new()

func _ready():
	barre_de_vie.value = vie  

	var main_scene = get_tree().current_scene  
	tour = main_scene.get_node_or_null("Tower")  
	if tour:
		position_tour = tour.position 
	else:
		print("⚠️ Erreur : La tour n'a pas été trouvée !")

	add_to_group("enemies")

	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _physics_process(delta):
	if mort:
		return  	
	var direction = (position_tour - position).normalized()
	velocity = direction * vitesse 
	move_and_slide() 

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Tower":
			start_attack()
			return 

	stop_attack()

func take_damage(amount):
	vie -= amount
	barre_de_vie.value = vie  
	if vie <= 0:
		die()  

func die():
	mort = true
	queue_free()

func start_attack():
	if not is_attacking:  
		is_attacking = true
		attack_timer.start()

func stop_attack():
	if is_attacking:  
		is_attacking = false
		attack_timer.stop()

func _on_attack_timer_timeout():
	if is_attacking and tour:  
		tour.take_damage(damage)
