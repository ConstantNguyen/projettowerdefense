extends Button

@export var activity_button_icon: Texture2D
@export var activity_draggable: PackedScene

var _is_dragging: bool = false
var _draggable: Node3D
var _is_valid_location: bool = false
var _last_valid_location: Vector3
var _cam: Camera3D
const RAYCAST_LENGTH: float = 100.0

func _ready():
	icon = activity_button_icon

	if activity_draggable == null:
		push_error("activity_draggable n'est pas assigné !")
		return

	_draggable = activity_draggable.instantiate()
	get_tree().current_scene.add_child(_draggable)
	_draggable.visible = false

	_cam = get_node("/root/Main/CameraRig/CameraPivot/Camera3D")

	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))
	
	print("Création du fantôme")
	print("_draggable: ", _draggable)

func _physics_process(_delta):
	if _is_dragging:
		var space_state = _cam.get_world_3d().direct_space_state
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = _cam.project_ray_origin(mouse_pos)
		var end = origin + _cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH

		var query = PhysicsRayQueryParameters3D.new()
		query.from = origin
		query.to = end
		query.collide_with_areas = true
		var ray_result: Dictionary = space_state.intersect_ray(query)

		if ray_result.size() > 0:
			var co: CollisionObject3D = ray_result["collider"]
			if co.is_in_group("grid_empty"):
				_is_valid_location = true
				_last_valid_location = Vector3(co.global_position.x, 0.2, co.global_position.z)
				_draggable.global_position = _last_valid_location
				_draggable.visible = true
				clear_child_mesh_error(_draggable)
			else:
				_is_valid_location = false
				_draggable.global_position = Vector3(co.global_position.x, 0.2, co.global_position.z)
				_draggable.visible = true
				set_child_mesh_error(_draggable)
		else:
			_draggable.visible = false

func _on_button_down():
	print("Bouton appuyé")
	_is_dragging = true

	# Supprimer l’ancien _draggable s’il existe
	if _draggable:
		_draggable.queue_free()

	# Création d’un cube simple à la main pour test
	_draggable = MeshInstance3D.new()

	var cube_mesh = BoxMesh.new()
	_draggable.mesh = cube_mesh
	_draggable.scale = Vector3(1, 1, 1)
	_draggable.global_position = Vector3(15, 0, 7)  # Change selon ta map

	get_tree().current_scene.add_child(_draggable)


func _on_button_up():
	_is_dragging = false
	_draggable.visible = false

	if _is_valid_location:
		var tower = activity_draggable.instantiate()
		get_tree().current_scene.add_child(tower)
		tower.global_position = _last_valid_location

func set_child_mesh_error(n: Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_error(c)
		elif c.get_child_count() > 0:
			set_child_mesh_error(c)

func clear_child_mesh_error(n: Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			clear_mesh_error(c)
		elif c.get_child_count() > 0:
			clear_child_mesh_error(c)

func set_mesh_error(mesh: MeshInstance3D):
	for si in mesh.mesh.get_surface_count():
		mesh.set_surface_override_material(si, preload("res://assets/error_material.tres"))

func clear_mesh_error(mesh: MeshInstance3D):
	for si in mesh.mesh.get_surface_count():
		mesh.set_surface_override_material(si, null)
