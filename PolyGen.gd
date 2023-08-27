@tool
extends Node3D

# Author: Jason Rametta

@export var sides: int = 8
@export var layers: int = 5
@export var width_curve: Curve
@export var height_curve: Curve
@export var x_offset_curve: Curve
@export var material: StandardMaterial3D = StandardMaterial3D.new()
@export var uv_scale: Vector2 = Vector2(1.0, 1.0)

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func uv(vertex: Vector3) -> Vector2:
	var normed = vertex.normalized()
	return abs(Vector2(normed.x, normed.y) * uv_scale)
	
func _process(_delta) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	
	var center = Vector3.ZERO
	st.set_uv(uv(center))
	st.add_vertex(center)
	
	var points_index = 0
	
	var first_width_sample = width_curve.sample(0)
	for side in range(sides):
		var u = float(side) / sides
		var x = cos(u * PI * 2.0) * first_width_sample
		var z = sin(u * PI * 2.0) * first_width_sample
		var point = Vector3(x, 0, z)
		st.set_uv(uv(point))
		st.add_vertex(point)
		points_index += 1
		
		if side > 1:
			st.add_index(side - 1)
			st.add_index(side)
			st.add_index(0)
		
	st.add_index(sides)
	st.add_index(1)
	st.add_index(0)
	
	st.add_index(0)
	st.add_index(sides - 1)
	st.add_index(sides)

	for layer in range(layers):
		var curve_sample = float(layer) / float(layers)
		var width_sample = width_curve.sample(curve_sample)
		var height_sample = height_curve.sample(curve_sample)
		var x_offset_sample = x_offset_curve.sample(curve_sample)
		var y = height_sample * layer
		var prev_row_first_index = points_index - sides + 1
		var prev_row_last_index = points_index
		var this_row_first_index = points_index + 1

		for side in range(sides):
			var u = float(side) / sides
			var x = cos(u * PI * 2.0) * width_sample + x_offset_sample
			var z = sin(u * PI * 2.0) * width_sample
			var point = Vector3(x, y, z)
			st.set_uv(uv(point))
			st.add_vertex(point)
			points_index += 1
			
			if side > 0:
				st.add_index(points_index)
				st.add_index(points_index - sides)
				st.add_index(points_index - sides - 1)
				
				st.add_index(points_index - sides - 1)
				st.add_index(points_index - 1)
				st.add_index(points_index)
				
		st.add_index(prev_row_first_index)
		st.add_index(points_index)
		st.add_index(this_row_first_index)
		
		st.add_index(points_index)
		st.add_index(prev_row_first_index)
		st.add_index(prev_row_last_index)
		
	# close the shape
	var height_sample_last = height_curve.sample(1)
	var y = height_sample_last * (layers - 1)
	
	var last_center = Vector3(0, y, 0)
	st.set_uv(uv(last_center))
	st.add_vertex(last_center)
	points_index += 1
	
	for side in range(sides):
		st.add_index(points_index)
		st.add_index(points_index - side)
		st.add_index(points_index - side - 1)
		
	st.add_index(points_index - sides)
	st.add_index(points_index - 1)
	st.add_index(points_index)

	st.generate_normals()
	st.generate_tangents()

	mesh_instance.mesh = st.commit()
