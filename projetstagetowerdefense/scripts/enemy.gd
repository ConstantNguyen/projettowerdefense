extends CharacterBody3D

@export var speed: float = 0.005
@export var max_pv: float = 20.0
@export var attack_interval = 1.5

@onready var health_bar = $SubViewport/EnemyHealthBar  
@onready var detection_area = $Area3D 
@onready var attack_timer = $Timer


var tower: Node 
var is_dead: bool = false  
var is_attacking = false
var parent = null
var pv : float = max_pv

func _ready():
	detection_area.body_entered.connect(_on_detection_zone_body_entered)
	health_bar.value = pv/max_pv * 100
	if get_parent() is PathFollow3D :
		parent = get_parent()
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _physics_process(delta):
	if is_dead:
		return
	if is_attacking :
		parent.progress = parent.progress
		if tower.is_dead : 
			is_attacking = false
	else : 
		parent.progress += speed + delta 


func take_damage(amount):
	pv -= amount
	health_bar.value = pv/max_pv * 100

	if pv <= 0:
		die()  

func die():
	is_dead = true
	queue_free()

func _on_detection_zone_body_entered(body):
	if body.is_in_group("towers"):  # Vérifie si c'est une tour
		is_attacking = true
		tower = body.get_parent().get_parent() 
		attack(tower)

func _on_attack_timer_timeout() : 
	if is_attacking : 
		attack(tower)

func attack(target):
	target.take_damage(0)
	take_damage(10)
	
	
