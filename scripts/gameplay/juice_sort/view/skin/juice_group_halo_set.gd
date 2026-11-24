class_name JuiceGroupHaloSet
extends Resource








@export var sources: Array[Texture2D] = []

@export var halos: Array[Texture2D] = []


@export var canvas_ratios: PackedFloat32Array = PackedFloat32Array()

var _halo_by_source: Dictionary[Texture2D, Texture2D] = {}
var _ratio_by_source: Dictionary[Texture2D, float] = {}
var _map_built: bool = false



func halo_for(source: Texture2D) -> Texture2D:
	_build_map()
	return _halo_by_source.get(source)


func canvas_ratio_for(source: Texture2D) -> float:
	_build_map()
	return float(_ratio_by_source.get(source, 0.0))


func _build_map() -> void :
	if _map_built:
		return
	_map_built = true
	if sources.size() != halos.size() or sources.size() != canvas_ratios.size():
		SortLogger.error("JuiceGroupHaloSet: 条目数量不一致 sources=%d halos=%d ratios=%d"
			%[sources.size(), halos.size(), canvas_ratios.size()])
		return
	for index in sources.size():
		var source: Texture2D = sources[index]
		var halo: Texture2D = halos[index]
		if source == null or halo == null:
			SortLogger.error("JuiceGroupHaloSet: 第 %d 项缺少贴图" % index)
			continue
		_halo_by_source[source] = halo
		_ratio_by_source[source] = canvas_ratios[index]
