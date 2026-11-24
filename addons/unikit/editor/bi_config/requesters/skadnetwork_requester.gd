@tool
class_name UniKitSKAdNetworkRequester
extends UniKitBIConfigRequester


const SOURCES: Array[Dictionary] = [
	{"name": "AppLovin", "url": "https://max.applovin.com/docs/v1/mediation_sk_adnetwork_ids", "required": true, "mode": "applovin"}, 
	{"name": "Fyber", "url": "https://fyber-engineering.github.io/SKAdNetworks/", "required": false, "mode": "standard"}, 
	{"name": "Unity", "url": "https://skan.mz.unity3d.com/v3/partner/skadnetworks.plist.json", "required": false, "mode": "unity"}, 
	{"name": "Vungle", "url": "https://vungle.com/skadnetworkids.json", "required": false, "mode": "standard"}, 
	{"name": "Chartboost", "url": "https://a3.chartboost.com/skadnetworkids.json", "required": false, "mode": "standard"}, 
	{"name": "PubMatic", "url": "https://pubmatic.com/skadnetworkids.json", "required": false, "mode": "standard"}, 
]

func config_name() -> String:
	return "skadnetwork"

func supports_platform(platform: String) -> bool:
	return platform == PLATFORM_IOS


func parse_source(mode: String, content: String) -> PackedStringArray:
	var out: = PackedStringArray()
	var parsed = JSON.parse_string(content)
	if parsed == null:
		return out
	match mode:
		"applovin":
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("mediationSKAdnetworkIdsSpecs"):
				for spec in parsed["mediationSKAdnetworkIdsSpecs"]:
					if typeof(spec) == TYPE_DICTIONARY and spec.has("skAdnetworkIds"):
						for id in spec["skAdnetworkIds"]:
							out.append(str(id))
		"unity":
			if typeof(parsed) == TYPE_ARRAY:
				for item in parsed:
					if typeof(item) == TYPE_DICTIONARY and item.has("skadnetwork_id"):
						out.append(str(item["skadnetwork_id"]))
		"standard":
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("skadnetwork_ids"):
				for item in parsed["skadnetwork_ids"]:
					if typeof(item) == TYPE_DICTIONARY and item.has("skadnetwork_id"):
						out.append(str(item["skadnetwork_id"]))
	return out


func aggregate(id_lists: Array) -> PackedStringArray:
	var seen: = {}
	for list in id_lists:
		for id in list:
			var low: = str(id).to_lower()
			if low != "":
				seen[low] = true
	var arr: = seen.keys()
	arr.sort()
	return PackedStringArray(arr)

func get_save_paths(platform: String, _is_debug: bool, ios_config_dir: String) -> PackedStringArray:
	if platform != PLATFORM_IOS:
		return PackedStringArray()
	return PackedStringArray([ios_config_dir.rstrip("/").path_join("SKAdNetworkIdentifier.json")])
