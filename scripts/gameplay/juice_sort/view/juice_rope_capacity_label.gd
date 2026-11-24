class_name JuiceRopeCapacityLabel
extends Control



const HEIGHT: float = 67.0
const MASK_GAP: float = 4.0

@onready var _label: Label = $Root / Label

var _count: int = -1
var _capacity: int = -1


func set_capacity(count: int, capacity: int) -> void :
	if count == _count and capacity == _capacity:
		return
	_count = count
	_capacity = capacity
	_label.text = "%d/%d" % [count, capacity]


func reset_for_pool() -> void :
	hide()
	_count = -1
	_capacity = -1
	_label.text = ""
