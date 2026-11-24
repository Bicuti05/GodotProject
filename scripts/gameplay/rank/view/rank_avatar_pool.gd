class_name RankAvatarPool
extends Node


@export var textures: Array[Texture2D] = []


func get_texture(avatar_index: int) -> Texture2D:
	if textures.is_empty():
		return null
	var index: int = avatar_index - 1
	return textures[index] if index >= 0 and index < textures.size() else textures[0]
