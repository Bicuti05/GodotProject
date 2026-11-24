class_name GrtEventDefinition
extends RefCounted














const KEY_NAME: String = "name"
const KEY_METRIC: String = "metric"
const KEY_WINDOW: String = "window"
const KEY_MAX_LIVING_DAYS: String = "max_living_days"
const KEY_THRESHOLD: String = "threshold"
const KEY_LEVEL_THRESHOLD: String = "level_threshold"
const KEY_REWARD_THRESHOLD: String = "reward_threshold"
const KEY_LTV_THRESHOLD: String = "ltv_threshold"
const KEY_BATCH_ID: String = "batch_id"

const KEY_MIN_FIRST_APP_VERSION: String = "min_first_app_version"
const KEY_SOURCE_ROW: String = "source_row"


const METRIC_INTER: String = "inter"
const METRIC_REWARD: String = "reward"
const METRIC_REWARD_OR_INTER: String = "reward_or_inter"
const METRIC_LEVELPASS: String = "levelpass"
const METRIC_LTV_LEVELPASS: String = "ltv_levelpass"

const METRIC_LEVELPASS_REWARD: String = "levelpass_reward"


const WINDOW_LIVING_DAYS: String = "living_days"
const WINDOW_HOURS_24: String = "hours_24"



const ANCHOR_UNSET: int = 0

const ANCHOR_OLD: int = 1

const ANCHOR_NEW: int = 2




static func anchor_for_version(first_app_version: String, min_first_app_version: String) -> int:
	var first_parts: PackedStringArray = _version_parts(first_app_version)
	var min_parts: PackedStringArray = _version_parts(min_first_app_version)
	if first_parts.is_empty() or min_parts.is_empty():
		return ANCHOR_UNSET
	for idx in range(maxi(first_parts.size(), min_parts.size())):

		var first: int = int(first_parts[idx]) if idx < first_parts.size() else 0
		var minimum: int = int(min_parts[idx]) if idx < min_parts.size() else 0
		if first != minimum:
			return ANCHOR_NEW if first > minimum else ANCHOR_OLD
	return ANCHOR_NEW



static func _version_parts(version: String) -> PackedStringArray:
	var parts: PackedStringArray = version.split(".")
	for part in parts:
		if part.is_empty():
			return PackedStringArray()
		for idx in range(part.length()):
			var digit: int = part.unicode_at(idx)
			if digit < 48 or digit > 57:
				return PackedStringArray()
	return parts
