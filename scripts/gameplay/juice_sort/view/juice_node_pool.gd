class_name JuiceNodePool
extends Node














@export var item_scene: PackedScene

var _free: Array[Node2D] = []
var _live: Array[Node2D] = []


func acquire(parent: Node) -> Node2D:
	var n: Node2D = _free.pop_back() if not _free.is_empty() else _make()
	if n == null:
		return null
	_live.append(n)
	n.visible = true
	if n.get_parent() != parent:
		if n.get_parent() != null:
			n.get_parent().remove_child(n)
		parent.add_child(n)
	return n


func release(n: Node2D) -> void :
	if n == null or not is_instance_valid(n):
		return
	_live.erase(n)
	if n in _free:
		return
	n.visible = false
	if n.has_method("reset_for_pool"):
		n.call("reset_for_pool")
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	_free.append(n)



func release_all() -> void :

	for n in _live.duplicate():
		release(n)


func live_count() -> int:
	return _live.size()


func _make() -> Node2D:
	if item_scene == null:
		push_error("JuiceNodePool: item_scene 没绑定(应由 .tscn 的 @export 注入)")
		return null
	var n: Node = item_scene.instantiate()
	if n is Node2D:
		return n as Node2D
	push_error("JuiceNodePool: item_scene 的根不是 Node2D")
	n.free()
	return null



func _exit_tree() -> void :
	for n in _free:
		if is_instance_valid(n) and n.get_parent() == null:
			n.queue_free()
	_free.clear()
