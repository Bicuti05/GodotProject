class_name OuterLoopPlan
extends RefCounted








enum Mode{STEADY, RISE, CROSS}

var mode: int = Mode.STEADY


var bg_chapter: int = 1
var bubble_chapter: int = 2

var done: int = 0

var done_from: int = 0
var done_to: int = 0

var from_bg_chapter: int = 1
var from_bubble_chapter: int = 2
var from_done: int = 0
var to_bg_chapter: int = 1
var to_bubble_chapter: int = 2
var to_done: int = 0

static func compute(current_level: int, level_won: bool, chapter_size: int) -> OuterLoopPlan:
	var p: = OuterLoopPlan.new()
	var lv: int = maxi(1, current_level)
	var c: int = (lv - 1) / chapter_size + 1
	var idx: int = (lv - 1) % chapter_size
	var crossing: bool = level_won and idx == 0 and lv > 1
	var partial: bool = level_won and idx != 0
	if crossing:
		p.mode = Mode.CROSS
		p.from_bg_chapter = c - 1
		p.from_bubble_chapter = c
		p.from_done = chapter_size - 1
		p.to_bg_chapter = c
		p.to_bubble_chapter = c + 1
		p.to_done = 0
	elif partial:
		p.mode = Mode.RISE
		p.bg_chapter = c
		p.bubble_chapter = c + 1
		p.done_to = idx
		p.done_from = idx - 1
	else:
		p.mode = Mode.STEADY
		p.bg_chapter = c
		p.bubble_chapter = c + 1
		p.done = idx
	return p
