class_name JuiceSkinDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var revision: int = 1
@export var page_theme: JuiceSkinPageTheme

@export var toast_keys: Dictionary[String, String] = {}
@export var colors: Array[JuiceSkinColorAssets] = []

@export var target_empty_icon: JuiceSkinVisual

@export var target_bar_max_visible_count: int = 0

@export var guide_target_empty_icon: JuiceSkinVisual

@export var guide_connect_same_color: JuiceSkinVisual
@export var guide_collect_by_color: JuiceSkinVisual
@export var guide_use_empty_ropes: JuiceSkinVisual


@export var rank_collectible_elements: Array[JuiceSkinVisual] = []
@export var rank_collectible_container: JuiceSkinVisual
@export var rank_collectible_target: JuiceSkinVisual

@export var rank_collectible_targets: Array[JuiceSkinVisual] = []

@export var rank_collectible_target_height_ratio: float = 0.0

@export var rank_collectible_rope_top: JuiceSkinVisual
@export var rank_collectible_rope_mid: JuiceSkinVisual
@export var rank_collectible_rope_bottom: JuiceSkinVisual

@export var rank_collectible_rope_body_rows: Vector2 = Vector2.ZERO
@export var parking_container: JuiceSkinVisual
@export var parking_rope_top: JuiceSkinVisual
@export var parking_rope_mid: JuiceSkinVisual
@export var parking_rope_bottom: JuiceSkinVisual
@export var mystery_element: JuiceSkinVisual
@export var collect_animation: JuiceSkinAnimationAssets

@export var collection_butterflies_enabled: bool = false
@export var door_frames: Array[Texture2D] = []
@export var door_closed_rect: Rect2 = Rect2(12, 17, 126, 120)
@export var bird_mouth_rect: Rect2 = Rect2(60, 78, 61, 61)
@export var effects: JuiceSkinEffectAssets

@export var sounds: Dictionary[StringName, StringName] = {}
