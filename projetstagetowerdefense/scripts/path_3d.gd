extends Path3D

@export var line_color: Color = Color.RED

@onready var path = $CSGPolygon3D

func _ready():
	var material = StandardMaterial3D.new()
	
	# Change la couleur d'albédo (couleur de base)
	material.albedo_color = line_color
	
	# Applique le matériau au mesh
	path.material_override = material
