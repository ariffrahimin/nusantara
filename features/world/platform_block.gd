class_name PlatformBlock
extends StaticBody2D

## Reusable greybox platform with automatic visual + collision shape sizing and one-way support.

@export var size: Vector2 = Vector2(256, 32)
@export var one_way: bool = false
@export var fill_color: Color = Color(0.26, 0.36, 0.24, 1.0)
@export var top_trim_color: Color = Color(0.56, 0.76, 0.38, 1.0)

func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	shape_node.position = Vector2(0, size.y * 0.5)
	shape_node.one_way_collision = one_way
	add_child(shape_node)

	var body_poly := Polygon2D.new()
	var hw := size.x * 0.5
	body_poly.color = fill_color
	body_poly.polygon = PackedVector2Array([
		Vector2(-hw, 0),
		Vector2(hw, 0),
		Vector2(hw, size.y),
		Vector2(-hw, size.y)
	])
	add_child(body_poly)

	var trim_poly := Polygon2D.new()
	trim_poly.color = top_trim_color
	var trim_h := minf(6.0, size.y)
	trim_poly.polygon = PackedVector2Array([
		Vector2(-hw, 0),
		Vector2(hw, 0),
		Vector2(hw, trim_h),
		Vector2(-hw, trim_h)
	])
	add_child(trim_poly)
