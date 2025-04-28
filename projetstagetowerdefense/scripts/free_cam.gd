@tool
extends Node3D

@export var pivot_node_path := NodePath("CameraPivot")
@export var camera_distance := 20.0
@export var zoom_speed := 2.0
@export var zoom_min := 5.0
@export var zoom_max := 40.0
@export var rotate_speed := 0.01

var pivot: Node3D = null
var camera: Camera3D = null
var rotation_x := 0.0
var rotation_y := -0.5
var is_rotating := false
var last_mouse_pos := Vector2.ZERO

func _ready():
	pivot = get_node_or_null(pivot_node_path)
	if not pivot:
		push_error("Pivot node not found at path: " + str(pivot_node_path))
		return

	camera = pivot.get_node_or_null("Camera3D")
	if not camera:
		push_error("Camera3D not found as child of pivot.")
		return

	# Centrer le pivot sur la map si besoin
	var current_scene_path = get_tree().current_scene.scene_file_path
	# Map aléatoire
	if current_scene_path.ends_with("main.tscn"):
		pivot.global_transform.origin = Vector3(15, 0, 7)
	# Map prédéfini
	else:
		pivot.global_transform.origin = Vector3.ZERO
	_update_camera_position()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			if is_rotating:
				last_mouse_pos = event.position

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance += zoom_speed

		camera_distance = clamp(camera_distance, zoom_min, zoom_max)

	if event is InputEventMouseMotion and is_rotating:
		var delta = event.relative
		rotation_x -= delta.x * rotate_speed
		rotation_y = clamp(rotation_y - delta.y * rotate_speed, deg_to_rad(-80), deg_to_rad(80))

func _process(delta):
	_update_camera_position()

func _update_camera_position():
	if not camera or not pivot:
		return

	var rotation = Basis(Vector3.UP, rotation_x) * Basis(Vector3.RIGHT, rotation_y)
	var offset = rotation * Vector3(0, 0, camera_distance)
	camera.global_transform.origin = pivot.global_transform.origin + offset
	camera.look_at(pivot.global_transform.origin, Vector3.UP)
