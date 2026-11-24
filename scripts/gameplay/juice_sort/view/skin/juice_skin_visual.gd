class_name JuiceSkinVisual
extends Resource


@export var texture: Texture2D
@export var content_rect: Rect2 = Rect2()
@export var visual_center: Vector2 = Vector2(0.5, 0.5)
@export var bottom_anchor: Vector2 = Vector2(0.5, 1.0)
@export var size_correction: float = 1.0
@export var offset: Vector2 = Vector2.ZERO

@export var source_bottom: float = 0.0

@export var source_bounds: Rect2 = Rect2()


func display_rect(reference: Rect2) -> Rect2:
	var content: Rect2 = content_rect if content_rect.has_area() else Rect2(Vector2.ZERO, texture.get_size())
	var fit_scale: Vector2 = reference.size / content.size * size_correction
	var center: Vector2 = reference.get_center() + offset * fit_scale
	return Rect2(center - content.get_center() * fit_scale, texture.get_size() * fit_scale)
