extends StaticBody3D

@export var speed: float = 5  
@export var damage: int = 25  

var target: Node3D = null
var direction: Vector3 = Vector3.ZERO

func _ready():
	if target == null:
		queue_free()

func _process(delta):
	if target != null:
		direction = (target.position - position).normalized()
		position += direction * speed * delta
		if position.distance_to(target.position) < 2:
			on_hit_target()

func on_hit_target():
	if target is CharacterBody3D and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
