extends PathFollow3D

@export var speed := 0.03

func _physics_process(delta):
	progress += speed * delta
