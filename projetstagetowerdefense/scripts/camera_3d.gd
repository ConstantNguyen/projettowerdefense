extends Node3D

@export var move_speed: float = 5.0   
@export var look_sensitivity: float = 0.3  

var velocity = Vector3.ZERO
var rotation_x = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	velocity = Vector3.ZERO  

	if Input.is_action_pressed("move_forward"):
		velocity -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		velocity += transform.basis.z
	if Input.is_action_pressed("move_left"):
		velocity -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		velocity += transform.basis.x

	velocity = velocity.normalized() * move_speed * delta
	global_translate(velocity)

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotation.y -= event.relative.x * look_sensitivity * 0.01
		rotation_x -= event.relative.y * look_sensitivity * 0.01
		rotation_x = clamp(rotation_x, -1.5, 1.5)  # Empêche de regarder trop haut/bas
		rotation = Vector3(rotation_x, rotation.y, 0)
