class_name JuiceSkinAnimationAssets
extends Resource


@export var scene: PackedScene
@export var color_keys: PackedStringArray = PackedStringArray()
@export var skin_prefix: String = "flower_"
@export var slot_prefixes: PackedStringArray = PackedStringArray(["pen_", "flower_"])
@export var get_animation: StringName = &"get"
@export var idle_animation: StringName = &"idle"
@export var end_animation: StringName = &"end"
@export var reference_width: float = 1440.0

@export var collection_display_scale: float = 1.0
@export var bottom_center: Vector2 = Vector2(1.5164, 896.81)
@export var offset_y: float = -30.0
