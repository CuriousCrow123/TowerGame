class_name Ground
extends StaticBody2D


func _ready() -> void:
	set_process(false)
	set_physics_process(false)

	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	physics_material_override = mat
