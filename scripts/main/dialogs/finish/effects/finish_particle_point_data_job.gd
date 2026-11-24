class_name FinishParticlePointDataJob
extends RefCounted


const POINT_COUNT: int = 64
const CARD_COUNT: int = 3
const HALF_SIZE: Vector2 = Vector2(140.0, 269.2308 * 0.5)

var _task_id: int = -1
var _result: Array[PackedByteArray] = []
var _seed: int


func request(seed_value: int) -> void :
	if _task_id != -1 or not _result.is_empty():
		return
	_seed = seed_value
	_task_id = WorkerThreadPool.add_task(_compute, false, "finish particle points")


func is_ready() -> bool:
	return (_task_id == -1 and not _result.is_empty()) or (_task_id != -1 and WorkerThreadPool.is_task_completed(_task_id))



func collect() -> Array[PackedByteArray]:
	if _task_id != -1:
		assert (WorkerThreadPool.is_task_completed(_task_id))
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	return _result


func _compute() -> void :
	var result: Array[PackedByteArray] = []
	var rng: = RandomNumberGenerator.new()
	rng.seed = _seed
	for i: int in CARD_COUNT:
		result.append(generate(rng))
	_result = result


static func generate(rng: RandomNumberGenerator) -> PackedByteArray:
	var pixels: = PackedByteArray()
	pixels.resize(POINT_COUNT * 12)
	for i: int in POINT_COUNT:
		var point: Vector2
		match i % 4:
			0: point = Vector2(rng.randf_range( - HALF_SIZE.x, HALF_SIZE.x), - HALF_SIZE.y + rng.randf() * 5.0)
			1: point = Vector2(rng.randf_range( - HALF_SIZE.x, HALF_SIZE.x), HALF_SIZE.y - rng.randf() * 5.0)
			2: point = Vector2( - HALF_SIZE.x + rng.randf() * 5.0, rng.randf_range( - HALF_SIZE.y, HALF_SIZE.y))
			3: point = Vector2(HALF_SIZE.x - rng.randf() * 5.0, rng.randf_range( - HALF_SIZE.y, HALF_SIZE.y))
		pixels.encode_float(i * 12, point.x)
		pixels.encode_float(i * 12 + 4, point.y)
		pixels.encode_float(i * 12 + 8, 0.0)
	return pixels
