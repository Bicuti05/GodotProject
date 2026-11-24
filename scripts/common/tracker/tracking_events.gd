class_name TrackingEvents
extends RefCounted



























const EV_USER_PERMISSIONS: String = "user_permissions"
const EV_SCR_SHOW: String = "scr_show"
const EV_DLG_SHOW: String = "dlg_show"
const EV_SW_CLICK: String = "sw_click"
const EV_BTN_CLICK: String = "btn_click"

const EV_GAME_START: String = "game_start"
const EV_GAME_EXIT: String = "game_exit"
const EV_GAME_OVER: String = "game_over"
const EV_GAME_END: String = "game_end"

const EV_NEW_ROPE_APPEAR: String = "new_rope_appear"
const EV_TILES_MOVE: String = "tiles_move"

const EV_PROP_GET: String = "prop_get"
const EV_PROP_USE: String = "prop_use"

const EV_COIN_STATUS: String = "coin_status"

const EV_RESOURCE_REQ_MONITOR: String = "resource_req_monitor"
const EV_GAME_LOAD_MONITOR: String = "game_load_monitor"
const EV_CHAPTER_UNLOCK_MONITOR: String = "chapter_unlock_monitor"
const EV_BACKUP_TRIGGERED: String = "backup_triggered"


const EV_BACKUP_EMPTY: String = "backup_empty"
const EV_API_REQ_MONITOR: String = "api_req_monitor"

const EV_AD_SHOW_TIMING: String = "ad_show_timing"
const EV_AD_IS_FILL: String = "ad_is_fill"
const EV_AD_REAL_SHOW: String = "ad_real_show"


const EV_CHALLENGE_INFO: String = "challenge_info"





const K_SCR_NAME: String = "scr_name"

const K_DLG_NAME: String = "dlg_name"

const K_TIMING: String = "timing"

const K_BTN_NAME: String = "btn_name"

const K_SW_NAME: String = "sw_name"

const K_SOURCE: String = "source"

const K_STATE: String = "state"

const K_LEVEL_UNIQUE_ID: String = "level_unique_id"




const K_LEVEL_NUM: String = "level_num"
const K_LEVEL_TYPE: String = "level_type"
const K_CHAPTER_INDEX: String = "chapter_index"
const K_GAME_ID: String = "game_id"
const K_LEVEL_INDEX: String = "level_index"
const K_LEVEL_DATA_SOURCE: String = "level_data_source"
const K_DIFFICULTY_LEVEL: String = "difficulty_level"


const K_GAME_STATE: String = "game_state"
const K_LEVEL_DEFAULT_INFO: String = "level_default_info"
const K_GAMEPLAY_SET_INFO: String = "gameplay_set_info"
const K_NEW_START_TIMES: String = "new_start_times"
const K_COST_TIME: String = "cost_time"
const K_GAME_PROCESS_INFO: String = "game_process_info"
const K_USED_HINT_INFO: String = "used_hint_info"
const K_LEFT_HINT_INFO: String = "left_hint_info"
const K_EXIT_TYPE: String = "exit_type"




const K_SES_NUM: String = "ses_num"


const K_IS_EMPTY_ROPE: String = "is_empty_rope"
const K_APPEAR_METHOD: String = "appear_method"
const K_NEW_ROPE_GAMEPLAY: String = "new_rope_gameplay"


const K_LEVEL_CURRENT_INFO: String = "level_current_info"
const K_MOVE_RESULT_INFO: String = "move_result_info"
const K_MOVE_TILES_INFO: String = "move_tiles_info"
const K_TARGET_TILES_INFO: String = "target_tiles_info"
const K_FAIL_LINK_REASON: String = "fail_link_reason"



const K_PROP_NAME: String = "prop_name"
const K_PROP_NUM: String = "prop_num"
const K_PROP_LEFT: String = "prop_left"


const K_COIN_CHANGE_REASON: String = "coin_change_reason"
const K_COIN_CHANGE_NUM: String = "coin_change_num"
const K_COIN_TOTAL_NUM: String = "coin_total_num"


const K_URL: String = "url"
const K_TYPE: String = "type"
const K_CONTENT_ID: String = "content_id"
const K_NET_TYPE: String = "net_type"
const K_ERR_CODE: String = "err_code"
const K_ERR_MSG: String = "err_msg"
const K_TOTAL_URL: String = "total_url"
const K_CHAPTER_LEVEL: String = "chapter_level"
const K_START_CONTENT_ID: String = "start_content_id"
const K_END_CONTENT_ID: String = "end_content_id"


const K_BACKUP_ID: String = "backup_id"
const K_ORIGIN_ID: String = "origin_id"
const K_CURRENT_CHAPTER_LEVEL: String = "current_chapter_level"
const K_COMPLETED_CHAPTER_LEVEL: String = "completed_chapter_level"
const K_BACKUPED_PAGE: String = "backuped_page"


const K_AD_SHOW_ID: String = "ad_show_id"
const K_PLACEMENT: String = "placement"
const K_POSITION: String = "position"



