extends PathFollow3D

@export var speed := 0.03
var started := false

func _ready():
	await get_tree().process_frame
	started = true

func _physics_process(delta):
	if started:
		progress += speed * delta
