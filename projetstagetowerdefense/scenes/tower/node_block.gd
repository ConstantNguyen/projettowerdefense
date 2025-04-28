@tool
extends Node3D
class_name MeshLibTool

@export var recursive_local:bool:
	set(value):
		print_debug("recusive local")
		value = false
		make_local($".",$".",$".")
		
	get :
		return false
func make_local(node,parent,node_owner):
	print_debug("making local:" + node.name)
	
	if node != $".":
		if node is MeshInstance3D:
			var duplicate_scene = node.duplicate()
			duplicate_scene.scene_file_path = ""
			duplicate_scene.name = duplicate_scene.name
			
			duplicate_scene.scale = Vector3(2, 2, 2)
			
			parent.add_child(duplicate_scene)
			duplicate_scene.owner = node_owner
			print_debug("found MeshInstance3D" + node.name)
			duplicate_scene.create_trimesh_collision()
			parent = duplicate_scene
			
		node.get_parent().remove_child(node)
	for child in node.get_children():
		make_local(child,parent,node_owner)
		