const K_EVENT_ID: String = "event_id"

const K_CHALLENGE_POSITION: String = "challenge_position"

const K_LEFT_TIME: String = "left_time"

const K_CHALLENGE_ITEM: String = "challenge_item"

const K_ITEM_NUM: String = "item_num"

const K_CHALLENGE_RANK: String = "challenge_rank"

const K_CHALLENGE_LEVEL: String = "challenge_level"

const K_CHALLENGE_STATE: String = "challenge_state"

const K_START_DT: String = "start_dt"

const K_END_DT: String = "end_dt"


const K_PUSH_STATE: String = "push_state"
const K_ATT_STATE: String = "att_state"





const SCR_HOME: String = "home_scr"
const SCR_GAME: String = "game_scr"
const SCR_GAME_FINISH: String = "game_finish_scr"
const SCR_SPLASH: String = "splash_scr"


const SCR_EDIT_NAME: String = "edit_name_scr"
const SCR_LEADERBOARD: String = "leaderboard_scr"
const SCR_CHALLENGE_START: String = "challenge_start_scr"
const SCR_CHALLENGE_RENEW: String = "challenge_renew_scr"
const SCR_RANK_RENEW: String = "rank_renew_scr"
const SCR_CHALLENGE_END: String = "challenge_end_scr"
const SCR_CHALLENGE_BONUS: String = "challenge_bonus_scr"


const DLG_PRIVACY: String = "privacy_dlg"
const DLG_SETTINGS_HOME: String = "settings_dlg_home"
const DLG_SETTINGS_GAME: String = "settings_dlg_game"
const DLG_GAME_OVER: String = "game_over_dlg"



const DLG_RESET_CONFIRM: String = "reset_confirm_dlg"


const DLG_DAILY_CHECKIN: String = "daily_checkin_dlg"







const SW_SOUND: String = "sound_sw"
const SW_VIBRATION: String = "vibration_sw"
const SW_STATE_CLOSE: String = "close"
const SW_STATE_OPEN: String = "open"








const BTN_PLAY: String = "play_btn"
const BTN_SETTING: String = "setting_btn"
const BTN_RESTART: String = "restart_btn"
const BTN_CLOSE: String = "close_btn"
const BTN_AGREE: String = "agree_btn"

const BTN_NEXT: String = "next_btn"

const BTN_GAME_END_ADS: String = "game_end_ads"


const BTN_CONFIRM: String = "confirm_btn"
const BTN_HOME: String = "home_btn"
const BTN_HELP: String = "help_btn"
const BTN_RATE: String = "rate_btn"
const BTN_PRIVACY_POLICY: String = "privacy_policy_btn"
const BTN_PRIVACY_PREFERENCE: String = "privacy_preference_btn"
const BTN_TERMS: String = "terms_btn"

const BTN_OPEN_SOURCE_LICENSES: String = "open_source_licenses_btn"

const BTN_HINT: String = "hint_btn"
const BTN_UNDO: String = "undo_btn"
const BTN_ROPE: String = "rope_btn"

const BTN_FILL_POT: String = "fill_pot_btn"

const BTN_EDIT_CONFIRM: String = "edit_confirm_btn"
const BTN_EDIT_NAME: String = "edit_name_btn"
const BTN_GO_TO_COLLECT: String = "go_to_collect_btn"
const BTN_CHALLENGE_START: String = "challenge_start_btn"
const BTN_CHALLENGE_RENEW: String = "challenge_renew_btn"
const BTN_LEADERBOARD: String = "leaderboard_btn"
const BTN_CHALLENGE_BONUS_CLAIM: String = "challenge_bonus_claim_btn"
const BTN_RANK_RENEW: String = "rank_renew_btn"
const BTN_CHALLENGE_END: String = "challenge_end_btn"


const LEVEL_TYPE_LEVEL: String = "level"

const LEVEL_TYPE_SPECIAL_CHALLENGE: String = "special_challenge"


const LEVEL_TYPE_ENDLESS: String = "endless"


const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "hard"
const DIFFICULTY_SUPER_HARD: String = "super_hard"


const GAME_STATE_START: String = "start"
const GAME_STATE_RESTART: String = "restart"
const GAME_STATE_CONTINUE_START: String = "continue_start"






const GAME_STATE_CONTINUE_UNDO: String = "continue_undo"
const GAME_STATE_CONTINUE_ROPE: String = "continue_rope"


const EXIT_TYPE_RETURN_HOME: String = "return_home_page"
const EXIT_TYPE_CUT_BACKGROUND: String = "cut_background"


const APPEAR_DEFAULT_AUTO: String = "default_auto"
const APPEAR_COIN_EXCHANGE: String = "coin_exchange"
const APPEAR_ADS_EXCHANGE: String = "ads_exchange"




const APPEAR_FREE: String = "free"


const ROPE_QUESTION: String = "question_rope"
const ROPE_CAGE: String = "cage_rope"

