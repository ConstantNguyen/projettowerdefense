extends StaticBody3D

@export var speed: float = 300  
@export var damage: int = 25  

var target: Node3D = null
var direction: Vector3 = Vector3.ZERO

func _ready():
	set_process(true)
#Ca marche pas dutout j'arrive pas à afficher ce qui me sert de projectile mais les mecs prennent des dégats donc OKLM 
func _process(delta):
	if target != null:
		direction = (target.position - position).normalized()
		position += direction * speed * delta
		if position.distance_to(target.position) < 10:
			on_hit_target()

func on_hit_target():
	target.take_damage(damage)
	queue_free() 
