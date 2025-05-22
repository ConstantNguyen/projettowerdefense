extends Button

@export var activity_draggable: PackedScene
var gestion_tour = preload("res://scripts/RandomLevel/TowerManager.gd").new()
var _is_dragging: bool = false
var _draggable: Node3D
var _is_valid_location: bool = false
var _last_valid_location: Vector3
var _cam: Camera3D
const RAYCAST_LENGTH: float = 100

func _ready():
	add_to_group("towers")
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))
	_cam = get_tree().current_scene.get_node("CameraRig/CameraPivot/Camera3D")

func _on_button_down():
	if activity_draggable == null:
		push_error("No tower scene assigned to activity_draggable!")
		return

	_is_dragging = true
	_draggable = activity_draggable.instantiate()
	get_tree().current_scene.add_child(_draggable)
	_draggable.visible = true
	_draggable.global_position = Vector3(0, 2, 0)

func _on_button_up():
	_is_dragging = false
	if _is_valid_location and _draggable:
		var placed_tower = activity_draggable.instantiate()
		placed_tower.global_position = _last_valid_location
		get_tree().current_scene.add_child(placed_tower)

		gestion_tour.add_tower(placed_tower)
	if _draggable:
		_draggable.queue_free()

func _physics_process(_delta):
	if not _is_dragging or _cam == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var origin = _cam.project_ray_origin(mouse_pos)
	var end = origin + _cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH

	var space_state = _cam.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = end
	var result = space_state.intersect_ray(query)

	if result.size() > 0:
		_last_valid_location = result["position"]
		_is_valid_location = true
		if _draggable:
			_draggable.global_position = _last_valid_location
	else:
		_is_valid_location = false
