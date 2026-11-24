class_name MockUnikitConfig
extends RefCounted




















enum MockState{RESET = -1, FALSE = 0, TRUE = 1}





enum PushState{UNDETERMINED = 0, AUTHORIZED = 1, DENIED = 2}

const _KEY_MOCK_ENABLED: String = "mock_enabled"
const _KEY_PRIVACY_REQUIRED: String = "privacy_required"
const _KEY_CMP_REQUIRED: String = "cmp_required"
const _KEY_ATT_STATUS: String = "att_status"
const _KEY_PUSH_STATE: String = "push_state"
const _KEY_INTER_AD_READY: String = "inter_ad_ready"
const _KEY_REWARD_AD_READY: String = "reward_ad_ready"
const _KEY_BANNER_AD_READY: String = "banner_ad_ready"
const _KEY_REWARD_AD_RESULT: String = "reward_ad_result"

const _KEY_GRT_LTV: String = "grt_ltv"




static func is_mock_enabled(default_value: bool) -> bool:
	return UserState.get_mock_unikit_value(_KEY_MOCK_ENABLED, default_value)

static func set_mock_enabled(v: bool) -> void :
	UserState.set_mock_unikit_value(_KEY_MOCK_ENABLED, v)



static func get_mock_privacy_required() -> int:
	return int(UserState.get_mock_unikit_value(_KEY_PRIVACY_REQUIRED, MockState.RESET))

static func set_mock_privacy_required(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_PRIVACY_REQUIRED, v)



static func get_mock_cmp_required() -> int:
	return int(UserState.get_mock_unikit_value(_KEY_CMP_REQUIRED, MockState.RESET))

static func set_mock_cmp_required(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_CMP_REQUIRED, v)





static func get_mock_att_status() -> int:
	return int(UserState.get_mock_unikit_value(_KEY_ATT_STATUS, -1))

static func set_mock_att_status(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_ATT_STATUS, v)






static func get_mock_push_state() -> int:
	return int(UserState.get_mock_unikit_value(_KEY_PUSH_STATE, MockState.RESET))

static func set_mock_push_state(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_PUSH_STATE, v)













static func get_mock_inter_ad_ready(default_value: int = MockState.RESET) -> int:
	return int(UserState.get_mock_unikit_value(_KEY_INTER_AD_READY, default_value))

static func set_mock_inter_ad_ready(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_INTER_AD_READY, v)





static func get_mock_reward_ad_ready(default_value: int = MockState.RESET) -> int:
	return int(UserState.get_mock_unikit_value(_KEY_REWARD_AD_READY, default_value))

static func set_mock_reward_ad_ready(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_REWARD_AD_READY, v)





static func get_mock_banner_ad_ready(default_value: int = MockState.RESET) -> int:
	return int(UserState.get_mock_unikit_value(_KEY_BANNER_AD_READY, default_value))

static func set_mock_banner_ad_ready(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_BANNER_AD_READY, v)





static func get_mock_reward_ad_result(default_value: int = MockState.RESET) -> int:
	return int(UserState.get_mock_unikit_value(_KEY_REWARD_AD_RESULT, default_value))

static func set_mock_reward_ad_result(v: int) -> void :
	UserState.set_mock_unikit_value(_KEY_REWARD_AD_RESULT, v)





static func get_mock_grt_ltv() -> float:
	return float(UserState.get_mock_unikit_value(_KEY_GRT_LTV, 0.0))

static func set_mock_grt_ltv(v: float) -> void :
	UserState.set_mock_unikit_value(_KEY_GRT_LTV, v)
