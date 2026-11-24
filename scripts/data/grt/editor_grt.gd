class_name EditorGrt
extends RefCounted










signal ltv_received(ltv: float)



func get_ltv() -> void :
	var ltv: float = MockUnikitConfig.get_mock_grt_ltv()
	ltv_received.emit.call_deferred(ltv)
