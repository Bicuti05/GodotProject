class_name RankCollectElementPool
extends Node


@export var fixed_texture: Texture2D = null

var presentation_texture: Texture2D = null
@export var collectible_textures: Array[Texture2D] = []


func get_texture() -> Texture2D:
	if presentation_texture != null:
		return presentation_texture
	return get_texture_for_index(RankManager.get_collectible_index())

func get_texture_for_index(index: int) -> Texture2D:
	if index >= 0 and index < collectible_textures.size():
		return collectible_textures[index]
	return fixed_texture
