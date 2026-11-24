class_name JuiceSkinEffectAssets
extends Resource


@export var rope_petal: Texture2D
@export var rope_star: Texture2D

@export var rank_collectible_connection_01: Texture2D
@export var rank_collectible_connection_02: Texture2D

@export var rank_collectible_connection_size: Vector2 = Vector2.ZERO
@export var rank_collectible_collection_size: Vector2 = Vector2.ZERO
@export var unlock_leaf: Texture2D
@export var unlock_glow: Texture2D
@export var complete_column_glow: Texture2D
@export var mystery_petal: Texture2D

@export var mystery_particles: Array[Texture2D] = []
@export_range(0.1, 8.0, 0.1) var mystery_particle_size_correction: float = 1.0
@export var mystery_glow: Texture2D
@export var mystery_flash: Texture2D
@export var mystery_star: Texture2D
@export var cup_bloom: Texture2D
@export var quota_ring: Texture2D

@export var quota_ring_center: Vector2 = Vector2(0.5, 0.5)
@export var quota_ring_shape: Vector2 = Vector2.ONE
@export var progress_dot: Texture2D
@export var progress_star: Texture2D
@export var progress_flower: Texture2D
@export var ice_sparkle: Texture2D
@export var ice_shard: Texture2D
@export var landing_star: Texture2D

@export var collection_particles: Array[Texture2D] = []

@export_range(0.1, 8.0, 0.1) var collection_particle_size_correction: float = 1.0

@export_range(0.0, 8.0, 0.1) var connection_particle_size_correction: float = 0.0
@export var progress_colors: Array[Texture2D] = []
@export var progress_excellent: Texture2D
@export var butterflies: Array[PackedScene] = []
