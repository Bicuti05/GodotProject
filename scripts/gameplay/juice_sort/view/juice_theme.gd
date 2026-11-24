class_name JuiceTheme
extends RefCounted

























const COLOR_KEYS: PackedStringArray = [
	"red", "purple", "pink", "cyan", "yellow", "green", "blue", "teal", "orange", "lavender", 
]

const FRUIT_NAMES: PackedStringArray = [
	"watermelon", "orange", "coconut", "plum", "pineapple", 
	"strawberry", "kiwi", "dragonfruit", "blueberry", "banana", 
]






const PARK_COLOR: = Color("#BFD0DE")
const SUN_COLOR: = Color("#FFD166")
const YELLOW_SLOT: int = 4











const SLOT_ORDER: PackedInt32Array = [0, 6, 4, 1, 2, 8, 3, 5, 9, 7]



static func slots_for(level: int, types: int) -> PackedInt32Array:
	if types > SLOT_ORDER.size():
		SortLogger.error("JuiceTheme: 第 %d 关要 %d 种水果,但只有 %d 种可用颜色" % [level, types, SLOT_ORDER.size()])
	return SLOT_ORDER.slice(0, mini(types, SLOT_ORDER.size()))



static func resolve_slots(level: int, types: int, saved: PackedInt32Array) -> PackedInt32Array:
	if saved.size() == types:
		var seen: Dictionary = {}
		var valid: bool = true
		for slot: int in saved:
			if slot < 0 or slot >= SLOT_ORDER.size() or seen.has(slot):
				valid = false
				break
			seen[slot] = true
		if valid:
			return saved.duplicate()
	return slots_for(level, types)


static func sunlight_pot_slots(slots: PackedInt32Array, sunlight_type: int) -> PackedInt32Array:
	var result: PackedInt32Array = slots.duplicate()
	if sunlight_type < 0 or sunlight_type >= result.size():
		return result
	var yellow_type: int = result.find(YELLOW_SLOT)
	if yellow_type < 0 or yellow_type == sunlight_type:
		return result
	var replacement: int = result[sunlight_type]
	var used: Dictionary = {}
	for type_id: int in result.size():
		if type_id != sunlight_type and type_id != yellow_type:
			used[result[type_id]] = true
	if replacement == YELLOW_SLOT or used.has(replacement):
		replacement = -1
		for slot: int in SLOT_ORDER:
			if slot != YELLOW_SLOT and not used.has(slot):
				replacement = slot
				break
	if replacement < 0:
		return result
	result[yellow_type] = replacement
	result[sunlight_type] = YELLOW_SLOT
	return result




static func color_of_slot(slot: int, skin: JuiceSkin) -> Color:
	if skin == null or slot < 0 or slot >= skin.colors.size():
		return PARK_COLOR
	return skin.colors[slot]


static func name_of_slot(slot: int) -> String:
	if slot == 10:
		return "violet"
	if slot == 11:
		return "lime"
	if slot < 0 or slot >= FRUIT_NAMES.size():
		return "park"
	return FRUIT_NAMES[slot]
