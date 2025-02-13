extends Area2D

@export var speed: float = 300
@export var damage: int = 25
var direction: Vector2
var target: Node2D  # L'ennemi visé

func _ready():
	# S'assurer que le projectile ne détecte pas la tour
	set_collision_mask_value(1, false)  # Désactiver la collision avec la tour
	set_process(true)

func _process(delta):
	if target.position != Vector2.ZERO:
			direction = (target.position - position).normalized()
			position += direction * speed * delta
			if position.distance_to(target.position) < 10:
				on_hit_target()

# Quand le projectile touche quelque chose
func _on_area_entered(area):
	if area.is_in_group("enemies"):
		#print("Ennemi touché !")
		on_hit_target()
		area.take_damage(damage)
		
			
func on_hit_target():
	target.take_damage(damage)
	queue_free() 
