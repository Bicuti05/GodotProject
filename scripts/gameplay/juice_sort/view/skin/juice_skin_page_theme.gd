class_name JuiceSkinPageTheme
extends Resource


@export var reference_size: Vector2 = UiMetrics.DESIGN
@export var background_color: Color = Color.WHITE
@export var illustration: Texture2D

@export var illustration_rect: Rect2
@export var quote_rect: Rect2
@export var quote_text_size: Vector2
@export var author_rect: Rect2
@export var quote_color: Color = Color.WHITE
@export var quote_font_size: int = 74
@export var author_font_size: int = 60
@export var progress_track: Texture2D
@export var progress_fill: Texture2D
@export var progress_icon: Texture2D
@export var progress_size: Vector2
@export var progress_bottom_margin: float = 0.0
@export var progress_fill_rect: Rect2
@export var progress_icon_size: Vector2

@export var progress_icon_offset: Vector2
@export var decoration_textures: Array[Texture2D] = []
@export var decoration_rects: Array[Rect2] = []

@export var decoration_anchors: Array[Vector2] = []
