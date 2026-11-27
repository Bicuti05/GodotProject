extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var bank: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var output: Array = []
	for chapter in bank.data:
		for value in chapter.values():
			if value is Array:
				for row in value:
					if row is Dictionary and row.has("initialLayout"):
						var raw: Variant = JSON.parse_string(AESDecryptor.decrypt(row.initialLayout))
						if raw is Dictionary:
							output.append({"key": row.get("levelUniqueId", str(output.size() + 1)), "raw": raw})
	var out := FileAccess.open(args[1], FileAccess.WRITE)
	out.store_string(JSON.stringify(output))
	print(output.size())
	quit()