const ROPE_QUESTION_CAGE: String = "question_cage_rope"


const FAIL_WRONG_COLOR: String = "wrong_color"
const FAIL_NOT_ENOUGH_SPACE: String = "not_enough_space"

const FAIL_QUESTION_ERROR: String = "question_error"

const FAIL_CAGE_ROPE_ERROR: String = "cage_rope_error"


const PROP_SOURCE_GAME_END: String = "game_end"

const PROP_SOURCE_GAME_END_ADS: String = "game_end_ads"
const PROP_SOURCE_REWARD_ADS: String = "reward_ads"
const PROP_SOURCE_UNLOCK_FIRST: String = "unlock_default_first"
const PROP_SOURCE_COIN_EXCHANGE: String = "coin_exchange"



const PROP_HINT: String = "hint"
const PROP_UNDO: String = "undo"
const PROP_ROPE: String = "rope"


const REWARD_SOURCE_SPECIAL_CHALLENGE: String = "special_challenge"
const REWARD_SOURCE_SPECIAL_CHALLENGE_ADS: String = "special_challenge_ads"


const REWARD_SOURCE_RANK_SEASON: String = "rank_season_reward"


const COIN_REASON_GAME_END: String = "game_end"

const COIN_REASON_GAME_END_ADS: String = "game_end_ads"

const COIN_REASON_BOUNS_LEVEL: String = "bouns_level"


const COIN_REASON_DAILY_CHECKIN: String = "daily_checkin"

const COIN_REASON_HINT: String = "hint"
const COIN_REASON_UNDO: String = "undo"
const COIN_REASON_ROPE: String = "rope"


const PERM_UNDETERMINED: String = "undetermined"
const PERM_AUTHORIZED: String = "authorized"
const PERM_DENIED: String = "denied"


const API_TYPE_CHAPTER: String = "chapter"








const AD_POSITION_GAME_END: String = "game_end"
const AD_POSITION_GAME_RESTART: String = "game_restart"
const AD_POSITION_HINT: String = "hint"
const AD_POSITION_UNDO: String = "undo"
const AD_POSITION_ROPE: String = "rope"

const AD_POSITION_FILL_POT: String = "fill_pot"

const AD_POSITION_FINISH_AD_REWARD: String = "finish_ad_reward"

const AD_POSITION_SPECIAL_CHALLENGE: String = "special_challenge"



const AD_POSITION_GAME_PAGE: String = "game_page"


const CHALLENGE_STATE_START: String = "start"
const CHALLENGE_STATE_IN_PROGRESS: String = "in_progress"
const CHALLENGE_STATE_END: String = "end"

const CHALLENGE_POSITION_START: String = "challenge_start"
const CHALLENGE_POSITION_END: String = "challenge_end"

const CHALLENGE_POSITION_GAME_FINISH: String = "game_finish_scr"







const REQ_STATE_SUCCESS: String = "success"
const REQ_STATE_FAIL: String = "fail"




const NET_ONLINE: String = "online"
const NET_OFFLINE: String = "offline"
















const ERR_HTTP_PREFIX: String = "http_"



const ERR_DEADLINE_PREFIX: String = "deadline_"




const ERR_PARSE_FAIL_PREFIX: String = "parse_fail_"






const ERR_HTTPREQUEST_CHUNKED_BODY_SIZE_MISMATCH: String = "HTTPRequest_chunked_body_size_mismatch"
const ERR_HTTPREQUEST_CANT_CONNECT: String = "HTTPRequest_cant_connect"
const ERR_HTTPREQUEST_CANT_RESOLVE: String = "HTTPRequest_cant_resolve"
const ERR_HTTPREQUEST_CONNECTION_ERROR: String = "HTTPRequest_connection_error"
const ERR_HTTPREQUEST_TLS_HANDSHAKE_ERROR: String = "HTTPRequest_tls_handshake_error"
const ERR_HTTPREQUEST_NO_RESPONSE: String = "HTTPRequest_no_response"
const ERR_HTTPREQUEST_BODY_SIZE_LIMIT_EXCEEDED: String = "HTTPRequest_body_size_limit_exceeded"
const ERR_HTTPREQUEST_BODY_DECOMPRESS_FAILED: String = "HTTPRequest_body_decompress_failed"
const ERR_HTTPREQUEST_REQUEST_FAILED: String = "HTTPRequest_request_failed"
const ERR_HTTPREQUEST_DOWNLOAD_FILE_CANT_OPEN: String = "HTTPRequest_download_file_cant_open"
const ERR_HTTPREQUEST_DOWNLOAD_FILE_WRITE_ERROR: String = "HTTPRequest_download_file_write_error"


const ERR_HTTPREQUEST_UNKNOWN: String = "HTTPRequest_unknown"





const ERR_HTTPREQUEST_TIMEOUT: String = "HTTPRequest_timeout"

const ERR_START_FAIL: String = "start_fail"


const ERR_IO_FAIL: String = "io_fail"
