extends Area2D

@export var speed: float = 300  
@export var damage: int = 25  

var target_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO

func _ready():
	set_process(true)
#Ca marche pas dutout j'arrive pas à afficher ce qui me sert de projectile mais les mecs prennent des dégats donc OKLM 
func _process(delta):
	if target_position != Vector2.ZERO:
		position += direction * speed * delta
		if position.distance_to(target_position) < 10:
			on_hit_target()

func on_hit_target():
	var enemy = get_parent().get_node_or_null("Enemy") 
	if enemy and enemy.is_in_group("enemies"):
		enemy.take_damage(damage)
	queue_free() 
