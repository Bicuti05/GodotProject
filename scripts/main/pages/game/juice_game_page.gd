class_name JuiceGamePage
extends PageScene


enum PlayMode{LEVEL, ENDLESS}
var play_mode: PlayMode = PlayMode.LEVEL
signal endless_finished(cups: int, reason: String)
signal endless_exit_requested()
const ENDLESS_START = preload("res://scripts/main/pages/game/flow/endless_game_start_flow.gd")
const ENDLESS_HINT = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_hint_solver.gd")
var _endless_controller: JuiceEndlessController
var _endless_context: EndlessGameStartFlow.Context
var _endless_generation: int = 0
var _endless_requested_seed: Variant = null
var _endless_seed: int = -1
var _endless_rng: = RandomNumberGenerator.new()
var _endless_skip_entrance: bool = false
var _endless_start_count: int = 0
var _external_play_suspended: bool = false
var _endless_background_paused: bool = false
var _mainline_timed_offer: Dictionary = {}
var _timed_result: Dictionary = {}
var _timed_finish_running: bool = false
var _timed_reward_owned: bool = false
var _endless_display_seconds: int = -1
const TIME_BONUS_ENTER_DUR: float = 0.2
const TIME_BONUS_HOLD_DUR: float = 0.6
const TIME_BONUS_EXIT_DUR: float = 0.25
const TIME_BONUS_RISE: float = 18.0
const TIME_BONUS_SIZE: Vector2 = Vector2(100.0, 40.0)
const TIME_BONUS_GAP: float = 4.0
const ENDLESS_TIMER_HEIGHT: float = 80.0
const ENDLESS_TIMER_TRACK_GAP: float = 12.0
var _time_bonus_tween: Tween
var _time_bonus_offset_y: float = 0.0
const ENDLESS_WARNING_MS: int = 20000
const ENDLESS_WARNING_URGENT_MS: int = 5000
var _endless_warning_envelope: float = 0.0
var _endless_warning_phase: float = 0.0
var _endless_warning_clock_ms: int = -1
@onready var _endless_time_warning: ColorRect = $EndlessTimeWarning

@onready var _endless_mask: ColorRect = $EndlessEndMask
@onready var _endless_message: Label = $EndlessEndMask / Message


























const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

const PROP_BTN_SCENE: PackedScene = preload("res://scripts/widget/prop_btn/prop_btn.tscn")

const SMART_MOVE_ANIM: = &"Animation"

const SMART_MOVE_SKIN: = "Smart Move!"
const LIKE_ANIM: = &"like"

const SMART_MOVE_REF_CENTER: = Vector2(4.5, -23.9)
const LIKE_REF_CENTER: = Vector2(-0.3, -3.6)


const GOOD_LUCK_ANIM: = &"Animation"

const GOOD_LUCK_REF_CENTER: = Vector2(-3.2, -6.9)


const GOOD_LUCK_MIN_MOVE_GAP_MSEC: = 3000



const DESIGN: = Vector2(1080.0, 2340.0)
const PROP_BAR_RESERVED_H: = 432.0

const TWO_ROW_PROP_SHIFT: = 140.0

const TWO_ROW_PROP_EXTRA_SHIFT: = 48.0


const LONG_ROPE_CAPACITY: = 8

const QUOTA_Y: = 204.0
const IQ_QUOTA_Y: = 248.0
const RULES_QUOTA_Y: = 247.0



static var debug_quota_shift: float = 0.0


static var debug_prop_bar_shift: float = 0.0

const BOARD_TOP: = 604.0




const BOARD_H: = DESIGN.y - BOARD_TOP - PROP_BAR_RESERVED_H


const FLOWER_FADE_OUT_DUR: = 0.45


enum EntranceStyle{SLIDE_WIND, SOFT_DROP}
@export var entrance_style: EntranceStyle = EntranceStyle.SLIDE_WIND


const SOFT_ENTRANCE_RISE: = 64.0
const SOFT_ENTRANCE_SETTLE: = 3.0
const SOFT_ENTRANCE_MOVE_DUR: = 0.32
const SOFT_ENTRANCE_SETTLE_DUR: = 0.14
const SOFT_ENTRANCE_FADE_DUR: = 0.24


const UI_LEVEL_ENTRANCE_DUR: = 0.22
const UI_QUOTA_ENTRANCE_DELAY: = 0.06
const UI_QUOTA_ENTRANCE_DUR: = 0.24
const UI_PROP_ENTRANCE_DELAY: = 0.3
const UI_PROP_ENTRANCE_STAGGER: = 0.035
const UI_PROP_ENTRANCE_DUR: = 0.24
const UI_ENTRANCE_DUR: = UI_PROP_ENTRANCE_DELAY + UI_PROP_ENTRANCE_STAGGER * 3.0 + UI_PROP_ENTRANCE_DUR







const ENTRANCE_DUR: = 0.95






const ENTRANCE_START_OVERSHOOT: = 1.35


const ENTRANCE_SFX_DELAY: = 0.31



const ENTRANCE_WIND_WAIT_CAP: = 2.5















const CUP_FLY_RISE: = 200.0
const CUP_FLY_RISE_DUR: = 0.18


const CUP_FLY_HOLD_RISE_RATIO: = 0.08


const CUP_FLY_HOLD_DUR: = 15.0 / 60.0
const CUP_FLY_DUR: = 0.45


const CUP_FLY_WAIT_CAP: = 1.2

const CUP_BLOOM_DUR: = 0.16
const CUP_BLOOM_FROM: = 0.88







const CUP_BLOOM_SCALE: = 1.36


const CUP_POT_BASE_V: = 160.0 / 184.0
const CUP_BLOOM_BASE_V: = 251.0 / 261.0










const CUP_FLY_SPINE_SCENE: PackedScene = preload(
	"res://assets/spine/effect_flowerpot_big/effect_flowerpot_big.tscn")
















const CUP_FLY_SPINE_COLOR_KEYS: Array[String] = [
	"red", "purple", "pink", "lightblue", "yellow", 
	"green", "blue", "cyan", "orange", "lightpurple", 
]



const CUP_FLY_SPINE_BBOX_W: = 1440.0

const CUP_FLY_SPINE_POT_BOTTOM_CENTER: = Vector2(1.5164, 896.81)

const CUP_FLY_STATIC_POT_BOTTOM_V: = 250.0 / 261.0


const CUP_FLY_SPINE_ANIM: = "get"

const CUP_FLY_SPINE_IDLE_ANIM: = "idle"


const CUP_FLY_SPINE_END_ANIM: = "end"


const CUP_FLY_SPINE_END_DUR = GameSkinPreparer.CUP_FLY_SPINE_END_DUR


const CUP_FLY_SPINE_Y_OFFSET: = -30.0





const CUP_FLY_SPINE_LANDING_SCALE: = 0.9 * 0.8





const CUP_FLY_SPINE_PREROLL_LEAD: = 0.0


const HARD_BADGE_FONT_MAX: int = 44
const HARD_BADGE_FONT_MIN: int = 28
const HARD_BADGE_LABEL_LEFT: float = 48.0
const HARD_BADGE_LABEL_MIN_W: float = 96.0
const HARD_BADGE_BLOCK_W: float = 470.0

const SUPER_HARD_BADGE_COLOR: Color = Color(0.72549, 0.219608, 1.0)







const CUP_FLY_Z: = 77
















const CUP_BLOOM_PARTICLE_TEX: Texture2D = preload(
	"res://assets/effect/texture/point/ef_point_001.png")

const CUP_BLOOM_PARTICLE_AMOUNT_MIN: = 5
const CUP_BLOOM_PARTICLE_AMOUNT_MAX: = 8


const CUP_BLOOM_HOVER_RATE: = 18.0



const CUP_BLOOM_HOVER_LIFETIME: = 0.35



const CUP_BLOOM_LANDING_LIFETIME: = 0.9

const CUP_BLOOM_PARTICLE_LIFETIME_RANDOMNESS: = 0.3


const CUP_BLOOM_HOVER_OFFSET: = Vector2(0.0, -10.0)


const CUP_BLOOM_LANDING_EXPLOSIVENESS: = 1.0



const CUP_BLOOM_PARTICLE_SIZE_RATIO: = 0.22

const CUP_BLOOM_LANDING_SIZE_RATIO: = CUP_BLOOM_PARTICLE_SIZE_RATIO * 1.5


const CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS: = 0.3


const CUP_BLOOM_PARTICLE_SPEED_RATIO: = 0.5



const CUP_BLOOM_HOVER_SPEED_RATIO: = CUP_BLOOM_PARTICLE_SPEED_RATIO * 1.3


const CUP_BLOOM_LANDING_SPEED_RATIO: = CUP_BLOOM_PARTICLE_SPEED_RATIO * 1.5 * 1.5




const CUP_BLOOM_HOVER_EMISSION_RADIUS: = 175.0



const CUP_BLOOM_HOVER_EMISSION_RADIUS_LANDING: = 75.0



const CUP_BLOOM_PARTICLE_DAMPING_MIN: = 40.0
const CUP_BLOOM_PARTICLE_DAMPING_MAX: = 70.0





const CUP_BLOOM_LANDING_DAMPING_MIN: = 80.0
const CUP_BLOOM_LANDING_DAMPING_MAX: = 140.0





const CUP_BLOOM_PARTICLE_GOLD: = Color(1.0, 0.9529, 0.7)






const CUP_BUTTERFLY_SCENES: Array[PackedScene] = [
	preload("res://assets/spine/effect_butterfly_oringe/effect_butterfly_oringe.tscn"), 
	preload("res://assets/spine/effect_butterfly_bigoringe/effect_butterfly_bigoringe.tscn"), 
	preload("res://assets/spine/effect_butterfly_caise/effect_butterfly_caise.tscn"), 
	preload("res://assets/spine/effect_butterfly_green/effect_butterfly_green.tscn"), 
	preload("res://assets/spine/effect_butterfly_red/effect_butterfly_red.tscn"), 
]


const CUP_BUTTERFLY_ANIMS = GameSkinPreparer.CUP_BUTTERFLY_ANIMS


const CUP_BUTTERFLY_BBOX_W: Array[float] = [560.9912, 446.5873, 483.7399, 597.55, 583.082]

const CUP_BUTTERFLY_COUNT_MIN: = 1
const CUP_BUTTERFLY_COUNT_MAX: = 2


const CUP_BUTTERFLY_SIZE_RATIO: = 0.36







const CUP_BUTTERFLY_SCATTER_X_RATIO: = 0.32
const CUP_BUTTERFLY_SCATTER_Y_MIN_RATIO: = -0.55
const CUP_BUTTERFLY_SCATTER_Y_MAX_RATIO: = -0.15






const CUP_BUTTERFLY_ARRIVE_DIST_MIN: = 20.0
const CUP_BUTTERFLY_ARRIVE_DIST_MAX: = 30.0
const CUP_BUTTERFLY_ARRIVE_DUR: = 0.15



const CUP_BUTTERFLY_SIZE_RAND: = 0.3

const CUP_BUTTERFLY_Y_LIFT: = 7.0



const TUTORIAL_LAYER_Z: = 71

const TUTORIAL_BAR_BOTTOM_GAP: = 64.0
const TUTORIAL_QUOTA_COVER_PAD: = 16.0
const LEGACY_TUTORIAL_LAYER_SCENE: PackedScene = preload(
	"res://scripts/gameplay/juice_sort/tutorial/legacy/juice_legacy_tutorial_layer.tscn")
const TUTORIAL_LAYER_SCENE: PackedScene = preload(
	"res://scripts/gameplay/juice_sort/tutorial/juice_tutorial_layer.tscn")



const LOCK_GUIDE_Z: = 75
const LOCK_GUIDE_SCENE: PackedScene = preload(
	"res://scripts/gameplay/juice_sort/tutorial/juice_lock_guide_overlay.tscn")
const SUNLIGHT_GUIDE_SCENE: PackedScene = preload(
	"res://scripts/gameplay/juice_sort/tutorial/juice_sunlight_guide_overlay.tscn")

const PROP_BTN_Z: = 5


const PROP_BTN_SIZE: = 160.0

const PROP_BTN_PITCH: = 226.0



const PROP_BTN_VISUAL_SIZE: = Vector2(204.0, 228.0)



const PROP_BTN_TAP_INSET: = Vector2(22.0, 34.0)

const WOOD_LOCK_PROP_GAP: float = 24.0

const PROP_AD_GRANT_COUNT: = 3

const RESET_BADGE_CENTER_X: = 174.0
const RESET_BADGE_TOP: = 137.0
const RESET_BADGE_HEIGHT: = 88.0
const RESET_BADGE_MIN_WIDTH: = 141.0
const RESET_BADGE_MAX_WIDTH: = 220.0
const RESET_BADGE_TEXT_PAD: = 22.0
const RESET_BADGE_FONT_SIZE: = 46
const RESET_BADGE_MIN_FONT_SIZE: = 32


const HINT_OPT: = {"ms_cap": 800, "death_first_ms": 50, "death_last_ms": 70, "fast_ms": 80, 
	"state_cap": 24000, "shorten_nodes": 100000, 
	"width": 6, "route_nodes": 6000, "max_routes": 2000}


const COIN_PER_TARGET: = 10








const BANNER_AD_HEIGHT: float = 180.0
const BANNER_AD_MAX_ROWS: int = 6









const COIN_HUD_WIDTH: float = 270.0
const COIN_ICON_SIZE: float = 88.0


const COIN_ICON_VISIBLE_INSET_LEFT: float = 7.0
const COIN_ICON_VISIBLE_INSET_RIGHT: float = 7.0
const COIN_ICON_VISIBLE_WIDTH: float = COIN_ICON_SIZE\
- COIN_ICON_VISIBLE_INSET_LEFT - COIN_ICON_VISIBLE_INSET_RIGHT

const COIN_ICON_TEXT_GAP: float = 8.0

const COIN_GROUP_EDGE_PAD: float = 14.0

const COIN_GROUP_MAX_W: float = COIN_HUD_WIDTH - COIN_GROUP_EDGE_PAD * 2.0
const COIN_TEXT_MAX_W: float = COIN_GROUP_MAX_W\
- COIN_ICON_VISIBLE_WIDTH - COIN_ICON_TEXT_GAP


const COIN_FONT_MAX: int = 64
const COIN_FONT_MIN: int = 36


const WIN_COIN_FLY_COUNT: int = 5
const WIN_COIN_FLY_DUR: float = 0.55
const WIN_COIN_FLY_STAGGER: float = 0.1


const WIN_COIN_FLY_SIZE: float = COIN_ICON_SIZE * 0.8
const WIN_COIN_PUNCH_SCALE: float = 1.2
const WIN_COIN_PUNCH_DUR: float = 0.18
const COIN_BONUS_TEXT_WIDTH: float = 108.0
const COIN_BONUS_TEXT_ICON_WIDTH_RATIO: float = 0.85
const COIN_BONUS_TEXT_DURATION: float = 0.48
const COIN_BONUS_START_SCALE: float = 0.82
const COIN_BONUS_POP_SCALE: float = 1.24
const COIN_BONUS_POP_DURATION: float = 0.045
const COIN_BONUS_SETTLE_DURATION: float = 0.085
const COIN_BONUS_RISE_DISTANCE: float = 120.0
const COIN_BONUS_RISE_DURATION: float = COIN_BONUS_TEXT_DURATION * 0.75


const WIN_COIN_ANIM: String = "animation"
const WIN_COIN_ANIM_DUR: float = 0.3667
const WIN_COIN_BBOX_W: float = 597.1333


const WIN_COIN_SPIN_DESYNC_RATIO: float = 0.9


const WIN_COIN_ARC_HEIGHT: float = 180.0
const WIN_COIN_ARC_RAND: float = 0.39

const WIN_COIN_FLY_SPEED_RAND: float = 0.3


const WIN_COIN_POP_DUR: float = 0.45
const WIN_COIN_POP_DIST_MIN: float = 80.0
const WIN_COIN_POP_DIST_MAX: float = 200.0


const WIN_COIN_TRAIL_TEX: Texture2D = preload("res://assets/effect/texture/point/ef_point_004.png")

const WIN_COIN_TRAIL_LIFETIME: float = 0.4
const WIN_COIN_TRAIL_LIFETIME_RANDOMNESS: float = 0.2

const WIN_COIN_TRAIL_RATE: float = 20.0

const WIN_COIN_TRAIL_SIZE: float = 32.0
const WIN_COIN_TRAIL_SIZE_RANDOMNESS: float = 0.4


const BONUS_GAIN_FADE_IN_DUR: float = 0.18
const BONUS_GAIN_HOLD_DUR: float = 1.0
const BONUS_GAIN_FADE_OUT_DUR: float = 0.6

var _board: JuiceBoardView
@onready var _background: TextureRect = $Bg
@export var christmas_theme_skin: JuiceSkinDefinition
var _christmas_theme_enabled: bool = false
@onready var _christmas_theme: JuiceSkinPageTheme = JuiceSkinResolver.resolve_page_theme(christmas_theme_skin)
@onready var _christmas_background: ColorRect = $ChristmasBackground
@onready var _christmas_decorations: Array[TextureRect] = [
	$ChristmasBackground / Snowflake, $ChristmasBackground / Candy, $ChristmasBackground / Bell, 
	$ChristmasBackground / Hat, $ChristmasBackground / Gift, 
]
var _rank_bar: RankCollectBar
var _rank_fly: RankCollectFlyLayer
var _rank_round: = RankRoundTracker.new()
var _rank_collectible_type: int = -1
var _rank_gift_slot: int = -1
var _prepared_rank_gift_flight: JuiceRankGiftFlight = null
var _rank_gift_warmed_textures: Array[Texture2D] = []
var _daily_checkin_round: = DailyCheckinRound.new()

@onready var _quota: JuiceQuotaBar = $Quota
var _progress_bling: ProgressBling
@onready var _progress_full_timer: Timer = $ProgressFullPreviewTimer
var _combo_feedback: ComboFeedback
var _empty_col_feedback: EmptyColFeedback
var _long_link_feedback: LongLinkFeedback

@onready var _header: Control = $Header
@onready var _coin_bonus_text: TextureRect = $CoinBonusText
var _win_completion_payload: Dictionary = {}
var _win_completion_iq: Dictionary = {}
var _win_coin_reported: bool = false

@onready var _level_block: Control = $Header / LevelBlock
@onready var _level_label: Label = $Header / LevelBlock / LevelLabel
var _timer_row: Control
var _timer_label: Label
var _timer_alarm: TextureRect
var _timer_track: TextureRect
var _time_bonus: Label
@onready var _timed_clock_flight: TimedClockFlight = $TimedClockFlight
var _iq_progress: IqProgressBar
var _iq_genius_feedback: Control
var _special_challenge_banner: Control
@onready var _special_challenge_chest: TextureRect = $Header / LevelBlock / ChallengeChest
@onready var _hard_badge: Control = $Header / LevelBlock / HardBadge
@onready var _hard_badge_label: Label = $Header / LevelBlock / HardBadge / Label
@onready var _hard_badge_icon: TextureRect = $Header / LevelBlock / HardBadge / Icon

@onready var _hard_fire_texture: Texture2D = _hard_badge_icon.texture
@onready var _hard_badge_label_color: Color = _hard_badge_label.get_theme_color("font_color")
@onready var _coin_hud: Control = $Header / CoinHud
@onready var _bonus_coin_hud: Control = $Header / CoinHud
@onready var _bonus_coin_hud_base_z: int = _bonus_coin_hud.z_index
@onready var _coin_hud_label: Label = $Header / CoinHud / CoinLabel
@onready var _coin_hud_icon: TextureRect = $Header / CoinHud / CoinIcon

@onready var _bonus_gain_label: Label = $Header / CoinHud / BonusGainLabel
var _bonus_pig_hud: BonusPigHud
var _bonus_pig_smash: BonusPigSmash
var _bonus_level_banner: BonusLevelBanner
@onready var _back_btn: Button = $Header / BackBtn

@onready var _header_reset_btn: Button = $Header / ResetSmallBtn

@onready var _header_reset_bg: TextureRect = $Header / ResetSmallBtn / Bg
@onready var _header_reset_bg_white: TextureRect = $Header / ResetSmallBtn / BgWhite
@onready var _header_reset_icon: TextureRect = $Header / ResetSmallBtn / Texture
@onready var _header_reset_icon_blue: TextureRect = $Header / ResetSmallBtn / TextureBlue
@onready var _reset_btn: Button = $ResetBtn
@onready var _reset_badge: NinePatchRect = $ResetBtn / Badge
@onready var _reset_badge_label: Label = $ResetBtn / Badge / Label
@onready var _reset_bg: TextureRect = $ResetBtn / Bg
@onready var _reset_icon: TextureRect = $ResetBtn / Icon


const SOFT_BACKGROUND_TINT: = Color(0.93, 0.927, 0.916, 1.0)
const SOFT_UI_TINT: = Color(0.938, 0.93, 0.895, 1.0)
const SOFT_DROP_HOVER_TINT: = Color(1.0, 1.0, 1.0, 0.7)

@export var skin_catalog: JuiceSkinCatalog
var _skin_loader: JuiceSkinLoader = JuiceSkinLoader.new()
var _skin_resources: JuiceSkinResolver
var _next_skin_preparation_generation: int = -1
var _skin_generation: int = 0
var _skin_refreshing: bool = false
var _pending_special_theme_assignment: Dictionary = {}



var _banner_ad_shown: bool = false

@export var super_hard_fire_texture: Texture2D = null
var _default_background_texture: Texture2D = null


var _complete_panel: Node = null
var _unlock_overlay: GamePropUnlockOverlay = null

var _unlock_reveal_key: String = ""
var _opening_banner_input_locked: bool = false
var _opening_banner_input_was_enabled: bool = true
var _opening_banner_input_generation: int = 0
var _special_challenge_banner_pending: bool = true
var _start_banner: GameStartBanner = null
var _challenge_banner: ChallengeBanner = null



var _unlock_forced_close: bool = false

var _prop_ui: Dictionary = {}

var _complete_prop_enabled: bool = false
var _reset_moved_to_header: bool = false

var _reset_white_style: bool = false
var _hint_guide_tracker: HintGuideTracker = HintGuideTracker.new()
var _hint_guide_playing: bool = false
var _hint_guide_background_paused: bool = false
var _hint_guide_skip_frame: bool = false

var _hint_guide_checked_key: String = ""

var _hint_guide_unwinnable_key: String = ""
var _rope_guide_playing: bool = false


var _prop_ad_in_flight: bool = false









var _prop_ad_ready: Dictionary = {}










var _prop_ad_needed: Dictionary = {}




var _prop_refresh_gen: int = 0


var _hint_cache_key: String = ""
var _hint_cache: Dictionary = {}

var _hint_checked_key: String = ""

var _hint_plan: Array = []


var _hint_plan_key: String = ""


var _hint_plan_col: int = -1
var _hint_plan_optimal: bool = false
var _hint_plan_win_path: bool = false

var _hint_plan_root_necessary: bool = false











const HINT_TASK_NONE: = -1
var _restart_interstitial_busy: bool = false
var _restart_interstitial_generation: int = 0
var _hint_task_id: int = HINT_TASK_NONE
var _hint_task_cancel: Semaphore = null


var _hint_task_result: Dictionary = {}

var _hint_task_progress: S.HintProgress = null
var _hint_task_version: int = -1
var _hint_task_latest: Dictionary = {}



var _hint_task_key: String = ""

var _hint_task_auto: bool = false

var _hint_task_preflight: bool = false

var _root_hint_pending_key: String = ""


var _fly_layer: Node2D = null


var _fly_pool: Array[SpineSprite] = []

var _fly_end_tweens: Dictionary = {}

var _bloom_pool: Array[CPUParticles2D] = []
var _pot_petal_pool: Array[CPUParticles2D] = []
const POT_PETAL_AMOUNT: int = 28
const POT_PETAL_LIFETIME: float = 0.9



var _hover_pool: Array[CPUParticles2D] = []










var _hover_particle_by_spr: Dictionary = {}

var _butterfly_pools: Array = [[], [], [], [], []]





var _butterflies_by_spr: Dictionary = {}


var _cup_flights: Array[Dictionary] = []

var _level_model: JuiceLevelModel = null


var _bonus_pot_collecting: bool = false
var _bonus_collect_generation: int = 0
var _bonus_type: int = -1

var _bonus_v2: bool = false

var _bonus_coin_before: int = 0

var _bonus_coin_reward: int = 0

var _bonus_gain_tween: Tween = null


var _bonus_coin_pending: int = 0
var _combo_tracker: JuiceComboTracker = JuiceComboTracker.new()

var _combo_sfx_counts: Dictionary[int, int] = {}
var _combo_frequency_tracker: JuiceComboFrequencyTracker = JuiceComboFrequencyTracker.new()

var _combo_frequency_wait_before_end: bool = false

var _combo_steps: int = 0

var _combo_haptic_dyed: bool = false


var _early_wrong_drags: int = 0
const EARLY_WRONG_DRAG_MAX_LEVEL: int = 5
const EARLY_WRONG_DRAG_TRIGGER: int = 2
var _progress_full_active: bool = false
var _progress_full_looping: bool = false
var _progress_full_cycle: bool = false
var _progress_full_slot: int = 0
var _progress_full_sprite: SpineSprite
var _progress_full_petal: CPUParticles2D
var _applying_undo: bool = false

var _applying_fill_pot: bool = false



var _win_committed: bool = false

var _won_level_num: int = 0

var _win_coin_before: int = 0
var _win_coin_reward: int = 0

var _round_target_coins: int = COIN_PER_TARGET
var _win_coin_tween: Tween = null

var _win_coin_haptic: int = 0
var _game_enter_haptic: int = 0
var _win_coin_punch_tween: Tween = null
var _coin_bonus_text_rest_position: Vector2 = Vector2.ZERO
var _coin_bonus_texts: Array[TextureRect] = []
var _coin_bonus_text_tweens: Array[Tween] = []
var _win_coin_sprites: Array[SpineSprite] = []


var _win_coin_trails: Array[CPUParticles2D] = []









var _tutorial_active: bool = false
var _tutorial_quota_intro_hidden: bool = false
var _tutorial_resume_step: int = 0

var _four_goal_tutorial_round: bool = false
var _rules_guide_round: bool = false

var _challenge_toasted: Dictionary = {}



const CHALLENGE_MIN_GAP: = 5

const CHALLENGE_MIN_LEVEL: = 3
var _challenge_last_seen_link: int = - CHALLENGE_MIN_GAP
var _challenge_last_shown_link: int = - CHALLENGE_MIN_GAP

var _challenge_clear_joint: Vector2 = Vector2.ZERO
var _smart_move_spine: SpineSprite = null
var _like_spine: SpineSprite = null
var _smart_move_tween: Tween = null
var _like_tween: Tween = null
var _good_luck_spine: SpineSprite = null
var _good_luck_tween: Tween = null


var _last_move_msec: int = 0
var _last_move_gap_msec: int = 0
var _tutorial_dir: Variant = null
var _tutorial_layer: Variant = null





var _mystery_guide: JuiceMysteryGuide = null
var _mystery_layer: JuiceTutorialLayer = null


var _root_swap_guide: JuiceRootSwapGuide = null
var _root_swap_layer: JuiceTutorialLayer = null
var _root_swap_guide_pending: Dictionary = {}
var _root_swap_guide_endless_id: String = ""
var _root_swap_guide_timer_paused: bool = false





var _lock_guide: JuiceLockGuideOverlay = null

var _lock_guide_forced_close: bool = false


var _sunlight_guide: JuiceSunlightGuideOverlay = null
var _sunlight_guide_running: bool = false
var _sunlight_guide_input_was_enabled: bool = false




var _end_flow_running: bool = false

var _flowers_faded: bool = false

var _complete_shown: bool = false
var _finish_ad_reward_enabled: bool = false
var _finish_game_data_enabled: bool = false
var _finish_use_new_result_data: bool = false
var _finish_iq_replacement_metric: String = ""
var _finish_record_improvements: Dictionary = {}
var _finish_ad_busy: bool = false
var _finish_ad_busy_generation: int = 0
var _finish_ad_reward_motion: FinishAdRewardMotion
var _finish_interstitial_busy: bool = false
var _end_flow_generation: int = 0

var _start_flow_context: GameStartContext = null
var _prepared_sunlight_bonus: Variant = null



var _tracking_common: TrackingCommonParams = null

var _pending_free_prop_get: Array[String] = []


var _tracking_game_state: String = TrackingEvents.GAME_STATE_START

var _tracking_special_state: Dictionary = {}







var _tracking_prop_used_round: Dictionary = {"hint": 0, "undo": 0, "rope": 0, "fill_pot": 0}
var _iq_round: IqRoundModel = IqRoundModel.new()
var _iq_genius_shown: bool = false
var _iq_complete_sound_pending: bool = false

var _level_complete_sound_id: StringName = &"level_complete"
var _finish_cart_appear_sound_id: StringName = &"finish_cart_appear"

var _tracking_background_reported: bool = false









var _entrance_dx: float = 0.0

var _entrance_dy: float = 0.0
var _entrance_alpha: float = 1.0
var _entrance_tween: Tween = null

var _playfield_ready: bool = false
var _entrance_generation: int = 0

var _ui_entrance_pending: bool = false
var _ui_entrance_preparing: bool = false
var _ui_entrance_tween: Tween = null
var _ui_entrance_entries: Array[Dictionary] = []
var _ui_entrance_time: float = 0.0
var _ui_entrance_generation: int = 0
var _rules_ui_entrance: bool = false
var _ui_entrance_duration: float = UI_ENTRANCE_DUR
var _ui_props_ready: bool = true




var _next_pressed: bool = false



var _play_timer: LevelPlayTimer = LevelPlayTimer.new()


func _ready() -> void :
	_endless_rng.randomize()
	LevelManager.level_data_changed.connect(_on_finish_level_data_changed)
	_default_background_texture = _background.texture

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_components = PageComponentLoader.new(self, COMPONENT_SCENES)
	set_process(false)


const COMPONENT_SCENES: Dictionary = GamePagePreparation.COMPONENT_SCENES
var _components: PageComponentLoader
var _components_ready: bool = false
var _assembly_step: int = 0
var _game_effects_ready: bool = false
var _preparation_running: bool = false
var _preparation_can_work: Callable
var _finish_prepare_generation: int = -1
var _finish_prepare_state: Dictionary = {}
var _deferred_prepare_request: RefCounted


func set_preparation_work_permission(can_work: Callable) -> void :
	_preparation_can_work = can_work
	_components.set_work_permission(can_work)


func prepare_for_display(active: Callable) -> bool:

	while _preparation_running and active.call():
		await get_tree().process_frame
	if not active.call():
		return false
	_preparation_running = true
	var prepared: bool = await _prepare_for_display(active)
	_preparation_running = false
	return prepared


func _prepare_for_show(active: Callable) -> bool:
	if not is_node_ready():
		await ready
	if not active.call():
		return false
	_set_ui_entrance_preparing(true)
	if _preparation_running or not _components_ready or not _game_effects_ready:
		return await prepare_for_display(active)
	return active.call()


func _prepare_for_display(active: Callable) -> bool:
	if not is_node_ready():
		await ready
	_deferred_prepare_request = null
	_components.set_work_permission(_preparation_can_work)
	var next_round: Dictionary = LevelManager.get_next_round_descriptor(false)
	var preparing_endless: bool = is_endless() or bool(next_round.get("is_timed_endless", false))
	var special: bool = false if preparing_endless else bool(next_round["is_special"])


	var bonus: bool = not preparing_endless and JuiceBonusLevel.is_bonus_level(UserState.get_current_level())
	var rank: bool = not preparing_endless and RankManager.is_enabled() and UserState.is_rank_unlocked()
	var groups: Array[String] = GamePagePreparation.first_screen_groups(special, bonus, rank)
	_components.request_groups(groups)
	if not await _ensure_component_groups(groups, active):
		return false
	var builders: Array[Callable] = [
		func() -> void : _build_prop_button(0), 
		func() -> void : _build_prop_button(1), 
		func() -> void : _build_prop_button(2), 
		func() -> void : _build_prop_button(3), 
		_build_fly_layer, _build_entrance_pot_layer, 
	]
	while _assembly_step < builders.size():
		if not await SceneManager.wait_preparation_permission(active, _preparation_can_work):
			return false
		builders[_assembly_step].call()
		_assembly_step += 1
		await get_tree().process_frame
	if not active.call():
		return false
	if not _components_ready:
		_quota.panel_style = _quota.panel_style.duplicate() as StyleBoxTexture
		_connect_board()
		_quota.width_changed.connect(_layout_quota)
		_progress_bling.effect_started.connect(_quota.play_progress_impact)
		_progress_bling.effect_stopped.connect(_quota.stop_progress_impact)
		_quota.progress_transform_changed.connect(_progress_bling.sync_global_color_transform)
		_components_ready = true
	_layout()
	if not _game_effects_ready:
		if not await SceneManager.wait_preparation_permission(active, _preparation_can_work):
			return false
		var preparer: = GameEffectsPreparer.new()
		await preparer.run(self, active)
		_game_effects_ready = not preparer.should_run(null)
	return active.call()



func take_prepared_component(component_path: String) -> Node:
	if _motion_preview_only:
		return null
	return GameEffectsPreparer.take_startup_board() if component_path == "Board" else null


func bind_component_group(group: String) -> void :
	match group:
		"core":
			_board = get_node("Board") as JuiceBoardView
			_combo_feedback = get_node("ComboFeedback") as ComboFeedback
			_empty_col_feedback = get_node("EmptyColFeedback") as EmptyColFeedback

			_combo_feedback.show()
			_empty_col_feedback.show()
			_long_link_feedback = get_node("LongLinkFeedback") as LongLinkFeedback
			_long_link_feedback.show()
			_iq_progress = get_node("Quota/IqProgressBar") as IqProgressBar
			_timer_row = _iq_progress.get_node("EndlessTimerRow") as Control
			_timer_label = _timer_row.get_node("TimeLabel") as Label
			_timer_alarm = _timer_row.get_node("TimerAlarm") as TextureRect
			_time_bonus = _timer_row.get_node("TimeBonus") as Label
			_timer_track = _iq_progress.get_node("Track") as TextureRect
			_progress_bling = get_node("Quota/ProgressBling") as ProgressBling
			_start_banner = get_node("GameStartBanner") as GameStartBanner
			_good_luck_spine = get_node("GoodLuckSpine") as SpineSprite
			_quota.visible = not _ui_entrance_preparing
			_iq_progress.show()
		"bonus":
			_bonus_pig_hud = get_node("BonusPigHud") as BonusPigHud
			_bonus_pig_hud.show()
			_bonus_level_banner = get_node("BonusLevelBanner") as BonusLevelBanner
		"special":
			_special_challenge_banner = get_node("SpecialChallengeBanner") as Control
		"rank":
			_rank_bar = get_node("RankCollectBar") as RankCollectBar
			_rank_fly = get_node("RankCollectFly") as RankCollectFlyLayer

			_rank_fly.visible = visible
		"end_iq":
			_iq_genius_feedback = get_node("IqGeniusFeedback") as Control
		"end_bonus":
			_bonus_pig_smash = get_node("BonusPigSmash") as BonusPigSmash
		"preview":
			_challenge_banner = get_node("ChallengeBanner") as ChallengeBanner
			_smart_move_spine = get_node("SmartMoveSpine") as SpineSprite
			_like_spine = get_node("LikeSpine") as SpineSprite
	for path: String in COMPONENT_SCENES[group]:
		get_node(path).process_mode = Node.PROCESS_MODE_INHERIT


func _ensure_component_groups(groups: Array[String], active: Callable) -> bool:
	_components.request_groups(groups)
	for group: String in groups:
		if _components.is_ready(group):
			continue
		if not await _components.prepare_group(group, active):
			return false
	return active.call()



func prepare_round_components(ctx: GameStartContext) -> bool:
	_deferred_prepare_request = null
	_components.set_work_permission(Callable())
	var active: Callable = func() -> bool:
		return is_instance_valid(self) and visible and not ctx.aborted and ctx == _start_flow_context
	if not active.call() or _level_model == null:
		return false
	var tutorial: bool = should_run_tutorial_now(ctx.current_state)
	var bonus: bool = int(ctx.current_state.get("bonus_type", -1)) >= 0 if not ctx.current_state.is_empty()\
	else not tutorial and not is_special_challenge()\
	and JuiceBonusLevel.is_bonus_level(_level_model.level_id)\
	and JuiceBonusLevel.has_bonus_candidate(_level_model.juice, BonusLevelEntry.is_v2_enabled())
	var rank: bool = RankManager.is_enabled() and UserState.is_rank_unlocked()
	return await _ensure_component_groups(GamePagePreparation.first_screen_groups(
		is_special_challenge(), bonus, rank), active)



func request_round_deferred_preparation() -> void :
	var request: = RefCounted.new()
	_deferred_prepare_request = request
	var generation: int = _entrance_generation
	var groups: Array[String] = GamePagePreparation.end_groups(_iq_round.enabled, _bonus_type >= 0)
	_components.request_groups(groups)
	_components.request_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]))
	_prepare_round_deferred(groups, request, generation)


func _prepare_round_deferred(groups: Array[String], request: RefCounted, generation: int) -> void :
	var active: Callable = func() -> bool:
		return is_instance_valid(self) and visible and generation == _entrance_generation\
		and request == _deferred_prepare_request and not _end_flow_running
	var can_work: Callable = func() -> bool: return active.call() and can_prepare_other_page()
	if not await SceneManager.wait_preparation_permission(active, can_work):
		return

	_components.set_work_permission(can_work)
	await _ensure_component_groups(groups, active)
	if active.call():
		await _components.ensure_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]), active)



func _prepare_round_end(active: Callable) -> bool:
	_deferred_prepare_request = null
	_components.set_work_permission(Callable())
	var groups: Array[String] = GamePagePreparation.end_groups(_iq_round.enabled, _bonus_type >= 0)
	if not await _ensure_component_groups(groups, active):
		return false
	return await _components.ensure_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]), active)



func get_win_coin_scene() -> PackedScene:
	return _components.get_resource(GamePagePreparation.WIN_COIN_PATH) as PackedScene


func can_prepare_other_page() -> bool:
	return _components_ready and _playfield_ready and not _hint_guide_background_paused\
	and not _board.has_active_drag() and not _board.is_busy() and not _has_cup_flights()\
	and not _end_flow_running and not _home_navigation_running\
	and not _ui_entrance_pending and _entrance_tween == null



func request_finish_preparation() -> void :
	if _finish_prepare_generation == _entrance_generation and not _finish_prepare_state.is_empty():
		return
	_finish_prepare_generation = _entrance_generation
	var state: Dictionary = {"done": false, "page": null}
	_finish_prepare_state = state
	var generation: int = _entrance_generation
	var active: Callable = func() -> bool:
		return is_instance_valid(self) and visible and generation == _entrance_generation
	_prepare_finish(state, active)


func _prepare_finish(state: Dictionary, active: Callable) -> void :
	var lease: RefCounted = PagePreparationCoordinator.begin_foreground()
	state.page = await SceneManager.prepare_page_for_display("finish", active)
	state.done = true
	PagePreparationCoordinator.end_foreground(lease)


func wait_finish_preparation() -> bool:
	var generation: int = _entrance_generation
	while visible and generation == _entrance_generation:
		request_finish_preparation()
		var state: Dictionary = _finish_prepare_state
		while visible and generation == _entrance_generation and not state.done:
			await get_tree().process_frame
		if not visible or generation != _entrance_generation:
			return false
		if state.page != null:
			return true
		SortLogger.error("GamePage: 完成页准备失败，保留盘面并重试")
		_finish_prepare_generation = -1
		await get_tree().create_timer(0.5).timeout
	return false







func _show_challenge_banner(title_locale: String = "") -> void :
	if _challenge_banner == null or not is_instance_valid(_challenge_banner):
		return
	var quota_bottom: float = (_quota.get_global_transform() * Vector2(0.0, _quota.size.y)).y
	var shelf_y: float = _board.layout().plank_top
	var shelf_top: float = (_board.get_global_transform() * Vector2(0.0, shelf_y)).y
	var center_global: Vector2 = Vector2(UiMetrics.viewport_size().x * 0.5, 
		(quota_bottom + shelf_top) * 0.5)

	_hide_good_luck_fx()

	var locale: String = "en" if title_locale.is_empty() else title_locale
	_challenge_banner.play(get_global_transform().affine_inverse() * center_global, locale)



func _hide_challenge_banner() -> void :
	_stop_skin_sound(&"smart_move")
	if _challenge_banner != null and is_instance_valid(_challenge_banner):
		_challenge_banner.hide_now()
	_kill_tween(_smart_move_tween)
	_kill_tween(_like_tween)
	_kill_tween(_good_luck_tween)
	for spr: SpineSprite in [_smart_move_spine, _like_spine, _good_luck_spine]:
		if spr != null and is_instance_valid(spr):
			spr.visible = false



func _play_challenge_clear_fx() -> void :
	if is_instance_valid(_challenge_banner):
		_challenge_banner.dismiss()
	if _smart_move_spine == null or _like_spine == null:
		return
	var to_local: Transform2D = get_global_transform().affine_inverse()

	if _good_luck_spine != null and _good_luck_spine.visible:
		SortLogger.info("[Challenge] Good Luck 正在播放,跳过 Smart Move! 文字")
	else:
		_kill_tween(_smart_move_tween)
		_smart_move_tween = _play_spine_once(_smart_move_spine, SMART_MOVE_ANIM, SMART_MOVE_SKIN, 
			to_local * _challenge_text_center_global() - SMART_MOVE_REF_CENTER)
		if _smart_move_tween != null:
			_play_skin_sound(&"smart_move")
	_kill_tween(_like_tween)
	_like_tween = _play_spine_once(_like_spine, LIKE_ANIM, "", 
		to_local * _challenge_clear_joint - LIKE_REF_CENTER)



func _challenge_text_center_global() -> Vector2:
	var quota_bottom: float = (_quota.get_global_transform() * Vector2(0.0, _quota.size.y)).y
	return Vector2(UiMetrics.viewport_size().x * 0.5, (quota_bottom + _board.pot_top_global_y()) * 0.5)




func _play_good_luck_fx() -> void :
	if _good_luck_spine == null:
		return
	if is_instance_valid(_challenge_banner) and _challenge_banner.is_card_showing():
		SortLogger.info("[LuckyReveal] Challenge 飘屏正在展示,跳过 Good Luck")
		return
	if _smart_move_spine != null and _smart_move_spine.visible:
		_kill_tween(_smart_move_tween)
		_smart_move_spine.visible = false
		_stop_skin_sound(&"smart_move")
	_kill_tween(_good_luck_tween)
	_good_luck_tween = _play_spine_once(_good_luck_spine, GOOD_LUCK_ANIM, "", 
		get_global_transform().affine_inverse() * _challenge_text_center_global() - GOOD_LUCK_REF_CENTER)



func _hide_good_luck_fx() -> void :
	_kill_tween(_good_luck_tween)
	if _good_luck_spine != null and is_instance_valid(_good_luck_spine):
		_good_luck_spine.visible = false




func _play_spine_once(spr: SpineSprite, anim_name: StringName, skin: String, pos: Vector2) -> Tween:
	spr.position = pos
	var skel: SpineSkeleton = spr.get_skeleton()
	var anim: SpineAnimationState = spr.get_animation_state()
	if skel == null or anim == null:
		return null
	if not skin.is_empty():
		skel.set_skin_by_name(skin)
	anim.clear_tracks()
	skel.set_to_setup_pose()
	anim.set_animation(anim_name, false, 0)
	anim.update(0.0)
	anim.apply(skel)
	skel.update_world_transform(SpineConstant.Physics_Update)
	spr.visible = true
	var anim_def: SpineAnimation = skel.get_data().find_animation(anim_name)
	var dur: float = anim_def.get_duration() if anim_def != null else 1.4
	var tw: Tween = spr.create_tween()
	tw.tween_interval(dur + 0.05)
	tw.tween_callback( func() -> void : spr.visible = false)
	return tw


func _kill_tween(tw: Tween) -> void :
	if tw != null and tw.is_valid():
		tw.kill()



func _freeze_complete_prop_group() -> void :
	_complete_prop_enabled = ABManager.complete_prop.is_complete_prop_enabled()
	_reset_moved_to_header = false
	_reset_white_style = false
	if is_endless():
		return
	_reset_moved_to_header = ABManager.complete_prop.is_reset_moved_to_header()
	_reset_white_style = ABManager.complete_prop.is_reset_white_style()



func _apply_header_reset_style() -> void :
	_header_reset_bg.visible = not _reset_white_style
	_header_reset_icon.visible = not _reset_white_style
	_header_reset_bg_white.visible = _reset_white_style
	_header_reset_icon_blue.visible = _reset_white_style


func _build_prop_button(index: int) -> void :
	if index == 0:
		_back_btn.button_down.connect(_on_undo_guide_action)
		_reset_btn.button_down.connect(_on_undo_guide_action)
		_header_reset_btn.button_down.connect(_on_undo_guide_action)
	var types: Array[int] = [PropBtn.PropType.HINT, PropBtn.PropType.UNDO, PropBtn.PropType.ROPE, 
		PropBtn.PropType.FILL_POT]
	var btn: PropBtn = PROP_BTN_SCENE.instantiate()
	btn.size = PROP_BTN_VISUAL_SIZE
	btn.z_index = PROP_BTN_Z
	btn.visible = not _ui_entrance_preparing
	add_child(btn)
	btn.configure(types[index])
	var key: String = btn.get_prop_id()
	btn.button_down.connect(_on_undo_guide_action)
	btn.pressed_prop.connect( func(_id: String) -> void : _on_prop_pressed(key))
	_prop_ui[key] = {"btn": btn}
	if key == "hint" or key == "rope":
		btn.button_down.connect(_on_hint_guide_button_down)




func _on_prop_pressed(key: String) -> void :
	if _root_swap_guide_blocks_input():
		return
	_on_undo_guide_action()
	if key == "hint" or key == "rope":
		_reset_hint_guide()
		_clear_hint_guide_motion()
	if not _ui_button_is_ready(key):
		return
	if _tutorial_active and _four_goal_tutorial_round and is_instance_valid(_tutorial_dir):
		_tutorial_dir.enter_free_stage()
	var btn_name: String = _prop_btn_name(key)
	if not btn_name.is_empty() and not is_endless():
		Tracker.track_btn_click(btn_name, _dead_toast_source())
	_use_prop(key)





func _dead_toast_source() -> String:
	var toast: CanvasItem = SceneManager.get_page("game_dead_toast") as CanvasItem
	if toast != null and toast.visible:
		return TrackingEvents.DLG_GAME_OVER
	return ""



func _prop_btn_name(key: String) -> String:
	match key:
		"hint": return TrackingEvents.BTN_HINT
		"undo": return TrackingEvents.BTN_UNDO
		"rope": return TrackingEvents.BTN_ROPE
		"fill_pot": return TrackingEvents.BTN_FILL_POT
	return ""


func _build_fly_layer() -> void :
	var layer: = Node2D.new()
	layer.name = "CupFlyLayer"
	layer.z_index = CUP_FLY_Z
	add_child(layer)
	_fly_layer = layer
	_board.set_sunlight_layer(layer)
	if not _board.bird_house_hovered.is_connected(_on_bird_house_hovered):
		_board.bird_house_hovered.connect(_on_bird_house_hovered)
	if not _board.sunlight_collector_landed.is_connected(_on_sunlight_collector_landed):
		_board.sunlight_collector_landed.connect(_on_sunlight_collector_landed)
	_quota.set_sunlight_textures(_board.sunlight_blender_texture, _board.sunlight_fruit_texture)




func _build_entrance_pot_layer() -> void :
	var layer: Node2D = Node2D.new()
	layer.name = "EntrancePotLayer"
	add_child(layer)
	move_child(layer, _board.get_index())
	_board.garden_pot_layer = layer


func _connect_board() -> void :
	_board.major_sound_requested.connect(_play_major_sound)
	_board.same_color_merge_sound_requested.connect(_on_same_color_merge_sound_requested)
	_board.moved.connect(_on_board_moved)
	_board.mystery_auto_unlock_requested.connect(_on_board_mystery_auto_unlock_requested)
	_board.automatic_settlement_requested.connect(_on_board_automatic_settlement_requested)
	_board.player_operated.connect(_stop_undo_guide_motion_preview)
	_board.player_operated.connect(_on_root_swap_guide_player_operated)
	_board.long_link_triggered.connect(_on_long_link_triggered)
	_board.move_attempted.connect(_on_board_move_attempted)
	_board.new_rope_appeared.connect(_on_new_rope_appeared)
	_board.drag_started.connect(_on_board_drag_started)
	_board.drop_target_entered.connect(_on_board_drop_target_entered)
	_board.cup_collected.connect(_on_cup_collected)
	_board.cups_changed.connect(_on_cups_changed)
	_board.error_feedback_requested.connect(_on_error_feedback_requested)
	_board.move_rejected.connect(_on_move_rejected)
	_board.blank_dropped.connect(_on_blank_dropped)
	_board.move_blocked.connect(_on_move_blocked)
	_board.locked_grabbed.connect(_on_locked_grabbed)
	_board.won.connect(_on_board_won)
	_board.dead.connect(_on_board_dead)
	_board.dead_attributed.connect(_on_board_dead_attributed)
	_board.challenge_detected.connect(_on_board_challenge_detected)
	_board.revealed_undo_touched.connect(_on_board_revealed_undo_touched)
	_board.lucky_reveal_detected.connect(_on_board_lucky_reveal_detected)
	_board.settled.connect(_on_board_settled)










func _layout() -> void :
	if not _components_ready:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_christmas_background()
	_layout_quota()
	_board.position = Vector2(0.0, _board_top())
	var two_rows: bool = _level_model != null and _level_model.juice != null and _level_model.juice.layout_rows == 2
	var long_rope: bool = _is_long_rope_level()
	var extra_board_h: float = TWO_ROW_PROP_SHIFT if two_rows else 0.0
	var prop_shift: float = 0.0
	if two_rows or long_rope:
		prop_shift = TWO_ROW_PROP_SHIFT + TWO_ROW_PROP_EXTRA_SHIFT

	var board_h: float = BOARD_H + extra_board_h + (180.0 if two_rows else 0.0)
	if long_rope:

		board_h += prop_shift + (BOARD_TOP - _base_board_top())
	if two_rows and _rank_bar != null and _rank_bar.visible:
		board_h -= _board_top() - _base_board_top()
	_board.size = Vector2(vp.x, board_h)

	var bar_y: float = _prop_bar_y(vp, prop_shift)


	var keys: Array[String] = ["undo", "hint", "rope"]
	if _complete_prop_enabled:
		keys.append("fill_pot")
	if not _reset_moved_to_header:
		keys.append("reset")
	if is_endless():
		keys.erase("reset")
	_reset_btn.visible = not is_endless() and not _reset_moved_to_header
	_header_reset_btn.visible = not is_endless() and _reset_moved_to_header
	_apply_header_reset_style()
	if _prop_ui.has("fill_pot"):
		((_prop_ui["fill_pot"] as Dictionary)["btn"] as Control).visible = _complete_prop_enabled
	var n: int = keys.size()
	var total: float = PROP_BTN_SIZE + PROP_BTN_PITCH * float(n - 1)
	var x0: float = UiMetrics.center_left(total)
	var btn_y: float = bar_y + 8.0
	var i: int = 0
	_layout_reset_btn_frame()
	for key: String in keys:
		var btn: Control = _reset_btn if key == "reset"\
		else (_prop_ui[key] as Dictionary)["btn"] as Control


		var p: Vector2 = Vector2(x0 + PROP_BTN_PITCH * float(i), btn_y) - PROP_BTN_TAP_INSET
		btn.position = p.snapped(Vector2.ONE)
		_update_ui_entrance_layout_base(btn)
		i += 1
	_layout_reset_badge()

	var prop_visible_top: float = snappedf(btn_y - PROP_BTN_TAP_INSET.y, 1.0)
	_board.set_wood_lock_bottom_limit(prop_visible_top - WOOD_LOCK_PROP_GAP - _board_top())
	if is_endless():
		_sync_level_card()
		_endless_mask.position = _board.position
		_endless_mask.size = _board.size

	_layout_guide_bars()
	_apply_tutorial_visibility()

	if not _board.is_entrance_motion_active()\
	and (entrance_style != EntranceStyle.SLIDE_WIND or _entrance_tween == null):
		_set_entrance_dx(_entrance_dx)
	_set_entrance_dy(_entrance_dy)
	_set_entrance_alpha(_entrance_alpha)


func _prop_bar_y(viewport: Vector2, prop_shift: float) -> float:
	var safe_bottom: float = viewport.y - UiMetrics.safe_insets().y
	var bar_y: float = safe_bottom - PROP_BAR_RESERVED_H + debug_prop_bar_shift + prop_shift
	return bar_y



func _layout_reset_btn_frame() -> void :
	_reset_btn.pivot_offset = _reset_btn.size * 0.5
	_reset_btn.z_index = PROP_BTN_Z



func _set_reset_buttons_disabled(disabled: bool) -> void :
	_reset_btn.disabled = disabled
	_header_reset_btn.disabled = disabled


func _is_long_rope_level() -> bool:
	return _level_model != null and _level_model.juice != null\
	and _level_model.juice.layout_rows == 1 and _level_model.juice.capacity >= LONG_ROPE_CAPACITY




func _base_board_top() -> float:

	if not _is_long_rope_level() and (_level_model == null or _level_model.juice == null\
	or _level_model.juice.layout_rows != 2):
		return BOARD_TOP
	return minf(BOARD_TOP, maxf(BOARD_TOP - 120.0, _quota_bottom_at_rest() + 12.0))



func _quota_bottom_at_rest() -> float:
	var quota_base_y: float = RULES_QUOTA_Y if _rules_guide_round else (IQ_QUOTA_Y if _iq_round.enabled or is_endless() else QUOTA_Y)
	var height: float = _quota.desired_height()
	var shift: float = minf(UiMetrics.safe_insets().x + debug_quota_shift, 
		maxf(BOARD_TOP - quota_base_y - height, 0.0))
	return quota_base_y + height + shift


func _layout_quota() -> void :
	var width: float = _quota.desired_width()
	var height: float = _quota.desired_height()
	var quota_base_y: float = RULES_QUOTA_Y if _rules_guide_round else (IQ_QUOTA_Y if _iq_round.enabled or is_endless() else QUOTA_Y)


	var max_shift: float = maxf(BOARD_TOP - quota_base_y - height, 0.0)
	var quota_y: float = quota_base_y + minf(UiMetrics.safe_insets().x + debug_quota_shift, max_shift)
	_quota.position = Vector2(UiMetrics.center_left(width), quota_y)
	_quota.size = Vector2(width, height)

	_quota.pivot_offset = _quota.layout_pivot()
	_layout_iq_header()
	_update_ui_entrance_layout_base(_quota)
	_layout_rank_bar()


func _layout_reset_badge() -> void :
	if _reset_badge == null or _reset_badge_label == null:
		return
	_reset_badge_label.text = tr("JUICE_RESET_BADGE")
	var font: Font = _reset_badge_label.get_theme_font("font")
	var font_size: int = RESET_BADGE_FONT_SIZE
	var text_width: float = font.get_string_size(
		_reset_badge_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var badge_width: float = clampf(
		ceilf(text_width + RESET_BADGE_TEXT_PAD * 2.0), 
		RESET_BADGE_MIN_WIDTH, 
		RESET_BADGE_MAX_WIDTH)
	var max_text_width: float = badge_width - RESET_BADGE_TEXT_PAD * 2.0
	while font_size > RESET_BADGE_MIN_FONT_SIZE and text_width > max_text_width:
		font_size -= 1
		text_width = font.get_string_size(
			_reset_badge_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	_reset_badge_label.add_theme_font_size_override("font_size", font_size)
	_reset_badge.position = Vector2(RESET_BADGE_CENTER_X - badge_width * 0.5, RESET_BADGE_TOP)
	_reset_badge.size = Vector2(badge_width, RESET_BADGE_HEIGHT)








func _add_ui_entrance_entry(key: String, node: Control, delay: float, dur: float, 
		displacement_y: float, grow: bool = false, input_button: BaseButton = null) -> void :
	if input_button != null:


		SceneManager.clear_button_feedback_baseline(input_button)
		SceneManager.reset_button_feedback(input_button)
	var entry: Dictionary = {
		"key": key, "node": node, "base_pos": node.position, "base_scale": node.scale, 
		"base_pivot": node.pivot_offset, "base_color": node.modulate, 
		"delay": delay, "dur": dur, "dy": displacement_y, "grow": grow, "done": false, 
		"input_button": input_button, 
	}
	if grow:

		node.pivot_offset = PROP_BTN_VISUAL_SIZE * 0.5
	if input_button != null:
		entry["mouse_filter"] = input_button.mouse_filter
		entry["focus_mode"] = input_button.focus_mode
		input_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		input_button.focus_mode = Control.FOCUS_NONE
		input_button.release_focus()
	_ui_entrance_entries.append(entry)




func _set_ui_entrance_preparing(preparing: bool) -> void :
	_ui_entrance_preparing = preparing
	if not is_node_ready():
		return
	_level_block.visible = not preparing
	if is_instance_valid(_quota):
		_apply_tutorial_visibility()


func _prepare_ui_entrance() -> void :
	_cancel_ui_entrance()
	_tutorial_quota_intro_hidden = _tutorial_active and _four_goal_tutorial_round
	_ui_entrance_pending = true

	_header.modulate.a = 1.0
	_coin_hud.modulate.a = 1.0
	SceneManager.clear_button_feedback_baseline(_back_btn)
	SceneManager.reset_button_feedback(_back_btn)
	_ui_props_ready = false
	_add_ui_entrance_entry("level", _level_block, 0.0, UI_LEVEL_ENTRANCE_DUR, -12.0)
	_add_ui_entrance_entry("quota", _quota, UI_QUOTA_ENTRANCE_DELAY, UI_QUOTA_ENTRANCE_DUR, -8.0)
	var index: int = 0
	var ui_keys: Array[String] = ["undo", "hint", "rope", "reset"]
	if _complete_prop_enabled:
		ui_keys.append("fill_pot")
	if is_endless() or _reset_moved_to_header:
		ui_keys.erase("reset")
	for key: String in ui_keys:
		var button: BaseButton = _reset_btn if key == "reset"\
		else (_prop_ui[key] as Dictionary)["btn"] as BaseButton
		_add_ui_entrance_entry(key, button, 
			UI_PROP_ENTRANCE_DELAY + float(index) * UI_PROP_ENTRANCE_STAGGER, 
			UI_PROP_ENTRANCE_DUR, 20.0, true, button)
		index += 1
	_set_ui_entrance_time(0.0)



func _play_ui_entrance(ctx = null) -> void :
	if not _ui_entrance_pending:
		return
	_ui_entrance_pending = false

	var fresh_entry: bool = ctx != null and bool(ctx.params.get("play_enter_haptic", false))\
	and (is_endless() or (ctx is GameStartContext and (ctx as GameStartContext).current_state.is_empty()))
	_rules_ui_entrance = _rules_guide_round and fresh_entry and not _is_first_level_presentation()
	if _rules_guide_round and (_rules_ui_entrance or not fresh_entry):

		for entry: Dictionary in _ui_entrance_entries:
			if String(entry["key"]) == "quota":
				_restore_ui_entrance_entry(entry)
				_ui_entrance_entries.erase(entry)
				break
	if _rules_ui_entrance:
		_quota.begin_rules_entrance()
	_ui_entrance_duration = maxf(UI_ENTRANCE_DUR, JuiceQuotaBar.RULES_ENTRANCE_DUR) if _rules_ui_entrance else UI_ENTRANCE_DUR
	_set_ui_entrance_time(0.0)
	_ui_entrance_tween = create_tween()
	_ui_entrance_tween.tween_method(_set_ui_entrance_time, 0.0, _ui_entrance_duration, _ui_entrance_duration)
	_ui_entrance_tween.finished.connect(_on_ui_entrance_finished.bind(_ui_entrance_tween), CONNECT_ONE_SHOT)


func _restore_ui_entrance_entry(entry: Dictionary) -> void :
	var node: Control = entry["node"] as Control
	if is_instance_valid(node):
		node.position = entry["base_pos"] as Vector2
		node.scale = entry["base_scale"] as Vector2
		node.pivot_offset = entry["base_pivot"] as Vector2
		node.modulate = entry["base_color"] as Color
	var button: BaseButton = entry["input_button"] as BaseButton
	if is_instance_valid(button):
		button.mouse_filter = int(entry["mouse_filter"])
		button.focus_mode = int(entry["focus_mode"])
		SceneManager.clear_button_feedback_baseline(button)
	entry["done"] = true


func _apply_ui_entrance_entry(entry: Dictionary) -> void :

	if bool(entry["done"]):
		return
	var node: Control = entry["node"] as Control
	if not is_instance_valid(node):
		return
	var u: float = clampf((_ui_entrance_time - float(entry["delay"])) / float(entry["dur"]), 0.0, 1.0)
	var ease: float = sin(u * PI * 0.5)
	node.position = (entry["base_pos"] as Vector2) + Vector2(0.0, float(entry["dy"]) * (1.0 - ease))
	var color: Color = entry["base_color"] as Color
	color.a *= ease
	node.modulate = color
	if bool(entry["grow"]):
		node.scale = (entry["base_scale"] as Vector2) * lerpf(0.96, 1.0, ease)
	if u >= 1.0:
		_restore_ui_entrance_entry(entry)


func _set_ui_entrance_time(time: float) -> void :
	_ui_entrance_time = time
	if _rules_ui_entrance:
		_quota.set_rules_entrance_time(time)
	var props_done: bool = true
	for entry: Dictionary in _ui_entrance_entries:
		_apply_ui_entrance_entry(entry)
		if bool(entry["grow"]) and not bool(entry["done"]):
			props_done = false
	_ui_props_ready = props_done



func _update_ui_entrance_layout_base(node: Control) -> void :
	for entry: Dictionary in _ui_entrance_entries:
		if entry["node"] == node:
			entry["base_pos"] = node.position
			if node == _quota:

				entry["base_pivot"] = node.pivot_offset
			_apply_ui_entrance_entry(entry)
			return


func _on_ui_entrance_finished(tween: Tween) -> void :
	if _ui_entrance_tween != tween:
		return
	_set_ui_entrance_time(_ui_entrance_duration)

	for entry: Dictionary in _ui_entrance_entries:
		if not bool(entry["done"]):
			_restore_ui_entrance_entry(entry)
	_rules_ui_entrance = false
	_ui_entrance_tween = null
	_ui_entrance_entries.clear()
	_ui_props_ready = true


func _cancel_ui_entrance() -> void :
	_clear_hint_guide_motion(true)
	_ui_entrance_generation += 1
	_ui_entrance_pending = false
	if _ui_entrance_tween != null and _ui_entrance_tween.is_valid():
		_ui_entrance_tween.kill()
	_ui_entrance_tween = null
	if is_instance_valid(_quota):
		_quota.reset_rules_entrance()
	_rules_ui_entrance = false
	_ui_entrance_duration = UI_ENTRANCE_DUR
	for entry: Dictionary in _ui_entrance_entries:
		if not bool(entry["done"]):
			_restore_ui_entrance_entry(entry)
	_ui_entrance_entries.clear()
	_ui_entrance_time = 0.0
	_ui_props_ready = true


func _ui_button_is_ready(key: String) -> bool:
	if _root_swap_guide_blocks_input():
		return false
	if _opening_banner_input_locked or _sunlight_guide_running:
		return false
	for entry: Dictionary in _ui_entrance_entries:
		if String(entry["key"]) == key:
			return bool(entry["done"])
	return true






func _set_entrance_dx(dx: float) -> void :
	_entrance_dx = dx
	if _board != null:
		_board.set_content_offset_x(dx)



func _set_entrance_time(time: float, generation: int) -> void :
	if generation != _entrance_generation:
		return
	_board.set_entrance_time(time)


func _set_entrance_dy(dy: float) -> void :
	_entrance_dy = dy
	if _board != null:
		_board.position.y = _board_top() + dy


func _set_entrance_alpha(alpha: float) -> void :
	_entrance_alpha = alpha
	if _board != null:
		_board.modulate.a = alpha



func _entrance_start_dx() -> float:
	return UiMetrics.viewport_size().x * ENTRANCE_START_OVERSHOOT







func play_playfield_entrance(ctx = null) -> void :
	_board.set_entrance_lock(true)
	_kill_entrance_tween()
	var generation: int = _entrance_generation

	if ctx != null:
		ctx.params["generation"] = generation
	if entrance_style == EntranceStyle.SOFT_DROP:
		_board.end_entrance_wind()
		_set_entrance_dx(0.0)
		_set_entrance_dy( - SOFT_ENTRANCE_RISE)
		_set_entrance_alpha(0.0)
		_entrance_tween = create_tween()
		_entrance_tween.tween_method(_set_entrance_dy, _entrance_dy, 
			SOFT_ENTRANCE_SETTLE, SOFT_ENTRANCE_MOVE_DUR)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_entrance_tween.parallel().tween_method(_set_entrance_alpha, 0.0, 1.0, 
			SOFT_ENTRANCE_FADE_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_method(_set_entrance_dy, SOFT_ENTRANCE_SETTLE, 0.0, 
			SOFT_ENTRANCE_SETTLE_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_set_entrance_dx(_entrance_start_dx())

		_board.begin_entrance_wind(_entrance_dx, ENTRANCE_DUR)
		_entrance_tween = create_tween()

		_entrance_tween.tween_method(_set_entrance_time.bind(generation), 0.0, ENTRANCE_DUR, ENTRANCE_DUR)
		_entrance_tween.parallel().tween_callback(_play_skin_sound.bind(&"juice_whoosh"))\
		.set_delay(ENTRANCE_SFX_DELAY)

	_board.show()
	_play_ui_entrance(ctx)
	_play_game_enter_haptic(ctx)
	var tw: Tween = _entrance_tween







	var done: = {"v": false}
	tw.finished.connect( func() -> void : done.v = true, CONNECT_ONE_SHOT)
	while true:
		if done.v:
			break
		if not tw.is_valid():









			if _entrance_tween != null and _entrance_tween.is_valid() and _entrance_tween != tw:
				tw = _entrance_tween
				done = {"v": false}
				tw.finished.connect( func() -> void : done.v = true, CONNECT_ONE_SHOT)
				continue
			break
		await get_tree().process_frame

	while _board.is_entrance_motion_active():
		if not visible or _entrance_tween == null:
			return
		await get_tree().process_frame

	if _entrance_tween == tw:
		_entrance_tween = null
		_set_entrance_dx(0.0)
		_set_entrance_dy(0.0)
		_set_entrance_alpha(1.0)




	await _wait_entrance_wind()

	while _ui_entrance_tween != null and _ui_entrance_tween.is_valid():
		if not visible or generation != _entrance_generation:
			return
		await get_tree().process_frame
	if generation == _entrance_generation and visible and is_zero_approx(_entrance_dx)\
	and is_zero_approx(_entrance_dy) and is_equal_approx(_entrance_alpha, 1.0):
		_playfield_ready = true
		_finish_entrance_mystery_auto_unlock(ctx)

		if not _tutorial_active and _board.over() != "win":
			_board.set_entrance_lock(false)



func show_playfield_without_entrance(ctx: GameStartContext) -> void :
	if not visible or ctx.aborted or ctx != _start_flow_context:
		return
	_kill_entrance_tween()
	ctx.params["generation"] = _entrance_generation
	_set_entrance_dx(0.0)
	_cancel_ui_entrance()
	_board.show()
	_playfield_ready = true
	_finish_entrance_mystery_auto_unlock(ctx)
	if not _tutorial_active and _board.over() != "win":
		_board.set_entrance_lock(false)







func _wait_entrance_wind() -> void :
	var deadline: int = Time.get_ticks_msec() + int(ENTRANCE_WIND_WAIT_CAP * 1000.0)

	await get_tree().process_frame
	while _board != null and is_instance_valid(_board)\
	and _board.is_entrance_wind_strong()\
	and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _kill_entrance_tween() -> void :
	HapticManager.cancel_event(_game_enter_haptic)
	_game_enter_haptic = 0
	_entrance_generation += 1
	_playfield_ready = false
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	_entrance_tween = null
	if _board != null:
		_board.end_entrance_wind()
	_set_entrance_dy(0.0)
	_set_entrance_alpha(1.0)


var _home_navigation_generation: int = 0
var _home_navigation_running: bool = false
var _home_navigation_saved: bool = false
var _home_navigation_nodes: Array[Dictionary] = []


func _on_back_pressed() -> void :
	if is_mainline_timed_endless():
		if _prop_ad_in_flight or _back_btn.disabled or _home_navigation_running:
			return
		if not settle_mainline_timed_endless("exit", _endless_cups()):
			return
		if is_instance_valid(_endless_controller):
			_endless_controller.cancel()
		await return_home()
		return
	if is_endless():
		if not _prop_ad_in_flight:
			endless_exit_requested.emit()
		return
	_on_undo_guide_action()
	if _back_btn.disabled or _home_navigation_running:
		return
	Tracker.track_btn_click(TrackingEvents.BTN_HOME, TrackingEvents.SCR_GAME)
	await return_home()


func _on_back_request() -> void :

	if OS.has_feature("android"):
		return
	_on_back_pressed()


func _on_reset_pressed() -> void :
	if is_endless():
		return
		return
	if _finish_ad_busy or _prop_ad_in_flight:
		return
	_on_undo_guide_action()
	if not _ui_button_is_ready("reset"):
		return

	Tracker.track_btn_click(TrackingEvents.BTN_RESTART, _dead_toast_source())
	var st: Dictionary = _board.state()
	SceneManager.show_dlg("reset_confirm", {
		"on_confirm": Callable(self, "_on_reset_confirmed"), 
		"done": int(st.get("done", 0)), 

		"total": _board.level().groups_total if _board.level() != null else 0, 
		"streak": UserState.get_win_streak_count(), 
	})


func _on_reset_confirmed() -> void :
	if _root_swap_guide_blocks_input():
		return
	if _finish_ad_busy or _restart_interstitial_busy:
		AdManager.log_ad_baseline_blocked("interstitial", "ad_busy", TrackingEvents.AD_POSITION_GAME_RESTART, 
			{"stage": "restart_gate", "finish_ad_busy": _finish_ad_busy, 
			"restart_interstitial_busy": _restart_interstitial_busy})
		return
	_stop_undo_guide_motion_preview()

	if _level_model != null and ABManager.inter_unlock_level.should_allow_interstitial(
			_level_model.level_id, UserState.is_interstitial_unlocked()):
		UserState.unlock_ads(true, false)
		if ABManager.inter_protect_by_day.should_allow_interstitial(
				UserState.get_install_days(), UserState.get_daily_completed_level_count(), false):

			AdManager.log_ad_baseline_conditions(TrackingEvents.AD_POSITION_GAME_RESTART, 
				{"stage": "restart_gate", "level_id": _level_model.level_id, "after_completion": false})
			_show_restart_interstitial()
		else:
			AdManager.log_ad_baseline_blocked("inter_protect_by_day", "daily_protection", TrackingEvents.AD_POSITION_GAME_RESTART, 
				{"stage": "restart_gate", "level_id": _level_model.level_id, "after_completion": false})
	elif _level_model == null:
		AdManager.log_ad_baseline_blocked("interstitial", "level_model_missing", TrackingEvents.AD_POSITION_GAME_RESTART, 
			{"stage": "restart_gate"})
	else:
		AdManager.log_ad_baseline_blocked("inter_unlock_level", "unlock_threshold", TrackingEvents.AD_POSITION_GAME_RESTART, 
			{"stage": "restart_gate", "level_id": _level_model.level_id})
	_hide_dead_toast()
	restart_level()


func _show_restart_interstitial() -> void :
	_restart_interstitial_generation += 1
	var generation: int = _restart_interstitial_generation
	_restart_interstitial_busy = true
	await AdManager.show_interstitial_and_await(TrackingEvents.AD_POSITION_GAME_RESTART)
	if generation == _restart_interstitial_generation:
		_restart_interstitial_busy = false





func _on_show(params: Dictionary) -> void :
	_restore_round_for_show()
	if is_mainline_timed_endless() and not _timed_finish_running:
		if not settle_mainline_timed_endless("exit", _endless_cups()):
			return
	var timed_offer: Dictionary = UserState.get_timed_endless_offer()
	if not timed_offer.is_empty()\
	and String(params.get("play_mode", "")) != "endless":
		_mainline_timed_offer = timed_offer
		_timed_result = {}
		_timed_finish_running = false
		_complete_prop_enabled = false
		_reset_moved_to_header = false
		_reset_white_style = false
		if timed_offer.get("status", "") == "reward_pending":
			play_mode = PlayMode.ENDLESS
			_initialize_timed_reward(timed_offer["result"])
			_timed_finish_running = true
			_back_btn.disabled = true
			var generation: int = _end_flow_generation
			await MainlineTimedEndlessEndFlow.run(self, int(_timed_result["after_level"]))
			if generation == _end_flow_generation:
				_timed_finish_running = false
			return
		await start_endless(null, false, true)
		return
	_mainline_timed_offer = {}
	_timed_result = {}
	if String(params.get("play_mode", "")) == "endless":

		_complete_prop_enabled = false
		_reset_moved_to_header = false
		_reset_white_style = false
		await start_endless(params.get("seed"), false, true)
		return
	if is_endless():
		stop_endless()
	play_mode = PlayMode.LEVEL

	if _board != null:
		_board.hide()
	_kill_entrance_tween()
	if _rules_ui_entrance:
		_cancel_ui_entrance()
	_cancel_game_start()
	var prepare_request: RefCounted = RefCounted.new()
	set_meta(&"show_prepare_request", prepare_request)
	var active: Callable = func() -> bool:
		return visible and get_meta(&"show_prepare_request") == prepare_request
	if not await _prepare_for_show(active):
		return
	_special_challenge_banner_pending = true
	_stop_undo_guide_motion_preview()
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	var ctx: GameStartContext = _begin_game_start(params)
	ctx.params["play_enter_haptic"] = true



	if not is_node_ready():
		await ready
	if ctx.aborted:
		return

	_board.hide()
	if _rank_fly != null:
		_rank_fly.show()
	_special_challenge_chest.hide()
	if _iq_genius_feedback != null:
		_iq_genius_feedback.hide_now()
	_iq_round.reset(false, 0)
	_refresh_iq_header()
	ABManager.allow_root_swapping.reload_value()
	if ABManager.is_ab_init_done():
		ABManager.dye_at_enter_game()
	ABManager.dye_at_new_guide()
	_four_goal_tutorial_round = ABManager.new_guide.is_four_goal_tutorial_enabled()
	_freeze_rules_guide_group()
	_freeze_complete_prop_group()
	_christmas_theme_enabled = ABManager.christmas_theme.is_christmas_theme_enabled()
	_apply_game_visuals()
	_cancel_ui_entrance()
	entrance_style = EntranceStyle.SLIDE_WIND
	if ABManager.long_link.is_long_link_enabled():
		_long_link_feedback.prepare()

	_board.set_ambient_sway_enabled(true)
	_board.set_reveal_memory_enabled(ABManager.sort_reveal_memory.is_memory_enabled())
	_board.set_capacity_knots_enabled(ABManager.sort_rope_capacity_knots.is_capacity_knots_enabled())
	_tracking_background_reported = false
	_tracking_common = null
	_pending_free_prop_get.clear()
	_entrance_generation += 1
	_playfield_ready = false
	_board.set_entrance_lock(true)

	Tracker.track_scr_show(TrackingEvents.SCR_GAME)
	visible = true
	_layout()
	_refresh_coin_hud()
	_prepare_ui_entrance()
	_set_ui_entrance_preparing(false)
	var ui_generation: int = _ui_entrance_generation

	if not CheatBus.command_issued.is_connected(_on_cheat_command):
		CheatBus.command_issued.connect(_on_cheat_command)

	if not AdManager.reward_ad_loaded.is_connected(_on_reward_ad_loaded):
		AdManager.reward_ad_loaded.connect(_on_reward_ad_loaded)

	set_process(true)

	await GameStartFlow.run(ctx)
	if ctx.aborted or ctx != _start_flow_context:
		return
	PagePreparationCoordinator.first_page_entered(self, "game")
	if bool(ctx.params.get("special_reward_pending", false)):
		_win_committed = true
		_play_timer.disarm()
		_board.set_input_enabled(false)
		_run_game_end_flow()

	if _ui_entrance_pending and ui_generation == _ui_entrance_generation:
		_cancel_ui_entrance()
	var cheat_eight_columns_rows: int = int(params.get("cheat_eight_columns_rows", 0))
	if cheat_eight_columns_rows > 0:
		_cheat_finish_eight_columns_setup(cheat_eight_columns_rows)
	var cheat_challenge_tip: String = String(params.get("cheat_challenge_tip", ""))
	if cheat_challenge_tip != "":
		_cheat_finish_challenge_setup(cheat_challenge_tip)


func _process(delta: float) -> void :
	_poll_root_swap_guide()
	_update_endless_time_warning(delta)
	if is_endless():
		_hint_poll()
		_refresh_endless_hud()
		return
	_hint_poll()
	_poll_hint_guide(delta)


func _on_hide() -> void :
	_teardown_root_swap_guide()
	HapticManager.cancel_event(_game_enter_haptic)
	_game_enter_haptic = 0

	_cancel_tutorial_transition()
	_skin_generation += 1
	if _board != null:
		_board.reset_skin_effects()
	if _motion_preview_only:
		cancel_rank_motion_preview()
		hide()
		return
	if is_endless():
		if is_mainline_timed_endless():
			if not settle_mainline_timed_endless("exit", _endless_cups()):
				return
			if _components_ready:
				_cancel_finish_ad_reward()
				_cancel_win_coin_reward()
		_end_flow_generation += 1
		_complete_shown = false
		_timed_finish_running = false
		stop_endless()
		_hide_round_view()
		return
	_board.cancel_sunlight_animation()
	SceneManager.hide_dlg("daily_first_win_checkin")
	_daily_checkin_round.mark_presented()
	_deferred_prepare_request = null
	if _components != null:
		_components.cancel()
	set_meta(&"show_prepare_request", RefCounted.new())
	if not _components_ready:
		visible = false
		return
	_home_navigation_generation += 1

	hide_banner_ad()
	_board.clear_capacity_error_hint()
	if _iq_genius_feedback != null:
		_iq_genius_feedback.hide_now()
	_rank_round.cancel()
	SceneManager.hide_dlg("rank_game_finish")
	for route: String in ["rank_change", "rank_new_season", "rank_introduction", "rank_season_win"]:
		SceneManager.hide_dlg(route)
	_cancel_bonus_collection()
	_bonus_coin_pending = 0
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	if _bonus_level_banner != null:
		_bonus_level_banner.cancel()
	_hide_bonus_gain()
	_cancel_finish_ad_reward()
	_finish_ad_busy_generation += 1
	_finish_ad_busy = false
	_finish_interstitial_busy = false
	_finish_ad_reward_enabled = false
	_finish_game_data_enabled = false
	_finish_use_new_result_data = false
	_finish_iq_replacement_metric = ""
	_stop_undo_guide_motion_preview()
	if _special_challenge_banner != null:
		_special_challenge_banner.cancel()
	_cancel_opening_banner_input_lock()
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	_combo_feedback.hide_now()
	_empty_col_feedback.hide_now()
	_long_link_feedback.hide_now()
	_hide_challenge_banner()
	_cancel_game_start()
	_end_flow_generation += 1
	_cancel_ui_entrance()
	if not _home_navigation_saved:
		if not _tracking_background_reported:
			report_game_exit(TrackingEvents.EXIT_TYPE_RETURN_HOME)

		_save_progress("exit")
		_flush_play_time("time_exit")
		LevelManager.flush()
	_cancel_win_coin_reward()
	_play_timer.disarm()
	_play_timer.resume(&"home_navigation")
	_home_navigation_saved = false

	_hide_round_view()
	_close_prop_unlock_now()
	_hint_cancel()


	_cancel_cup_flights()

	_kill_entrance_tween()
	_set_entrance_dx(0.0)
	_board.set_entrance_lock(true)

	_teardown_tutorial()
	_teardown_mystery_guide()
	_close_lock_guide_now()
	_close_sunlight_guide_now()
	_discard_prepared_rank_gift_flight()
	if CheatBus.command_issued.is_connected(_on_cheat_command):
		CheatBus.command_issued.disconnect(_on_cheat_command)
	if AdManager.reward_ad_loaded.is_connected(_on_reward_ad_loaded):
		AdManager.reward_ad_loaded.disconnect(_on_reward_ad_loaded)
	_hide_dead_toast()
	SceneManager.hide_dlg("reset_confirm")
	_restore_home_navigation_nodes()
	_home_navigation_running = false
	set_process(false)


func _notification(what: int) -> void :
	super (what)
	if _external_play_suspended:
		return
	if is_endless():
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
			_hint_guide_background_paused = true
			_endless_background_paused = true
			if is_instance_valid(_endless_controller):
				_endless_controller.pause(&"background")
			if is_mainline_timed_endless() and _timed_result.is_empty():
				if not UserState.checkpoint_timed_endless(String(_mainline_timed_offer["instance_id"]), _endless_cups()):
					SortLogger.error("限时挑战后台结算检查点保存失败")
			if is_instance_valid(_board):
				_board.cancel_active_drag()
			_hint_cancel()
		elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
			_hint_guide_background_paused = false
			_endless_background_paused = false
			if is_instance_valid(_endless_controller):
				_endless_controller.resume(&"background")
		elif what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _components_ready:
			_sync_level_card()
		return
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _components_ready:
		_sync_level_card()

		_layout_reset_badge()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT\
	or what == NOTIFICATION_APPLICATION_PAUSED:

		_hint_guide_background_paused = true
		_stop_rope_guide()
		if _components_ready:
			_combo_feedback.hide_now()
			_empty_col_feedback.hide_now()
			_long_link_feedback.hide_now()
			_stop_progress_full_preview()
			_hide_challenge_banner()
			if _ui_entrance_pending or _ui_entrance_tween != null:
				_cancel_ui_entrance()

		if _board != null:
			_board.cancel_active_drag()

		_play_timer.pause(LevelPlayTimer.PAUSE_BACKGROUND)
		if is_node_ready() and visible and not _tracking_background_reported:
			_tracking_background_reported = true
			report_game_exit(TrackingEvents.EXIT_TYPE_CUT_BACKGROUND)




		_save_progress("background")
		_flush_play_time("time_background")
		LevelManager.flush()
	if what == NOTIFICATION_APPLICATION_FOCUS_IN\
	or what == NOTIFICATION_APPLICATION_RESUMED:
		_hint_guide_background_paused = false
		_hint_guide_skip_frame = true
		_tracking_background_reported = false
		_play_timer.resume(LevelPlayTimer.PAUSE_BACKGROUND)
		if is_node_ready() and visible and _complete_shown:
			_refresh_finish_tracking()







func _begin_game_start(params: Dictionary) -> GameStartContext:
	_cancel_game_start()
	_start_flow_context = GameStartContext.new(self, params)
	return _start_flow_context


func _cancel_game_start() -> void :
	_restart_interstitial_generation += 1
	_restart_interstitial_busy = false
	if _start_flow_context != null:
		_start_flow_context.aborted = true
		if _start_flow_context.loading:
			_start_flow_context.loading = false
			SceneManager.hide_loading()
	if _start_banner != null and is_instance_valid(_start_banner):
		_start_banner.hide_now()




func reset_reuse_state() -> void :
	_teardown_root_swap_guide()
	_cancel_tutorial_transition()
	_board.cancel_sunlight_animation()
	_deferred_prepare_request = null
	_components.cancel()
	_long_link_feedback.hide_now()
	_cancel_bonus_collection()
	_bonus_type = -1
	_bonus_v2 = false
	_board.set_bonus_candidate(false)
	_bonus_coin_pending = 0
	_hide_bonus_gain()
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	if _bonus_level_banner != null:
		_bonus_level_banner.cancel()
	_stop_progress_full_preview()
	_stop_undo_guide_motion_preview()
	if _special_challenge_banner != null:
		_special_challenge_banner.cancel()
	_special_challenge_chest.hide()
	_cancel_opening_banner_input_lock()
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	_combo_feedback.hide_now()
	_empty_col_feedback.hide_now()
	_cancel_win_coin_reward()
	_hide_dead_toast()
	SceneManager.hide_dlg("reset_confirm")
	_close_prop_unlock_now()
	_teardown_tutorial()
	_teardown_mystery_guide()
	_close_lock_guide_now()
	_close_sunlight_guide_now()
	_tutorial_active = false
	_hide_challenge_banner()



func resolve_restart_model(level_id: int, model: LevelModel) -> LevelModel:
	if model != null and model.is_special_challenge():
		return model
	var restart_model: LevelModel = LevelManager.resolve_restart_model(level_id, model)
	if restart_model is JuiceLevelModel and model is JuiceLevelModel:
		(restart_model as JuiceLevelModel).special_theme_skin_id = (model as JuiceLevelModel).special_theme_skin_id
		(restart_model as JuiceLevelModel).rank_collectible_rule = (model as JuiceLevelModel).rank_collectible_rule.duplicate(true)
	return restart_model






func apply_level_model(model: LevelModel) -> JuiceLevelModel:
	var juice_model: JuiceLevelModel = model as JuiceLevelModel
	if juice_model == null or juice_model.juice == null:
		SortLogger.info("[JuiceGamePage] apply_level_model: 数据缺失或非 juice_sort 玩法数据")
		_level_model = null

		hide_banner_ad()
		return null
	_level_model = juice_model
	_layout()

	_sync_banner_ad()
	SortLogger.info("[JuiceGamePage] apply_level_model: 加载成功")
	return juice_model



func _sync_banner_ad() -> void :
	if _level_model != null and not is_special_challenge():
		UserState.unlock_ads(
			ABManager.inter_unlock_level.should_allow_interstitial(_level_model.level_id), 
			ABManager.banner_unlock_level.should_allow_banner(_level_model.level_id))
	AdManager.log_ad_baseline_conditions(TrackingEvents.AD_POSITION_GAME_PAGE, 
		{"stage": "level_start", "level_id": _level_model.level_id if _level_model != null else -1, 
		"model_available": _level_model != null, "special_challenge": is_special_challenge(), 
		"max_rows": _level_model.juice.capacity if _level_model != null else -1})
	if not _should_show_banner_ad():
		hide_banner_ad()
		return
	if _banner_ad_shown:
		AdManager.log_ad_baseline_blocked("banner", "show_already_requested", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "show_gate", "level_id": _level_model.level_id})
		return
	_banner_ad_shown = true
	AdManager.show_banner(TrackingEvents.AD_POSITION_GAME_PAGE, 
		_banner_offset_base(), _banner_height_base())



func _should_show_banner_ad() -> bool:
	if _level_model == null:
		AdManager.log_ad_baseline_blocked("banner", "level_model_missing", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "show_gate"})
		return false
	if is_special_challenge():
		AdManager.log_ad_baseline_blocked("banner", "special_challenge", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "show_gate", "level_id": _level_model.level_id})
		return false
	var max_rows: int = _level_model.juice.capacity
	if max_rows > BANNER_AD_MAX_ROWS:
		SortLogger.info("[BannerAd] 不展示：本局最大行数 %d > %d" % [max_rows, BANNER_AD_MAX_ROWS])
		AdManager.log_ad_baseline_blocked("banner", "row_limit", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "show_gate", "level_id": _level_model.level_id, 
			"max_rows": max_rows, "row_limit": BANNER_AD_MAX_ROWS})
		return false
	var allowed: bool = ABManager.banner_unlock_level.should_allow_banner(
		_level_model.level_id, UserState.is_banner_unlocked())
	if not allowed:
		AdManager.log_ad_baseline_blocked("banner_unlock_level", "unlock_threshold", TrackingEvents.AD_POSITION_GAME_PAGE, 
			{"stage": "show_gate", "level_id": _level_model.level_id})
	else:
		AdManager.log_ad_baseline_banner({"stage": "show_gate", "level_id": _level_model.level_id, 
			"model_available": true, "special_challenge": false, "max_rows": max_rows})
	return allowed






func _banner_offset_base() -> int:
	return int(round(UiMetrics.safe_insets().y * _banner_design_scale()))





func _banner_height_base() -> int:
	return int(round(BANNER_AD_HEIGHT * _banner_design_scale()))




func _banner_design_scale() -> float:
	var vp_w: float = UiMetrics.viewport_size().x
	if vp_w <= 0.0:
		return 1.0
	return 1080.0 / vp_w




func hide_banner_ad() -> void :
	if not _banner_ad_shown:
		return
	AdManager.log_ad_baseline_blocked("banner", "hidden_by_page", TrackingEvents.AD_POSITION_GAME_PAGE, 
		{"stage": "hide", "page_visible": visible})
	_banner_ad_shown = false
	AdManager.hide_banner()



func show_fallback_toast_if_needed() -> void :
	if OS.has_feature("rel") or _level_model == null or not _level_model.used_fallback:
		return
	SceneManager.show_toast(tr("GAME_LEVEL_FALLBACK_TOAST"))















func setup_tracking_context(model: LevelModel, restore: Dictionary) -> void :
	var special: bool = model != null and model.is_special_challenge()
	_tracking_special_state = UserState.get_special_challenge_tracking(model.challenge_instance_id)\
	if special else {}
	var current_level: int = UserState.get_current_level()
	_tracking_common = TrackingCommonParams.new()
	if special:
		_tracking_common.level_num = current_level
		_tracking_common.level_type = TrackingEvents.LEVEL_TYPE_SPECIAL_CHALLENGE
	else:
		_tracking_common.level_num = current_level
		_tracking_common.level_type = TrackingEvents.LEVEL_TYPE_LEVEL
	_tracking_common.game_id = LevelManager.new_transient_game_id() if _is_legacy_tutorial() else _round_game_id()
	if special and _tracking_common.game_id.is_empty():
		SortLogger.error("Special Challenge 无开局存档，无法装配埋点局 ID")
		_tracking_common = null
		return
	if model != null:
		_tracking_common.level_unique_id = model.level_unique_id
		_tracking_common.chapter_index = model.chapter_index
		_tracking_common.level_index = model.level_index
		_tracking_common.level_data_source = model.level_data_source



		_tracking_common.difficulty_level = TrackingEvents.DIFFICULTY_SUPER_HARD\
		if model.is_super_hard() else model.difficulty_type.to_lower()
	_tracking_game_state = (TrackingEvents.GAME_STATE_CONTINUE_START
		if not restore.is_empty() else TrackingEvents.GAME_STATE_START)
	var previous_game_id: String = String(_tracking_special_state.get("game_id", ""))
	if special and not previous_game_id.is_empty() and previous_game_id != _tracking_common.game_id:

		_tracking_game_state = TrackingEvents.GAME_STATE_RESTART








func setup_endless_tracking_context() -> void :
	if not is_mainline_timed_endless():
		return
	_tracking_common = TrackingCommonParams.new()
	_tracking_common.level_num = UserState.get_current_level()
	_tracking_common.level_type = TrackingEvents.LEVEL_TYPE_ENDLESS
	_tracking_common.level_unique_id = ""
	_tracking_common.chapter_index = -1
	_tracking_common.level_index = -1
	_tracking_common.game_id = LevelManager.new_transient_game_id()
	_tracking_common.level_data_source = ""
	_tracking_common.difficulty_level = TrackingEvents.DIFFICULTY_NORMAL
	_tracking_game_state = TrackingEvents.GAME_STATE_START
	_reset_tracking_round_props()














func report_game_start(count_as_new_start: bool = true) -> void :
	if _tracking_common == null:
		return
	if not is_endless() and is_special_challenge()\
	and UserState.get_special_challenge().get("status", "") != "playing":
		return
	if count_as_new_start and not is_endless():
		if is_special_challenge():
			_record_special_challenge_start()
		else:

			if _tracking_game_state != TrackingEvents.GAME_STATE_CONTINUE_START:
				_inc_level_counter("start_times")
		_log_special_pot_replacements()
	var start_times: int = 1
	if is_endless():

		start_times = 1
	elif is_special_challenge():
		start_times = int(_tracking_special_state.get("new_start_times", 1))
	else:

		start_times = maxi(LevelManager.get_level_start_times(_round_storage_key()), 1)

	var params: Dictionary = {
		TrackingEvents.K_GAME_STATE: _tracking_game_state, 
		TrackingEvents.K_SES_NUM: SessionManager.get_session_num(), 
		TrackingEvents.K_NEW_START_TIMES: start_times, 
		TrackingEvents.K_LEVEL_DEFAULT_INFO: _tracking_level_default_info(), 
	}

	var set_info: String = _tracking_gameplay_set_info()
	if not set_info.is_empty():
		params[TrackingEvents.K_GAMEPLAY_SET_INFO] = set_info
	Tracker.send_event(TrackingEvents.EV_GAME_START, params, _tracking_common)
	for key: String in _pending_free_prop_get:

		var acquired_count: int = UserState.get_prop_count(key)\
		+ int(UserState.is_prop_free_available(key))
		_report_prop_get(key, acquired_count, TrackingEvents.PROP_SOURCE_UNLOCK_FIRST)
		UserState.mark_prop_free_get_reported(key)
	_pending_free_prop_get.clear()



func _record_special_challenge_start() -> void :
	if String(_tracking_special_state.get("game_id", "")) == _tracking_common.game_id:
		return
	_tracking_special_state["game_id"] = _tracking_common.game_id
	_tracking_special_state["new_start_times"] = int(_tracking_special_state.get("new_start_times", 0)) + 1
	_tracking_special_state.erase("game_end_params")
	_tracking_special_state["game_end_reported"] = false
	_persist_special_challenge_tracking()


func _persist_special_challenge_tracking() -> bool:
	return UserState.update_special_challenge_tracking(_level_model.challenge_instance_id, _tracking_special_state)



func _log_special_pot_replacements() -> void :
	if _level_model == null or _level_model.juice == null:
		return
	var lv: JuiceLevel = _level_model.juice
	var bonus_pots: Array[Dictionary] = []
	var bonus_descriptions: PackedStringArray = []
	for type_id: int in lv.types:
		var slot: int = _board.slot_for_type(type_id)
		if type_id != _bonus_type:
			continue
		var color_name: String = _special_pot_log_color_name(slot)
		var replacement: Dictionary = {"type_id": type_id, "color_slot": slot, "color": color_name, 
			"initial_columns": [], "incoming_after": []}
		var locations: PackedStringArray = []

		for ci: int in lv.board_jars.size():
			if lv.board_jars[ci] == type_id:
				replacement["initial_columns"].append(ci)
				locations.append("开局第%d个盆（initial[%d]）" % [ci + 1, ci])
		for k: int in lv.incoming.size():
			var entry: Dictionary = lv.incoming[k]
			if String(entry.get("slot", "")) == JuiceLevel.SLOT_JAR and int(entry["jar"]) == type_id:
				replacement["incoming_after"].append(k + 1)
				locations.append("第%d次收盆后补入（incoming[%d]）" % [k + 1, k])
		var description: String = "编号%d（%s）的盆替换为金猪；位置：%s" % [
			type_id, color_name, "、".join(locations)]
		bonus_pots.append(replacement)
		bonus_descriptions.append(description)
	if bonus_pots.is_empty():
		return
	var info: Dictionary = {"level_id": _level_model.level_id, 
		"level_unique_id": _level_model.level_unique_id, "game_state": _tracking_game_state, 
		"level_config": _level_model.raw}
	if not bonus_pots.is_empty():
		info["replacements"] = bonus_pots
		SortLogger.info("[BonusLevel] 第%d关：%s | 关卡配置及替换详情：%s" % [
			_level_model.level_id, "；".join(bonus_descriptions), JSON.stringify(info)])



func _special_pot_log_color_name(slot: int) -> String:
	var names: Array[String] = ["红色", "紫色", "粉色", "浅蓝色", "黄色", 
		"绿色", "蓝色", "青绿色", "橙色", "淡紫色", "紫罗兰色", "黄绿色"]
	return names[slot] if slot >= 0 and slot < names.size() else "未知颜色"


func _report_new_rope(is_empty: bool, method: String, gameplay: String = "") -> void :
	if _tracking_common == null:
		return
	var params: Dictionary = {
		TrackingEvents.K_IS_EMPTY_ROPE: 1 if is_empty else 0, 
		TrackingEvents.K_APPEAR_METHOD: method, 
	}
	if not gameplay.is_empty():
		params[TrackingEvents.K_NEW_ROPE_GAMEPLAY] = gameplay
	Tracker.send_event(TrackingEvents.EV_NEW_ROPE_APPEAR, params, _tracking_common)



func report_finish_ad_reward(kind: String, amount: int) -> void :
	if amount <= 0:
		return
	if is_special_challenge():
		if kind == "coins":
			Tracker.send_event(TrackingEvents.EV_COIN_STATUS, {
				TrackingEvents.K_COIN_CHANGE_REASON: TrackingEvents.COIN_REASON_GAME_END_ADS, 
				TrackingEvents.K_COIN_CHANGE_NUM: amount, 
				TrackingEvents.K_COIN_TOTAL_NUM: UserState.get_coins()})
		else:
			Tracker.send_event(TrackingEvents.EV_PROP_GET, {
				TrackingEvents.K_SOURCE: TrackingEvents.PROP_SOURCE_GAME_END_ADS, 
				TrackingEvents.K_PROP_NAME: kind, TrackingEvents.K_PROP_NUM: amount, 
				TrackingEvents.K_PROP_LEFT: UserState.get_prop_count(kind)})
		return
	if kind == "coins":
		_report_coin_change(TrackingEvents.COIN_REASON_GAME_END_ADS, amount)
	else:
		_report_prop_get(kind, amount, TrackingEvents.PROP_SOURCE_GAME_END_ADS)


func _report_coin_change(reason: String, amount: int) -> void :
	if _tracking_common == null or amount == 0:
		return
	Tracker.send_event(TrackingEvents.EV_COIN_STATUS, {
		TrackingEvents.K_COIN_CHANGE_REASON: reason, 
		TrackingEvents.K_COIN_CHANGE_NUM: amount, 
		TrackingEvents.K_COIN_TOTAL_NUM: UserState.get_coins(), 
	}, _tracking_common)





func _report_daily_checkin_coins(completion: Dictionary) -> void :
	_report_coin_change(TrackingEvents.COIN_REASON_DAILY_CHECKIN, 
		int(completion.get("reward_coins", 0)))


func _report_prop_get(key: String, amount: int, source: String) -> void :
	if _tracking_common == null or amount <= 0:
		return
	var left: int = UserState.get_prop_count(key)
	if source == TrackingEvents.PROP_SOURCE_UNLOCK_FIRST\
	and UserState.is_prop_free_available(key):
		left += 1
	Tracker.send_event(TrackingEvents.EV_PROP_GET, {
		TrackingEvents.K_SOURCE: source, 
		TrackingEvents.K_PROP_NAME: key, 
		TrackingEvents.K_PROP_NUM: amount, 
		TrackingEvents.K_PROP_LEFT: left, 
	}, _tracking_common)


func _report_prop_use(key: String, source: String, left: int) -> void :
	if _tracking_common == null:
		return
	Tracker.send_event(TrackingEvents.EV_PROP_USE, {
		TrackingEvents.K_SOURCE: source, 
		TrackingEvents.K_PROP_NAME: key, 
		TrackingEvents.K_PROP_NUM: 1, 
		TrackingEvents.K_PROP_LEFT: left, 
	}, _tracking_common)




func _tracking_round_cost_ms() -> int:
	if is_endless() and is_instance_valid(_endless_controller):
		return _endless_controller.elapsed_ms()
	return _play_timer.elapsed_ms()








func _tracking_round_params() -> Dictionary:
	var st: Dictionary = _board.state()

	var used_info: Dictionary = {
		"hint": _tracking_prop_used("hint"), 
		"undo": _tracking_prop_used("undo"), 
		"rope": _tracking_prop_used("rope"), 
	}
	var left_info: Dictionary = {
		"hint": _tracking_prop_left("hint"), 
		"undo": _tracking_prop_left("undo"), 
		"rope": _tracking_prop_left("rope"), 
	}
	if _complete_prop_enabled:
		used_info["fill_pot"] = _tracking_prop_used("fill_pot")
		left_info["fill_pot"] = _tracking_prop_left("fill_pot")
	var params: Dictionary = {
		TrackingEvents.K_GAME_STATE: _tracking_game_state, 
		TrackingEvents.K_SES_NUM: SessionManager.get_session_num(), 
		TrackingEvents.K_LEVEL_DEFAULT_INFO: _tracking_level_default_info(), 
		TrackingEvents.K_COST_TIME: _tracking_round_cost_ms(), 
		TrackingEvents.K_USED_HINT_INFO: JSON.stringify(used_info), 
		TrackingEvents.K_LEFT_HINT_INFO: JSON.stringify(left_info), 
	}
	var set_info: String = _tracking_gameplay_set_info()
	if not set_info.is_empty():
		params[TrackingEvents.K_GAMEPLAY_SET_INFO] = set_info
	if not st.is_empty():
		params[TrackingEvents.K_GAME_PROCESS_INFO] = JSON.stringify({
			"finished_orders_num": int(st["done"]), 
			"step_num": _board.move_attempt_count(), 
			"link_num": _board.successful_link_count(), 
		})
	return params







func _tracking_prop_unlocked(key: String) -> bool:

	var round_level: int = _level_model.level_id if _level_model != null\
	else (UserState.get_current_level() if is_endless() else 0)
	return round_level >= PropBtn.get_unlock_level_by_id(key)\
	or UserState.is_prop_early_unlocked(key)




func _tracking_prop_used(key: String) -> int:
	if not _tracking_prop_unlocked(key):
		return 0
	return int(_tracking_prop_used_round.get(key, 0))





func _reset_tracking_round_props() -> void :
	for key: String in _tracking_prop_used_round:
		_tracking_prop_used_round[key] = 0



func _restore_tracking_round_props(d: Dictionary) -> void :
	_reset_tracking_round_props()
	for key: String in _tracking_prop_used_round:
		_tracking_prop_used_round[key] = int(d.get(key, 0))








func _tracking_prop_left(key: String) -> int:
	if not _tracking_prop_unlocked(key):
		return 0
	var left: int = UserState.get_prop_count(key)
	if UserState.is_prop_free_available(key):
		left += 1
	return left


func report_game_exit(exit_type: String) -> void :

	if not is_endless():

		GrtManager.evaluate_level_milestones()
	if _tracking_common == null or _board == null or _board.level() == null:
		return
	if not is_endless() and is_special_challenge()\
	and UserState.get_special_challenge().get("status", "") != "playing":
		return
	var params: Dictionary = _tracking_round_params()
	params[TrackingEvents.K_EXIT_TYPE] = exit_type
	Tracker.send_event(TrackingEvents.EV_GAME_EXIT, params, _tracking_common)


func report_game_over() -> void :
	if is_endless():

		if _tracking_common == null or _board == null or _board.level() == null:
			return
		var endless_params: Dictionary = _tracking_round_params()
		endless_params[TrackingEvents.K_NEW_START_TIMES] = 1
		Tracker.send_event(TrackingEvents.EV_GAME_OVER, endless_params, _tracking_common)
		return
	if _tracking_common == null or _board == null or _board.level() == null:
		return
	var params: Dictionary = _tracking_round_params()
	if is_special_challenge():
		_record_special_challenge_death()
		params[TrackingEvents.K_NEW_START_TIMES] = int(_tracking_special_state["dead_times"])
	else:
		params[TrackingEvents.K_NEW_START_TIMES] = int(LevelManager.get_ztime_stats(
			_round_storage_key()).get("dead_times", 0))
	Tracker.send_event(TrackingEvents.EV_GAME_OVER, params, _tracking_common)


func _record_special_challenge_death() -> void :
	_tracking_special_state["dead_times"] = int(_tracking_special_state.get("dead_times", 0)) + 1
	_persist_special_challenge_tracking()


func report_game_end() -> void :
	if is_endless():

		if _tracking_common == null or _board == null or _board.level() == null:
			return
		var endless_params: Dictionary = _tracking_round_params()
		endless_params.erase(TrackingEvents.K_GAME_PROCESS_INFO)
		Tracker.send_event(TrackingEvents.EV_GAME_END, endless_params, _tracking_common)
		return
	if _tracking_common == null:
		return
	if is_special_challenge():

		var final_params: Dictionary = _tracking_special_state.get("game_end_params", {}) as Dictionary
		if bool(_tracking_special_state.get("game_end_reported", false)) or final_params.is_empty():
			return
		Tracker.send_event(TrackingEvents.EV_GAME_END, final_params, _tracking_common)
		_tracking_special_state["game_end_reported"] = true
		_persist_special_challenge_tracking()
		return
	if _board == null or _board.level() == null:
		return
	var params: Dictionary = _tracking_round_params()
	params.erase(TrackingEvents.K_GAME_PROCESS_INFO)
	Tracker.send_event(TrackingEvents.EV_GAME_END, params, _tracking_common)





















func _tracking_level_default_info() -> String:
	var lv: JuiceLevel = null
	if _level_model != null:
		lv = _level_model.juice
	elif is_endless() and _board != null:

		lv = _board.level()
	if lv == null:
		return ""
	var filled: int = 0
	for col in lv.board_cols:
		filled += (col as Array).size()
	var total_slots: int = lv.initial_total_capacity()
	var fill_rate: int = 0
	if total_slots > 0:
		fill_rate = int(round(float(filled) * 100.0 / float(total_slots)))
	return JSON.stringify({
		"target_orders_num": lv.groups_total, 
		"initial_rope_num": lv.columns, 
		"initial_fill_rate": fill_rate, 
		"rope_tile_num": lv.capacity, 
		"tile_type_num": lv.types, 
		"empty_rope_num": _tracking_empty_rope_cols(lv), 
	})



















func _tracking_gameplay_set_info() -> String:
	if _level_model == null or _level_model.juice == null:
		return ""
	var lv: JuiceLevel = _level_model.juice
	var question_cols: int = 0
	var cage_cols: int = 0
	for i in lv.board_cols.size():
		if _beads_have_hidden(lv.board_cols[i] as Array):
			question_cols += 1
		if not (lv.board_locks[i] as Dictionary).is_empty():
			cage_cols += 1
	for entry: Dictionary in lv.incoming:
		if _beads_have_hidden(entry["beads"] as Array):
			question_cols += 1
		if not (entry.get("lock", {}) as Dictionary).is_empty():
			cage_cols += 1
	var frozen_pots: int = lv.board_frozen_pots.count(true)
	if question_cols == 0 and cage_cols == 0 and frozen_pots == 0:
		return ""
	return JSON.stringify({
		"question_rope_num": question_cols, 
		"cage_rope_num": cage_cols, 
		"frozen_pot_num": frozen_pots, 
	})










func _tracking_empty_rope_cols(lv: JuiceLevel) -> int:
	var empty_cols: int = 0
	for col: Array in lv.board_cols:
		if col.is_empty():
			empty_cols += 1
	for entry: Dictionary in lv.incoming:
		if String(entry["slot"]) == JuiceLevel.SLOT_RETIRE:
			continue
		if (entry["beads"] as Array).is_empty():
			empty_cols += 1
	return empty_cols



func _beads_have_hidden(beads: Array) -> bool:
	for tile: int in beads:
		if JuiceLevel.is_hidden(tile):
			return true
	return false





func should_run_tutorial_now(restore: Dictionary) -> bool:
	return UserState.get_current_level() == JuiceTutorialScript.LEVEL\
	and not UserState.is_tutorial_done()\
	and (restore.is_empty() or restore.has("tutorial_step"))








func start_tutorial_board(color_slots: PackedInt32Array = PackedInt32Array(), restore: Dictionary = {}) -> bool:
	_teardown_tutorial()
	_tutorial_active = true
	_freeze_tutorial_variant(restore)
	_board.set_four_goal_tutorial_visuals(_four_goal_tutorial_round)
	_tutorial_resume_step = int(restore.get("tutorial_step", 0))
	if restore.is_empty():
		if _level_model == null:
			return false
		_prepare_tutorial_model(color_slots)
		LevelManager.clear_game_state(JuiceTutorialScript.LEVEL, "clear_restart_tutorial")
	return await start_round(restore)



func _prepare_tutorial_model(color_slots: PackedInt32Array) -> void :
	_level_model.raw = JuiceTutorialScript.board_for() if _four_goal_tutorial_round else JuiceLegacyTutorialScript.board_for()
	_level_model.juice = JuiceTutorialScript.build_level() if _four_goal_tutorial_round else JuiceLegacyTutorialScript.build_level()
	_level_model.level_unique_id = "guided_first_level" if _four_goal_tutorial_round else "legacy_tutorial"
	_level_model.color_slots = color_slots.duplicate()









func start_tutorial_round(color_slots: PackedInt32Array = PackedInt32Array()) -> void :
	if not await start_tutorial_board(color_slots):
		return
	await play_playfield_entrance()
	show_tutorial()






func show_tutorial() -> void :
	_teardown_root_swap_guide()
	_stop_undo_guide_motion_preview()


	_teardown_tutorial()
	_tutorial_layer = TUTORIAL_LAYER_SCENE.instantiate() if _four_goal_tutorial_round else LEGACY_TUTORIAL_LAYER_SCENE.instantiate()
	_tutorial_quota_intro_hidden = _four_goal_tutorial_round
	_apply_tutorial_visibility()
	_tutorial_layer.z_index = TUTORIAL_LAYER_Z
	add_child(_tutorial_layer)
	_layout_guide_bars()
	_tutorial_dir = JuiceTutorialDirector.new() if _four_goal_tutorial_round else JuiceLegacyTutorialDirector.new()
	if _rules_guide_round and not _four_goal_tutorial_round:
		var legacy: JuiceLegacyTutorialDirector = _tutorial_dir as JuiceLegacyTutorialDirector
		legacy.set_rules_mode(true)
		legacy.active_rule_changed.connect(_quota.set_active_rule)
	_tutorial_dir.name = "TutorialDirector"
	_tutorial_dir.setup(_board, _tutorial_layer)


	_tutorial_dir.set_extra_busy_probe(_has_cup_flights)
	add_child(_tutorial_dir)
	_tutorial_dir.finished.connect(_on_tutorial_finished)
	if _four_goal_tutorial_round:
		_tutorial_dir.start(_tutorial_resume_step)
		_reveal_tutorial_quota_after_intro(_tutorial_layer)
	else:
		_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_TUTORIAL)
		_tutorial_dir.start()

	if _playfield_ready and visible:
		_board.set_entrance_lock(false)



func _reveal_tutorial_quota_after_intro(layer: JuiceTutorialLayer) -> void :
	await get_tree().create_timer(JuiceTutorialDirector.START_TEXT_DELAY).timeout
	await get_tree().process_frame
	if not is_instance_valid(layer) or layer != _tutorial_layer or not visible:
		return
	_tutorial_quota_intro_hidden = false
	_apply_tutorial_visibility()




func _layout_guide_bars() -> void :
	var vp: Vector2 = UiMetrics.viewport_size()
	if _tutorial_layer != null and is_instance_valid(_tutorial_layer):
		var card_bottom: float = BOARD_TOP - TUTORIAL_BAR_BOTTOM_GAP
		if _four_goal_tutorial_round:
			var quota_bottom: float = _quota_bottom_at_rest()
			var quota_top: float = quota_bottom - _quota.desired_height()
			card_bottom = maxf(card_bottom - 96.0, quota_bottom + TUTORIAL_QUOTA_COVER_PAD)
			_tutorial_layer.text_card_min_height = maxf(240.0, 
				card_bottom - quota_top + TUTORIAL_QUOTA_COVER_PAD)
		_tutorial_layer.layout_text_bar_bottom(vp.x * 0.5, 
			card_bottom, UiMetrics.safe_insets().x)
	if _mystery_layer != null and is_instance_valid(_mystery_layer):
		_mystery_layer.layout_text_bar_bottom(vp.x * 0.5, 
			BOARD_TOP - TUTORIAL_BAR_BOTTOM_GAP, UiMetrics.safe_insets().x)
	if _root_swap_layer != null and is_instance_valid(_root_swap_layer):
		_root_swap_layer.layout_text_bar_bottom(vp.x * 0.5, 
			BOARD_TOP - TUTORIAL_BAR_BOTTOM_GAP, UiMetrics.safe_insets().x)


func _on_tutorial_finished() -> void :
	if _is_legacy_tutorial():
		UserState.set_tutorial_done(true)
		_teardown_tutorial()
		return
	if _tutorial_active and _four_goal_tutorial_round and R.is_win(_board.state(), _board.level()):
		UserState.set_tutorial_done(true)


func _is_legacy_tutorial() -> bool:
	return _tutorial_active and not _four_goal_tutorial_round



func _freeze_tutorial_variant(restore: Dictionary) -> void :
	if restore.has("tutorial_variant") or restore.has("tutorial_step"):
		_four_goal_tutorial_round = String(restore.get("tutorial_variant", "4guide")) == "4guide"
	else:
		ABManager.dye_at_new_guide()
		_four_goal_tutorial_round = ABManager.new_guide.is_four_goal_tutorial_enabled()
		_freeze_rules_guide_group()


func _freeze_rules_guide_group() -> void :
	_rules_guide_round = ABManager.new_guide.is_rules_group()
	_quota.set_rules_layout_enabled(_rules_guide_round)


func _cancel_tutorial_transition() -> void :
	_tutorial_resume_step = 0


func _prepare_first_level_model(restore: Dictionary) -> void :
	if not _four_goal_tutorial_round:
		return
	if _tutorial_active or not restore.is_empty() or not _is_first_level_presentation():
		return
	_level_model.raw = JuiceTutorialScript.BOARD.duplicate(true)
	_level_model.juice = JuiceTutorialScript.build_level()
	_level_model.color_slots = PackedInt32Array([0, 6, 4, 1])
	_level_model.level_unique_id = "guided_first_level"


func _is_first_level_presentation() -> bool:
	return _level_model != null and _level_model.level_id == 1 and not is_endless() and not is_special_challenge()


func _apply_tutorial_visibility() -> void :
	_quota.visible = not _ui_entrance_preparing and not _tutorial_quota_intro_hidden
	_header.visible = true
	var show_props: bool = not _ui_entrance_preparing\
	and not (_four_goal_tutorial_round and _is_first_level_presentation())
	_reset_btn.visible = show_props and not is_endless() and not _reset_moved_to_header
	_header_reset_btn.visible = show_props and not is_endless() and _reset_moved_to_header
	for key: String in _prop_ui:
		((_prop_ui[key] as Dictionary)["btn"] as Control).visible = show_props\
		and (key != "fill_pot" or _complete_prop_enabled)





func _teardown_tutorial() -> void :
	if _tutorial_quota_intro_hidden:
		_tutorial_quota_intro_hidden = false
		_apply_tutorial_visibility()
	if _tutorial_dir != null and is_instance_valid(_tutorial_dir):
		_tutorial_dir.stop()
		_tutorial_dir.queue_free()
	_tutorial_dir = null
	if _tutorial_layer != null and is_instance_valid(_tutorial_layer):
		_tutorial_layer.queue_free()
	_tutorial_layer = null
	_quota.set_active_rule(-1)
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_TUTORIAL)













func should_run_mystery_guide_now(restore: Dictionary) -> bool:
	return restore.is_empty()\
	and not UserState.is_mystery_guide_shown()\
	and not _tutorial_active\
	and not JuiceMysteryGuide.find_reveal_move(
		_board.state(), _board.order()).is_empty()




func maybe_show_mystery_guide(restore: Dictionary = {}) -> void :
	if _mystery_guide != null and is_instance_valid(_mystery_guide):
		return
	if not should_run_mystery_guide_now(restore):
		return
	_teardown_root_swap_guide()
	_stop_undo_guide_motion_preview()
	_mystery_layer = TUTORIAL_LAYER_SCENE.instantiate() as JuiceTutorialLayer
	_mystery_layer.z_index = TUTORIAL_LAYER_Z
	add_child(_mystery_layer)
	_layout_guide_bars()
	_mystery_guide = JuiceMysteryGuide.new()
	_mystery_guide.name = "MysteryGuide"
	_mystery_guide.setup(_board, _mystery_layer)
	add_child(_mystery_guide)
	_mystery_guide.finished.connect(_on_mystery_guide_finished)

	if not _mystery_guide.start():
		_teardown_mystery_guide()
		return
	_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_MYSTERY)


func _on_mystery_guide_finished() -> void :

	UserState.set_mystery_guide_shown(true)
	_teardown_mystery_guide()







func _teardown_mystery_guide() -> void :
	if _mystery_guide != null and is_instance_valid(_mystery_guide):
		_mystery_guide.stop()
		_mystery_guide.queue_free()
	_mystery_guide = null
	if _mystery_layer != null and is_instance_valid(_mystery_layer):
		_mystery_layer.queue_free()
	_mystery_layer = null
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_MYSTERY)




func _queue_root_swap_guide() -> void :
	if is_instance_valid(_root_swap_guide) or not _root_swap_guide_pending.is_empty():
		return
	if _board.tutorial_demo_only or _tutorial_active or _board.can_play_after_dead()\
	or not bool(_board.state().get("allow_root_swapping", false))\
	or UserState.is_root_swap_guide_shown():
		return
	var info: Dictionary = _board.move_feedback_info()
	if not bool(info.get("player_drop", false)) or bool(info.get("root_swapped", false)):
		return
	var mv: Dictionary = JuiceRootSwapGuide.find_swap(_board.state(), _board.order(), 
		int(info.get("completed_col", -1)))
	if mv.is_empty():
		return
	_root_swap_guide_pending = _root_swap_guide_request(mv)
	if not UserState.set_root_swap_guide_pending(_root_swap_guide_pending):
		SortLogger.error("整列互换引导待办保存失败，当前局继续强制引导")
	_hint_cancel()
	_stop_hint_guide(true)
	_stop_undo_guide_motion_preview()
	_poll_root_swap_guide()



func _root_swap_guide_request(mv: Dictionary) -> Dictionary:

	var normalized_state: Dictionary = JSON.parse_string(JSON.stringify(_board.state())) as Dictionary
	return {"storage_key": _round_storage_key(), "game_id": _root_swap_guide_game_id(), 
		"endless": is_endless(), "move": mv.duplicate(true), 
		"board_key": JSON.stringify([_board.level().id, _board.steps(), _board.order(), 
			S._full_state_key(normalized_state)])}


func _root_swap_guide_game_id() -> String:
	if is_endless():
		return _root_swap_guide_endless_id
	return _tracking_common.game_id if _tracking_common != null else _round_game_id()


func _root_swap_guide_request_matches(request: Dictionary) -> bool:
	if not is_instance_valid(_board) or _board.level() == null or _board.over() != ""\
	or _win_committed or _tutorial_active or _board.tutorial_demo_only\
	or not bool(_board.state().get("allow_root_swapping", false))\
	or UserState.is_root_swap_guide_shown():
		return false
	if not request.get("move", {}) is Dictionary:
		return false
	var mv: Dictionary = request.get("move", {}) as Dictionary
	if mv.is_empty() or int(mv.get("j", -1)) != 0:
		return false
	var current: Dictionary = _root_swap_guide_request(mv)
	if request != current:
		return false
	return JuiceRootSwapGuide.find_swap(_board.state(), _board.order(), int(mv.get("src", -1))) == mv


func _restore_root_swap_guide_pending() -> void :
	if not _playfield_ready or not is_visible_in_tree() or _hint_guide_background_paused\
	or _external_play_suspended or not _root_swap_guide_pending.is_empty():
		return
	var request: Dictionary = UserState.get_root_swap_guide_pending()
	if request.is_empty():
		return
	if not _root_swap_guide_request_matches(request):
		_teardown_root_swap_guide(true)
		return
	_root_swap_guide_pending = request
	_hint_cancel()
	_stop_hint_guide(true)
	_stop_undo_guide_motion_preview()


func _poll_root_swap_guide() -> void :
	if is_instance_valid(_root_swap_guide):
		if _win_committed or _board.over() != "" or UserState.is_root_swap_guide_shown()\
		or not bool(_board.state().get("allow_root_swapping", false)):
			_teardown_root_swap_guide(true)
		return
	_restore_root_swap_guide_pending()
	if _root_swap_guide_pending.is_empty():
		return
	if not _root_swap_guide_request_matches(_root_swap_guide_pending):
		_teardown_root_swap_guide(true)
		return

	if _board.has_move_gate() or _board.has_grab_gate() or _board.has_active_drag():
		return
	var mv: Dictionary = _root_swap_guide_pending["move"]
	_root_swap_layer = TUTORIAL_LAYER_SCENE.instantiate() as JuiceTutorialLayer
	_root_swap_layer.z_index = TUTORIAL_LAYER_Z
	add_child(_root_swap_layer)
	_layout_guide_bars()
	_root_swap_guide = JuiceRootSwapGuide.new()
	_root_swap_guide.name = "RootSwapGuide"
	_root_swap_guide.setup(_board, _root_swap_layer, _root_swap_guide_can_play)
	add_child(_root_swap_guide)
	_root_swap_guide.finished.connect(_on_root_swap_guide_finished.bind(_root_swap_guide))
	_root_swap_guide.completed.connect(_on_root_swap_guide_completed.bind(_root_swap_guide))
	if not _root_swap_guide.start(mv):
		_teardown_root_swap_guide()
		return
	_pause_root_swap_guide_timer(true)
	_refresh_prop_btns()


func _on_root_swap_guide_completed(guide: Variant) -> void :
	if not is_instance_valid(guide) or guide != _root_swap_guide:
		return

	UserState.mark_root_swap_guide_shown()
	_teardown_root_swap_guide()
	_refresh_prop_btns()


func _on_root_swap_guide_finished(guide: Variant) -> void :
	if not is_instance_valid(guide) or guide != _root_swap_guide:
		return

	_teardown_root_swap_guide(true)
	_refresh_prop_btns()


func _on_root_swap_guide_player_operated() -> void :
	if not _root_swap_guide_blocks_input():
		_teardown_root_swap_guide()


func _root_swap_guide_blocks_input() -> bool:
	if not is_instance_valid(_board) or not bool(_board.state().get("allow_root_swapping", false)):
		return false
	return is_instance_valid(_root_swap_guide) or not _root_swap_guide_pending.is_empty()


func _pause_root_swap_guide_timer(paused: bool) -> void :
	if _root_swap_guide_timer_paused == paused:
		return
	_root_swap_guide_timer_paused = paused
	if paused:
		_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_ROOT_SWAP)
		pause_endless(LevelPlayTimer.PAUSE_GUIDE_ROOT_SWAP, true)
	else:
		_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_ROOT_SWAP)
		resume_endless(LevelPlayTimer.PAUSE_GUIDE_ROOT_SWAP)


func _root_swap_guide_can_play() -> bool:
	if not is_visible_in_tree() or not _playfield_ready or not _ui_props_ready\
	or _hint_guide_background_paused or _external_play_suspended\
	or _opening_banner_input_locked or _sunlight_guide_running or _tutorial_active\
	or _end_flow_running or _complete_shown or _win_committed or _prop_ad_in_flight\
	or _restart_interstitial_busy or _home_navigation_running:
		return false
	if not is_instance_valid(_board) or _board.over() != "" or _board.is_busy()\
	or _has_cup_flights() or _board.has_active_hint() or _hint_task_id != HINT_TASK_NONE:
		return false
	if (_board.has_move_gate() or _board.has_grab_gate())\
	and ( not is_instance_valid(_root_swap_guide) or not _root_swap_guide.owns_input_gates()):
		return false
	if is_instance_valid(_mystery_guide) or (is_instance_valid(_lock_guide) and _lock_guide.is_open())\
	or (is_instance_valid(_unlock_overlay) and _unlock_overlay.visible):
		return false
	for route: String in ["setting", "prop_unlock", "confirm", "reset_confirm", "privacy", "finish"]:
		var dialog: Node = SceneManager.get_page(route)
		if is_instance_valid(dialog) and dialog.visible:
			return false
	return true



func _teardown_root_swap_guide(clear_pending: bool = false) -> void :
	if clear_pending:
		UserState.discard_root_swap_guide_pending()
	elif not _root_swap_guide_pending.is_empty() and not UserState.is_root_swap_guide_shown():
		if not UserState.set_root_swap_guide_pending(_root_swap_guide_pending):
			SortLogger.error("整列互换引导待办保存失败")
	_root_swap_guide_pending.clear()
	if is_instance_valid(_root_swap_guide):
		_root_swap_guide.stop()
		_root_swap_guide.queue_free()
	_root_swap_guide = null
	if is_instance_valid(_root_swap_layer):
		_root_swap_layer.queue_free()
	_root_swap_layer = null
	_pause_root_swap_guide_timer(false)







func _first_locked_col() -> int:
	if _board == null:
		return -1
	var st: Dictionary = _board.state()
	if st.is_empty():
		return -1
	for ci: int in _board.order():
		if R.is_locked(st, ci):
			return ci
	return -1












func should_run_lock_guide_now(restore: Dictionary) -> bool:
	return restore.is_empty()\
	and not UserState.is_lock_guide_shown()\
	and not _tutorial_active\
	and _first_locked_col() >= 0








func maybe_show_lock_guide(restore: Dictionary = {}) -> void :
	if _lock_guide != null and _lock_guide.is_open():
		return
	if not should_run_lock_guide_now(restore):
		return
	var ci: int = _first_locked_col()

	var art_rect: Rect2 = _board.locked_column_global_rect(ci)


	if art_rect.size.x <= 0.0 or art_rect.size.y <= 0.0:
		return
	var st: Dictionary = _board.state()
	var locks: Array = st.get("locks", []) as Array
	if ci >= locks.size():
		return
	var lock: Dictionary = locks[ci] as Dictionary
	var condition: String = String(lock.get("condition", ""))

	var remaining: int = int(lock.get("count", 0)) - int(st.get("done", 0))

	var flower_tex: Texture2D = null
	if condition == JuiceLevel.LOCK_COLLECT_TYPE:
		flower_tex = _board.lock_icon(int(lock.get("typeId", -1)))
	_teardown_root_swap_guide()
	_stop_undo_guide_motion_preview()
	if _lock_guide == null:
		_lock_guide = LOCK_GUIDE_SCENE.instantiate() as JuiceLockGuideOverlay
		_lock_guide.name = "LockGuide"
		_lock_guide.z_index = LOCK_GUIDE_Z
		add_child(_lock_guide)



	move_child(_lock_guide, -1)
	_board.set_input_enabled(false)
	_lock_guide_forced_close = false
	_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_LOCK)
	_lock_guide.open(art_rect, condition, remaining, flower_tex, 
		_board.resolved_lock_visual_version(), _board.locked_column_width_ratio(ci), _board.lock_visual(int(lock.get("typeId", -1))), _skin_resources)
	await _lock_guide.closed
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_LOCK)
	_board.set_input_enabled(true)
	if not _lock_guide_forced_close:

		UserState.set_lock_guide_shown(true)











func _close_lock_guide_now() -> void :
	if _lock_guide == null or not _lock_guide.is_open():
		return
	_lock_guide_forced_close = true
	_lock_guide.close(true)



func should_run_sunlight_guide_now(restore: Dictionary) -> bool:
	return restore.is_empty() and not _tutorial_active and not is_special_challenge()\
	and not UserState.is_sunlight_guide_shown()\
	and _level_model != null and _level_model.raw.has("sunlightPotSource")\
	and ABManager.sunlight_gameplay.is_sunlight_gameplay_enabled()\
	and _board != null and not _board.sunlight_guide_visuals().is_empty()


func maybe_show_sunlight_guide(restore: Dictionary = {}) -> bool:
	if _sunlight_guide_running:
		return false
	if not should_run_sunlight_guide_now(restore):
		return true
	var visuals: Array[Dictionary] = _board.sunlight_guide_visuals()
	var generation: int = _entrance_generation
	_sunlight_guide_input_was_enabled = bool(_board.get("_input_enabled"))
	_teardown_root_swap_guide()
	_stop_undo_guide_motion_preview()
	_clear_hint_guide_motion(true)
	if _sunlight_guide == null:
		_sunlight_guide = SUNLIGHT_GUIDE_SCENE.instantiate() as JuiceSunlightGuideOverlay
		_sunlight_guide.name = "SunlightGuide"
		_sunlight_guide.z_index = LOCK_GUIDE_Z
		add_child(_sunlight_guide)
	move_child(_sunlight_guide, -1)
	_sunlight_guide_running = true
	_board.set_input_enabled(false)
	_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_SUNLIGHT)
	_sunlight_guide.open(visuals)
	var acknowledged: bool = await _sunlight_guide.closed

	if generation != _entrance_generation:
		return false
	_sunlight_guide_running = false
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_SUNLIGHT)
	if is_visible_in_tree() and _board.over() == "":
		_board.set_input_enabled(_sunlight_guide_input_was_enabled)
	if acknowledged:
		UserState.set_sunlight_guide_shown(true)
	return acknowledged and is_visible_in_tree() and _board.over() == ""


func _close_sunlight_guide_now() -> void :

	if _sunlight_guide_running and _board != null:
		_board.set_input_enabled(_sunlight_guide_input_was_enabled)
	_sunlight_guide_running = false
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_SUNLIGHT)
	if is_instance_valid(_sunlight_guide):
		_sunlight_guide.close(true)




func is_dead_resume(model: LevelModel, blob: Dictionary) -> bool:
	var juice_model: JuiceLevelModel = model as JuiceLevelModel
	if juice_model == null or juice_model.juice == null or blob.is_empty():
		return false
	var st: Dictionary = R.state_from_dict(blob.get("state", {}), juice_model.juice)
	var enabled: bool = _root_swapping_enabled_for_level(juice_model.level_id)
	var rules_changed: bool = bool(st.get("allow_root_swapping", false)) != enabled
	if not rules_changed and (bool(blob.get("dead", false)) or bool(blob.get("hint_dead", false))):
		return true
	if not st.is_empty():
		st["allow_root_swapping"] = enabled
	return not st.is_empty() and not (st["cols"] as Array).is_empty()\
	and not R.is_win(st, juice_model.juice) and not R.has_any_move(st)



func prepare_dead_resume_restart() -> void :
	if _level_model == null or should_run_tutorial_now({}):
		return
	_level_model.color_slots.clear()


func prepare_coin_bonus_level(restore: Dictionary) -> bool:
	if _level_model == null or is_special_challenge() or is_endless():
		return true
	var assignment: Dictionary = CoinBonusLevelEntry.enter(_level_model, not restore.is_empty())
	if assignment.is_empty():
		SortLogger.error("[CoinBonusLevel] 本局身份保存失败，保留原关卡")
		return false
	_level_model.coin_bonus_rule = assignment
	return true


func is_coin_bonus_round() -> bool:
	return _level_model != null and not is_special_challenge()\
	and bool(_level_model.coin_bonus_rule.get("double_coins", false))


func prepare_sunlight_pot_round(restore: Dictionary) -> void :
	_prepared_sunlight_bonus = null
	if not restore.is_empty() or _level_model == null or _level_model.juice == null:
		return
	var bonus_enabled: bool = _decide_bonus_enabled()
	_prepared_sunlight_bonus = bonus_enabled
	var original: JuiceLevel = _level_model.juice
	var plan: Dictionary = {}
	if bonus_enabled:
		plan = JuiceBonusLevel.pick_plan(original, 
			JuiceTheme.resolve_slots(original.id, original.types, _level_model.color_slots), _bonus_v2)
	_board._bonus_plan_pending = plan
	if JuiceBonusLevel.is_valid_bonus_type(original, int(plan.get("type", -1))):
		return
	if _tutorial_active or is_special_challenge() or _level_model.raw.has("sunlightPotSource")\
	or not JuiceSunlightPotVariant.scheduled(_level_model.level_id):
		return
	if not OS.has_feature("rel") and JuiceLevelParser.debug_row_level() == _level_model.level_id:
		return
	var enabled: bool = ABManager.sunlight_gameplay.is_sunlight_gameplay_enabled()
	ABManager.dye_at_sunlight_gameplay()
	if not enabled:
		return
	if _level_model.used_fallback:
		SortLogger.mark("Sunlight pot skipped: fallback level=%d" % _level_model.level_id)
		return
	var recipe: Dictionary = LevelManager.read_sunlight_pot_recipe(_level_model.level_id, 
		_level_model.level_unique_id, _level_model.level_user_tags)
	var converted: Dictionary = JuiceSunlightPotVariant.apply_recipe(_level_model.raw, recipe)
	if converted.is_empty():
		SortLogger.mark("Sunlight pot skipped level=%d reason=%s" % [_level_model.level_id, 
			recipe.get("reason", "missing_or_content_mismatch")])
		return
	_level_model.raw = converted
	_level_model.juice = JuiceLevel.from_dict(converted)
	_level_model.level_unique_id = String(recipe["converted_hash"])
	_prepared_sunlight_bonus = false
	_board._bonus_plan_pending = {}
	SortLogger.mark("Sunlight pot applied level=%d target=%d" % [_level_model.level_id, recipe["target"]])



func _configure_level_target_coins(restore: Dictionary) -> void :
	_round_target_coins = COIN_PER_TARGET
	if _level_model == null or _level_model.juice == null or is_special_challenge():
		return
	if not restore.is_empty():
		var saved: int = int(restore.get("level_target_coins", COIN_PER_TARGET))
		if saved in [LevelTargetCoinsConfig.ORIGINAL_COINS, LevelTargetCoinsConfig.REDUCED_COINS]:
			_round_target_coins = saved
		return
	_round_target_coins = ABManager.level_target_coins.coins_per_target()


func start_round(restore: Dictionary) -> bool:
	_teardown_root_swap_guide()
	_rank_collectible_type = -1
	_rank_gift_slot = -1
	_board.set_rank_collectible(-1, -1, false)
	_freeze_tutorial_variant(restore)
	_board.set_four_goal_tutorial_visuals(_four_goal_tutorial_round and _is_first_level_presentation())
	_prepare_first_level_model(restore)
	_empty_col_feedback.reset_round()
	_stop_undo_guide_motion_preview()
	if _level_model == null or _level_model.juice == null:
		return false
	_restore_rank_collectible_rule(restore)
	if _level_model.coin_bonus_rule.is_empty() and not prepare_coin_bonus_level(restore):
		return false
	_configure_level_target_coins(restore)
	_special_challenge_banner_pending = is_special_challenge() and restore.is_empty()\
	and (_start_flow_context == null or not _start_flow_context.skip_opening_banner)
	_board.set_entrance_lock(true)
	_entrance_generation += 1
	_playfield_ready = false
	var lv: JuiceLevel = _level_model.juice
	_hint_cancel()
	_cancel_win_coin_reward()
	_win_committed = false
	_win_completion_payload = {}
	_win_completion_iq = {}
	_win_coin_reported = false
	_won_level_num = 0
	_daily_checkin_round.reset()
	SceneManager.hide_dlg("daily_first_win_checkin")
	_win_coin_before = 0
	_win_coin_reward = 0
	_reset_end_flow_state()
	_reset_challenge_feedback()


	_reset_tracking_round_props()










	_flush_play_time("time_start")
	var arm_level: int = _round_storage_key()
	var is_resume: bool = not restore.is_empty()
	_play_timer.arm(arm_level, 
		LevelManager.get_round_play_time_ms(arm_level) if is_resume else 0, 
		not is_resume)

	var resumed: = false
	_configure_root_swapping()
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	_bonus_coin_reward = 0
	_bonus_coin_pending = 0
	if not restore.is_empty():

		_bonus_v2 = BonusLevelEntry.is_v2_enabled()
		resumed = _board.restore(lv, restore, _level_model.color_slots)
		if not resumed:
			push_warning("JuiceGamePage: 续局数据不合法,丢弃并全新起局")
	if not resumed:
		if _prepared_sunlight_bonus == null:
			prepare_sunlight_pot_round({})
			lv = _level_model.juice
		var mystery_auto_unlock_test: bool = not OS.has_feature("rel") and _start_flow_context != null\
		and bool(_start_flow_context.params.get("cheat_mystery_auto_unlock_test", false))
		var bonus_enabled: bool = bool(_prepared_sunlight_bonus) and not mystery_auto_unlock_test
		_prepared_sunlight_bonus = null

		if bonus_enabled and not _components.is_ready("bonus")\
		and JuiceBonusLevel.has_bonus_candidate(lv, _bonus_v2):
			var generation: int = _entrance_generation
			if not await _ensure_component_groups(["bonus"], _is_start_round_current.bind(generation)):
				return false
		_board.set_bonus_candidate(bonus_enabled, _bonus_v2)
		if not OS.has_feature("rel") and _start_flow_context != null and bool(_start_flow_context.params.get("cheat_bonus_start_test", false)):
			_board._bonus_plan_pending = {"type": 0, "recolor_from": -1, "recolor_to": -1}
		_board.setup(lv, {}, _level_model.color_slots)

	_bonus_type = _board.bonus_type()

	if not resumed:
		_maybe_show_bonus_skip_toast()
	if resumed:
		_restore_challenge_feedback(restore.get("challenge", {}) as Dictionary)
		_empty_col_feedback.reset_round(int(restore.get("empty_rope_feedback_count", 0)), 
			restore.get("empty_rope_feedback_operations", []) as Array)

		_restore_tracking_round_props(restore.get("used_hint_info", {}) as Dictionary)
	LevelManager.configure_special_challenge_schedule(_level_model, is_resume)

	_board.set_flowers_alpha(1.0)
	_quota.setup(lv.groups_total)
	_configure_iq_round(restore.get("iq", {}) as Dictionary if resumed else {}, resumed)
	_rank_round.begin(restore, _rank_collect_count(lv), _rank_bar, _rank_fly, _round_game_id() if resumed else "")
	_configure_rank_collectible(resumed)
	_layout()
	_on_cups_changed()
	_sync_level_card()

	GrtManager.set_round_level(_level_model.level_id)
	var unlocked_props: Array[String] = []
	var current_level: int = UserState.get_current_level()
	var prop_keys: Array[String] = ["hint", "undo", "rope"]
	if _complete_prop_enabled:
		prop_keys.append("fill_pot")
	for key: String in prop_keys:
		var ui: Dictionary = _prop_ui.get(key, {}) as Dictionary
		var btn: PropBtn = ui.get("btn") as PropBtn
		if btn != null and (current_level >= btn.get_unlock_level() or UserState.is_prop_early_unlocked(key)):
			unlocked_props.append(key)
	var newly_granted: Array[String] = UserState.grant_prop_free_uses(unlocked_props)
	_pending_free_prop_get.clear()
	for key: String in unlocked_props:

		if not UserState.is_prop_free_get_reported(key)\
		and (newly_granted.has(key) or not UserState.is_prop_unlock_shown(key)):
			_pending_free_prop_get.append(key)

	if unlocked_props.has("undo") and not UserState.is_prop_unlock_shown("undo"):
		UserState.mark_prop_unlock_shown("undo")

	_refresh_prop_btns(true)



	if not _commit_special_theme_assignment():
		return false
	if not resumed:
		_save_initial_snapshot("start")
		request_round_deferred_preparation()
	return true


func _is_start_round_current(generation: int) -> bool:
	return visible and generation == _entrance_generation\
	and (_start_flow_context == null or not _start_flow_context.aborted)



func restart_level() -> void :
	_teardown_root_swap_guide(true)
	if is_endless():
		start_endless(_endless_requested_seed, _endless_skip_entrance)
		return
	_deferred_prepare_request = null
	_components.cancel()
	_components.set_work_permission(Callable())
	_cancel_bonus_collection()
	if is_special_challenge() and UserState.get_special_challenge().get("status", "") != "playing":
		return
	_empty_col_feedback.reset_round()
	_stop_undo_guide_motion_preview()
	if _special_challenge_banner != null:
		_special_challenge_banner.cancel()
	_cancel_opening_banner_input_lock()
	if _level_model == null or _level_model.juice == null:
		return
	_board.set_rank_collectible(-1, -1, false)
	_special_challenge_banner_pending = is_special_challenge()
	if _special_challenge_banner_pending:
		_special_challenge_chest.hide()
	var previous_slots: PackedInt32Array = JuiceTheme.resolve_slots(
		_level_model.juice.id, _level_model.juice.types, _level_model.color_slots)
	_board.set_entrance_lock(true)
	_entrance_generation += 1
	_playfield_ready = false
	_hide_dead_toast()
	_hint_cancel()
	_reset_challenge_feedback()


	_reset_tracking_round_props()

	_teardown_mystery_guide()

	_close_lock_guide_now()
	_close_sunlight_guide_now()


	UserState.reset_win_streak()


	if not is_special_challenge():
		UserState.mark_current_level_dirty()

	_flush_play_time("time_restart")
	_play_timer.arm(_round_storage_key())



	if _tutorial_active:
		_teardown_tutorial()
		hide_complete_panel_now()

		await start_tutorial_round(previous_slots)


		_tracking_common.game_id = LevelManager.new_transient_game_id() if _is_legacy_tutorial() else _round_game_id()
		_tracking_game_state = TrackingEvents.GAME_STATE_RESTART
		report_game_start()
		return

	LevelManager.clear_game_state(UserState.get_current_level(), "clear_restart", 
		_tracking_common.game_id if _tracking_common != null else "")


	var restart_model: LevelModel = resolve_restart_model(UserState.get_current_level(), _level_model)
	if restart_model != _level_model:
		if restart_model is JuiceLevelModel:
			(restart_model as JuiceLevelModel).coin_bonus_rule = _level_model.coin_bonus_rule.duplicate(true)
		apply_level_model(restart_model)
	_configure_level_target_coins({})
	_cancel_win_coin_reward()
	_win_committed = false
	_win_completion_payload = {}
	_win_completion_iq = {}
	_win_coin_reported = false
	_daily_checkin_round.reset()
	SceneManager.hide_dlg("daily_first_win_checkin")
	_win_coin_before = 0
	_win_coin_reward = 0
	_reset_end_flow_state()
	hide_complete_panel_now()
	_board.set_flowers_alpha(1.0)

	_level_model.color_slots.clear()
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	_bonus_coin_reward = 0
	_bonus_coin_pending = 0
	_hide_bonus_gain()
	prepare_sunlight_pot_round({})
	var bonus_enabled: bool = bool(_prepared_sunlight_bonus)
	_prepared_sunlight_bonus = null
	if bonus_enabled and JuiceBonusLevel.has_bonus_candidate(_level_model.juice, _bonus_v2):
		var generation: int = _entrance_generation
		if not await _ensure_component_groups(["bonus"], func() -> bool:
			return visible and generation == _entrance_generation):
			return
	_board.set_bonus_candidate(bonus_enabled, _bonus_v2)
	ABManager.allow_root_swapping.load_value_silent()
	_configure_root_swapping()
	_board.setup(_level_model.juice, {}, _level_model.color_slots)
	_bonus_type = _board.bonus_type()

	_quota.setup(_level_model.juice.groups_total)
	_configure_rank_collectible(false)
	_configure_iq_round()
	request_round_deferred_preparation()
	_sync_level_card()
	_on_cups_changed()


	GrtManager.set_round_level(_level_model.level_id)

	_refresh_prop_btns(true)
	_save_initial_snapshot("restart")


	setup_tracking_context(_level_model, {})
	_tracking_game_state = TrackingEvents.GAME_STATE_RESTART
	report_game_start()
	GameRestartFlow.run(self)












func fade_win_flowers() -> void :
	_long_link_feedback.hide_now()
	_combo_feedback.hide_now()
	_empty_col_feedback.hide_now()
	if _flowers_faded:
		return
	_flowers_faded = true
	_board.set_input_enabled(false)
	_board.fade_flowers_out(FLOWER_FADE_OUT_DUR)






func play_bonus_pig_smash() -> void :
	if _bonus_coin_reward <= 0:
		return

	if not _win_committed:
		await get_tree().process_frame
	if not _win_committed or not visible:
		return
	var generation: int = _end_flow_generation

	while visible and generation == _end_flow_generation and (_bonus_pot_collecting or (_bonus_pig_hud != null and _bonus_pig_hud.is_flying())):
		await get_tree().process_frame
	if not visible or generation != _end_flow_generation:
		return
	if not _bonus_pig_hud.is_docked():

		_bonus_coin_pending = 0
		_refresh_coin_hud()
		return
	var before: int = _bonus_coin_before
	var after: int = before + _bonus_coin_reward
	var center: Vector2 = UiMetrics.viewport_size() * 0.5

	_set_coin_hud_display(before, after)

	for conn: Dictionary in _bonus_pig_smash.smashed.get_connections():
		_bonus_pig_smash.smashed.disconnect(conn["callable"])
	_bonus_pig_smash.smashed.connect(_on_bonus_pig_smashed.bind(before, after), CONNECT_ONE_SHOT)
	var from_rect: Rect2 = _bonus_pig_hud.dock_global_rect()
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	await _bonus_pig_smash.play(from_rect, center, true)

	while visible and generation == _end_flow_generation\
	and _win_coin_tween != null and _win_coin_tween.is_valid() and _win_coin_tween.is_running():
		await get_tree().process_frame
	if not visible or generation != _end_flow_generation:
		return
	_bonus_coin_pending = 0
	_refresh_coin_hud()



	while visible and generation == _end_flow_generation\
	and _bonus_gain_tween != null and _bonus_gain_tween.is_valid() and _bonus_gain_tween.is_running():
		await get_tree().process_frame
	_bonus_coin_hud.z_index = _bonus_coin_hud_base_z











func _show_bonus_gain(amount: int) -> void :
	if amount <= 0 or not is_instance_valid(_bonus_gain_label):
		return
	_hide_bonus_gain()
	_bonus_gain_label.text = "+%d" % amount
	_bonus_gain_label.visible = true
	_bonus_gain_label.modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	_bonus_gain_tween = tw
	tw.tween_property(_bonus_gain_label, "modulate:a", 1.0, BONUS_GAIN_FADE_IN_DUR)
	tw.tween_interval(BONUS_GAIN_HOLD_DUR)


	if _rank_round.will_present_collect():
		tw.tween_callback(_release_bonus_smash_dim)
	tw.tween_property(_bonus_gain_label, "modulate:a", 0.0, BONUS_GAIN_FADE_OUT_DUR)
	tw.tween_callback(_hide_bonus_gain)



func _release_bonus_smash_dim() -> void :
	if _bonus_pig_smash != null:
		_bonus_pig_smash.fade_out_held_background(BONUS_GAIN_FADE_OUT_DUR)



func _hide_bonus_gain() -> void :
	if _bonus_gain_tween != null and _bonus_gain_tween.is_valid():
		_bonus_gain_tween.kill()
	_bonus_gain_tween = null
	if is_instance_valid(_bonus_gain_label):
		_bonus_gain_label.visible = false
		_bonus_gain_label.modulate = Color.WHITE





func _on_bonus_pig_smashed(burst_center: Vector2, before: int, after: int) -> void :
	_bonus_coin_hud.z_index = _bonus_pig_smash.z_index + 1
	var target: Rect2 = _bonus_coin_target_rect()
	var count: int = 8
	var tw: Tween = create_tween().set_parallel(true)
	_win_coin_tween = tw

	HapticManager.cancel_event(_win_coin_haptic)
	_win_coin_haptic = play_finish_coin_haptic()
	var delays: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.55, 0.65, 0.75, 0.85]
	var arrivals: Array[int] = [0]
	var last_sound_ms: Array[int] = [-1000]
	var on_landed: Callable = func() -> void :
		arrivals[0] += 1
		_coin_hud_label.text = str(before + roundi(float(after - before) * arrivals[0] / count))
		var now: int = Time.get_ticks_msec()
		if now - last_sound_ms[0] >= 140 or arrivals[0] == count:
			_play_skin_sound(&"coin_fly")
			last_sound_ms[0] = now

	var last_arrival: float = 0.0
	for i: int in range(count):
		last_arrival = maxf(last_arrival, _append_coin_flight(
			tw, burst_center, target.get_center(), i, count, _win_coin_sprites, _win_coin_trails, 
			on_landed, null, 135.0 + float(i % 3) * 15.0, target, delays[i]))
	var last: float = delays[-1] + WIN_COIN_POP_DUR + WIN_COIN_FLY_DUR * 1.3
	tw.tween_interval(last + WIN_COIN_TRAIL_LIFETIME * 1.2)


	if _bonus_v2:
		var gain_lead: float = BONUS_GAIN_FADE_IN_DUR + BONUS_GAIN_HOLD_DUR
		var gain_delay: float = maxf(0.0, last_arrival - gain_lead)
		if gain_delay > 0.0:
			tw.tween_callback( func() -> void : _show_bonus_gain(after - before)).set_delay(gain_delay)
		else:
			_show_bonus_gain(after - before)

func _bonus_coin_target_rect() -> Rect2:
	var image: Image = _coin_hud_icon.texture.get_image()
	if image == null:
		return _coin_hud_icon.get_global_rect()
	var used: Rect2i = image.get_used_rect()
	var size: Vector2 = _coin_hud_icon.texture.get_size()
	var ratio: float = minf(_coin_hud_icon.size.x / size.x, _coin_hud_icon.size.y / size.y)
	var pad: Vector2 = (_coin_hud_icon.size - size * ratio) * 0.5
	return _coin_hud_icon.get_global_transform() * Rect2(pad + Vector2(used.position) * ratio, Vector2(used.size) * ratio)


func play_win_coin_reward(source_rect: Rect2 = Rect2(), effect_parent: Node = null) -> void :

	if not _win_committed:
		await get_tree().process_frame
	if not _win_committed or not visible:
		return
	if _win_coin_reward <= 0:
		if _iq_complete_sound_pending:
			_iq_complete_sound_pending = false
			_play_complete_sound()
		_refresh_coin_hud()
		return

	var before: int = _win_coin_before
	var after: int = before + _win_coin_reward

	_set_coin_hud_display(before, after)
	var start_center: Vector2 = source_rect.get_center() if source_rect.has_area() else _quota.count_global_rect().get_center()
	var dst_center: Vector2 = _coin_hud_icon.get_global_rect().get_center()
	var count: int = clampi(_win_coin_reward / _round_target_coins, 1, WIN_COIN_FLY_COUNT)

	var tw: Tween = create_tween().set_parallel(true)
	_win_coin_tween = tw

	tw.tween_callback( func() -> void :
		if visible and _iq_complete_sound_pending:
			_iq_complete_sound_pending = false
			_play_complete_sound())

	HapticManager.cancel_event(_win_coin_haptic)
	_win_coin_haptic = play_finish_coin_haptic()



	var last_delay: float = float(count - 1) * WIN_COIN_FLY_STAGGER
	var min_dur: float = WIN_COIN_POP_DUR + WIN_COIN_FLY_DUR * (1.0 - WIN_COIN_FLY_SPEED_RAND)
	var max_dur: float = WIN_COIN_POP_DUR + WIN_COIN_FLY_DUR * (1.0 + WIN_COIN_FLY_SPEED_RAND)
	var last_arrival: float = _append_coin_bonus_flights(tw, start_center, dst_center, count, effect_parent)


	tw.tween_method(
		func(v: float) -> void : _coin_hud_label.text = str(int(round(v))), 
		float(before), float(after), maxf(WIN_COIN_FLY_STAGGER, last_delay + max_dur - min_dur)
	).set_delay(min_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var reward_end: float = last_delay + max_dur + WIN_COIN_PUNCH_DUR
	if is_coin_bonus_round():

		reward_end = maxf(reward_end, last_arrival + COIN_BONUS_TEXT_DURATION)
	tw.tween_interval(reward_end)
	var generation: int = _end_flow_generation
	while visible and generation == _end_flow_generation\
	and ((tw.is_valid() and tw.is_running()) or _has_active_coin_bonus_text()):
		await get_tree().process_frame
	if not visible or generation != _end_flow_generation:
		return
	_win_coin_tween = null
	_refresh_coin_hud()





func _append_coin_flight(tw: Tween, start_center: Vector2, dst_center: Vector2, 
		i: int, count: int, sprites: Array[SpineSprite], trails: Array[CPUParticles2D], 
		landed: Callable = Callable(), effect_parent: Node = null, bonus_size: float = 0.0, target_rect: Rect2 = Rect2(), 
		custom_delay: float = -1.0) -> float:
	var parent: Node = effect_parent if effect_parent != null else self
	var base_scale: float = (bonus_size if bonus_size > 0.0 else WIN_COIN_FLY_SIZE) / WIN_COIN_BBOX_W
	var coin: SpineSprite = get_win_coin_scene().instantiate() as SpineSprite
	coin.scale = Vector2.ONE * base_scale
	coin.z_index = 100 if bonus_size > 0.0 else 80
	parent.add_child(coin)
	coin.global_position = start_center
	sprites.append(coin)



	var trail: CPUParticles2D = _win_coin_trail_make()
	if bonus_size > 0.0:
		trail.z_index = 99
	parent.add_child(trail)
	trail.global_position = start_center
	trails.append(trail)





	var anim: SpineAnimationState = coin.get_animation_state()
	if anim != null:
		var entry: SpineTrackEntry = anim.set_animation(WIN_COIN_ANIM, true, 0)
		if entry != null:
			entry.set_track_time(randf() * WIN_COIN_ANIM_DUR * WIN_COIN_SPIN_DESYNC_RATIO)
	var delay: float = custom_delay if custom_delay >= 0.0 else float(i) * WIN_COIN_FLY_STAGGER


	var pop_angle: float = randf_range(0.0, TAU)
	var pop_dist: float = randf_range(WIN_COIN_POP_DIST_MIN, WIN_COIN_POP_DIST_MAX)
	var settle_center: Vector2 = start_center + Vector2(cos(pop_angle), sin(pop_angle)) * pop_dist
	tw.tween_method(
		func(t: float) -> void :
			if not is_instance_valid(coin):
				return
			var e: float = 1.0 - pow(1.0 - t, 3.0)
			coin.global_position = start_center.lerp(settle_center, e), 
		0.0, 1.0, WIN_COIN_POP_DUR
	).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var arc_h: float = WIN_COIN_ARC_HEIGHT * randf_range(
		1.0 - WIN_COIN_ARC_RAND, 1.0 + WIN_COIN_ARC_RAND)
	var ctrl: Vector2 = (settle_center + dst_center) * 0.5\
	+ Vector2((float(i) - float(count - 1) * 0.5) * 25.0, arc_h)

	var dur: float = WIN_COIN_FLY_DUR * randf_range(
		1.0 - WIN_COIN_FLY_SPEED_RAND, 1.0 + WIN_COIN_FLY_SPEED_RAND)
	tw.tween_callback( func() -> void :
		if is_instance_valid(trail):
			trail.emitting = true
	).set_delay(delay + WIN_COIN_POP_DUR)
	var bonus_landing: Dictionary = {}
	var flight_step: = func(t: float) -> void :
		if not is_instance_valid(coin):
			return
		var p: Vector2 = settle_center.lerp(ctrl, t).lerp(ctrl.lerp(dst_center, t), t)
		coin.global_position = p
		coin.scale = Vector2.ONE * base_scale * lerpf(1.25, 0.85, t)
		if bonus_size > 0.0 and target_rect.has_area():
			var sk: SpineSkeleton = coin.get_skeleton()
			if t >= 0.65:
				var state: SpineAnimationState = coin.get_animation_state()
				var track: SpineTrackEntry = state.get_current(0)
				if track != null:
					if bonus_landing.is_empty():
						bonus_landing["start"] = track.get_track_time()
						bonus_landing["end"] = ceilf(track.get_track_time() / WIN_COIN_ANIM_DUR) * WIN_COIN_ANIM_DUR
						track.set_time_scale(0.0)
					track.set_track_time(lerpf(float(bonus_landing["start"]), float(bonus_landing["end"]), smoothstep(0.65, 1.0, t)))
					sk.set_to_setup_pose()
					state.apply(sk)
					sk.update_world_transform(SpineConstant.Physics_Update)
			var bounds: Rect2 = sk.get_bounds()
			if bounds.has_area():
				var desired: Vector2 = (bounds.size * base_scale).lerp(target_rect.size, smoothstep(0.65, 1.0, t))
				coin.scale = desired / bounds.size
				coin.global_position = p - bounds.get_center() * coin.scale
		if is_instance_valid(trail):
			trail.global_position = p
	tw.tween_method(flight_step, 0.0, 1.0, dur)\
	.set_delay(delay + WIN_COIN_POP_DUR).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback( func() -> void :
		if is_instance_valid(coin):
			coin.queue_free()
			if bonus_size <= 0.0:
				_play_skin_sound(&"coin_fly")
		sprites.erase(coin)
		_punch_win_coin_icon()
		if landed.is_valid():
			landed.call()

		if is_instance_valid(trail):
			trail.emitting = false
			trails.erase(trail)
		var trail_extra: float = WIN_COIN_TRAIL_LIFETIME * (1.0 + WIN_COIN_TRAIL_LIFETIME_RANDOMNESS)
		get_tree().create_timer(trail_extra).timeout.connect( func() -> void :
			if is_instance_valid(trail):
				trail.queue_free())
	).set_delay(delay + WIN_COIN_POP_DUR + dur)
	return delay + WIN_COIN_POP_DUR + dur


func _append_coin_bonus_flights(tween: Tween, start_center: Vector2, dst_center: Vector2, 
		count: int, effect_parent: Node = null) -> float:
	var double_coins: bool = is_coin_bonus_round()
	if double_coins:
		_stop_coin_bonus_text()
		_prepare_coin_bonus_text()
		_prepare_coin_bonus_text_pool(count)
	var last_arrival: float = 0.0
	for index: int in range(count):
		var landed: Callable = Callable()
		if double_coins:

			landed = func() -> void : _play_coin_bonus_text(index)
		last_arrival = maxf(last_arrival, _append_coin_flight(tween, start_center, dst_center, 
			index, count, _win_coin_sprites, _win_coin_trails, landed, effect_parent))
	return last_arrival


func _prepare_coin_bonus_text_pool(count: int) -> void :
	while _coin_bonus_texts.size() < count:
		var text: TextureRect = _coin_bonus_text.duplicate() as TextureRect
		text.hide()
		text.position = _coin_bonus_text_rest_position
		text.scale = Vector2.ONE
		text.modulate.a = 1.0
		add_child(text)
		_coin_bonus_texts.append(text)
		_coin_bonus_text_tweens.append(null)
	for text: TextureRect in _coin_bonus_texts:
		text.size = _coin_bonus_text.size
		text.pivot_offset = text.size * 0.5
		text.position = _coin_bonus_text_rest_position


func _play_coin_bonus_text(index: int) -> void :
	var text: TextureRect = _coin_bonus_texts[index]
	var start_position: Vector2 = _coin_bonus_text_rest_position
	text.position = start_position
	text.scale = Vector2.ONE * COIN_BONUS_START_SCALE
	text.modulate.a = 1.0
	text.show()
	var tween: Tween = create_tween().set_parallel(true)
	_coin_bonus_text_tweens[index] = tween
	tween.tween_method( func(age: float) -> void :
		var scale_value: float = 1.0
		if age < COIN_BONUS_POP_DURATION:
			var pop: float = age / COIN_BONUS_POP_DURATION
			scale_value = lerpf(COIN_BONUS_START_SCALE, COIN_BONUS_POP_SCALE, 
				1.0 - (1.0 - pop) * (1.0 - pop))
		elif age < COIN_BONUS_POP_DURATION + COIN_BONUS_SETTLE_DURATION:
			var settle: float = (age - COIN_BONUS_POP_DURATION) / COIN_BONUS_SETTLE_DURATION
			scale_value = lerpf(COIN_BONUS_POP_SCALE, 1.0, 
				1.0 - (1.0 - settle) * (1.0 - settle))
		var fade: float = age / COIN_BONUS_TEXT_DURATION
		text.scale = Vector2.ONE * scale_value
		text.position = start_position + Vector2.UP * COIN_BONUS_RISE_DISTANCE\
		* minf(1.0, age / COIN_BONUS_RISE_DURATION)
		text.modulate.a = 1.0 - fade * fade, 
			0.0, COIN_BONUS_TEXT_DURATION, COIN_BONUS_TEXT_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect( func() -> void :
		text.hide()
		_coin_bonus_text_tweens[index] = null, CONNECT_ONE_SHOT)


func _prepare_coin_bonus_text() -> void :
	var tex_size: Vector2 = _coin_bonus_text.texture.get_size()
	var coin_rect: Rect2 = _coin_hud.get_global_rect()
	var coin_icon_rect: Rect2 = _coin_hud_icon.get_global_rect()
	var text_width: float = minf(COIN_BONUS_TEXT_WIDTH, 
		coin_icon_rect.size.x * COIN_BONUS_TEXT_ICON_WIDTH_RATIO)
	_coin_bonus_text.size = tex_size * (text_width / tex_size.x)
	_coin_bonus_text.pivot_offset = _coin_bonus_text.size * 0.5
	var viewport: Vector2 = UiMetrics.viewport_size()
	var pulse_half_width: float = _coin_bonus_text.size.x * COIN_BONUS_POP_SCALE * 0.5
	var gap: float = 8.0


	var center: Vector2 = Vector2(
		clampf(coin_icon_rect.get_center().x, 
			pulse_half_width + gap, viewport.x - pulse_half_width - gap), 
		coin_rect.position.y - gap)
	_coin_bonus_text_rest_position = get_global_transform().affine_inverse() * center\
	- _coin_bonus_text.pivot_offset
	_coin_bonus_text.position = _coin_bonus_text_rest_position
	_coin_bonus_text.scale = Vector2.ONE
	_coin_bonus_text.modulate.a = 1.0
	_coin_bonus_text.hide()


func _has_active_coin_bonus_text() -> bool:
	for tween: Tween in _coin_bonus_text_tweens:
		if tween != null and tween.is_valid() and tween.is_running():
			return true
	return false


func _stop_coin_bonus_text() -> void :
	for index: int in range(_coin_bonus_texts.size()):
		var tween: Tween = _coin_bonus_text_tweens[index]
		if tween != null and tween.is_valid():
			tween.kill()
		_coin_bonus_text_tweens[index] = null
		var text: TextureRect = _coin_bonus_texts[index]
		text.hide()
		text.position = _coin_bonus_text_rest_position
		text.scale = Vector2.ONE
		text.modulate.a = 1.0
	_coin_bonus_text.hide()
	_coin_bonus_text.position = _coin_bonus_text_rest_position
	_coin_bonus_text.scale = Vector2.ONE
	_coin_bonus_text.modulate.a = 1.0


func _punch_win_coin_icon() -> void :
	if _win_coin_punch_tween != null and _win_coin_punch_tween.is_valid():
		_win_coin_punch_tween.kill()
	_coin_hud_icon.scale = Vector2.ONE * WIN_COIN_PUNCH_SCALE
	_win_coin_punch_tween = create_tween()
	_win_coin_punch_tween.tween_property(_coin_hud_icon, "scale", Vector2.ONE, 
		WIN_COIN_PUNCH_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _cancel_win_coin_reward() -> void :
	_stop_coin_bonus_text()

	HapticManager.cancel_event(_win_coin_haptic)
	_win_coin_haptic = 0
	_bonus_coin_hud.z_index = _bonus_coin_hud_base_z

	_hide_bonus_gain()
	if _win_coin_tween != null and _win_coin_tween.is_valid():
		_win_coin_tween.kill()
	_win_coin_tween = null
	if _win_coin_punch_tween != null and _win_coin_punch_tween.is_valid():
		_win_coin_punch_tween.kill()
	_win_coin_punch_tween = null
	for coin in _win_coin_sprites:
		if is_instance_valid(coin):
			coin.queue_free()
	_win_coin_sprites.clear()
	for trail in _win_coin_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	_win_coin_trails.clear()
	_coin_hud_icon.scale = Vector2.ONE
	_refresh_coin_hud()





func _win_coin_trail_make() -> CPUParticles2D:
	return create_win_coin_trail()



static func create_win_coin_trail() -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	p.texture = WIN_COIN_TRAIL_TEX
	p.emitting = false
	p.one_shot = false
	p.z_index = 79

	p.modulate = CUP_BLOOM_PARTICLE_GOLD

	var add_mat: = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = add_mat
	p.amount = maxi(1, roundi(WIN_COIN_TRAIL_RATE * WIN_COIN_TRAIL_LIFETIME))
	p.lifetime = WIN_COIN_TRAIL_LIFETIME
	p.lifetime_randomness = WIN_COIN_TRAIL_LIFETIME_RANDOMNESS
	p.gravity = Vector2.ZERO

	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = WIN_COIN_FLY_SIZE * 0.5
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 20.0
	var cell: float = maxf(1.0, float(WIN_COIN_TRAIL_TEX.get_width()))
	var s: float = WIN_COIN_TRAIL_SIZE / cell
	p.scale_amount_min = s * (1.0 - WIN_COIN_TRAIL_SIZE_RANDOMNESS)
	p.scale_amount_max = s * (1.0 + WIN_COIN_TRAIL_SIZE_RANDOMNESS)
	p.color_ramp = _make_win_coin_trail_ramp()
	return p






static func _make_win_coin_trail_ramp() -> Gradient:
	var g: = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
	return g







func _refresh_coin_hud() -> void :
	var shown: int = UserState.get_coins() - _bonus_coin_pending - _daily_checkin_round.pending_coin_display()
	_set_coin_hud_display(shown, shown)


func _set_coin_hud_display(value: int, layout_value: int) -> void :
	_coin_hud_label.text = str(value)
	var text_value: String = str(layout_value)
	var font: Font = _coin_hud_label.get_theme_font("font")
	var font_size: int = COIN_FONT_MAX
	var text_width: float = 0.0
	if font != null:
		while true:
			text_width = font.get_string_size(
				text_value, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size
			).x
			if text_width <= COIN_TEXT_MAX_W or font_size <= COIN_FONT_MIN:
				break
			font_size -= 2
		text_width = minf(text_width, COIN_TEXT_MAX_W)
	_coin_hud_label.add_theme_font_size_override("font_size", font_size)
	_layout_coin_group(text_width)






func _layout_coin_group(text_width: float) -> void :
	var visible_group_w: float = COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP + text_width
	var visible_group_left: float = (COIN_HUD_WIDTH - visible_group_w) * 0.5
	var icon_box_left: float = visible_group_left - COIN_ICON_VISIBLE_INSET_LEFT
	_coin_hud_icon.offset_left = icon_box_left
	_coin_hud_icon.offset_right = icon_box_left + COIN_ICON_SIZE
	var text_center: float = visible_group_left + COIN_ICON_VISIBLE_WIDTH + COIN_ICON_TEXT_GAP\
	+ text_width * 0.5
	_coin_hud_label.offset_left = text_center - COIN_TEXT_MAX_W * 0.5
	_coin_hud_label.offset_right = text_center + COIN_TEXT_MAX_W * 0.5



func prepare_finish_ad_reward() -> bool:
	_finish_ad_reward_enabled = false
	if not (is_mainline_timed_endless() or _is_hard_level() or _is_super_hard_level()):
		return true
	var generation: int = _end_flow_generation

	var ready: bool = await AdManager.check_reward_ads_available("finish_ad_reward")
	if not visible or generation != _end_flow_generation:
		return false
	if not ready:
		return true
	ABManager.dye_at_finish_ad_reward()
	_finish_ad_reward_enabled = ABManager.finish_ad_reward.is_reward_enabled()
	return true

func is_finish_ad_busy() -> bool:
	return _finish_ad_busy

func is_finish_interstitial_busy() -> bool:
	return _finish_interstitial_busy

func set_finish_interstitial_busy(busy: bool) -> void :
	_finish_interstitial_busy = busy

func begin_finish_ad_busy() -> int:
	_finish_ad_busy_generation += 1
	_finish_ad_busy = true
	_back_btn.disabled = true
	_set_reset_buttons_disabled(true)
	return _finish_ad_busy_generation

func end_finish_ad_busy(generation: int) -> void :
	if generation != _finish_ad_busy_generation:
		return
	_finish_ad_busy = false
	_back_btn.disabled = false
	_set_reset_buttons_disabled(false)

func _on_finish_ad_reward_pressed() -> void :
	if not visible or not _complete_shown or _next_pressed or _complete_panel == null:
		return
	await FinishAdRewardFlow.run(self, _complete_panel)

func play_finish_ad_reward(panel, reward: Dictionary, before: int, after: int) -> void :
	var kind: String = String(reward["kind"])
	var target: Control = _coin_hud if kind == "coins" else _prop_ui[kind]["btn"] as Control
	var icon: Control = _coin_hud_icon if kind == "coins" else target.get_node("Icon") as Control
	var dialog: FinishAdRewardDialog = SceneManager.show_dlg("finish_ad_reward") as FinishAdRewardDialog
	var motion: FinishAdRewardMotion = dialog.get_motion()
	var generation: int = _finish_ad_busy_generation
	_finish_ad_reward_motion = motion
	motion.haptic_style = _shake_style()
	await dialog.play(self, target, icon, reward, before, after, panel.get_ad_reward_texture(kind), panel)
	if _finish_ad_reward_motion == motion and generation == _finish_ad_busy_generation:
		_finish_ad_reward_motion = null
		SceneManager.hide_dlg("finish_ad_reward")

func set_finish_ad_reward_display(kind: String, value: int, layout_value: int) -> void :
	if kind == "coins":
		_set_coin_hud_display(value, layout_value)
	else:
		(_prop_ui[kind]["btn"] as PropBtn).set_reward_count_display(value)

func _cancel_finish_ad_reward() -> void :
	if is_instance_valid(_finish_ad_reward_motion):
		_finish_ad_reward_motion.stop()
		SceneManager.hide_dlg("finish_ad_reward")
	_finish_ad_reward_motion = null



func play_celebration() -> void :
	_stop_progress_full_preview()

	var won_level: int = _level_model.level_id if _level_model != null else 0
	_finish_game_data_enabled = won_level >= 3 and not is_special_challenge()
	if _finish_game_data_enabled:
		ABManager.dye_at_game_data()
	_finish_use_new_result_data = _finish_game_data_enabled and ABManager.game_data_2_0.is_new_result_data_enabled()
	var has_iq: bool = _finish_game_data_enabled and won_level >= 4 and _iq_round.enabled
	_finish_iq_replacement_metric = ""
	if has_iq:
		ABManager.dye_at_iq_data()
		if ABManager.iq_data.should_replace_steps():
			_finish_iq_replacement_metric = "step"
		elif ABManager.iq_data.should_replace_streak():
			_finish_iq_replacement_metric = "streak"


	_complete_shown = false
	_complete_panel = SceneManager.show_dlg("finish", {
		"background_initial_opacity": _bonus_pig_smash.held_background_opacity() if _bonus_pig_smash != null else 0.0, 
		"background_handoff": _bonus_pig_smash.hide_now if _bonus_pig_smash != null and _bonus_pig_smash.held_background_opacity() > 0.0 else Callable(), 
		"is_hard": _is_hard_level(), 
		"is_super_hard": _is_super_hard_level(), 
		"ad_reward_enabled": _finish_ad_reward_enabled, 
		"haptic_style": _shake_style(), 
		"finish_cart_appear_sound_id": _finish_cart_appear_sound_id, 
		"game_data_enabled": _finish_game_data_enabled, 
		"timed_endless_result": _timed_result, 
	})
	_refresh_finish_tracking()
	if _complete_panel != null and not _complete_panel.is_connected("next_pressed", _on_finish_next_pressed):
		_complete_panel.connect("next_pressed", _on_finish_next_pressed)
	if _complete_panel != null and not _complete_panel.is_connected("ad_reward_pressed", _on_finish_ad_reward_pressed):
		_complete_panel.connect("ad_reward_pressed", _on_finish_ad_reward_pressed)
	_mark_complete_shown_after_finish_entrance()
	_back_btn.disabled = false
	_set_reset_buttons_disabled(false)


func _refresh_finish_tracking() -> void :
	if _complete_panel == null or _level_model == null:
		return
	var target: Dictionary = LevelManager.get_next_round_descriptor()
	var special: bool = bool(target["is_special"])
	var next_level: int = _next_round_level_id()
	var next_model: LevelModel = null if special else LevelManager.get_level_model(
		LevelIndex.chapter_of(next_level), LevelIndex.index_of(next_level))
	_complete_panel.set_next_tracking(next_model.level_unique_id if next_model != null else "", special)


func _on_finish_level_data_changed(chapter: int) -> void :
	if visible and _complete_shown and not _next_pressed and _level_model != null\
	and chapter == LevelIndex.chapter_of(_next_round_level_id()):
		_refresh_finish_tracking()


func _on_finish_next_pressed() -> void :
	_next_pressed = true



func _is_hard_level() -> bool:
	return _level_model != null\
	and _level_model.difficulty_type.strip_edges().to_lower() == "hard"



func _is_super_hard_level() -> bool:
	return _level_model != null and _level_model.is_super_hard()



func is_complete_panel_shown() -> bool:
	return _complete_shown



func wait_complete_panel_shown(generation: int) -> bool:
	var panel: Node = _complete_panel
	if not _is_finish_entrance_active(panel, generation):
		return false
	var tree: SceneTree = get_tree()
	while _is_finish_entrance_active(panel, generation):
		if _complete_shown:
			return true
		await tree.process_frame
	return false



func _is_finish_entrance_active(panel: Variant, generation: int) -> bool:
	return is_inside_tree() and visible and generation == _end_flow_generation\
	and is_instance_valid(panel) and panel == _complete_panel and panel.is_inside_tree() and panel.visible




func _mark_complete_shown_after_finish_entrance() -> void :
	var panel: Node = _complete_panel
	var generation: int = _end_flow_generation
	if not _is_finish_entrance_active(panel, generation):
		return
	var tree: SceneTree = get_tree()
	while _is_finish_entrance_active(panel, generation) and not _finish_reward_entrance_done(panel):
		await tree.process_frame
	if _is_finish_entrance_active(panel, generation):
		_complete_shown = true



func _finish_reward_entrance_done(panel: Node) -> bool:
	if not panel.has_method("is_reward_entrance_complete"):
		return true
	return bool(panel.call("is_reward_entrance_complete"))



func is_finish_game_data_enabled() -> bool:
	return _finish_game_data_enabled



func get_finish_game_data() -> Dictionary:
	return {
		"target_flower_count": _level_model.juice.total_flowers, 
		"elapsed_ms": _play_timer.finish_elapsed_ms(), 
		"move_attempt_count": _board.move_attempt_count(), 
		"win_streak_count": UserState.get_win_streak_count(), 
		"record_improvements": _finish_record_improvements.duplicate(), 
		"use_new_result_data": _finish_use_new_result_data, 
		"iq_data_enabled": not _finish_iq_replacement_metric.is_empty(), 
		"iq_replacement_metric": _finish_iq_replacement_metric, 
		"final_iq": _iq_round.value(), 
		"iq_score_boost_enabled": _iq_round.score_boost_enabled, 
	}



func show_finish_game_data(data: Dictionary) -> void :
	if not _finish_game_data_enabled or not visible or not _complete_shown\
	or _complete_panel == null or not is_instance_valid(_complete_panel):
		return
	await _complete_panel.call("show_game_data", data, _is_hard_level(), _is_super_hard_level())



func show_finish_button() -> void :
	if not visible or not _complete_shown\
	or _complete_panel == null or not is_instance_valid(_complete_panel):
		return
	await _complete_panel.call("show_next_button")



func is_finish_presentation_complete() -> bool:
	return _complete_panel != null and is_instance_valid(_complete_panel)\
	and _complete_panel.has_method("is_entrance_complete")\
	and bool(_complete_panel.call("is_entrance_complete"))



func await_next_pressed() -> bool:
	while not _next_pressed and is_inside_tree() and visible and _complete_shown:
		await get_tree().process_frame
	return _next_pressed



func exit_finish_after_win(_won_level: int) -> void :
	if not visible:
		return
	await return_home()






func _on_board_drag_started(_col: int, _j: int) -> void :
	_on_location_judge_pickup()
	_on_same_color_highlight_pickup()
	_stop_undo_guide_motion_preview(false)

	var round_clock: Variant = _endless_controller if is_endless() else _play_timer
	if is_instance_valid(round_clock):
		round_clock.on_flower_touched()
	if _board.tutorial_demo_only:
		HapticManager.play_event(HapticManager.Event.PICK_UP)
	else:
		ABManager.dye_at_shake_v2()
		_play_game_haptic(HapticManager.Event.PICK_UP)



func _on_location_judge_pickup() -> void :

	if not _board.tutorial_demo_only:
		ABManager.dye_at_location_judge()
		_board.set_drop_settings(ABManager.location_judge.get_drop_settings())
	else:
		_board.set_drop_settings({})



func _on_same_color_highlight_pickup() -> void :
	if _board.tutorial_demo_only:
		_board.set_same_color_highlight_enabled(false)
		return
	ABManager.dye_at_same_color_highlight()
	_board.set_same_color_highlight_enabled(
		ABManager.same_color_highlight.is_same_color_highlight_enabled())



func _root_swapping_enabled_for_level(level_id: int) -> bool:
	return ABManager.allow_root_swapping.should_allow_root_swapping(level_id)


func _configure_root_swapping() -> void :
	var level_id: int = _level_model.level_id if _level_model != null else UserState.get_current_level()


	_board.set_root_adjudication_suspended(true)
	var enabled: bool = _root_swapping_enabled_for_level(level_id)
	_board.set_allow_root_swapping_enabled(enabled)
	_board.set_play_after_dead_enabled(ABManager.allow_root_swapping.should_allow_playing_after_dead(level_id))
	if not enabled:
		_teardown_root_swap_guide(true)



func _on_long_link_triggered(geometry: Dictionary) -> void :
	if geometry.is_empty():
		return

	if _level_model != null and not is_special_challenge() and _level_model.level_id == 1:
		return
	ABManager.dye_at_long_link()
	if not ABManager.long_link.is_long_link_enabled() or not is_visible_in_tree():
		return
	var inverse: Transform2D = _long_link_feedback.get_global_transform().affine_inverse()
	_long_link_feedback.play(inverse * (geometry["center"] as Vector2), 
		float(geometry["width"]) * inverse.x.length())


func _on_board_moved(steps: int, automatic_only: bool = false, automatic_collected: bool = false) -> bool:
	if is_endless():
		GameMoveFlow.run(GameMoveContext.new(self, steps))
		_refresh_endless_hud()
		return false
	var ctx: = GameMoveContext.new(self, steps, automatic_only)
	ctx.auto_unlock_applied = automatic_collected
	GameMoveFlow.run(ctx)

	if not ctx.sync_settlement_done:
		SortLogger.error("GameMoveFlow: synchronous settlement was delayed")
		PersistMoveStep.new().run(ctx)
	return ctx.auto_unlock_applied



func _on_board_mystery_auto_unlock_requested() -> bool:
	if _playfield_ready and is_visible_in_tree() and _board.can_auto_unlock_mystery():
		return _on_board_moved(_board.steps(), true)
	return false



func _on_board_automatic_settlement_requested() -> void :
	if not is_endless():
		_on_board_moved(_board.steps(), true, true)


func _finish_entrance_mystery_auto_unlock(ctx) -> void :
	var auto_unlocked: bool = _on_board_mystery_auto_unlock_requested()
	if auto_unlocked and R.is_win(_board.state(), _board.level()):
		if ctx != null:
			ctx.aborted = true
	if auto_unlocked:
		_board.check_over_after_auto_unlock()

	if not is_endless():
		_board.set_root_adjudication_suspended(false)


func check_mystery_auto_unlock(ctx: GameMoveContext) -> void :
	if is_endless() or _board.can_play_after_dead() or _board.tutorial_demo_only or not _board.can_auto_unlock_mystery():
		return
	ABManager.dye_at_mystery_auto_unlock()
	if ABManager.mystery_auto_unlock.is_auto_unlock_enabled():
		ctx.auto_unlock_applied = _board.auto_unlock_mystery() or ctx.auto_unlock_applied



func apply_auto_unlock_feedback() -> void :
	var done: int = int(_board.state().get("done", 0))
	_iq_round.on_move(done, [] as Array[int])
	_combo_tracker.sync_done(done)
	_combo_frequency_tracker.sync_done(done)
	_refresh_iq_header()



func apply_empty_rope_feedback() -> void :
	if is_endless() or _board.can_play_after_dead():
		return
	var info: Dictionary = _board.take_empty_rope_feedback()
	if _tutorial_active or info.is_empty():
		return
	var operation_key: String = info["operation_key"]
	if not _empty_col_feedback.can_show(operation_key):
		return
	var inverse: Transform2D = _empty_col_feedback.get_global_transform().affine_inverse()
	_empty_col_feedback.play(inverse * (info["center"] as Vector2), 
		float(info["width"]) * inverse.x.length(), 
		_empty_rope_geometry_local.bind(info["rope_geometry"]), operation_key)


func _empty_rope_geometry_local(provider: Callable) -> Dictionary:
	if not provider.is_valid():
		return {}
	var geometry: Dictionary = provider.call()
	if geometry.is_empty():
		return {}
	var inverse: Transform2D = _empty_col_feedback.get_global_transform().affine_inverse()
	return {"top": inverse * (geometry["top"] as Vector2), 
		"bottom": inverse * (geometry["bottom"] as Vector2), 
		"width": float(geometry["width"]) * inverse.x.length()}


func apply_move_feedback(_steps: int) -> void :
	if is_endless():
		_queue_root_swap_guide()
		_play_move_haptic()
		return
	if _progress_full_active:
		_stop_progress_full_preview()

	_reset_hint_guide()
	_clear_hint_guide_motion()
	_play_move_haptic()

	if _board.can_play_after_dead():
		return
	var now_msec: int = Time.get_ticks_msec()
	_last_move_gap_msec = now_msec - _last_move_msec
	_last_move_msec = now_msec
	_combo_steps += 1
	_early_wrong_drags = 0
	var combos: Array[int] = _combo_tracker.on_move(_combo_steps, 
		int(_board.state().get("done", 0)), 
		_play_timer.elapsed_ms())
	var done: int = int(_board.state().get("done", 0))

	for i: int in combos.size():
		_combo_sfx_counts[done - combos.size() + i] = combos[i]
	_iq_round.on_move(done, combos)
	_refresh_iq_header()

	var frequency_feedbacks: Array[int] = _combo_frequency_tracker.on_move(done)
	if not combos.is_empty() or not frequency_feedbacks.is_empty():
		ABManager.dye_at_combo_freq()
	var new_frequency: bool = ABManager.combo_freq.is_new_frequency_enabled()
	_combo_frequency_wait_before_end = new_frequency
	if new_frequency:
		combos = []
		for feedback_count: int in frequency_feedbacks:

			combos.append(mini(feedback_count + 1, ComboFeedback.LEGENDARY_START_COUNT))
	if not combos.is_empty():

		if not _combo_haptic_dyed:
			ABManager.dye_at_combo_haptic()
			_combo_haptic_dyed = true
		var fullscreen_fx_enabled: bool = ABManager.combo_fullscreen_fx.is_fullscreen_fx_enabled()
		var haptic_events: Array[int] = []
		var style: int = _shake_style()

		var three_levels: bool = style == 0 and HapticProfiles.is_three_level_combo_platform(OS.get_name())
		for count: int in combos:
			var event: int = HapticProfiles.combo_event_for_count(count, three_levels)
			haptic_events.append(HapticProfiles.shake_event_for(event, style))
		var quota_bottom: float = (_quota.get_global_transform() * Vector2(0.0, _quota.size.y)).y
		var pot_top: float = _board.pot_top_global_y()
		var center: Vector2 = Vector2(UiMetrics.viewport_size().x * 0.5, (quota_bottom + pot_top) * 0.5)

		_combo_feedback.play(combos, get_global_transform().affine_inverse() * center, 
			haptic_events, fullscreen_fx_enabled, new_frequency)
	_queue_root_swap_guide()


func queue_move_prop_refresh() -> void :




	if not _board.is_busy():
		call_deferred("_refresh_prop_btns")


func persist_moved_state() -> void :
	if is_endless():
		return

	if R.is_win(_board.state(), _board.level()):


		_back_btn.disabled = true
		_set_reset_buttons_disabled(true)
		_commit_win_data_once()
		return





func debug_try_move(src: int, j: int, dst: int) -> bool:
	if not visible or _board == null:
		return false
	var cols: Array = _board.state().get("cols", [])
	if src < 0 or dst < 0 or src >= cols.size() or dst >= cols.size():
		return false
	if j < 0 or j >= (cols[src] as Array).size():
		return false
	return _board.try_move(src, j, dst)


func debug_game_action(action: String) -> void :
	if OS.has_feature("rel") or not visible or _board == null or not _playfield_ready:
		return
	match action:
		"undo":
			_on_prop_pressed("undo")
		"restart":
			if _ui_button_is_ready("reset"):
				_on_reset_confirmed()


func _on_board_move_attempted(info: Dictionary) -> void :
	if _tracking_common == null:
		return
	var params: Dictionary = {
		TrackingEvents.K_LEVEL_CURRENT_INFO: JSON.stringify({
			"finished_orders_num": info["finished_orders_num"], 
			"left_orders_num": info["left_orders_num"], 
			"before_empty_rope_num": info["before_empty_rope_num"], 
			"before_total_rope_num": info["before_total_rope_num"], 
			"before_possible_moves": info["before_possible_moves"], 
		}), 
		TrackingEvents.K_MOVE_RESULT_INFO: JSON.stringify({
			"is_link": info["is_link"], 
			"is_finished_order": info["is_finished_order"], 
			"after_empty_rope_num": info["after_empty_rope_num"], 
			"after_possible_moves": info["after_possible_moves"], 
		}), 
		TrackingEvents.K_MOVE_TILES_INFO: JSON.stringify(info["move_tiles_info"]), 
		TrackingEvents.K_TARGET_TILES_INFO: JSON.stringify(info["target_tiles_info"]), 
	}
	if info.has("reject_reason"):


		match int(info["reject_reason"]):
			R.Reject.COLOR:
				params[TrackingEvents.K_FAIL_LINK_REASON] = TrackingEvents.FAIL_WRONG_COLOR
			R.Reject.FULL:
				params[TrackingEvents.K_FAIL_LINK_REASON] = TrackingEvents.FAIL_NOT_ENOUGH_SPACE
			R.Reject.MYSTERY, R.Reject.FROZEN:
				params[TrackingEvents.K_FAIL_LINK_REASON] = TrackingEvents.FAIL_QUESTION_ERROR
			R.Reject.LOCKED:
				params[TrackingEvents.K_FAIL_LINK_REASON] = TrackingEvents.FAIL_CAGE_ROPE_ERROR
	Tracker.send_event(TrackingEvents.EV_TILES_MOVE, params, _tracking_common)


func _on_new_rope_appeared(info: Dictionary) -> void :
	var has_question: bool = bool(info["has_question"])
	var has_lock: bool = bool(info["has_lock"])

	var gameplay: String = ""
	if has_question and has_lock:
		gameplay = TrackingEvents.ROPE_QUESTION_CAGE
	elif has_question:
		gameplay = TrackingEvents.ROPE_QUESTION
	elif has_lock:
		gameplay = TrackingEvents.ROPE_CAGE
	_report_new_rope(bool(info["is_empty"]), TrackingEvents.APPEAR_DEFAULT_AUTO, gameplay)



func _on_cup_collected(fruit_type: int, nth: int, color: Color, from_rect_global: Rect2) -> void :
	if is_endless():
		if _endless_controller.end_reason == "":
			_play_game_haptic(HapticManager.Event.CUP_DONE)
			_quota.reserve_endless_slot(nth)
			_quota.reveal_slot(nth)
			_start_cup_flight(nth, _board.target_icon_for_type(fruit_type), color, from_rect_global, _board.slot_for_type(fruit_type))
		return
	if _board.level().is_sunlight_type(fruit_type):
		if nth + 1 == _board.level().groups_total:
			request_finish_preparation()
		_quota.reveal_slot(nth)
		_board.start_sunlight_collection(nth, from_rect_global, 
			_quota.cup_global_rect(nth, _board.sunlight_full_blender_texture), 
			_quota.cup_global_rect.bind(nth, _board.sunlight_full_blender_texture))
		return







	if _level_model != null and nth + 1 == _level_model.juice.groups_total\
	and int(_board.state().get("done", 0)) >= _level_model.juice.groups_total:
		request_finish_preparation()
	_play_game_haptic(HapticManager.Event.CUP_DONE)



	if _bonus_type >= 0 and fruit_type == _bonus_type:
		_on_bonus_pot_collected(nth, from_rect_global)
		return
	_quota.reveal_slot(nth)
	if _rank_collectible_type >= 0 and fruit_type == _rank_collectible_type:
		_rank_gift_slot = nth
		_start_rank_gift_flight(nth, from_rect_global)
		return
	_start_cup_flight(nth, _board.target_icon_for_type(fruit_type), 
		color, from_rect_global, _board.slot_for_type(fruit_type))



func _on_bonus_pot_collected(nth: int, from_rect_global: Rect2) -> void :
	_bonus_collect_generation += 1
	var generation: int = _bonus_collect_generation
	_bonus_pot_collecting = true
	while visible and generation == _bonus_collect_generation and _board.is_bonus_entry_feedback_running():
		await get_tree().process_frame
	if not visible or generation != _bonus_collect_generation:
		return
	_bonus_pot_collecting = false
	var tex: Texture2D = _board.full_blender_texture_for_type(_bonus_type)
	if _rank_collectible_type >= 0:
		_quota.push_sunlight_round_cup(nth, tex, _board.color_for_type(_bonus_type), true)
	else:
		_quota.push_cup(tex, _board.color_for_type(_bonus_type), true)
	_place_bonus_pig_dock()
	var handoff: Dictionary = _board.take_bonus_pig_handoff()
	_bonus_pig_hud.fly_in_from(handoff.get("rect", from_rect_global), handoff)
	_play_skin_sound(&"coin_fly")





func _place_bonus_pig_dock() -> void :
	var font: Font = _level_label.get_theme_font("font")
	if font == null:
		return
	var font_size: int = _level_label.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(
		_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_bonus_pig_hud.place_left_of_label(_level_label.get_global_rect(), text_width)






func _sync_bonus_pig_hud() -> void :
	if _bonus_pig_hud == null:
		return
	if _bonus_type < 0 or _board.level() == null:
		if _bonus_pig_hud != null:
			_bonus_pig_hud.hide_now()
		return
	var collected: bool = (_board.state()["cups"] as Array).has(_bonus_type)
	if not collected:
		if _bonus_pig_hud != null:
			_bonus_pig_hud.hide_now()
		return
	_place_bonus_pig_dock()
	if not _bonus_pig_hud.is_docked() and not _bonus_pig_hud.is_flying():
		_bonus_pig_hud.dock_instantly()


func _on_cups_changed() -> void :
	if _skin_refreshing:
		_refresh_skin_quota()
		return
	if is_endless():
		_cancel_cup_flights()
		_quota.set_endless_cups(_board.cup_textures(), _board.cup_colors(), int(_board.state().get("done", 0)))
		_hint_cancel()
		_refresh_endless_hud()
		return
	_cancel_bonus_collection()
	_sync_bonus_pig_hud()
	_combo_feedback.hide_now()
	_empty_col_feedback.hide_now()
	if _board.level() != null:
		_iq_round.sync_done(int(_board.state().get("done", 0)))
		if _applying_undo:
			_combo_tracker.sync_done(int(_board.state().get("done", 0)))
			_combo_frequency_tracker.sync_done(int(_board.state().get("done", 0)))
		else:
			_combo_steps = 0
			_combo_frequency_wait_before_end = false
			_early_wrong_drags = 0
			_combo_tracker.reset(_board.level().capacity, 
				_level_model.difficulty if _level_model != null else 1, _combo_steps, 
				int(_board.state().get("done", 0)))
			_combo_frequency_tracker.reset(_board.level().capacity, _board.level().groups_total, 
				int(_board.state().get("done", 0)))





	_cancel_cup_flights()
	var hidden_slots: Array[int] = []
	var cups: Array = _board.state().get("cups", [])
	_rank_gift_slot = cups.find(_rank_collectible_type) if _rank_collectible_type >= 0 else -1
	for i: int in range(cups.size()):
		if int(cups[i]) == _bonus_type and _bonus_type >= 0:
			hidden_slots.append(i)
	_quota.set_cups(_board.cup_textures(), _board.cup_colors(), hidden_slots)











func _on_bird_house_hovered(visual: JuiceBirdCollection) -> void :
	var particles: CPUParticles2D = _hover_particles_make()
	particles.z_index = -1
	particles.local_coords = false
	particles.modulate = CUP_BLOOM_PARTICLE_GOLD
	particles.lifetime = CUP_BLOOM_HOVER_LIFETIME
	particles.lifetime_randomness = CUP_BLOOM_PARTICLE_LIFETIME_RANDOMNESS
	particles.emission_sphere_radius = CUP_BLOOM_HOVER_EMISSION_RADIUS
	var width: float = visual.house.texture.get_width() * visual.house.scale.x
	var particle_scale: float = width * CUP_BLOOM_PARTICLE_SIZE_RATIO / maxf(1.0, particles.texture.get_width())
	particles.scale_amount_min = particle_scale * (1.0 - CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)
	particles.scale_amount_max = particle_scale * (1.0 + CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)
	particles.initial_velocity_min = width * CUP_BLOOM_HOVER_SPEED_RATIO * 0.6
	particles.initial_velocity_max = width * CUP_BLOOM_HOVER_SPEED_RATIO
	visual.add_child(particles)
	particles.restart()
	particles.emitting = true


func _start_bird_cup_flight(slot: int, visual: JuiceBirdCollection, tex: Texture2D, 
		tint: Color) -> void :
	var from_rect: Rect2 = visual.filled_global_rect()
	var tween: Tween = create_tween()
	_append_cup_flight_sound(tween, false, slot)
	tween.parallel().tween_method(_bird_to_slot_step.bind(visual, from_rect, slot, tex), 
		0.0, 1.0, CUP_FLY_DUR).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var rec: Dictionary = {"tw": tween, "spr": null, "bird_visual": visual, 
		"slot": slot, "tex": tex, "tint": tint, "preview_only": false}
	_cup_flights.append(rec)
	tween.finished.connect(_on_cup_flight_finished.bind(rec), CONNECT_ONE_SHOT)


func _bird_to_slot_step(progress: float, visual: JuiceBirdCollection, from_rect: Rect2, 
		slot: int, texture: Texture2D) -> void :
	if not is_instance_valid(visual):
		return
	var destination: Rect2 = _quota.cup_global_rect(slot, texture)
	visual.place_filled(Rect2(from_rect.position.lerp(destination.position, progress), 
		from_rect.size.lerp(destination.size, progress)))


func _start_cup_flight(slot: int, tex: Texture2D, tint: Color, from_rect: Rect2, 
		color_slot: int, preview_only: bool = false) -> void :

	if tex == null or _fly_layer == null:
		if not preview_only:
			_quota.push_cup(tex, tint, false, slot)
		else:
			SortLogger.warn("ProgressBling: full preview requires cup texture and fly layer")
			_stop_progress_full_preview()
		return
	if not preview_only:
		var bird_visual: JuiceBirdCollection = _board.take_bird_handoff(slot)
		if is_instance_valid(bird_visual):
			_start_bird_cup_flight(slot, bird_visual, tex, tint)
			return
	var spr: SpineSprite = _fly_acquire(color_slot)
	if preview_only:
		_progress_full_sprite = spr


	var bloom_size: Vector2 = from_rect.size * CUP_BLOOM_SCALE
	var base_y: float = from_rect.position.y + from_rect.size.y * CUP_POT_BASE_V
	var bloom_rect: = Rect2(
		Vector2(from_rect.position.x + (from_rect.size.x - bloom_size.x) * 0.5, 
			base_y - bloom_size.y * CUP_BLOOM_BASE_V), bloom_size)
	var from_center: Vector2 = _fly_layer.to_local(bloom_rect.position + bloom_rect.size * 0.5)
	if preview_only:
		_play_pot_petals(from_center, bloom_size, _progress_bling.normal_ripple_color(color_slot), true, color_slot)

	var hold_from: Vector2 = from_center - Vector2(0.0, 
		CUP_FLY_RISE * (1.0 - CUP_FLY_HOLD_RISE_RATIO))
	var lift_center: Vector2 = from_center - Vector2(0.0, CUP_FLY_RISE)
	_fly_bloom_step(0.0, spr, from_center, bloom_size)

	var tw: Tween = create_tween()



	tw.tween_interval(CUP_FLY_SPINE_PREROLL_LEAD)
	tw.tween_callback(_fly_reveal.bind(spr))



	tw.tween_callback(_play_pot_butterflies.bind(spr, bloom_size))

	tw.tween_method(_fly_bloom_step.bind(spr, from_center, bloom_size), 
		0.0, 1.0, CUP_BLOOM_DUR).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tw.tween_method(_fly_move_step.bind(spr, from_center, hold_from, bloom_size), 
		0.0, 1.0, CUP_FLY_RISE_DUR).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tw.tween_callback(_play_hover_particles.bind(spr, bloom_size))

	tw.tween_method(_fly_move_step.bind(spr, hold_from, lift_center, bloom_size), 
		0.0, 1.0, CUP_FLY_HOLD_DUR).set_trans(Tween.TRANS_LINEAR)


	_append_cup_flight_sound(tw, preview_only, slot)
	tw.parallel().tween_method(_fly_to_slot_step.bind(spr, lift_center, bloom_size, slot, tex), 
		0.0, 1.0, CUP_FLY_DUR).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	var rec: Dictionary = {"tw": tw, "spr": spr, "slot": slot, "tex": tex, "tint": tint, 
		"color_slot": color_slot, "preview_only": preview_only, 
		"preview_color_slot": _progress_full_slot}
	_cup_flights.append(rec)


	tw.finished.connect(_on_cup_flight_finished.bind(rec), CONNECT_ONE_SHOT)





func _play_pot_petals(center: Vector2, pot_size: Vector2, tint: Color, preview_only: bool = false, 
		color_slot: int = -1) -> void :
	if _fly_layer == null or _board == null or _board.rope_petal_texture == null:
		return
	var p: CPUParticles2D = _pot_petal_acquire()
	if preview_only:
		_progress_full_petal = p
	var feather: Texture2D = _skin_resources.color_texture(JuiceTheme.COLOR_KEYS[color_slot], &"feather")\
	if _skin_resources != null and color_slot >= 0 and color_slot < JuiceTheme.COLOR_KEYS.size() else null
	var tex: Texture2D = feather if feather != null else _board.rope_petal_texture
	(p.material as CanvasItemMaterial).particles_animation = feather == null
	p.texture = tex
	p.position = center
	p.visible = true
	p.modulate = Color.WHITE if feather != null else tint
	p.amount = POT_PETAL_AMOUNT
	p.explosiveness = 1.0
	p.lifetime = POT_PETAL_LIFETIME
	p.lifetime_randomness = 0.3

	p.emission_sphere_radius = maxf(1.0, pot_size.x * 0.4)
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.gravity = Vector2(0.0, pot_size.x * 1.2)
	p.initial_velocity_min = pot_size.x * 0.9
	p.initial_velocity_max = pot_size.x * 2.0
	p.damping_min = pot_size.x * 0.8
	p.damping_max = pot_size.x * 1.4
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0

	var cell_px: float = maxf(1.0, float(tex.get_width()) * (1.0 if feather != null else 0.5))

	p.anim_speed_min = 0.0
	p.anim_speed_max = 0.0
	p.anim_offset_min = 0.0
	p.anim_offset_max = 1.0
	p.scale_amount_min = pot_size.x * 0.12 / cell_px
	p.scale_amount_max = pot_size.x * 0.22 / cell_px
	p.restart()
	p.emitting = true


func _pot_petal_acquire() -> CPUParticles2D:
	var p: CPUParticles2D = _pot_petal_pool.pop_back() if not _pot_petal_pool.is_empty() else _pot_petal_make()
	if p.get_parent() != _fly_layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		_fly_layer.add_child(p)
	return p


func _pot_petal_make() -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	var material: = CanvasItemMaterial.new()
	material.particles_animation = true
	material.particles_anim_h_frames = 2
	material.particles_anim_v_frames = 2
	material.particles_anim_loop = false
	p.material = material
	p.emitting = false
	p.one_shot = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE

	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.add_point(0.6, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.finished.connect(_pot_petal_release.bind(p))
	return p


func _pot_petal_release(p: CPUParticles2D) -> void :
	if p == null or not is_instance_valid(p):
		return
	if p == _progress_full_petal:
		_progress_full_petal = null
	p.emitting = false
	p.visible = false
	if p.get_parent() != null:
		p.get_parent().remove_child(p)
	if not _pot_petal_pool.has(p):
		_pot_petal_pool.append(p)



func _fly_reveal(spr: SpineSprite) -> void :
	if is_instance_valid(spr):
		spr.visible = true



func _fly_bloom_step(u: float, spr: SpineSprite, center: Vector2, sz: Vector2) -> void :
	if not is_instance_valid(spr):
		return
	spr.modulate.a = clampf(u, 0.0, 1.0)
	_fly_place(spr, center, sz * lerpf(CUP_BLOOM_FROM, 1.0, u), -1.0, _fly_collection_display_scale())



func _fly_move_step(u: float, spr: SpineSprite, from_c: Vector2, to_c: Vector2, sz: Vector2) -> void :
	if not is_instance_valid(spr):
		return
	_fly_place(spr, from_c.lerp(to_c, u), sz, -1.0, _fly_collection_display_scale())




func _fly_to_slot_step(u: float, spr: SpineSprite, lift_c: Vector2, from_sz: Vector2, slot: int, 
		tex: Texture2D) -> void :
	if not is_instance_valid(spr) or _fly_layer == null:
		return
	var dst: Rect2 = _quota.cup_global_rect(slot, tex)


	var dst_size: Vector2 = dst.size * CUP_FLY_SPINE_LANDING_SCALE
	var dst_center: Vector2 = _cup_fly_landing_center(dst, dst_size, from_sz.x, tex)


	_fly_place(spr, lift_c.lerp(dst_center, u), from_sz.lerp(dst_size, u), from_sz.x, 
		lerpf(_fly_collection_display_scale(), 1.0, u))



	var hover_p: Variant = _hover_particle_by_spr.get(spr)
	if hover_p != null and is_instance_valid(hover_p):
		(hover_p as CPUParticles2D).emission_sphere_radius = lerpf(
			CUP_BLOOM_HOVER_EMISSION_RADIUS, CUP_BLOOM_HOVER_EMISSION_RADIUS_LANDING, u)



func _cup_fly_landing_center(dst: Rect2, dst_size: Vector2, ref_width: float, icon: Texture2D = null) -> Vector2:
	var bottom_v: float = _quota.icon_bottom_ratio(icon) if icon != null else CUP_FLY_STATIC_POT_BOTTOM_V
	var bottom_center: Vector2 = _fly_layer.to_local(dst.position + dst.size * Vector2(0.5, bottom_v))
	var spine_scale: float = dst_size.x / (_skin_resources.animation().reference_width if _skin_resources != null else CUP_FLY_SPINE_BBOX_W)
	var offset_y: float = (_skin_resources.animation().offset_y if _skin_resources != null else CUP_FLY_SPINE_Y_OFFSET) * (dst_size.x / ref_width if ref_width > 0.0 else 1.0)
	return bottom_center - (_skin_resources.animation().bottom_center if _skin_resources != null else CUP_FLY_SPINE_POT_BOTTOM_CENTER) * spine_scale - Vector2(0.0, offset_y)



func _fly_collection_display_scale() -> float:
	return _skin_resources.animation().collection_display_scale if _skin_resources != null else 1.0





func _fly_place(spr: SpineSprite, center: Vector2, size: Vector2, ref_size_x: float = -1.0, 
		display_scale: float = 1.0) -> void :










	var ref: float = ref_size_x if ref_size_x > 0.0 else size.x
	var offset_y: float = (_skin_resources.animation().offset_y if _skin_resources != null else CUP_FLY_SPINE_Y_OFFSET) * (size.x / ref if ref > 0.0 else 1.0)
	spr.position = center + Vector2(0.0, offset_y)
	var s: float = size.x / (_skin_resources.animation().reference_width if _skin_resources != null else CUP_FLY_SPINE_BBOX_W)
	spr.scale = Vector2(s, s) * display_scale
	if display_scale != 1.0:

		var bottom: Vector2 = _skin_resources.animation().bottom_center if _skin_resources != null else CUP_FLY_SPINE_POT_BOTTOM_CENTER
		spr.position -= bottom * s * (display_scale - 1.0)



	var hover_p: Variant = _hover_particle_by_spr.get(spr)
	if hover_p != null and is_instance_valid(hover_p):
		(hover_p as CPUParticles2D).position = spr.position + CUP_BLOOM_HOVER_OFFSET



	var butterflies: Variant = _butterflies_by_spr.get(spr)
	if butterflies != null:
		var shrink: float = size.x / ref if ref > 0.0 else 1.0
		var now_ms: int = Time.get_ticks_msec()
		for entry in (butterflies as Array):
			var node: SpineSprite = entry["node"]
			if is_instance_valid(node):


				var t: float = float(now_ms - int(entry["spawn_ms"])) / 1000.0
				var u: float = clampf(t / CUP_BUTTERFLY_ARRIVE_DUR, 0.0, 1.0)
				var eased: float = 1.0 - pow(1.0 - u, 3.0)
				var cur_offset: Vector2 = (entry["start_offset"] as Vector2).lerp(
					entry["end_offset"] as Vector2, eased)
				node.position = spr.position + cur_offset * shrink
				var bfly_s: float = float(entry["base_scale"]) * shrink
				node.scale = Vector2(
					bfly_s * (-1.0 if bool(entry.get("flip_x", false)) else 1.0), bfly_s)





func _on_sunlight_collector_landed(nth: int) -> void :
	_quota.push_sunlight_round_cup(nth, _board.sunlight_full_blender_texture, JuiceTheme.SUN_COLOR)
	_play_major_sound(&"juice_quota", false, nth)
	_play_game_haptic(HapticManager.Event.CUP_DONE)


func _on_cup_flight_finished(rec: Dictionary) -> void :
	_cup_flights.erase(rec)
	var gift_visual: JuiceRankGiftFlight = rec.get("gift_visual") as JuiceRankGiftFlight
	var bird_visual: JuiceBirdCollection = rec.get("bird_visual") as JuiceBirdCollection
	if is_instance_valid(gift_visual):
		gift_visual.reset_now()
		gift_visual.queue_free()
	elif is_instance_valid(bird_visual):
		bird_visual.remove_door()
		bird_visual.hide()
		bird_visual.queue_free()
	else:
		var spr: SpineSprite = rec["spr"] as SpineSprite
		if _rules_guide_round:
			_fly_release(spr)
		else:
			_fly_play_end_anim(spr)
	var tex: Texture2D = rec["tex"] as Texture2D
	var tint: Color = rec["tint"] as Color
	if is_endless() and not _quota.is_endless_slot_retained(int(rec["slot"])):
		return
	if bool(rec.get("preview_only", false)):
		_quota.show_preview_cup(tex, tint, int(rec["slot"]))
		var color_slot: int = int(rec["preview_color_slot"])
		if color_slot < 0:
			_progress_bling.play_excellent(_progress_bling.normal_ripple_color(int(rec["color_slot"])))
		else:
			_progress_bling.play_normal(color_slot)
		_progress_full_timer.start(ProgressBling.TOTAL_DURATION + ProgressBling.PREVIEW_GAP)
	else:
		if not is_endless() and (_board.level().has_sunlight() or rec.has("gift_visual")
				or is_instance_valid(bird_visual) or _rank_collectible_type >= 0):
			_quota.push_sunlight_round_cup(int(rec["slot"]), tex, tint)
		else:
			_quota.push_cup(tex, tint, false, int(rec["slot"]))



	if _fly_layer != null and not _rules_guide_round:
		var dst: Rect2 = _quota.cup_global_rect(rec["slot"] as int, tex)
		var dst_center: Vector2 = _fly_layer.to_local(dst.position + dst.size * 0.5)
		_play_bloom_particles(dst_center, dst.size, CUP_BLOOM_LANDING_LIFETIME, 
			CUP_BLOOM_LANDING_SPEED_RATIO, CUP_BLOOM_LANDING_SIZE_RATIO, 
			CUP_BLOOM_LANDING_EXPLOSIVENESS, CUP_BLOOM_PARTICLE_AMOUNT_MIN, 
			CUP_BLOOM_PARTICLE_AMOUNT_MAX)



func _cancel_cup_flights() -> void :
	_combo_sfx_counts.clear()
	if is_instance_valid(_board):
		_board.cancel_sunlight_animation()
		_board.cancel_bird_collections()
	_stop_progress_full_preview()
	_progress_bling.hide_now()
	for rec: Dictionary in _cup_flights:
		var tw: Tween = rec["tw"] as Tween
		if tw != null and tw.is_valid():
			tw.kill()
		var bird_visual: JuiceBirdCollection = rec.get("bird_visual") as JuiceBirdCollection
		var gift_visual: JuiceRankGiftFlight = rec.get("gift_visual") as JuiceRankGiftFlight
		if is_instance_valid(gift_visual):
			gift_visual.reset_now()
			gift_visual.queue_free()
		elif is_instance_valid(bird_visual):
			bird_visual.hide()
			bird_visual.queue_free()
		else:
			_fly_release(rec["spr"] as SpineSprite)
	_cup_flights.clear()




func _has_cup_flights() -> bool:
	return not _cup_flights.is_empty() or _bonus_pot_collecting or (_bonus_pig_hud != null and _bonus_pig_hud.is_flying())



func _wait_cup_flights() -> void :
	var deadline: int = Time.get_ticks_msec() + int(CUP_FLY_WAIT_CAP * 1000.0)
	while not _cup_flights.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _exit_tree() -> void :
	_teardown_root_swap_guide()
	_reset_time_bonus()
	if is_endless():
		stop_endless()
		var pools: Array = [_fly_pool, _bloom_pool, _pot_petal_pool, _hover_pool]
		pools.append_array(_butterfly_pools)
		for pool: Array in pools:
			for node: Node in pool:
				if is_instance_valid(node) and node.get_parent() == null:
					node.free()
			pool.clear()
	if is_instance_valid(_long_link_feedback):
		_long_link_feedback.hide_now()

	HapticManager.cancel_event(_win_coin_haptic)






func _fly_acquire(color_slot: int) -> SpineSprite:
	var spr: SpineSprite = _fly_pool.pop_back() if not _fly_pool.is_empty() else _make_fly_spine()


	var brightness: float = JuiceFruit.get_debug_flower_brightness()
	spr.self_modulate = Color(brightness, brightness, brightness, 1.0)
	spr.modulate = Color.WHITE
	var skel: SpineSkeleton = spr.get_skeleton()
	if skel != null:





		skel.set_skin_by_name((_skin_resources.animation().skin_prefix if _skin_resources != null else "flower_") + _fly_spine_color_key(color_slot))






		skel.set_to_setup_pose()
		_fly_spine_hide_other_colors(skel, color_slot)
	var anim: SpineAnimationState = spr.get_animation_state()
	if anim != null:
		anim.clear_tracks()


		anim.set_animation(_skin_resources.animation().get_animation if _skin_resources != null else CUP_FLY_SPINE_ANIM, false, 0)
		anim.add_animation(_skin_resources.animation().idle_animation if _skin_resources != null else CUP_FLY_SPINE_IDLE_ANIM, 0.0, true, 0)












	if anim != null and skel != null:
		anim.update(0.0)
		anim.apply(skel)
		skel.update_world_transform(SpineConstant.Physics_Update)



	spr.visible = false
	if spr.get_parent() != _fly_layer:
		if spr.get_parent() != null:
			spr.get_parent().remove_child(spr)
		_fly_layer.add_child(spr)
	return spr




func _make_fly_spine() -> SpineSprite:
	return (_skin_resources.animation().scene if _skin_resources != null else CUP_FLY_SPINE_SCENE).instantiate() as SpineSprite






func _fly_spine_hide_other_colors(skel: SpineSkeleton, color_slot: int) -> void :
	var key: String = _fly_spine_color_key(color_slot)
	var prefixes: PackedStringArray = _skin_resources.animation().slot_prefixes if _skin_resources != null else PackedStringArray(["pen_", "flower_"])
	for slot: SpineSlot in skel.get_slots():
		var name_lower: String = slot.get_data().get_name().to_lower()
		for prefix: String in prefixes:
			if name_lower.begins_with(prefix.to_lower()) and name_lower != (prefix + key).to_lower():
				var color: Color = slot.get_color()
				color.a = 0.0
				slot.set_color(color)


func _fly_spine_color_key(color_slot: int) -> String:
	var keys: PackedStringArray = _skin_resources.animation().color_keys if _skin_resources != null else PackedStringArray(CUP_FLY_SPINE_COLOR_KEYS)
	return keys[color_slot] if color_slot >= 0 and color_slot < keys.size() else keys[0]


func _fly_play_end_anim(spr: SpineSprite) -> void :
	if spr == null or not is_instance_valid(spr):
		return

	if spr.get_parent() != _quota:
		spr.reparent(_quota, true)
	var anim: SpineAnimationState = spr.get_animation_state()
	if anim != null:
		anim.clear_tracks()
		anim.set_animation(_skin_resources.animation().end_animation if _skin_resources != null else CUP_FLY_SPINE_END_ANIM, false, 0)
	var tw: Tween = spr.create_tween()
	_fly_end_tweens[spr] = tw
	tw.tween_interval(CUP_FLY_SPINE_END_DUR)
	tw.tween_callback(_fly_release.bind(spr))


func _fly_release(spr: SpineSprite) -> void :
	if spr == _progress_full_sprite:
		_progress_full_sprite = null
	if spr == null or not is_instance_valid(spr):
		return
	var end_tw: Tween = _fly_end_tweens.get(spr) as Tween
	if end_tw != null and end_tw.is_valid():
		end_tw.kill()
	_fly_end_tweens.erase(spr)



	var hover_p: Variant = _hover_particle_by_spr.get(spr)
	if hover_p != null and is_instance_valid(hover_p):
		_hover_particles_release(hover_p as CPUParticles2D)
	_hover_particle_by_spr.erase(spr)


	var butterflies: Variant = _butterflies_by_spr.get(spr)
	if butterflies != null:
		for entry in (butterflies as Array):
			_butterfly_release(entry["node"] as SpineSprite, int(entry["variant"]))
	_butterflies_by_spr.erase(spr)
	var anim: SpineAnimationState = spr.get_animation_state()
	if anim != null:
		anim.clear_tracks()
	spr.visible = false
	if spr.get_parent() != null:
		spr.get_parent().remove_child(spr)
	if not _fly_pool.has(spr):
		_fly_pool.append(spr)




func _hover_particles_acquire(spr: SpineSprite) -> CPUParticles2D:
	var p: CPUParticles2D = _hover_pool.pop_back() if not _hover_pool.is_empty() else _hover_particles_make()


	if p.get_parent() != _fly_layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		if _fly_layer != null:
			_fly_layer.add_child(p)
	_hover_particle_by_spr[spr] = p


	p.position = spr.position + CUP_BLOOM_HOVER_OFFSET
	return p




func _hover_particles_make() -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	p.texture = _skin_resources.effect_texture(&"cup_bloom", CUP_BLOOM_PARTICLE_TEX) if _skin_resources != null else CUP_BLOOM_PARTICLE_TEX
	p.emitting = false
	p.one_shot = false


	p.amount = roundi(CUP_BLOOM_HOVER_RATE * CUP_BLOOM_HOVER_LIFETIME)
	p.gravity = Vector2.ZERO
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.damping_min = CUP_BLOOM_PARTICLE_DAMPING_MIN
	p.damping_max = CUP_BLOOM_PARTICLE_DAMPING_MAX
	p.scale_amount_curve = _make_bloom_scale_curve()

	return p


func _hover_particles_release(p: CPUParticles2D) -> void :
	if p == null or not is_instance_valid(p):
		return
	p.emitting = false
	p.visible = false
	if p.get_parent() != null:
		p.get_parent().remove_child(p)
	if not _hover_pool.has(p):
		_hover_pool.append(p)





func _butterfly_acquire(variant: int) -> SpineSprite:
	var pool: Array = _butterfly_pools[variant]
	var node: SpineSprite = pool.pop_back() if not pool.is_empty()\
	else ((_skin_resources.butterfly_scene(variant, CUP_BUTTERFLY_SCENES[variant]) if _skin_resources != null else CUP_BUTTERFLY_SCENES[variant]).instantiate() as SpineSprite)
	if node.get_parent() != _fly_layer:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		if _fly_layer != null:
			_fly_layer.add_child(node)
	return node



func _butterfly_release(node: SpineSprite, variant: int) -> void :
	if node == null or not is_instance_valid(node):
		return
	var anim: SpineAnimationState = node.get_animation_state()
	if anim != null:
		anim.clear_tracks()
	node.visible = false
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	var pool: Array = _butterfly_pools[variant]
	if not pool.has(node):
		pool.append(node)







func _play_pot_butterflies(spr: SpineSprite, bloom_size: Vector2) -> void :
	if _skin_resources != null and not _skin_resources.collection_butterflies_enabled():
		return
	if spr == null or not is_instance_valid(spr) or _fly_layer == null:
		return
	var count: int = randi_range(CUP_BUTTERFLY_COUNT_MIN, CUP_BUTTERFLY_COUNT_MAX)
	var entries: Array = []
	var now_ms: int = Time.get_ticks_msec()
	for _i in count:
		var variant: int = randi() % CUP_BUTTERFLY_SCENES.size()
		var node: SpineSprite = _butterfly_acquire(variant)



		var center_y: float = bloom_size.y * (CUP_BUTTERFLY_SCATTER_Y_MIN_RATIO
			+ CUP_BUTTERFLY_SCATTER_Y_MAX_RATIO) * 0.5
		var semi_x: float = bloom_size.x * CUP_BUTTERFLY_SCATTER_X_RATIO
		var semi_y: float = bloom_size.y * (CUP_BUTTERFLY_SCATTER_Y_MAX_RATIO
			- CUP_BUTTERFLY_SCATTER_Y_MIN_RATIO) * 0.5
		var angle: float = randf_range(0.0, TAU)
		var end_offset: = Vector2(cos(angle) * semi_x, center_y + sin(angle) * semi_y)
		end_offset.y -= CUP_BUTTERFLY_Y_LIFT


		var away_dir: Vector2 = Vector2(cos(angle) * semi_x, sin(angle) * semi_y).normalized()
		var start_offset: Vector2 = end_offset + away_dir * randf_range(
			CUP_BUTTERFLY_ARRIVE_DIST_MIN, CUP_BUTTERFLY_ARRIVE_DIST_MAX)

		var base_scale: float = bloom_size.x * CUP_BUTTERFLY_SIZE_RATIO / CUP_BUTTERFLY_BBOX_W[variant] * randf_range(1.0 - CUP_BUTTERFLY_SIZE_RAND, 1.0)


		var flip_x: bool = end_offset.x > 0.0
		node.position = spr.position + start_offset
		node.scale = Vector2(base_scale * (-1.0 if flip_x else 1.0), base_scale)
		node.visible = true
		node.modulate = Color.WHITE
		var anim: SpineAnimationState = node.get_animation_state()
		if anim != null:
			anim.clear_tracks()
			anim.set_animation(CUP_BUTTERFLY_ANIMS[variant], true, 0)
		entries.append({
			"node": node, "variant": variant, "start_offset": start_offset, 
			"end_offset": end_offset, "base_scale": base_scale, "flip_x": flip_x, "spawn_ms": now_ms, 
		})
	_butterflies_by_spr[spr] = entries








func _play_hover_particles(spr: SpineSprite, bloom_size: Vector2) -> void :
	var p: CPUParticles2D = _hover_particles_acquire(spr)
	p.visible = true
	p.modulate = CUP_BLOOM_PARTICLE_GOLD
	p.lifetime = CUP_BLOOM_HOVER_LIFETIME
	p.lifetime_randomness = CUP_BLOOM_PARTICLE_LIFETIME_RANDOMNESS







	p.emission_sphere_radius = CUP_BLOOM_HOVER_EMISSION_RADIUS
	var tex_w: float = maxf(1.0, float(p.texture.get_width()))
	var scale_base: float = bloom_size.x * CUP_BLOOM_PARTICLE_SIZE_RATIO / tex_w
	p.scale_amount_min = scale_base * (1.0 - CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)
	p.scale_amount_max = scale_base * (1.0 + CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)
	var speed: float = bloom_size.x * CUP_BLOOM_HOVER_SPEED_RATIO
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.restart()
	p.emitting = true




func _bloom_particles_acquire() -> CPUParticles2D:
	var p: CPUParticles2D = _bloom_pool.pop_back() if not _bloom_pool.is_empty() else _bloom_particles_make()
	if p.get_parent() != _fly_layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		_fly_layer.add_child(p)
	return p





func _make_bloom_scale_curve() -> Curve:
	var c: = Curve.new()
	c.add_point(Vector2(0.0, 0.0), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	c.add_point(Vector2(0.2, 1.0), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	c.add_point(Vector2(0.5, 1.0), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	c.add_point(Vector2(1.0, 0.1), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return c





func _bloom_particles_make() -> CPUParticles2D:
	var p: = CPUParticles2D.new()
	p.texture = _skin_resources.effect_texture(&"cup_bloom", CUP_BLOOM_PARTICLE_TEX) if _skin_resources != null else CUP_BLOOM_PARTICLE_TEX
	p.emitting = false
	p.one_shot = true


	p.gravity = Vector2.ZERO
	p.direction = Vector2(0.0, -1.0)
	p.spread = 180.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.damping_min = CUP_BLOOM_LANDING_DAMPING_MIN
	p.damping_max = CUP_BLOOM_LANDING_DAMPING_MAX
	p.scale_amount_curve = _make_bloom_scale_curve()

	p.finished.connect(_bloom_particles_release.bind(p))
	return p


func _bloom_particles_release(p: CPUParticles2D) -> void :
	if p == null or not is_instance_valid(p):
		return
	p.visible = false
	if p.get_parent() != null:
		p.get_parent().remove_child(p)
	if not _bloom_pool.has(p):
		_bloom_pool.append(p)








func _play_bloom_particles(center: Vector2, size: Vector2, lifetime: float, 
		speed_ratio: float, size_ratio: float, explosiveness: float, amount_min: int, 
		amount_max: int) -> void :
	if _fly_layer == null:
		return
	var p: CPUParticles2D = _bloom_particles_acquire()
	p.position = center
	p.visible = true
	p.modulate = CUP_BLOOM_PARTICLE_GOLD
	p.amount = randi_range(amount_min, amount_max)
	p.explosiveness = explosiveness
	p.lifetime = lifetime
	p.lifetime_randomness = CUP_BLOOM_PARTICLE_LIFETIME_RANDOMNESS
	p.emission_sphere_radius = maxf(1.0, size.x * 0.5)
	var tex_w: float = maxf(1.0, float(p.texture.get_width()))
	var scale_base: float = size.x * size_ratio / tex_w

	p.scale_amount_min = scale_base * (1.0 - CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)
	p.scale_amount_max = scale_base * (1.0 + CUP_BLOOM_PARTICLE_SIZE_RANDOMNESS * 0.5)








	var speed: float = size.x * speed_ratio
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.restart()
	p.emitting = true








func _on_error_feedback_requested(reason: int) -> void :
	if reason not in [R.Reject.COLOR, R.Reject.FULL, R.Reject.MYSTERY, R.Reject.FROZEN]:
		return
	ABManager.dye_at_error_animation()
	_board.set_new_error_animation_enabled(ABManager.error_animation.is_new_error_animation_enabled())


func _on_move_rejected(reason: int) -> void :
	if reason in [R.Reject.FULL, R.Reject.COLOR, R.Reject.LOCKED, R.Reject.MYSTERY, R.Reject.FROZEN]:
		_combo_steps += 1
		_count_early_wrong_drag()
	HapticManager.play_event(HapticManager.Event.MOVE_REJECTED)
	match reason:
		R.Reject.FULL:
			var new_feedback: bool = ABManager.error_animation.is_new_error_animation_enabled()
			var values: Dictionary = {"x": _board.rejected_target_space()} if new_feedback else {}
			_show_error_toast("JUICE_TUTOR_WHY_FULL", values)

			if new_feedback:
				_board.show_capacity_error_hint(0.9)
		R.Reject.COLOR:
			_show_error_toast("JUICE_TUTOR_WHY_COLOR")
		R.Reject.LOCKED:
			_show_error_toast("JUICE_TOAST_LOCKED_DROP")
		R.Reject.MYSTERY:
			_show_error_toast("JUICE_TOAST_MYSTERY_EMPTY_ONLY")




func _show_error_toast(text_key: String, values: Dictionary = {}) -> void :
	if _rules_guide_round and _is_legacy_tutorial():
		return
	var display_key: String = text_key
	if text_key == "JUICE_TUTOR_WHY_FULL" and values.has("x"):
		display_key = "JUICE_TOAST_ROPE_FULL" if int(values["x"]) == 0 else "JUICE_TOAST_ROPE_SPACE"
	if _skin_resources != null:
		display_key = _skin_resources.toast_key(display_key)
	SceneManager.show_toast(tr(display_key).format(values))





func _count_early_wrong_drag() -> void :
	if _level_model == null or _level_model.level_id > EARLY_WRONG_DRAG_MAX_LEVEL:
		return
	_early_wrong_drags += 1
	if _early_wrong_drags < EARLY_WRONG_DRAG_TRIGGER:
		return
	if _try_auto_hint():
		_early_wrong_drags = 0




func _try_auto_hint() -> bool:
	if _win_committed or _opening_banner_input_locked or _sunlight_guide_running or not _playfield_ready:
		return false
	if not _hint_solvable() or _board.has_active_hint() or _hint_task_id != HINT_TASK_NONE\
	or not _root_hint_pending_key.is_empty():
		return false
	var cached: Dictionary = _hint_try_sync()
	if cached.is_empty():
		_hint_dispatch(true)
		return _hint_task_id != HINT_TASK_NONE or not _root_hint_pending_key.is_empty()
	return _show_hint_on_board(cached)



func _on_move_blocked(_src: int, _j: int, _dst: int) -> void :
	HapticManager.play_event(HapticManager.Event.MOVE_REJECTED)


func _on_blank_dropped() -> void :
	_combo_steps += 1



func _on_locked_grabbed(_col: int) -> void :
	HapticManager.play_event(HapticManager.Event.MOVE_REJECTED)
	_show_error_toast("JUICE_TOAST_LOCKED_GRAB")




func _on_board_won() -> void :
	_teardown_root_swap_guide(true)
	if _is_legacy_tutorial():
		UserState.set_tutorial_done(true)
	if is_endless():
		return
	_freeze_complete_sounds()
	_stop_undo_guide_motion_preview()
	_hide_challenge_banner()
	if not is_special_challenge():
		_iq_complete_sound_pending = _iq_round.enabled
		if not _iq_complete_sound_pending:
			_play_complete_sound()
	_play_game_haptic(HapticManager.Event.LEVEL_WIN)




	_teardown_tutorial()
	_tutorial_active = false

	_teardown_mystery_guide()


	_close_lock_guide_now()
	_close_sunlight_guide_now()


	await _wait_cup_flights()
	await _run_game_end_flow()











func _run_game_end_flow() -> void :
	if _end_flow_running:
		return
	request_finish_preparation()
	_end_flow_running = true
	_end_flow_generation += 1
	var generation: int = _end_flow_generation
	if is_special_challenge():
		_board.set_input_enabled(false)
		_back_btn.disabled = true
		_set_reset_buttons_disabled(true)
		while visible and generation == _end_flow_generation and not _win_committed:
			_commit_win_data_once()
			if not _win_committed:
				await get_tree().create_timer(0.5).timeout
		if not visible or generation != _end_flow_generation:
			return
	while visible and generation == _end_flow_generation and not _win_committed:
		_commit_win_data_once()
		if not _win_committed:
			await get_tree().create_timer(0.5).timeout
	if not visible or generation != _end_flow_generation:
		return
	var active: Callable = func() -> bool: return visible and generation == _end_flow_generation

	while active.call() and _combo_frequency_wait_before_end and _combo_feedback.is_playing():
		await get_tree().process_frame
	if not active.call():
		return
	while active.call():
		if await _prepare_round_end(active):
			break
		if not active.call():
			return
		SortLogger.error("GamePage: 结束特效准备失败，保留盘面并重试")
		await get_tree().create_timer(0.5).timeout
	if not active.call():
		return
	var won_level: int = _level_model.level_id if _level_model != null else 0
	await GameEndFlow.run(self, won_level)
	if generation == _end_flow_generation:
		_end_flow_running = false








func _reset_end_flow_state() -> void :
	_cancel_finish_ad_reward()
	if _iq_genius_feedback != null:
		_iq_genius_feedback.hide_now()
	_finish_ad_busy_generation += 1
	_finish_ad_reward_enabled = false
	_finish_game_data_enabled = false
	_finish_use_new_result_data = false
	_finish_iq_replacement_metric = ""
	_finish_record_improvements.clear()
	_iq_genius_shown = false
	_iq_complete_sound_pending = false
	_level_complete_sound_id = &"level_complete"
	_finish_cart_appear_sound_id = &"finish_cart_appear"
	_finish_ad_busy = false
	_finish_interstitial_busy = false
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	_end_flow_generation += 1
	_end_flow_running = false
	_flowers_faded = false
	_complete_shown = false
	_next_pressed = false

	_back_btn.disabled = false
	_set_reset_buttons_disabled(false)
	_board.set_input_enabled(true)



func hide_complete_panel_now() -> void :
	_hide_timed_reward_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	_cancel_finish_ad_reward()
	if _complete_panel == null:
		return
	if _complete_panel.has_method("hide_panel"):

		_complete_panel.call("hide_panel")
	else:
		SceneManager.hide_dlg("finish")


func _on_board_dead(reason: String) -> void :
	_teardown_root_swap_guide(true)
	if is_endless():
		if _board.can_play_after_dead():
			_hint_cancel()
			_reset_hint_guide(true)
			_clear_hint_guide_motion(true)
			SceneManager.show_dlg("game_dead_toast", {"hint_unwinnable": false})
			_sync_dead_prop_glows()
			_refresh_prop_btns()
		return
	if bool(_board.state().get("allow_root_swapping", false)):
		_hint_cancel()
	_long_link_feedback.hide_now()
	_stop_progress_full_preview()
	_stop_undo_guide_motion_preview()
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	_combo_feedback.hide_now()
	_empty_col_feedback.hide_now()
	_hide_challenge_banner()

	if not is_special_challenge():
		UserState.mark_current_level_dirty()


	_save_progress("dead")
	_inc_level_counter("dead_times")
	report_game_over()

	ABManager.dye_at_dead_revive_prompt()
	var progress: Vector2i = _board.pot_progress() if _board != null else Vector2i.ZERO
	SceneManager.show_dlg("game_dead_toast", {
		"hint_unwinnable": reason == JuiceBoardView.HINT_UNWINNABLE_REASON, 
		"revive_prompt_redesigned": ABManager.revive_prompt_style.is_revive_prompt_redesigned(), 
		"filled_pots": progress.x, 
		"target_pots": progress.y})
	_sync_dead_prop_glows()
	_refresh_prop_btns()


func _on_board_dead_attributed(_attribution: int, _reason: String, _steps: int) -> void :
	if _board != null and _board.over() == "dead":
		_sync_dead_prop_glows()
		_refresh_prop_btns(true)



func _on_board_revealed_undo_touched() -> void :
	ABManager.dye_at_reveal_memory()



func _on_board_lucky_reveal_detected(_cells: Array) -> void :
	if _board == null or _board.over() != "":
		return
	if _tutorial_active:
		SortLogger.info("[LuckyReveal] 判中但不提示:新手教学局")
		return

	if _last_move_gap_msec <= GOOD_LUCK_MIN_MOVE_GAP_MSEC:
		SortLogger.info("[LuckyReveal] 判中但不提示:距上一步 %dms,需超过 %dms" % [
			_last_move_gap_msec, GOOD_LUCK_MIN_MOVE_GAP_MSEC])
		return
	_play_good_luck_fx()



func _on_board_challenge_detected(_kind: int, info: Dictionary) -> void :
	if _board == null or _board.over() != "":
		return
	var kind_name: String = String(info.get("kind_name", ""))
	if _tutorial_active:
		SortLogger.info("[Challenge] 判出%s但不提示:新手教学局" % kind_name)
		return
	if _level_model == null or _level_model.level_id < CHALLENGE_MIN_LEVEL:
		SortLogger.info("[Challenge] 判出%s但不提示:第 %d 关起才触发" % [kind_name, CHALLENGE_MIN_LEVEL])
		return
	var link: int = _board.successful_link_count()
	var consecutive: bool = link - _challenge_last_seen_link <= 1
	_challenge_last_seen_link = link
	var key: String = String(info.get("key", ""))
	var skip: String = ""
	if consecutive:
		skip = "上一盘面也判出了关键点(连续只提示第一次)"
	elif link - _challenge_last_shown_link < CHALLENGE_MIN_GAP:
		skip = "距上次提示只隔 %d 步(至少 %d 步)" % [link - _challenge_last_shown_link, CHALLENGE_MIN_GAP]
	elif _challenge_toasted.has(key):
		skip = "这一盘面本局已提示过(撤销回来不重复)"
	if skip != "":
		SortLogger.info("[Challenge] 第%d步 判出%s但不提示:%s" % [int(info.get("steps", 0)), kind_name, skip])
	else:
		_challenge_last_shown_link = link
		_challenge_toasted[key] = true
		_log_challenge_triggered(info)



func _log_challenge_triggered(info: Dictionary) -> void :
	var kind_name: String = String(info.get("kind_name", ""))
	var n: int = int(info.get("n", 0))
	SortLogger.info("[Challenge] ★ 触发 challenge time:%s(第%d步)" % [
		"陷阱点 TRAP" if kind_name == "TRAP" else "妙手点 MASTER", int(info.get("steps", 0))])
	if kind_name == "TRAP":
		var ans: Dictionary = info.get("answer", {})
		SortLogger.info("[Challenge]   局面:推进走法 %d 种,只有 1 种能活,%d 种走完很快卡死;诱惑分 正解 %.1f / 最诱人死路 %.1f" % [
			n, int(info.get("fatal", 0)), float(info.get("appeal_alive", 0.0)), float(info.get("appeal_fatal", 0.0))])
		SortLogger.info("[Challenge]   正解:%s" % _board.describe_move(int(ans["src"]), int(ans["j"]), int(ans["dst"])))
	else:
		SortLogger.info("[Challenge]   局面:推进走法 %d 种%s,要先倒腾 %d 步才有出路" % [
			n, "全部会很快卡死" if n > 0 else "(没有)", int(info.get("depth", -1))])



func _challenge_feedback_snapshot() -> Dictionary:
	return {
		"toasted": _challenge_toasted.keys(), 
		"last_seen": _challenge_last_seen_link, 
		"last_shown": _challenge_last_shown_link, 
	}



func _restore_challenge_feedback(d: Dictionary) -> void :
	_reset_challenge_feedback()
	if d.is_empty():
		return
	for key: Variant in d.get("toasted", []) as Array:
		_challenge_toasted[String(key)] = true
	_challenge_last_seen_link = int(d.get("last_seen", - CHALLENGE_MIN_GAP))
	_challenge_last_shown_link = int(d.get("last_shown", - CHALLENGE_MIN_GAP))







func _reset_challenge_feedback() -> void :
	_long_link_feedback.hide_now()
	_challenge_toasted.clear()
	_challenge_last_seen_link = - CHALLENGE_MIN_GAP
	_challenge_last_shown_link = - CHALLENGE_MIN_GAP
	_hide_challenge_banner()
	_last_move_msec = Time.get_ticks_msec()
	_last_move_gap_msec = 0


func _hide_dead_toast() -> void :
	SceneManager.hide_dlg("game_dead_toast")
	_sync_dead_prop_glows(false)


static func _dead_prop_matches_attribution(key: String, attribution: int) -> bool:
	match attribution:
		S.DeathAttribution.LAST_MOVE:
			return key == "undo"
		S.DeathAttribution.EARLIER:
			return key == "rope"
		S.DeathAttribution.UNKNOWN:
			return key == "rope"
	return false


func _sync_dead_prop_glows(force_dead: Variant = null) -> void :
	if is_endless():
		for ui: Dictionary in _prop_ui.values():
			(ui["btn"] as PropBtn).set_dead_glow(false)
			(ui["btn"] as PropBtn).set_dead_dialog_icon(false)
		return
	var dead_now: bool = (_board != null and _board.over() == "dead")\
	if force_dead == null else bool(force_dead)
	if dead_now:
		_stop_undo_guide_motion_preview()
	var attribution: int = _board.death_attribution()\
	if dead_now and _board != null else S.DeathAttribution.UNKNOWN

	var fill_pot_unlocked: bool = _complete_prop_enabled and _prop_ui.has("fill_pot")\
	and (UserState.get_current_level()
		>= PropBtn.get_unlock_level_by_id("fill_pot")
		or UserState.is_prop_early_unlocked("fill_pot"))
	var fill_pot_mode: bool = dead_now and fill_pot_unlocked
	for key: String in _prop_ui:
		var ui: Dictionary = _prop_ui[key] as Dictionary
		var btn: PropBtn = ui.get("btn") as PropBtn
		if btn != null and is_instance_valid(btn):
			if key == "rope":
				btn.set_dead_dialog_icon(dead_now)
			var unlocked: bool = UserState.get_current_level() >= btn.get_unlock_level() or UserState.is_prop_early_unlocked(key)
			if fill_pot_mode:
				match key:
					"fill_pot":
						btn.set_dead_glow(unlocked)
					"rope":
						btn.set_dead_glow(unlocked and _board != null and not _board.has_rope())
					_:

						btn.set_dead_glow(false)
				continue
			var can_recover: bool = _board != null and (
				(key == "undo" and _board.can_undo())
				or (key == "rope" and not _board.has_rope()))
			btn.set_dead_glow((dead_now and unlocked and can_recover
				and _dead_prop_matches_attribution(key, attribution))
				or ( not dead_now and key == "rope" and _rope_guide_playing))


func _on_board_settled() -> void :
	_refresh_prop_btns()




func _configure_iq_round(saved: Dictionary = {}, resumed: bool = false) -> void :
	if _iq_genius_feedback != null:
		_iq_genius_feedback.hide_now()
	var eligible: bool = _level_model != null\
	and IqRoundModel.is_round_eligible(_level_model.level_id, is_special_challenge(), _bonus_type >= 0)
	var active: bool = eligible and bool(saved.get("enabled", true))
	var score_boost: bool = false
	var use_s_grade: bool = false
	if active and not resumed and saved.is_empty():
		ABManager.dye_at_iq_score_boost()
		score_boost = ABManager.iq_score_boost.is_score_boost_enabled()
		use_s_grade = ABManager.iq_score_boost.should_use_s_grade_guarantee()
	_iq_round.reset(active, 
		_level_model.juice.groups_total if _level_model != null else 0, 
		int(_board.state().get("done", 0)), saved, score_boost, use_s_grade)
	_refresh_iq_header(false)


func _refresh_iq_header(animate: bool = true) -> void :
	if is_endless():
		_refresh_endless_hud()
		return
	if _iq_progress == null:
		return
	_iq_progress.visible = _iq_round.enabled
	_iq_progress.set_score_boost_enabled(_iq_round.score_boost_enabled)
	_level_label.visible = true
	_quota.set_iq_layout_enabled(_iq_round.enabled)
	_iq_progress.set_iq(_iq_round.value(), animate)
	_layout_quota()



func _layout_iq_header() -> void :
	if _iq_progress == null:
		return
	_iq_progress.size = Vector2(IqProgressBar.DESIGN_WIDTH, IqProgressBar.DESIGN_HEIGHT)
	_iq_progress.position = Vector2((_quota.size.x - IqProgressBar.DESIGN_WIDTH) * 0.5, 
		-63.0 if _rules_guide_round else JuiceQuotaBar.PANEL_Y - 126.0)
	if is_endless():
		_layout_endless_timer()
	if _hard_badge != null:
		_hard_badge.position.y = 76.0



func _finalize_iq_win() -> Dictionary:
	var pending: Dictionary = UserState.get_pending_iq_completion(_level_model.level_id)
	if pending.has("final_iq"):
		_iq_round.restore_completion(pending)
		_refresh_iq_header()
		return pending
	_iq_round.on_move(int(_board.state().get("done", 0)), [] as Array[int])
	var used_prop: bool = _applying_fill_pot
	for key: String in ["hint", "undo", "rope", "fill_pot"]:
		used_prop = used_prop or int(_tracking_prop_used_round.get(key, 0)) > 0
	var pct: float = -1.0
	var step_pct: float = -1.0
	if _iq_round.enabled:
		var initial: JuiceLevel = _level_model.juice
		pct = ResultPercentileBank.lookup_percentile("time", initial.total_flowers, 
			float(_play_timer.finish_elapsed_ms()) / 1000.0)
		if _iq_round.s_grade_guarantee:
			step_pct = ResultPercentileBank.lookup_percentile("step", initial.total_flowers, 
				float(_board.move_attempt_count()))
	var result: Dictionary = _iq_round.finalize(used_prop, pct, 
		_is_hard_level() or _is_super_hard_level(), UserState.get_iq_rounds_since_guarantee(), Callable(), step_pct)

	result["mainline"] = not is_special_challenge() and _bonus_type < 0
	_refresh_iq_header()
	return result



func show_iq_genius_feedback() -> bool:
	var generation: int = _end_flow_generation
	if not _iq_round.enabled:
		return true

	while visible and generation == _end_flow_generation and not _win_committed:
		await get_tree().process_frame
	if not visible or generation != _end_flow_generation:
		return false
	if _iq_round.value() < _iq_round.genius_iq() or _iq_genius_shown:
		if _iq_complete_sound_pending and not _iq_genius_shown:
			_iq_complete_sound_pending = false
			_play_complete_sound()
		return true
	_iq_genius_shown = true
	_iq_genius_feedback.present()

	while visible and generation == _end_flow_generation and _iq_genius_feedback.is_playing():
		await get_tree().process_frame
	if generation == _end_flow_generation:
		if _iq_genius_feedback != null:
			_iq_genius_feedback.hide_now()
	return visible and generation == _end_flow_generation


func _sync_level_card() -> void :
	if is_endless():
		_level_label.text = tr("TIMED_CHALLENGE_TITLE")

		var title_left: float = maxf(0.0, _back_btn.position.x + _back_btn.size.x + 24.0 - _level_block.position.x)
		var title_right: float = minf(_level_block.size.x, _coin_hud.position.x - 24.0 - _level_block.position.x)
		var title_width: float = maxf(1.0, title_right - title_left)
		var title_font: Font = _level_label.get_theme_font("font")
		var title_size: int = 64
		while title_size > 20 and title_font.get_string_size(_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > title_width:
			title_size -= 1
		_level_label.add_theme_font_size_override("font_size", title_size)
		_level_label.position = Vector2(title_left, 0.0)
		_level_label.size = Vector2(title_width, 76.0)
		_refresh_endless_hud()
		return
	if is_instance_valid(_timer_row):
		_timer_row.hide()
	_reset_time_bonus()
	var special: bool = is_special_challenge()
	if _level_label != null:
		if special:
			_level_label.text = tr("SPECIAL_CHALLENGE_TITLE")
		else:
			_level_label.text = tr("LEVEL_NUM") % UserState.get_current_level()
		var font_size: int = 64
		if special:
			var font: Font = _level_label.get_theme_font("font")
			var max_width: float = _level_block.size.x - _special_challenge_chest.size.x - 16.0
			while font_size > 20 and font.get_string_size(_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
				font_size -= 1
			_level_label.add_theme_font_size_override("font_size", font_size)
			var text_width: float = ceilf(font.get_string_size(_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
			var group_left: float = (_level_block.size.x - _special_challenge_chest.size.x - text_width) * 0.5
			_special_challenge_chest.position = Vector2(group_left, 1.1643)
			_level_label.position = Vector2(group_left + _special_challenge_chest.size.x, 10.0)
			_level_label.size = Vector2(text_width, 76.0)
		else:
			_level_label.add_theme_font_size_override("font_size", font_size)
			_level_label.position = Vector2.ZERO
			_level_label.size = Vector2(_level_block.size.x, 76.0)
	_refresh_iq_header()
	_special_challenge_chest.visible = special and not _special_challenge_banner_pending\
	and _special_challenge_banner != null and not _special_challenge_banner.is_presenting_chest()
	_refresh_hard_badge()
	if _bonus_type >= 0:
		_place_bonus_pig_dock()




func _refresh_hard_badge() -> void :
	if _hard_badge == null or _hard_badge_label == null:
		return

	var is_super: bool = _level_model != null and _is_super_hard_level()
	_hard_badge.visible = _level_model != null and (_is_hard_level() or is_super)
	_hard_badge.modulate.a = 1.0
	if not _hard_badge.visible:
		return
	var badge_text: String = tr("GAME_SUPER_HARD_BANNER_TITLE") if is_super else tr("HOME_HARD_BADGE")
	_hard_badge_label.text = badge_text

	_hard_badge_icon.texture = super_hard_fire_texture if is_super else _hard_fire_texture
	_hard_badge_label.add_theme_color_override("font_color", SUPER_HARD_BADGE_COLOR if is_super else _hard_badge_label_color)
	var font: Font = _hard_badge_label.get_theme_font("font")
	if font == null:
		return
	var max_label_w: float = HARD_BADGE_BLOCK_W - HARD_BADGE_LABEL_LEFT
	var font_size: int = HARD_BADGE_FONT_MAX
	var text_w: float = font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	while text_w > max_label_w and font_size > HARD_BADGE_FONT_MIN:
		font_size -= 2
		text_w = font.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	_hard_badge_label.add_theme_font_size_override("font_size", font_size)
	var label_w: float = minf(maxf(text_w, HARD_BADGE_LABEL_MIN_W), max_label_w)
	var badge_w: float = HARD_BADGE_LABEL_LEFT + label_w
	_hard_badge_label.offset_right = badge_w
	_hard_badge.offset_left = (HARD_BADGE_BLOCK_W - badge_w) * 0.5
	_hard_badge.offset_right = _hard_badge.offset_left + badge_w













func _commit_win_data_once() -> void :
	if is_endless():
		return
	if _tutorial_active and _four_goal_tutorial_round and R.is_win(_board.state(), _board.level()):
		UserState.set_tutorial_done(true)
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)
	if _win_committed:
		return
	if _board.level() == null:
		return
	var st: Dictionary = _board.state()
	if st.is_empty() or (st["cols"] as Array).is_empty():
		return
	if not R.is_win(st, _board.level()):
		return
	_stop_undo_guide_motion_preview()

	var win_game_id: String = _tracking_common.game_id if _tracking_common != null else _round_game_id()
	var checkin_completion: Dictionary = _daily_checkin_round.prepare_win(
		_level_model.level_id, is_special_challenge(), _round_game_id())
	if not _rank_round.commit(_round_game_id()):
		SortLogger.error("[Rank] 通关积分存档失败，等待原对局重试")
		return
	if is_special_challenge():
		_flush_play_time("time_win")
		_play_timer.disarm()
		_won_level_num = UserState.get_current_level()
		if _tracking_common != null and not _tracking_special_state.has("game_end_params"):
			var final_params: Dictionary = _tracking_round_params()
			final_params.erase(TrackingEvents.K_GAME_PROCESS_INFO)
			_tracking_special_state["game_end_params"] = final_params

		if _tracking_common != null and not _persist_special_challenge_tracking():
			return


		_win_committed = LevelManager.complete_special_challenge(_level_model.challenge_instance_id, 
			true, checkin_completion, "win", win_game_id)

		if _win_committed:
			_report_daily_checkin_coins(checkin_completion)
		return
	_won_level_num = _level_model.level_id
	_flush_play_time("time_win")
	_play_timer.disarm()
	if _win_completion_payload.is_empty():
		_win_completion_payload = UserState.get_pending_coin_bonus_completion(_won_level_num)
		if _win_completion_payload.is_empty():
			_win_completion_iq = _finalize_iq_win()
			var initial_lv: JuiceLevel = _level_model.juice
			_finish_record_improvements = UserState.on_win_streak_won(
				initial_lv.total_flowers, _play_timer.finish_elapsed_ms(), _board.move_attempt_count())
			var reward: int = (st["cups"] as Array).size() * _round_target_coins
			if is_coin_bonus_round():
				reward *= 2
			_win_completion_payload = {"assignment": _level_model.coin_bonus_rule.duplicate(true), 
				"coins": reward, "before": UserState.get_coins(), 
				"bonus_coins": JuiceBonusLevel.reward_coins(_bonus_v2) if _bonus_type >= 0 else 0}
		else:
			_win_completion_iq = _finalize_iq_win()
	_win_coin_before = int(_win_completion_payload.before)
	_win_coin_reward = int(_win_completion_payload.coins)
	_bonus_coin_before = _win_coin_before + _win_coin_reward
	_bonus_coin_reward = int(_win_completion_payload.bonus_coins)
	_bonus_coin_pending = _bonus_coin_reward

	if not UserState.begin_level_completion(_won_level_num, _win_completion_iq, true, 
			_level_model.special_challenge_schedule, checkin_completion, _win_completion_payload, 
			MainlineTimedEndlessEntry.prepare_offer(_won_level_num)):
		SortLogger.error("[JuiceGamePage] 通关 journal 保存失败，禁止清盘与推进关号")
		return

	ABManager.dye_at_level_target_coins()
	if not _win_coin_reported:
		_win_coin_reported = true
		if _win_coin_reward > 0:
			_report_coin_change(TrackingEvents.COIN_REASON_GAME_END, _win_coin_reward)
		if _bonus_coin_reward > 0:
			_report_coin_change(TrackingEvents.COIN_REASON_BOUNS_LEVEL, _bonus_coin_reward)
	if not LevelManager.mark_pending_completed(_won_level_num, {}, "win", win_game_id):
		SortLogger.error("[JuiceGamePage] 第 %d 关通关行写入失败，保留 pending 待恢复" % _won_level_num)
		return
	if not UserState.finalize_level_completion(_won_level_num):
		SortLogger.error("[JuiceGamePage] 第 %d 关通关游标推进失败，保留 pending 待恢复" % _won_level_num)
		return
	_win_committed = true

	_report_daily_checkin_coins(checkin_completion)

	GrtManager.evaluate_level_milestones()

	LevelManager.after_level_advance(_won_level_num)


	UserLevelTag.on_level_completed(_won_level_num)

	var won_lv: JuiceLevel = _board.level()
	ZtimeTag.on_level_completed_scaled(_won_level_num, won_lv.total_flowers)
















func _save_initial_snapshot(timing: String = "initial") -> void :
	if is_endless() or _is_legacy_tutorial():
		return
	if _level_model != null and not _level_model.is_special_challenge()\
	and _level_model.special_challenge_schedule.is_empty():
		return
	_rank_round.begin({}, _rank_collect_count(_board.level()), _rank_bar, _rank_fly)
	var snapshot: Dictionary = _board.snapshot()
	if _tutorial_active:
		snapshot["tutorial_step"] = _tutorial_resume_step
	if _four_goal_tutorial_round and _is_first_level_presentation():
		snapshot["tutorial_variant"] = "4guide"
	snapshot["level_target_coins"] = _round_target_coins
	snapshot["iq"] = _iq_round.snapshot()
	snapshot["rank_round"] = _rank_round.snapshot()
	snapshot["rank_collectible_rule"] = _level_model.rank_collectible_rule.duplicate(true)
	LevelManager.save_initial(_round_storage_key(), _level_model, snapshot, timing)

	RankManager.prepare_update_round(_round_game_id(), _board.level().groups_total)
	_layout()


func _save_progress(timing: String = "") -> void :
	if is_endless() or _is_legacy_tutorial():
		return

	if _level_model != null and not _level_model.is_special_challenge()\
	and _level_model.special_challenge_schedule.is_empty():
		return
	if _board == null or _board.level() == null:
		return
	var st: Dictionary = _board.state()
	if st.is_empty() or (st["cols"] as Array).is_empty():
		return


	if _win_committed or R.is_win(st, _board.level()):
		return
	var level_id: int = _round_storage_key()
	var blob: Dictionary = _board.snapshot()
	if _tutorial_active:
		blob["tutorial_step"] = _tutorial_dir.current_step() if is_instance_valid(_tutorial_dir) else _tutorial_resume_step
	if _four_goal_tutorial_round and _is_first_level_presentation():
		blob["tutorial_variant"] = "4guide"
	blob["level_target_coins"] = _round_target_coins

	blob["rank_round"] = _rank_round.snapshot()

	blob["rank_collectible_rule"] = _level_model.rank_collectible_rule.duplicate(true)
	blob["challenge"] = _challenge_feedback_snapshot()
	blob["empty_rope_feedback_count"] = _empty_col_feedback.shown_count
	blob["empty_rope_feedback_operations"] = _empty_col_feedback.shown_operations.duplicate()



	blob["used_hint_info"] = _tracking_prop_used_round.duplicate()
	blob["iq"] = _iq_round.snapshot()


	var play_delta_ms: int = _take_play_time_ms(level_id)
	var round_ms: int = _take_round_time_ms(level_id)

	var game_id: String = _tracking_common.game_id if _tracking_common != null else _round_game_id()
	LevelManager.save_game_state(level_id, blob, play_delta_ms, round_ms, timing, game_id)



func _take_play_time_ms(level_id: int) -> int:
	if _is_legacy_tutorial():
		return 0
	if _play_timer.level_id() != level_id:
		return 0
	return _play_timer.take_pending_ms()





func _take_round_time_ms(level_id: int) -> int:
	if _play_timer.level_id() != level_id:
		return -1
	return _play_timer.elapsed_ms()






func _flush_play_time(timing: String = "") -> void :
	if is_endless():
		return
	var level_id: int = _play_timer.level_id()
	if level_id <= 0:
		return
	var ms: int = _play_timer.take_pending_ms()
	if _is_legacy_tutorial():
		return


	var game_id: String = _tracking_common.game_id if _tracking_common != null else ""
	LevelManager.add_play_time(level_id, ms, _play_timer.elapsed_ms(), timing, game_id)



func _inc_level_counter(column: String) -> void :
	if _is_legacy_tutorial():
		return
	var game_id: String = _tracking_common.game_id if _tracking_common != null else ""
	LevelManager.inc_level_counter(_round_storage_key(), column, game_id)



func _is_special_banner_pending(ctx) -> bool:
	if not is_special_challenge():
		return false
	return ctx == null or ctx.current_state.is_empty()






func show_opening_banners(ctx = null) -> void :
	var generation: int = _entrance_generation
	if not visible or (ctx != null and ctx.aborted) or _start_banner == null or _level_model == null:
		return

	if is_bonus_level_round() and not is_special_challenge():
		return
	var level_key: String = _opening_banner_level_key()
	var show_special: bool = _is_special_banner_pending(ctx)
	var is_super_hard: bool = _is_super_hard_level()
	var show_hard: bool = (_is_hard_level() or is_super_hard)\
	and not UserState.is_hard_banner_shown(level_key)
	var streak_count: int = UserState.get_win_streak_count()
	var show_streak: bool = streak_count >= 2 and not UserState.is_streak_word_shown(level_key)
	if not show_special and not show_hard and not show_streak:
		return

	var streak_group: int = 0
	if show_streak:
		ABManager.dye_at_streak_banner()
		streak_group = ABManager.streak_banner.value()



	var input_generation: int = -1
	if _opening_banner_should_lock_input(
		_opening_banner_has_guide(ctx), show_streak, streak_group
	):
		input_generation = _begin_opening_banner_input_lock()
	else:


		_board.cancel_active_drag()
	if show_special:
		var finished: bool = await _special_challenge_banner.play(_special_challenge_chest)
		if not finished or not _opening_banner_is_current(generation, ctx):
			_end_opening_banner_input_lock(input_generation)
			return
		_special_challenge_banner_pending = false
		_sync_level_card()
	if show_hard:

		ABManager.dye_at_hard_level_banner_style()
		var hard_style: GameStartBanner.HardStyle = _hard_banner_style()

		UserState.mark_hard_banner_shown(level_key)
		await _start_banner.show_hard(_level_model.chapter_index, is_super_hard, hard_style)
		if not _opening_banner_is_current(generation, ctx):
			_end_opening_banner_input_lock(input_generation)
			return
	if show_streak:
		UserState.mark_streak_word_shown(level_key)
		await _start_banner.show_streak(
			streak_count, streak_group, Callable(), 
			_streak_percentile(streak_count), UserState.is_current_streak_record(streak_count)
		)
	_end_opening_banner_input_lock(input_generation)




func _opening_banner_should_lock_input(has_guide: bool, show_streak: bool, streak_group: int) -> bool:
	if has_guide:
		return true
	return show_streak and streak_group == ABManager.streak_banner.VALUE_TIERED_BLOCKING



func _opening_banner_is_current(generation: int, ctx) -> bool:
	if not visible or (ctx != null and ctx.aborted):
		return false
	return generation == _entrance_generation



func _opening_banner_has_guide(ctx) -> bool:
	var restore: Dictionary = {}
	if ctx != null and ctx.get("current_state") is Dictionary:
		restore = ctx.get("current_state")
	if _tutorial_active or should_run_tutorial_now(restore):
		return true
	if (ctx == null or ctx.get("skip_lock_guide") != true) and should_run_lock_guide_now(restore):
		return true
	if (ctx == null or ctx.get("skip_sunlight_guide") != true) and should_run_sunlight_guide_now(restore):
		return true
	if (ctx == null or ctx.get("skip_mystery_guide") != true) and should_run_mystery_guide_now(restore):
		return true
	return (ctx == null or ctx.get("skip_prop_unlock") != true) and not _pending_prop_unlock_keys().is_empty()


func _begin_opening_banner_input_lock() -> int:
	_stop_undo_guide_motion_preview()
	_opening_banner_input_generation += 1
	if not _opening_banner_input_locked:
		_opening_banner_input_was_enabled = bool(_board.get("_input_enabled"))
	_opening_banner_input_locked = true
	_board.set_input_enabled(false)
	return _opening_banner_input_generation


func _end_opening_banner_input_lock(generation: int) -> void :
	if generation != _opening_banner_input_generation or not _opening_banner_input_locked:
		return
	_opening_banner_input_locked = false
	_board.set_input_enabled(_opening_banner_input_was_enabled)


func _cancel_opening_banner_input_lock() -> void :
	_end_opening_banner_input_lock(_opening_banner_input_generation)
	_opening_banner_input_generation += 1
	if _start_banner != null:
		_start_banner.hide_now()



func _pending_prop_unlock_keys() -> Array[String]:
	var pending: Array[String] = []
	var lv: int = UserState.get_current_level()
	var prop_keys: Array[String] = ["hint", "undo", "rope"]
	if _complete_prop_enabled:
		prop_keys.append("fill_pot")
	for key: String in prop_keys:
		var ui: Dictionary = _prop_ui.get(key, {})
		var btn: PropBtn = ui.get("btn") as PropBtn
		if btn != null and lv >= btn.get_unlock_level() and not UserState.is_prop_unlock_shown(key):
			pending.append(key)
	return pending


func _opening_banner_level_key() -> String:
	if _level_model == null:
		return ""



	if _level_model.is_fallback_content():
		return "%d:%d" % [_level_model.chapter_index, _level_model.level_index]
	if not _level_model.level_unique_id.is_empty():
		return _level_model.level_unique_id
	return "%d:%d" % [_level_model.chapter_index, _level_model.level_index]











func maybe_show_prop_unlock() -> void :
	if not visible or (_start_flow_context != null and _start_flow_context.aborted):
		return
	if _unlock_overlay != null and is_instance_valid(_unlock_overlay) and _unlock_overlay.is_open():
		return
	var pending: Array[String] = _pending_prop_unlock_keys()
	if pending.is_empty():
		return

	var target: String = pending[0]
	for key: String in pending:
		var a: PropBtn = (_prop_ui[key] as Dictionary)["btn"] as PropBtn
		var b: PropBtn = (_prop_ui[target] as Dictionary)["btn"] as PropBtn
		if a.get_unlock_level() > b.get_unlock_level():
			target = key

	for key: String in pending:
		if key != target:
			UserState.mark_prop_unlock_shown(key)
			var skipped_btn: PropBtn = (_prop_ui[key] as Dictionary)["btn"] as PropBtn
			if skipped_btn != null and is_instance_valid(skipped_btn):
				skipped_btn.set_unlock_revealed(true)

	var btn: PropBtn = (_prop_ui[target] as Dictionary)["btn"] as PropBtn
	if btn == null or not is_instance_valid(btn):
		UserState.mark_prop_unlock_shown(target)
		return
	await _present_prop_unlock(target, btn, false)




func _present_prop_unlock(target: String, btn: PropBtn, preview: bool) -> void :
	_stop_undo_guide_motion_preview()
	_unlock_forced_close = false
	_unlock_overlay = SceneManager.show_dlg("prop_unlock", {
		"prop_key": target, 
		"button": btn, 
		"start_context": _start_flow_context, 
	}) as GamePropUnlockOverlay
	if _unlock_overlay == null:
		SortLogger.error("JuiceGamePage: 道具解锁弹窗创建失败")
		if not preview:
			UserState.mark_prop_unlock_shown(target)
		return
	_unlock_reveal_key = target
	btn.set_unlock_revealed(true)
	_play_timer.pause(LevelPlayTimer.PAUSE_GUIDE_PROP_UNLOCK)
	await _unlock_overlay.closed
	_play_timer.resume(LevelPlayTimer.PAUSE_GUIDE_PROP_UNLOCK)
	if not preview and not _unlock_forced_close:
		UserState.mark_prop_unlock_shown(target)
	_unlock_reveal_key = ""
	if is_instance_valid(btn):
		btn.set_unlock_revealed(UserState.is_prop_unlock_shown(target))




func _cheat_preview_prop_unlock(args: Array[String]) -> void :
	var target: String = args[0].strip_edges().to_lower() if not args.is_empty() else "fill_pot"
	if not ["hint", "undo", "rope", "fill_pot"].has(target):
		SceneManager.show_toast("参数必须是 hint / undo / rope / fill_pot")
		return
	if not visible or not _playfield_ready or _board == null:
		SceneManager.show_toast("请先进入游戏页并等待开局完成")
		return
	if _unlock_overlay != null and is_instance_valid(_unlock_overlay) and _unlock_overlay.is_open():
		SceneManager.show_toast("解锁弹窗已经打开")
		return
	var ui: Dictionary = _prop_ui.get(target, {}) as Dictionary
	var btn: PropBtn = ui.get("btn") as PropBtn
	if btn == null or not is_instance_valid(btn) or not btn.visible:
		SceneManager.show_toast("当前分组没有 %s 道具按钮（fill_pot 需切到 complete_prop 组2/组3）" % target)
		return
	await _present_prop_unlock(target, btn, true)




func _close_prop_unlock_now() -> void :
	if _unlock_overlay == null or not is_instance_valid(_unlock_overlay):
		return
	if _unlock_overlay.is_open():


		_unlock_forced_close = true
		_unlock_overlay.close(false, true)







func _use_prop(key: String) -> void :
	if _root_swap_guide_blocks_input():
		return
	if is_endless() and not _endless_can_use_props():
		return
	if is_endless() and key in ["rope", "fill_pot"] and _board.over() == "dead":
		return

	if _win_committed or (_board != null and _board.over() == "win"):
		return
	if _opening_banner_input_locked or _sunlight_guide_running:
		return
	if not _playfield_ready or not _ui_props_ready:
		return
	var ui: Dictionary = _prop_ui.get(key, {})
	if ui.is_empty():
		return
	var btn: PropBtn = ui["btn"] as PropBtn
	if btn == null:
		return
	var business_state: int = btn.get_business_state()
	if business_state == PropBtn.PropState.LOCKED:
		SceneManager.show_toast(tr("JUICE_PROP_UNLOCK_LEVEL_TOAST").format(
			{"N": btn.get_unlock_level()}))
		return
	if _board == null or _board.level() == null:
		return
	var is_dead: bool = _board.over() == "dead"
	if is_dead and key == "hint":
		SceneManager.show_toast(tr("JUICE_PROP_NO_MOVES_TOAST"))
		return

	if (_board.over() != "" and not is_dead) or _board.is_busy():
		return
	if key == "hint" and _board.has_active_hint():
		return
	if key == "undo" and not _board.can_undo():
		SceneManager.show_toast(tr("JUICE_PROP_UNDO_EMPTY_TOAST"))
		return
	if key == "rope" and _board.has_rope():
		SceneManager.show_toast(tr("JUICE_PROP_ROPE_USED_TOAST"))
		return
	if key != "hint" and key != "undo" and key != "rope" and key != "fill_pot":
		return
	_teardown_root_swap_guide()

	if key == "hint" and _hint_try_sync().is_empty() and _hint_checked_key != _hint_state_key():
		_hint_dispatch()
		return

	if business_state == PropBtn.PropState.COIN\
	and UserState.get_coins() < btn.get_base_coin_price():
		SceneManager.show_toast(tr("JUICE_PROP_COINS_INSUFFICIENT_TOAST"))
		_refresh_prop_btns()
		return

	if business_state == PropBtn.PropState.NOT_READY:
		SceneManager.show_toast(tr("JUICE_PROP_AD_NOT_READY_TOAST"))
		return

	if business_state == PropBtn.PropState.AD:
		await _use_prop_via_ad(key)
		return


	if not _prop_tier_ok(btn):
		_refresh_prop_btns()
		return


	if key == "hint":
		var cached: Dictionary = _hint_try_sync()
		if cached.is_empty():
			_hint_dispatch()
			return
		if not _show_hint_on_board(cached):
			return
	elif not _apply_prop(key):
		return
	_charge_prop(key, btn)
	_after_prop_applied(key, is_dead)










func _use_prop_via_ad(key: String) -> void :



	if _prop_ad_in_flight:
		SceneManager.show_toast(tr("JUICE_PROP_AD_NOT_READY_TOAST"))
		return





	var ui: Dictionary = _prop_ui.get(key, {}) as Dictionary
	var btn: PropBtn = ui.get("btn") as PropBtn
	if btn == null or btn.get_business_state() != PropBtn.PropState.AD:
		SceneManager.show_toast(tr("JUICE_PROP_AD_NOT_READY_TOAST"))
		_refresh_prop_btns(true)
		return
	_prop_ad_in_flight = true
	var position: String = _prop_ad_position(key)

	var endless_token: int = _endless_generation
	if is_endless():
		_endless_controller.pause(&"ad")
	_play_timer.pause(LevelPlayTimer.PAUSE_AD)
	var grant: Dictionary = {"key": key, 
		"count": PROP_AD_GRANT_COUNT if key == "hint" or key == "undo" else 1, 
		"granted": false, "common": _tracking_common}
	var on_late_reward: Callable = _grant_prop_ad_reward.bind(grant)
	var rewarded: bool = await AdManager.show_reward_ad_and_await(position, on_late_reward)
	_play_timer.resume(LevelPlayTimer.PAUSE_AD)
	_prop_ad_in_flight = false
	if rewarded:
		_grant_prop_ad_reward(grant)
	if is_endless():
		if endless_token == _endless_generation and visible:
			_endless_controller.resume(&"ad")
			_refresh_prop_btns(true)
		return
	if not rewarded:



		_refresh_prop_btns(true)
		return

	_refresh_prop_btns(true)



func _grant_prop_ad_reward(grant: Dictionary) -> void :
	if grant["granted"]:
		return
	grant["granted"] = true
	var key: String = grant["key"]
	var count: int = grant["count"]
	UserState.add_prop_reward_ads(key, count)

	if grant["common"] != null:
		Tracker.send_event(TrackingEvents.EV_PROP_GET, {
			TrackingEvents.K_SOURCE: TrackingEvents.PROP_SOURCE_REWARD_ADS, 
			TrackingEvents.K_PROP_NAME: key, 
			TrackingEvents.K_PROP_NUM: count, 
			TrackingEvents.K_PROP_LEFT: UserState.get_prop_count(key), 
		}, grant["common"])
	if is_visible_in_tree() and not _prop_ad_in_flight:

		_refresh_prop_btns()



func _charge_prop(key: String, btn: PropBtn) -> void :
	match btn.get_business_state():
		PropBtn.PropState.FREE:
			if not UserState.is_prop_free_available(key):
				push_error("JuiceGamePage: 道具 %s 免费额度已失效,本次不计账" % key)
				return
			UserState.consume_prop_free_use(key)
			_report_prop_use(key, TrackingEvents.PROP_SOURCE_UNLOCK_FIRST, _prop_count(key))
			if key == "rope":

				_report_new_rope(true, TrackingEvents.APPEAR_FREE)
			return
		PropBtn.PropState.COUNT:
			var charge: Dictionary = UserState.consume_prop_stock(key)
			if charge.is_empty():
				push_error("JuiceGamePage: 道具 %s 库存已失效,本次不计账" % key)
				return
			var source: String = (TrackingEvents.PROP_SOURCE_REWARD_ADS
				if charge["from_reward_ads"] else TrackingEvents.PROP_SOURCE_UNLOCK_FIRST)
			_report_prop_use(key, source, int(charge["left"]))
			if key == "rope":


				_report_new_rope(true, TrackingEvents.APPEAR_ADS_EXCHANGE
					if bool(charge["from_reward_ads"]) else TrackingEvents.APPEAR_FREE)
			return
		PropBtn.PropState.COIN:

			var price: int = btn.get_base_coin_price()
			if not UserState.spend_coins(price):
				push_error("JuiceGamePage: 道具效果已生效但金币扣除失败")
				return
			var reason: String = (TrackingEvents.COIN_REASON_HINT if key == "hint" else
				TrackingEvents.COIN_REASON_UNDO if key == "undo" else TrackingEvents.COIN_REASON_ROPE)
			_report_coin_change(reason, - price)
			_report_prop_get(key, 1, TrackingEvents.PROP_SOURCE_COIN_EXCHANGE)
			_report_prop_use(key, TrackingEvents.PROP_SOURCE_COIN_EXCHANGE, _prop_count(key))
			if key == "rope":
				_report_new_rope(true, TrackingEvents.APPEAR_COIN_EXCHANGE)
			_refresh_coin_hud()
			return
		_:


			push_error("JuiceGamePage: 道具 %s 效果已生效但档位已失效,本次不计账" % key)
			return



func _prop_tier_ok(btn: PropBtn) -> bool:
	match btn.get_business_state():
		PropBtn.PropState.FREE:
			return UserState.is_prop_free_available(_prop_key_of(btn))
		PropBtn.PropState.COUNT:
			return _prop_count(_prop_key_of(btn)) > 0
		PropBtn.PropState.COIN:
			var price: int = btn.get_base_coin_price()
			return price > 0 and UserState.get_coins() >= price
	return false


func _prop_key_of(btn: PropBtn) -> String:
	for key: String in _prop_ui:
		if (_prop_ui[key] as Dictionary)["btn"] == btn:
			return key
	return ""







func _continue_state_for_prop(key: String) -> String:
	match key:
		"undo": return TrackingEvents.GAME_STATE_CONTINUE_UNDO
		"rope": return TrackingEvents.GAME_STATE_CONTINUE_ROPE

		"fill_pot": return ""
	return ""








func _after_prop_applied(key: String, was_dead: bool = false) -> void :
	if is_endless():
		if _board.over() != "dead":
			_hide_dead_toast()
		_refresh_endless_hud()
		_refresh_prop_btns(true, key)
		return
	if key == "undo" or key == "rope" or key == "fill_pot":
		_reset_hint_guide(true)
		_clear_hint_guide_motion(true)

	if not is_special_challenge()\
	and key != "undo" and key != "hint":
		UserState.mark_current_level_dirty()

	if was_dead:
		var continue_state: String = _continue_state_for_prop(key)
		if not continue_state.is_empty():
			_tracking_game_state = continue_state
			report_game_start(false)

	_inc_level_counter("%s_used" % key)

	if _tracking_prop_used_round.has(key):
		_tracking_prop_used_round[key] = int(_tracking_prop_used_round[key]) + 1

	if was_dead or (_board != null and _board.over() != "dead"):
		_hide_dead_toast()
	else:
		_sync_dead_prop_glows()




	if _board == null or not _board.is_busy():
		_refresh_prop_btns(true, key)


	if _unlock_overlay != null and is_instance_valid(_unlock_overlay) and _unlock_overlay.is_open():
		_unlock_overlay.close(true)





	_save_progress("prop")
	LevelManager.flush()




func _apply_prop(key: String) -> bool:
	if _root_swap_guide_blocks_input():
		return false
	if is_endless() and ( not _endless_can_use_props()\
	or (key == "fill_pot" and not _complete_prop_enabled)\
	or (key in ["rope", "fill_pot"] and _board.over() == "dead")):
		return false
	_teardown_root_swap_guide()
	match key:
		"fill_pot":

			_applying_fill_pot = true
			var completed: bool = _board.complete_column_prop()
			_applying_fill_pot = false
			if not completed:
				SceneManager.show_toast(tr("JUICE_PROP_FILL_POT_EMPTY_TOAST"))
			return completed
		"undo":

			_applying_undo = true
			var back_steps: int = _dead_undo_back_steps()
			var applied: bool = _board.undo(back_steps)
			_applying_undo = false
			if applied and back_steps > 1:
				SceneManager.show_toast(tr("JUICE_UNDO_BACK_STEPS_TOAST").format({"n": back_steps}))
			return applied
		"rope":
			return _board.revive_with_rope() if _board.over() == "dead" else _board.add_rope()
	return false






func _dead_undo_back_steps() -> int:
	if _board.over() != "dead":
		return 1
	var safe_steps: int = _board.safe_return_steps()
	if safe_steps <= 1:
		return 1
	ABManager.dye_at_dead_return_to_safe()
	if ABManager.sort_dead_return_to_safe_state.is_return_to_safe_enabled():
		return safe_steps
	return 1


func _prop_count(key: String) -> int:
	return UserState.get_prop_count(key)







func _hint_try_sync() -> Dictionary:
	if not _hint_solvable():
		return {}
	var state_key: String = _hint_state_key()
	if state_key == _hint_cache_key:
		if not _hint_cache.is_empty():
			_hint_checked_key = state_key
			SortLogger.info("[Hint] level=%d board=%d source=cache steps=%d" % [
				_board.level().id, state_key.hash(), int(_hint_cache.get("len", 0))])
		return _hint_cache
	var from_plan: Dictionary = _hint_from_plan(state_key)
	if not from_plan.is_empty():
		SortLogger.info("[Hint] level=%d board=%d source=plan steps=%d" % [
			_board.level().id, state_key.hash(), int(from_plan.get("len", 0))])
		return _cache_hint(state_key, from_plan)
	return {}



func _hint_solvable() -> bool:
	if is_endless() and not _endless_can_use_props():
		return false
	return _board != null and _board.level() != null and not _board.state().is_empty()\
	and not _board.is_busy() and _board.over() == ""



func _hint_state_key() -> String:
	return "%d:%s" % [_board.level().id, S._full_state_key(_board.state())]



func _hint_dispatch(auto: bool = false, preflight: bool = false) -> void :
	if _hint_task_id != HINT_TASK_NONE:
		if preflight or not _hint_task_preflight or not _hint_solvable():
			return
		if _hint_task_key == _hint_state_key():
			_hint_task_preflight = false
			_hint_task_auto = auto
			_board.set_hint_lock(true)
			return

		_hint_cancel()
	if not _hint_solvable():
		return
	var root_path: Array = []
	if bool(_board.state().get("allow_root_swapping", false)):
		var state_key: String = _hint_state_key()
		if not _root_hint_pending_key.is_empty():
			if _root_hint_pending_key == state_key:
				if _hint_task_preflight and not preflight:
					_hint_task_preflight = false
					_hint_task_auto = auto
				return
			_hint_cancel()
		var root_result: Dictionary = _board.root_closed_result()
		if root_result.is_empty() or String(root_result.get("status", "UNKNOWN")) == "UNKNOWN"\
		or bool(root_result.get("continuable", false))\
		or bool(root_result.get("recoverable", false)):
			_root_hint_pending_key = state_key
			_hint_task_key = state_key
			_hint_task_auto = auto
			_hint_task_preflight = preflight
			_board.ensure_root_closed_check()
			set_process(true)
			return
		if String(root_result.get("status", "UNKNOWN")) != "EXIT":

			return
		root_path = (root_result.get("path", []) as Array).duplicate(true)
	_hint_task_auto = auto
	_hint_task_preflight = preflight
	var opt: Dictionary = HINT_OPT.duplicate()
	if bool(_board.state().get("allow_root_swapping", false)):
		opt["require_complete"] = true
		opt["verify_safe"] = false
	opt["now"] = Time.get_ticks_msec
	opt["deadline"] = Time.get_ticks_msec() + int(opt["ms_cap"])
	_hint_task_cancel = Semaphore.new()
	opt["cancel"] = _hint_task_cancel
	_hint_task_progress = S.HintProgress.new()
	_hint_task_version = -1
	_hint_task_latest = {}
	opt["progress"] = _hint_task_progress
	var forbid: Dictionary = _board.last_move()
	if not forbid.is_empty():
		opt["forbid"] = {"src": int(forbid["dst"]), "dst": int(forbid["src"]), 
			"k": int(forbid["k"]), "root_swapped": bool(forbid.get("root_swapped", false))}
	if _hint_plan_root_necessary and _hint_plan_key == _hint_state_key():
		opt["preferred_path"] = _hint_plan.duplicate(true)
	if not root_path.is_empty():
		opt["preferred_path"] = root_path
	var snapshot: Dictionary = R.clone_state(_board.state())
	_hint_task_key = _hint_state_key()
	_hint_task_result = {"completed": false, "hint": {}, 
		"reachability": S.Reachability.UNKNOWN}
	var job: Callable = ENDLESS_HINT.run_task.bind(_endless_controller.session.player_snapshot(), opt, _hint_task_result) if is_endless() else S.run_checked_hint_task.bind(snapshot, _board.level(), opt, _hint_task_result)
	_hint_task_id = WorkerThreadPool.add_task(job, false, "juice hint")
	if not preflight:
		_board.set_hint_lock(true)
	set_process(true)



func _hint_poll() -> void :
	if _hint_task_id == HINT_TASK_NONE:
		_hint_poll_root_search()
		return
	var snapshot: Dictionary = _hint_task_progress.read(_hint_task_version)
	if not snapshot.is_empty():
		_hint_task_version = int(snapshot["version"])
		var verified: Dictionary = snapshot["hint"]
		if not verified.is_empty():
			_hint_task_latest = verified
	if not WorkerThreadPool.is_task_completed(_hint_task_id):
		return
	_hint_settle()



func _hint_poll_root_search() -> void :
	if _root_hint_pending_key.is_empty():
		return
	if _board == null or not is_visible_in_tree() or _board.level() == null\
	or _board.over() != "" or not bool(_board.state().get("allow_root_swapping", false))\
	or _hint_state_key() != _root_hint_pending_key:
		_hint_release()
		return
	if not _hint_solvable():
		return
	var result: Dictionary = _board.root_closed_result()
	if result.is_empty() or String(result.get("status", "UNKNOWN")) == "UNKNOWN"\
	or bool(result.get("continuable", false)) or bool(result.get("recoverable", false)):
		_board.ensure_root_closed_check()
		return
	var auto: bool = _hint_task_auto
	var preflight: bool = _hint_task_preflight
	_hint_release()
	if String(result.get("status", "UNKNOWN")) == "EXIT":
		_hint_dispatch(auto, preflight)




func _hint_settle() -> void :
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_hint_task_id)
	var final_snapshot: Dictionary = _hint_task_progress.read(_hint_task_version)
	if not final_snapshot.is_empty() and not (final_snapshot["hint"] as Dictionary).is_empty():
		_hint_task_latest = final_snapshot["hint"]
	var completed: bool = bool(_hint_task_result.get("completed", false))
	var hint: Dictionary = (_hint_task_result.get("hint", {}) as Dictionary).duplicate()
	var dispatch_key: String = _hint_task_key
	var reachability: int = int(_hint_task_result.get("reachability", S.Reachability.UNKNOWN))
	var auto: bool = _hint_task_auto
	var preflight: bool = _hint_task_preflight
	var stop_reason: String = String(_hint_task_result.get("stop_reason", ""))


	if hint.is_empty() and not _hint_task_latest.is_empty() and stop_reason != "cancelled":
		hint = _hint_task_latest
	SortLogger.info("[Hint] level=%d board=%d source=%s stop=%s budget_ms=%d elapsed_ms=%d routes=%d steps=%d trace=%s" % [
		int(dispatch_key.get_slice(":", 0)), dispatch_key.hash(), String(_hint_task_result.get("hint_source", "")), stop_reason, 
		int(_hint_task_result.get("budget_ms", 0)), 
		int(_hint_task_result.get("elapsed_ms", 0)), int(_hint_task_result.get("routes", 0)), 
		int(hint.get("len", 0)), JSON.stringify(_hint_task_result.get("search_trace", []))])
	_hint_release()
	if stop_reason == "cancelled":
		return
	if task_error != OK or not completed:
		SortLogger.error("juice_sort: 提示求解任务失败,error=%d verified_fallback=%s" % [task_error, not hint.is_empty()])
		if hint.is_empty():
			return

	if not _hint_solvable() or _hint_state_key() != dispatch_key:
		if preflight:
			_hint_guide_checked_key = ""
		SortLogger.info("[Hint] delivery=discarded reason=stale_board")
		return
	if is_endless() and not hint.is_empty():
		var prefix: Array = hint.get("queue_prefix", [])
		var incoming: Array = _endless_controller.session.incoming
		if incoming.size() < prefix.size() or incoming.slice(0, prefix.size()) != prefix:
			return
	var root_enabled: bool = bool(_board.state().get("allow_root_swapping", false))
	if root_enabled and hint.is_empty():

		_hint_checked_key = ""
		_root_hint_pending_key = dispatch_key
		_hint_task_key = dispatch_key
		_hint_task_auto = auto
		_hint_task_preflight = preflight
		_board.ensure_root_closed_check()
		SortLogger.info("[Hint] delivery=pending_or_unknown auto=%s preflight=%s" % [auto, preflight])
		return

	if preflight:
		var control_dead: bool = not root_enabled and reachability == S.Reachability.UNWINNABLE
		var cached_hint: Dictionary = {} if control_dead else hint
		_cache_hint(dispatch_key, cached_hint)
		_hint_guide_unwinnable_key = dispatch_key if not is_endless()\
		and control_dead else ""
		SortLogger.info("[Hint] delivery=%s preflight=true" % ("cached" if not cached_hint.is_empty() else "empty"))
		return

	if not root_enabled and reachability == S.Reachability.UNWINNABLE:
		SortLogger.info("[Hint] delivery=discarded reason=dead_proven")
		_board.mark_hint_unwinnable()
		if not is_endless():
			_save_progress("dead")
			LevelManager.flush()
		return
	_hint_checked_key = dispatch_key

	if auto:
		var auto_hint: Dictionary = _cache_hint(dispatch_key, hint)
		if not auto_hint.is_empty():
			var shown: bool = _show_hint_on_board(auto_hint)
			SortLogger.info("[Hint] delivery=%s auto=true" % ("shown" if shown else "display_rejected"))
		else:
			SortLogger.info("[Hint] delivery=empty auto=true")
		return

	var strict_hint: Dictionary = _cache_hint(dispatch_key, hint)
	if strict_hint.is_empty():
		SortLogger.info("[Hint] delivery=empty auto=false")
		SceneManager.show_toast(tr("JUICE_PROP_HINT_EMPTY_TOAST"))
		return
	var ui: Dictionary = _prop_ui.get("hint", {})
	if ui.is_empty():
		return
	var btn: PropBtn = ui["btn"] as PropBtn
	if btn == null or not is_instance_valid(btn):
		return


	if not _prop_tier_ok(btn):

		_use_prop("hint")
		return
	if not _show_hint_on_board(strict_hint):
		SortLogger.info("[Hint] delivery=display_rejected auto=false")
		return
	SortLogger.info("[Hint] delivery=shown auto=false")
	_charge_prop("hint", btn)
	_after_prop_applied("hint")





func _show_hint_on_board(hint: Dictionary) -> bool:
	if _root_swap_guide_blocks_input():
		return false

	_teardown_root_swap_guide()
	if _mystery_guide != null and is_instance_valid(_mystery_guide)\
	and _mystery_guide.is_running():
		_on_mystery_guide_finished()
	return _board.show_hint(hint)



func _hint_cancel() -> void :
	var root_pending: bool = not _root_hint_pending_key.is_empty()
	_root_hint_pending_key = ""
	_hint_guide_checked_key = ""
	_hint_guide_unwinnable_key = ""
	_stop_rope_guide()
	_hint_checked_key = ""
	_hint_cache_key = ""
	_hint_cache = {}
	_hint_plan = []
	_hint_plan_key = ""
	_hint_plan_root_necessary = false
	if _hint_task_id == HINT_TASK_NONE:
		if root_pending:
			_hint_release()
		return
	SortLogger.info("[Hint] board=%d delivery=discarded reason=cancelled" % _hint_task_key.hash())
	_hint_task_cancel.post()
	var retired: int = _hint_task_id
	_hint_release()
	_hint_reap_task(retired, get_tree())



static func _hint_reap_task(task: int, tree: SceneTree) -> void :
	while not WorkerThreadPool.is_task_completed(task):
		await tree.process_frame
	WorkerThreadPool.wait_for_task_completion(task)




func _hint_release() -> void :
	_root_hint_pending_key = ""
	_hint_task_cancel = null
	_hint_task_id = HINT_TASK_NONE
	_hint_task_result = {}
	_hint_task_progress = null
	_hint_task_version = -1
	_hint_task_latest = {}
	_hint_task_key = ""
	_hint_task_auto = false
	_hint_task_preflight = false

	set_process(is_visible_in_tree())
	if _board != null and is_instance_valid(_board):
		_board.set_hint_lock(false)




func _hint_from_plan(state_key: String) -> Dictionary:
	if _hint_plan_root_necessary or _hint_plan.is_empty() or state_key != _hint_plan_key:
		return {}
	var mv: Dictionary = _hint_plan[0]


	if R.move_info(_board.state(), int(mv["src"]), int(mv["j"]), int(mv["dst"])) <= 0:
		return {}


	return {"move": mv, "col": _hint_plan_col, "len": _hint_plan.size(), 
		"optimal": _hint_plan_optimal, "path": _hint_plan.duplicate(), "win_path": _hint_plan_win_path}



func _cache_hint(state_key: String, result: Dictionary) -> Dictionary:
	_hint_cache_key = state_key
	_hint_cache = result
	_hint_plan = []
	_hint_plan_key = ""
	_hint_plan_root_necessary = false
	if _hint_cache.is_empty():
		_hint_checked_key = ""
		return _hint_cache
	_hint_checked_key = _hint_state_key()
	var path: Array = _hint_cache.get("path", [])
	if bool(_hint_cache.get("root_necessary", false)):
		path = _hint_cache.get("root_win_path", path)
		_hint_plan_root_necessary = true
	if path.size() < 2:
		return _hint_cache

	if is_endless():
		_hint_plan = path.slice(1)
		_hint_plan_optimal = bool(_hint_cache.get("optimal", false))
		_hint_plan_win_path = false
		var probe_session: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(_endless_controller.session.player_snapshot())
		var first: Dictionary = path[0]
		var rec: Dictionary = probe_session.apply_move(int(first.src), int(first.j), int(first.dst))
		if rec.is_empty() or not (rec["deposits"] as Array).is_empty():
			_hint_plan = []
		else:
			_hint_plan_key = "%d:%s" % [_board.level().id, S._full_state_key(probe_session.state)]
		_hint_plan_col = int(_hint_cache.get("col", -1))
		return _hint_cache
	var probe: Dictionary = R.clone_state(_board.state())
	var mv: Dictionary = path[0]
	if R.apply_move(probe, _board.level(), int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
		return _hint_cache
	_hint_plan = path.slice(1)
	_hint_plan_key = "%d:%s" % [_board.level().id, S._full_state_key(probe)]
	_hint_plan_col = int(_hint_cache.get("col", -1))
	_hint_plan_optimal = bool(_hint_cache.get("optimal", false))
	_hint_plan_win_path = bool(_hint_cache.get("win_path", false))
	return _hint_cache


func _prop_effect_available(key: String) -> bool:
	if _root_swap_guide_blocks_input():
		return false
	if is_endless() and ( not _endless_can_use_props()\
	or (key == "fill_pot" and not _complete_prop_enabled)\
	or (key in ["rope", "fill_pot"] and _board.over() == "dead")):
		return false
	if _board == null or _board.level() == null or _board.is_busy():
		return false
	if _board.over() == "dead":
		match key:
			"undo":
				return _board.can_undo()
			"rope":
				return not _board.has_rope()
			"fill_pot":

				return _complete_prop_enabled
		return false
	if _board.over() != "":
		return false
	match key:
		"hint":











			return _hint_task_id == HINT_TASK_NONE
		"undo":
			return _board.can_undo()
		"rope":
			return not _board.has_rope()
		"fill_pot":

			return _complete_prop_enabled
	return false






func refresh_economy_ui() -> void :
	_refresh_coin_hud()
	_refresh_prop_btns()

















func _refresh_prop_btns(ad_query: bool = false, only_key: String = "") -> void :
	_prop_refresh_gen += 1
	var gen: int = _prop_refresh_gen

	if _win_committed or (_board != null and _board.over() == "win"):
		return
	_sync_dead_prop_glows()
	var lv: int = UserState.get_current_level()
	var coins: int = UserState.get_coins()
	if ad_query and only_key.is_empty():
		_prop_ad_ready.clear()
	for key: String in _prop_ui:
		var ui: Dictionary = _prop_ui[key] as Dictionary
		var btn: PropBtn = ui["btn"] as PropBtn
		if btn == null or not is_instance_valid(btn):
			continue



		btn.set_early_unlocked(UserState.is_prop_early_unlocked(key))
		var free_available: bool = UserState.is_prop_free_available(key)
		var effect_available: bool = _prop_effect_available(key)
		var left: int = _prop_count(key)
		var unlock_revealed: bool = UserState.is_prop_unlock_shown(key)\
		or key == _unlock_reveal_key






		var needed: bool = btn.needs_ad_ready(lv, coins, effect_available, free_available, left, 
			unlock_revealed)

		var turned_to_ad: bool = needed and not bool(_prop_ad_needed.get(key, false))
		var ad_ready: bool = bool(_prop_ad_ready.get(key, false))
		if needed and ((ad_query and (only_key.is_empty() or only_key == key)) or turned_to_ad):
			ad_ready = await AdManager.check_reward_ads_available(_prop_ad_position(key))

			if gen != _prop_refresh_gen or _win_committed or (_board != null and _board.over() == "win"):
				return
			_prop_ad_ready[key] = ad_ready


		_prop_ad_needed[key] = needed
		btn.refresh(lv, coins, effect_available, free_available, left, ad_ready, 
			unlock_revealed)




func _prop_ad_position(key: String) -> String:
	match key:
		"hint":
			return TrackingEvents.AD_POSITION_HINT
		"undo":
			return TrackingEvents.AD_POSITION_UNDO
		"rope":
			return TrackingEvents.AD_POSITION_ROPE
		"fill_pot":
			return TrackingEvents.AD_POSITION_FILL_POT
	return ""












func _on_reward_ad_loaded() -> void :
	for key: String in _prop_ui:
		_prop_ad_ready[key] = true
	_refresh_prop_btns()





func _cheat_finish_eight_columns_setup(rows: int) -> void :
	if _board == null or _board.level() == null:
		push_error("JuiceGamePage: eight_columns 测试关未成功加载")
		SceneManager.show_toast("8 列 × %d 行测试关打开失败" % rows)
		return
	if not _board.add_rope():
		push_error("JuiceGamePage: eight_columns 无法增加第 8 根绳子")
		SceneManager.show_toast("8 列 × %d 行测试关打开失败" % rows)
		return
	SceneManager.show_toast("已打开 8 列 × %d 行测试关" % rows)


func _cheat_finish_challenge_setup(tip: String) -> void :
	if _board == null or _board.level() == null:
		push_error("JuiceGamePage: challenge_time 测试关未成功加载")
		SceneManager.show_toast("challenge 测试关打开失败")
		return
	_board.skip_challenge_opening_gate()
	SceneManager.show_toast(tip)


func _cheat_progress_full_preview(args: Array[String]) -> void :
	var mode: String = args[0] if not args.is_empty() else "once"
	var selector: String = args[1] if args.size() > 1 else "excellent"
	if args.size() > 2 or mode not in ["on", "once", "off"]:
		SortLogger.warn("ProgressBling: use progress_bling_full on/once/off [0~11/excellent/all]")
		return
	var slot: int = -1
	if mode != "off" and selector not in ["all", "excellent"]:
		if not selector.is_valid_int() or selector.to_int() < 0 or selector.to_int() >= ProgressBling.COLOR_SLOT_COUNT:
			SortLogger.warn("ProgressBling: full preview color must be 0~11, excellent or all")
			return
		slot = selector.to_int()
	if mode != "off" and _cup_flights.any( func(rec: Dictionary) -> bool: return not bool(rec.get("preview_only", false))):
		SortLogger.warn("ProgressBling: wait for real cup flights before full preview")
		return
	_stop_progress_full_preview()
	if mode == "off":
		return
	_progress_full_active = true
	_progress_full_looping = mode == "on"
	_progress_full_cycle = selector == "all"
	_progress_full_slot = 0 if _progress_full_cycle else slot
	_play_progress_full_preview()


func _play_progress_full_preview() -> void :
	if not visible or _hint_guide_background_paused or _board == null or _board.level() == null:
		_stop_progress_full_preview()
		return
	var target: int = _quota.preview_slot_index()
	if target < 0:
		SortLogger.warn("ProgressBling: no visible quota slot for full preview")
		_stop_progress_full_preview()
		return

	var cup_color: int = maxi(_progress_full_slot, 0)
	if cup_color >= CUP_FLY_SPINE_COLOR_KEYS.size():
		cup_color = 1 if cup_color == 10 else 5
	var tex: Texture2D = _board.target_icon_for_slot(cup_color)
	if tex == null:
		SortLogger.warn("ProgressBling: no full cup texture for preview")
		_stop_progress_full_preview()
		return
	var from_size: Vector2 = _quota.cup_global_rect(target, tex).size * 1.5
	var center: = Vector2(UiMetrics.viewport_size().x * 0.5, _board.pot_top_global_y() + from_size.y * 0.5)
	_start_cup_flight(target, tex, Color.WHITE, Rect2(center - from_size * 0.5, from_size), cup_color, true)


func _on_progress_full_preview_timeout() -> void :
	_quota.clear_preview_cup()
	if not _progress_full_active or not _progress_full_looping:
		_progress_full_active = false
		return
	if _progress_full_cycle:
		_progress_full_slot = (_progress_full_slot + 1) % (ProgressBling.COLOR_SLOT_COUNT + 1)
		if _progress_full_slot == ProgressBling.COLOR_SLOT_COUNT:
			_progress_full_slot = -1
	_play_progress_full_preview()


func _stop_progress_full_preview() -> void :
	_progress_full_active = false
	_progress_full_looping = false
	_progress_full_cycle = false
	_progress_full_timer.stop()
	if is_instance_valid(_progress_full_petal):
		_pot_petal_release(_progress_full_petal)
	for rec: Dictionary in _cup_flights.duplicate():
		if not bool(rec.get("preview_only", false)):
			continue
		var tw: Tween = rec["tw"] as Tween
		if tw != null and tw.is_valid():
			tw.kill()
		_fly_release(rec["spr"] as SpineSprite)
		_cup_flights.erase(rec)
	if is_instance_valid(_progress_full_sprite):
		_fly_release(_progress_full_sprite)
	_progress_full_sprite = null
	_quota.clear_preview_cup()
	_progress_bling.hide_now()




func _prepare_preview_components(groups: Array[String]) -> bool:
	_deferred_prepare_request = null
	_components.set_work_permission(Callable())
	var generation: int = _entrance_generation
	return await _ensure_component_groups(groups, func() -> bool:
		return visible and generation == _entrance_generation)


func _on_cheat_command(cmd_name: String, args: Array[String]) -> void :
	match cmd_name:
		"win_round":
			_cheat_win_round()

		"complete_column":
			_cheat_complete_column()
		"last_cup":
			_cheat_last_cup()
		"sort_die":
			_cheat_force_die(args)
		"prop_unlock_preview":
			_cheat_preview_prop_unlock(args)

		"combo_preview":
			_cmd_combo_preview(args)
		"combo_fullscreen_fx":
			_cmd_combo_fullscreen_fx(args)
		"combo_timing2_preview":
			_cmd_combo_preview(args, true)
		"progress_bling_full":
			_cheat_progress_full_preview(args)
		"progress_bling_motion":
			_stop_progress_full_preview()
			if args.size() <= 3:
				_progress_bling.preview(args[0] if not args.is_empty() else "once", 
					args[1] if args.size() > 1 else "excellent", 
					args[2] if args.size() > 2 else "all")
			else:
				SortLogger.warn("ProgressBling: use progress_bling_motion on/once/off [0~11/excellent/all] [all/base]")
		"bonus_level":
			_cheat_force_bonus_level(args)
		"bonus_banner":
			if not await _prepare_preview_components(["bonus"]):
				return
			if not _bonus_level_banner.visible:
				await _bonus_level_banner.play()
		"hard_banner":
			await _cheat_preview_hard_banner(args)
		"super_hard_banner":
			await _cheat_preview_hard_banner(args, true)
		"streak_banner":
			await _cheat_preview_streak_banner(args)
		"trail":
			_cheat_preview_trail(args)
		"darkness":
			_cmd_darkness(args)
		"flower_brightness":
			_cmd_flower_brightness(args)
		"skin":
			await _cmd_skin(args)
		"challenge_banner":
			_cheat_preview_challenge_banner(args)
		"smart_move":
			_cheat_preview_smart_move()
		"good_luck":
			_play_good_luck_fx()


func _cmd_combo_fullscreen_fx(args: Array[String]) -> void :
	if args.size() > 1:
		SceneManager.show_toast("Combo 全屏动效参数：1=第一阶段 / 2=第二阶段 / 3=第三阶段 / 4=全部连续播放 / 5=彩带版本（全部连续播放） / off=停止")
		return
	var selection: String = args[0] if not args.is_empty() else "1"
	if selection == "off":
		_combo_feedback.hide_now()
		return
	if not selection.is_valid_int() or selection.to_int() < 1 or selection.to_int() > 5:
		SceneManager.show_toast("Combo 全屏动效参数：1=第一阶段 / 2=第二阶段 / 3=第三阶段 / 4=全部连续播放 / 5=彩带版本（全部连续播放） / off=停止")
		return
	if not _playfield_ready or _board == null:
		SceneManager.show_toast("请等待游戏盘面入场完成")
		return
	var quota_bottom: float = (_quota.get_global_transform() * Vector2(0.0, _quota.size.y)).y
	var pot_top: float = _board.pot_top_global_y()
	var center: Vector2 = Vector2(UiMetrics.viewport_size().x * 0.5, (quota_bottom + pot_top) * 0.5)
	_combo_feedback.preview_fullscreen_stage(selection.to_int(), get_global_transform().affine_inverse() * center)



func _cmd_combo_preview(args: Array[String], timing_feedback_enabled: bool = false) -> void :
	var usage: String = "Combo 时机2.0（最终七档）：all / 1~7（Nice!~Legendary!）/ off" if timing_feedback_enabled else (
		"Combo 预览参数：all / 正整数（1~6=Nice!~Unstoppable!，7及以上=Legendary!）/ off")
	if args.size() > 1:
		SceneManager.show_toast(usage)
		return
	var selection: String = args[0] if not args.is_empty() else "all"
	if selection == "off":
		_combo_feedback.hide_now()
		return
	var combos: Array[int] = []
	if selection == "all":
		for index: int in ComboFeedback.SKINS.size():
			combos.append(index + 2)
	elif selection.is_valid_int() and selection.to_int() >= 1:
		var tier: int = selection.to_int()
		if timing_feedback_enabled and tier > ComboFeedback.SKINS.size():
			SceneManager.show_toast(usage)
			return
		combos.append(tier + 1)
	else:
		SceneManager.show_toast(usage)
		return
	if not _playfield_ready or _board == null:
		SceneManager.show_toast("请等待游戏盘面入场完成")
		return

	var quota_bottom: float = (_quota.get_global_transform() * Vector2(0.0, _quota.size.y)).y
	var pot_top: float = _board.pot_top_global_y()
	var center: Vector2 = Vector2(UiMetrics.viewport_size().x * 0.5, (quota_bottom + pot_top) * 0.5)
	_combo_feedback.hide_now()
	_combo_feedback.play(combos, get_global_transform().affine_inverse() * center, 
		[], false, timing_feedback_enabled)


func _cheat_preview_challenge_banner(args: Array[String]) -> void :
	if not await _prepare_preview_components(["preview"]):
		return
	if args.is_empty():
		_show_challenge_banner(TranslationServer.get_locale())
		return
	var locales: Array[String] = ["en", "fr", "ru", "es", "pt"]
	var language_index: int = args[0].to_int() - 1 if args.size() == 1 and args[0].is_valid_int() else -1
	if language_index < 0 or language_index >= locales.size():
		SceneManager.show_toast("Challenge 语言：1 英语 / 2 法语 / 3 俄语 / 4 西班牙语 / 5 葡萄牙语")
		return
	_show_challenge_banner(locales[language_index])




func _poll_hint_guide(delta: float) -> void :
	if _hint_guide_background_paused:
		_stop_rope_guide()
		return
	if _hint_guide_skip_frame:
		_hint_guide_skip_frame = false
		return
	var paused: bool = _hint_guide_is_suspended()
	_hint_guide_tracker.advance(delta, paused)
	if paused:
		_stop_hint_guide(true)
		return
	if not _hint_guide_tracker.is_idle():
		return
	if not _hint_guide_unwinnable_key.is_empty():
		if _hint_guide_unwinnable_key != _hint_state_key():
			_hint_guide_unwinnable_key = ""
			_stop_rope_guide()
		else:
			if not _rope_guide_has_access():
				_stop_rope_guide()
			elif not _rope_guide_playing and not _board.has_active_drag():
				_rope_guide_playing = true
				(_prop_ui["rope"]["btn"] as PropBtn).set_dead_glow(true)
			return
	var available: bool = _hint_guide_has_access()
	if not available:
		_stop_hint_guide()

		if not _rope_guide_has_access():
			return
	if _hint_guide_playing or _board.has_active_drag():
		return
	var state_key: String = _hint_state_key()
	if _hint_guide_checked_key != state_key:
		var cached: Dictionary = _hint_try_sync()
		_hint_guide_checked_key = state_key
		if cached.is_empty():
			if _hint_cache_key != state_key:
				_hint_dispatch(false, true)
			return
	if not available or _hint_cache_key != state_key or _hint_cache.is_empty():
		return
	var btn: PropBtn = _prop_ui["hint"]["btn"] as PropBtn
	_hint_guide_playing = btn.play_hint_guide_motion(true, false)


func _hint_guide_has_access() -> bool:
	var btn: PropBtn = _prop_ui["hint"]["btn"] as PropBtn
	if btn.disabled or btn.get_state() in [PropBtn.PropState.LOCKED, PropBtn.PropState.DISABLED, PropBtn.PropState.NOT_READY]:
		return false

	return HintGuideTracker.has_access(UserState.is_prop_free_available("hint"), 
		_prop_count("hint"), UserState.get_coins(), btn.get_base_coin_price(), 
		bool(_prop_ad_ready.get("hint", false)))


func _rope_guide_has_access() -> bool:
	if is_endless() or not _prop_ui.has("rope") or _board == null or _board.has_rope():
		return false
	var btn: PropBtn = _prop_ui["rope"]["btn"] as PropBtn
	if not is_instance_valid(btn) or not btn.is_visible_in_tree() or btn.disabled or btn.is_pressed()\
	or btn.is_unlock_highlight_playing()\
	or btn.get_state() in [PropBtn.PropState.LOCKED, PropBtn.PropState.DISABLED, PropBtn.PropState.NOT_READY]:
		return false
	return HintGuideTracker.has_access(UserState.is_prop_free_available("rope"), 
		_prop_count("rope"), UserState.get_coins(), btn.get_base_coin_price(), 
		bool(_prop_ad_ready.get("rope", false)))


func _stop_rope_guide() -> void :
	if not _rope_guide_playing:
		return
	_rope_guide_playing = false

	if _board != null and _board.over() == "dead":
		return
	if _prop_ui.has("rope"):
		var btn: PropBtn = _prop_ui["rope"]["btn"] as PropBtn
		if is_instance_valid(btn):
			btn.set_dead_glow(false)


func _hint_guide_is_suspended() -> bool:
	if is_instance_valid(_root_swap_guide) or not _root_swap_guide_pending.is_empty():
		return true
	if _sunlight_guide_running:
		return true
	if _hint_guide_background_paused or not is_visible_in_tree() or not _playfield_ready\
	or not _ui_props_ready or _opening_banner_input_locked or _tutorial_active\
	or _end_flow_running or _complete_shown or _prop_ad_in_flight:
		return true
	if _board == null or _board.over() != "" or _board.is_busy() or _has_cup_flights()\
	or _board.has_active_hint() or _hint_task_id != HINT_TASK_NONE\
	or not _root_hint_pending_key.is_empty() or not _prop_ui.has("hint"):
		return true
	if is_instance_valid(_unlock_overlay) and _unlock_overlay.visible:
		return true
	if is_instance_valid(_mystery_guide) or (is_instance_valid(_lock_guide) and _lock_guide.is_open()):
		return true
	for route: String in ["setting", "prop_unlock", "confirm", "privacy", "finish"]:
		var dialog: Node = SceneManager.get_page(route)
		if is_instance_valid(dialog) and dialog.visible:
			return true
	return false


func _stop_hint_guide(immediate: bool = false) -> void :
	_stop_rope_guide()
	if not _hint_guide_playing:
		return
	_hint_guide_playing = false
	(_prop_ui["hint"]["btn"] as PropBtn).stop_hint_guide_motion(immediate)


func _reset_hint_guide(immediate: bool = false) -> void :
	_hint_guide_tracker.reset()
	_stop_hint_guide(immediate)


func _on_hint_guide_button_down() -> void :
	_reset_hint_guide(true)
	_clear_hint_guide_motion(true)


func _clear_hint_guide_motion(immediate: bool = false) -> void :

	_stop_rope_guide()
	_hint_guide_playing = false
	if _prop_ui.has("hint"):
		(_prop_ui["hint"]["btn"] as PropBtn).stop_hint_guide_motion(immediate)


func _cmd_darkness(args: Array[String]) -> void :
	if args.size() != 1 or not args[0].is_valid_float():
		SceneManager.show_toast("压暗百分比请输入 0~100")
		return
	var percent: float = args[0].to_float()
	if not is_finite(percent) or percent < 0.0 or percent > 100.0:
		SceneManager.show_toast("压暗百分比请输入 0~100")
		return
	JuiceFruit.debug_darkness_percent = percent
	JuiceFruit.debug_flower_brightness_percent = 100.0 - percent
	_apply_debug_darkness()
	_apply_debug_flower_brightness()
	SceneManager.show_toast("背景、花朵与花盆已压暗 %g%%" % percent)




func _apply_game_visuals() -> void :
	_iq_progress.set_rules_layout_enabled(_rules_guide_round)
	_quota.panel_style.modulate_color = SOFT_UI_TINT
	_quota.queue_redraw()
	_reset_bg.self_modulate = SOFT_UI_TINT
	for key: String in _prop_ui:
		var btn: PropBtn = _prop_ui[key]["btn"]
		(btn.get_node("Bg") as TextureRect).self_modulate = SOFT_UI_TINT
	_board.set_background_highlights(true)
	_board.set_drop_hover_tint(SOFT_DROP_HOVER_TINT)
	_apply_background()
	_apply_debug_darkness()
	_apply_debug_flower_brightness()


func _apply_background() -> void :
	var christmas_visible: bool = _christmas_theme_enabled
	_christmas_background.visible = christmas_visible
	_background.visible = not christmas_visible
	if christmas_visible:
		_christmas_background.color = _christmas_theme.background_color
		for i: int in _christmas_decorations.size():
			_christmas_decorations[i].texture = _christmas_theme.decoration_textures[i]
		_layout_christmas_background()
	_background.texture = _default_background_texture
	_background.stretch_mode = TextureRect.STRETCH_SCALE
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _cmd_flower_brightness(args: Array[String]) -> void :
	if args.size() != 1 or not args[0].is_valid_float():
		SceneManager.show_toast("花朵与花盆亮度请输入 0~200，100=原亮度")
		return
	var percent: float = args[0].to_float()
	if not is_finite(percent) or percent < 0.0 or percent > 200.0:
		SceneManager.show_toast("花朵与花盆亮度请输入 0~200，100=原亮度")
		return
	JuiceFruit.debug_flower_brightness_percent = percent
	_apply_debug_flower_brightness()
	SceneManager.show_toast("花朵与花盆亮度已设为 %g%%" % percent)


func _apply_debug_flower_brightness() -> void :
	for flower: Node in get_tree().get_nodes_in_group("juice_flower_debug_brightness"):
		flower.apply_debug_brightness()
	var brightness: float = JuiceFruit.get_debug_flower_brightness()
	for child: Node in _fly_layer.get_children():
		if child is SpineSprite:
			var spr: SpineSprite = child as SpineSprite
			spr.self_modulate = Color(brightness, brightness, brightness, spr.self_modulate.a)
	_quota.queue_redraw()


func _apply_debug_darkness() -> void :
	var brightness: float = 1.0 - JuiceFruit.debug_darkness_percent / 100.0
	_christmas_background.modulate = Color(brightness, brightness, brightness, _christmas_background.modulate.a)
	var base_tint: Color = SOFT_BACKGROUND_TINT
	var tint: Color = base_tint * Color(brightness, brightness, brightness, 1.0)
	_background.self_modulate = Color(tint.r, tint.g, tint.b, _background.self_modulate.a)


func _cheat_win_round() -> void :
	if is_endless():
		if not _playfield_ready or _end_flow_running or _has_cup_flights():
			return
		if is_instance_valid(_endless_controller):
			_endless_controller._finish_time_up()
		return
	if _board == null or _board.level() == null or _board.over() != "":
		return
	if not _playfield_ready or _end_flow_running or _has_cup_flights():
		return
	_board.cheat_force_win()

	_commit_win_data_once()





func _cheat_complete_column() -> void :
	var blocked: String = _cheat_complete_column_block_reason()
	if not blocked.is_empty():
		SceneManager.show_toast("完成一列跳过：" + blocked)
		return
	if not _board.complete_column_prop():
		SceneManager.show_toast("完成一列失败："\
		+ _complete_column_reason_text(_board.complete_column_fail_reason()))
		return

	_refresh_prop_btns()



func _cheat_complete_column_block_reason() -> String:
	if not is_visible_in_tree():
		return "游戏页不可见"
	if not _playfield_ready:
		return "盘面入场未完成"
	if _tutorial_active:
		return "新手教学进行中"
	if _win_committed:
		return "已判胜并提交"
	if _end_flow_running:
		return "通关流程进行中"
	if _has_cup_flights():
		return "花盆正在飞向订单栏"
	if _hint_task_id != HINT_TASK_NONE:
		return "Hint 求解中"
	if _board == null:
		return "盘面未就绪"
	return ""



func _complete_column_reason_text(reason: String) -> String:
	match reason:
		"input_locked": return "盘面输入被锁定"
		"entrance_lock": return "入场锁未解除"
		"hint_lock": return "提示展示中"
		"flight": return "上一列仍在飞行中"
		"entrance_motion": return "入场位移或惯性未停"
		"board_over": return "盘面已结束"
		"no_level": return "盘面无有效关卡或列"
		"busy": return "收盆/补位动画中"
		"drag": return "拖拽中"
		"returning": return "花朵归位中"
		"demo": return "提示演示中"
		"no_column": return "没有可凑满的彩盆列"
		_: return reason if not reason.is_empty() else "未知原因"



func _cheat_last_cup() -> void :
	if _board == null or _board.level() == null or _level_model == null\
	or _tutorial_active or _win_committed or _end_flow_running or _has_cup_flights()\
	or not _board.cheat_prepare_last_cup():
		SceneManager.show_toast("当前盘面暂不能布置最后一杯")
		return
	_save_progress("cheat")
	_refresh_prop_btns()
	SceneManager.show_toast("只差最后一步，拖动花串完成本局")



static func _sort_die_attribution(args: Array[String]) -> int:
	if args.size() == 1:
		match args[0]:
			"1":
				return S.DeathAttribution.LAST_MOVE
			"2":
				return S.DeathAttribution.EARLIER
			"3":
				return S.DeathAttribution.UNKNOWN
	return -1



func _cheat_force_die(args: Array[String]) -> void :
	if _board == null or _board.level() == null or _board.over() != "":
		return
	if args.is_empty():

		_board.cheat_force_dead()
		return
	var attribution: int = _sort_die_attribution(args)
	if attribution < 0:
		SceneManager.show_toast("sort_die 参数只接受 1、2、3")
		return
	_board.cheat_force_dead("stuck", attribution)




func _cheat_preview_smart_move() -> void :
	if not await _prepare_preview_components(["preview"]):
		return
	_challenge_clear_joint = _board.get_global_transform() * (_board.size * 0.5)
	var cols: Array = _board.state().get("cols", [])
	for ci: int in _board.order():
		var n: int = (cols[ci] as Array).size()
		if n >= 2:
			_challenge_clear_joint = (_board.fruit_global_pos(ci, n - 2)
				+ _board.fruit_global_pos(ci, n - 1)) * 0.5
			break
	_play_challenge_clear_fx()








func _cheat_force_bonus_level(args: Array[String]) -> void :
	if _level_model == null or _level_model.juice == null or _tutorial_active or is_special_challenge():
		SceneManager.show_toast("当前局不支持强制 Bonus Level")
		return
	if _board.is_busy():
		SceneManager.show_toast("盘面动画中，稍后再试")
		return
	if not args.is_empty() and args[0] not in ["on", "off"]:
		SceneManager.show_toast("用法：bonus_level on / off")
		return
	var turn_on: bool = args.is_empty() or args[0] != "off"

	_bonus_v2 = BonusLevelEntry.is_v2_enabled()
	if turn_on and not JuiceBonusLevel.has_bonus_candidate(_level_model.juice, _bonus_v2):
		SceneManager.show_toast("这关没有可用的单盆颜色，无法生成金猪；换一个普通关再试")
		return
	if turn_on and not await _prepare_preview_components(["bonus"]):
		return
	_cancel_bonus_collection()
	_cancel_win_coin_reward()
	_win_committed = false
	_win_completion_payload = {}
	_win_completion_iq = {}
	_win_coin_reported = false
	_reset_end_flow_state()
	_cancel_cup_flights()
	if _bonus_pig_hud != null:
		_bonus_pig_hud.hide_now()
	if _bonus_pig_smash != null:
		_bonus_pig_smash.hide_now()
	_bonus_coin_reward = 0
	_bonus_coin_pending = 0
	_board.set_bonus_candidate(turn_on, _bonus_v2)
	_configure_root_swapping()
	_board.setup(_level_model.juice, {}, _level_model.color_slots)
	_bonus_type = _board.bonus_type()
	_quota.setup(_level_model.juice.groups_total)
	_configure_iq_round()
	_on_cups_changed()
	_sync_level_card()

	_save_initial_snapshot("cheat")
	request_round_deferred_preparation()
	_play_bonus_restart_entrance()
	if turn_on and _bonus_type >= 0:
		var present: bool = (_board.state()["jars"] as Array).has(_bonus_type)
		SceneManager.show_toast("金猪已启用：开局花盆位出现" if present else "金猪已启用：在后续补充花盆中出现")
	else:
		SceneManager.show_toast("已恢复普通关")



func _hard_banner_style() -> GameStartBanner.HardStyle:
	if ABManager.hard_level_banner_style.is_new_style_enabled():
		return GameStartBanner.HardStyle.NEW
	if ABManager.hard_level_banner_style.is_flower_character_enabled():
		return GameStartBanner.HardStyle.FLOWER_CHARACTER
	return GameStartBanner.HardStyle.ORIGINAL


func _cheat_preview_hard_banner(args: Array[String], super_hard: bool = false) -> void :
	if _start_banner == null or not is_instance_valid(_start_banner) or _start_banner.visible:
		return
	var chapter_index: int = _level_model.chapter_index if _level_model != null\
	else LevelIndex.chapter_of(UserState.get_current_level())
	if not args.is_empty() and args[0].is_valid_int():
		chapter_index = maxi(int(args[0]), 1)
	await _start_banner.show_hard(chapter_index, super_hard, _hard_banner_style())


func _streak_percentile(count: int) -> float:
	return ResultPercentileBank.lookup_streak_percentile(count, ABManager.game_data_2_0.is_new_result_data_enabled())




func _cheat_preview_streak_banner(args: Array[String]) -> void :
	if _start_banner == null or not is_instance_valid(_start_banner) or _start_banner.visible:
		return
	var count: int = 10
	if not args.is_empty() and args[0].is_valid_int():
		count = clampi(int(args[0]), 1, 999)
	var group: int = ABManager.streak_banner.value()
	if args.size() >= 2 and args[1].is_valid_int():
		group = clampi(int(args[1]), 0, 2)
	await _start_banner.show_streak(count, group, Callable(), _streak_percentile(count))


const _TRAIL_SLOT_NAMES: PackedStringArray = [
	"红", "紫", "粉", "浅蓝", "黄", "绿", "蓝", "青绿", "橙", "淡紫", 
]




func _cheat_preview_trail(args: Array[String]) -> void :
	if _board == null or _board.level() == null:
		SceneManager.show_toast("先进一局再预览拖尾")
		return
	if args.is_empty() or args[0].strip_edges().is_empty():
		_board.cheat_preview_trail(-1)
		SceneManager.show_toast("依次预览 10 种拖尾")
		return
	if not args[0].is_valid_int():
		SceneManager.show_toast("trail 参数是 0~9，留空播全部")
		return
	var slot: int = int(args[0])
	if slot < 0 or slot >= _TRAIL_SLOT_NAMES.size():
		SceneManager.show_toast("trail 参数是 0~9，留空播全部")
		return
	_board.cheat_preview_trail(slot)
	SceneManager.show_toast("预览拖尾：%s" % _TRAIL_SLOT_NAMES[slot])



func _undo_guide_motion_btn() -> PropBtn:
	var ui: Dictionary = _prop_ui.get("undo", {}) as Dictionary
	var btn: Variant = ui.get("btn")
	return btn as PropBtn if is_instance_valid(btn) else null



func _stop_undo_guide_motion_preview(immediate: bool = true) -> void :
	var btn: PropBtn = _undo_guide_motion_btn()
	if btn != null and (immediate or btn.is_undo_guide_motion_playing()):
		btn.stop_undo_guide_motion(immediate)



func _on_undo_guide_action() -> void :
	_stop_undo_guide_motion_preview()



func _undo_guide_motion_preview_blocked() -> bool:
	if is_instance_valid(_root_swap_guide) or not _root_swap_guide_pending.is_empty():
		return true
	if not is_node_ready() or not is_visible_in_tree() or _hint_guide_background_paused:
		return true
	if not _playfield_ready or not _ui_props_ready or _opening_banner_input_locked or _sunlight_guide_running\
	or _tutorial_active or _end_flow_running or _complete_shown or _win_committed:
		return true
	if _board == null or _board.level() == null or _board.over() != ""\
	or _board.is_busy() or _board.has_active_drag() or _board.has_active_hint():
		return true
	if _unlock_reveal_key != "" or (_unlock_overlay != null\
	and is_instance_valid(_unlock_overlay) and _unlock_overlay.is_open()):
		return true

	for key: String in _prop_ui:
		var button: Variant = (_prop_ui[key] as Dictionary).get("btn")
		if not is_instance_valid(button):
			continue
		var btn: PropBtn = button as PropBtn
		if btn != null and btn.is_unlock_highlight_playing():
			return true
	if _lock_guide != null and is_instance_valid(_lock_guide) and _lock_guide.is_open():
		return true
	if _mystery_guide != null and is_instance_valid(_mystery_guide)\
	and _mystery_guide.is_running():
		return true
	for route: String in ["game_dead_toast", "reset_confirm"]:
		var dlg: CanvasItem = SceneManager.get_page(route) as CanvasItem
		if dlg != null and is_instance_valid(dlg) and dlg.is_visible_in_tree():
			return true
	return false






func _decide_bonus_enabled() -> bool:
	_bonus_v2 = false
	if _level_model != null and not (_level_model.coin_bonus_rule.get("rule", {}) as Dictionary).is_empty():
		return false
	if _level_model != null and _level_model.raw.has("sunlightPotSource"):
		return false
	if _tutorial_active or is_special_challenge():
		return false
	if not JuiceBonusLevel.is_bonus_level(UserState.get_current_level()):
		return false


	if ABManager.is_ab_init_done():
		ABManager.dye_at_bonus_level()
	_bonus_v2 = BonusLevelEntry.is_v2_enabled()
	return true



func _maybe_show_bonus_skip_toast() -> void :
	if not OS.is_debug_build() or not _bonus_v2:
		return
	var reason: String = _board.bonus_skip_reason()
	if reason.is_empty():
		return
	var why: String = "本局没有只占一盆的颜色" if reason == JuiceBonusLevel.REASON_NO_SINGLE_POT\
	else "单盆颜色都只在补货列，首屏看不到"
	SceneManager.show_toast("第 %d 关奖励关跳过：%s" % [UserState.get_current_level(), why])



func is_bonus_level_round() -> bool:
	return _bonus_type >= 0


func is_special_challenge() -> bool:
	return _level_model != null and _level_model.is_special_challenge()




func _round_storage_key() -> int:
	return UserState.get_current_level()



func _round_game_id() -> String:
	return LevelManager.get_game_id(_round_storage_key())

func _next_round_level_id() -> int:
	return UserState.get_current_level() if is_special_challenge() else _level_model.level_id + 1


func get_bonus_motion_preview_anchors() -> Dictionary:
	if not is_node_ready() or not is_visible_in_tree() or not _playfield_ready\
	or _board.is_busy() or _board.has_active_drag():
		return {}
	var order: Array = _board.get("_order")
	var geometry: Dictionary = {}
	for offset: int in range(order.size()):
		var slot: int = (floori(order.size() * 0.5) + offset) % order.size()
		geometry = _board.bonus_collection_preview_geometry(int(order[slot]))
		if not geometry.is_empty():
			break
	if geometry.is_empty():
		return {}
	var label_font: Font = _level_label.get_theme_font("font")
	var label_size: int = _level_label.get_theme_font_size("font_size")
	geometry["level_rect"] = _level_label.get_global_rect()
	geometry["level_text_width"] = label_font.get_string_size(_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	geometry["coin_rect"] = _coin_hud_icon.get_global_rect()

	var image: Image = _coin_hud_icon.texture.get_image()
	if image != null:
		var used: Rect2i = image.get_used_rect()
		var tex_size: Vector2 = _coin_hud_icon.texture.get_size()
		var ratio: float = minf(_coin_hud_icon.size.x / tex_size.x, _coin_hud_icon.size.y / tex_size.y)
		var pad: Vector2 = (_coin_hud_icon.size - tex_size * ratio) * 0.5
		var local: Rect2 = Rect2(pad + Vector2(used.position) * ratio, Vector2(used.size) * ratio)
		geometry["coin_rect"] = _coin_hud_icon.get_global_transform() * local
	return geometry

func get_special_reward_target(kind: String) -> Vector2:
	if kind == "coins":
		return _coin_hud_icon.get_global_rect().get_center()
	var button: Control = _prop_ui[kind]["btn"]
	return button.get_global_rect().get_center()

func get_special_reward_hud_controls() -> Dictionary:
	var props: Array[Control] = []
	for kind: String in ["undo", "hint", "rope", "fill_pot"]:
		if not _prop_ui.has(kind):
			continue
		var btn: Control = (_prop_ui[kind] as Dictionary)["btn"] as Control
		if btn != null and btn.visible:
			props.append(btn)

	if _reset_btn.visible:
		props.append(_reset_btn)
	return {"coins": _coin_hud, "props": props}

func append_special_challenge_coin_reward(tw: Tween, start_center: Vector2, 
		before: int, after: int, effect_parent: Node, 
		sprites: Array[SpineSprite], trails: Array[CPUParticles2D]) -> void :
	before -= _daily_checkin_round.pending_coin_display()
	after -= _daily_checkin_round.pending_coin_display()
	_set_coin_hud_display(before, after)
	var dst_center: Vector2 = _coin_hud_icon.get_global_rect().get_center()
	var count: int = clampi((after - before) / COIN_PER_TARGET, 1, WIN_COIN_FLY_COUNT)
	var last_delay: float = float(count - 1) * WIN_COIN_FLY_STAGGER
	var min_dur: float = WIN_COIN_POP_DUR + WIN_COIN_FLY_DUR * (1.0 - WIN_COIN_FLY_SPEED_RAND)
	var max_dur: float = WIN_COIN_POP_DUR + WIN_COIN_FLY_DUR * (1.0 + WIN_COIN_FLY_SPEED_RAND)
	for index: int in count:
		_append_coin_flight(tw, start_center, dst_center, index, count, sprites, trails, 
			Callable(), effect_parent)
	tw.tween_method(
		func(value: float) -> void : _coin_hud_label.text = str(int(round(value))), 
		float(before), float(after), maxf(WIN_COIN_FLY_STAGGER, last_delay + max_dur - min_dur)
	).set_delay(min_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tail_duration: float = WIN_COIN_TRAIL_LIFETIME * (1.0 + WIN_COIN_TRAIL_LIFETIME_RANDOMNESS)
	tw.tween_interval(last_delay + max_dur + maxf(WIN_COIN_PUNCH_DUR, tail_duration))

func await_special_challenge_reward() -> bool:
	_board.set_input_enabled(false)
	_back_btn.disabled = true
	_set_reset_buttons_disabled(true)

	var generation: int = _end_flow_generation
	while visible and generation == _end_flow_generation and not LevelManager.recover_special_challenge_completion():
		await get_tree().create_timer(0.5).timeout
	if not visible or generation != _end_flow_generation:
		return false
	var dialog = SceneManager.show_dlg("special_challenge_reward", {"host": self})
	if dialog == null:
		return false
	dialog.set_host(self)
	while visible and generation == _end_flow_generation and not dialog.was_claimed():
		await get_tree().process_frame
	var claimed: bool = dialog.was_claimed()
	SceneManager.hide_dlg("special_challenge_reward")
	return claimed and visible and generation == _end_flow_generation

func get_special_chest_origin() -> Vector2:
	return _special_challenge_chest.get_global_rect().get_center()

func get_round_entrance_generation() -> int:
	return _entrance_generation

func is_round_entrance_current(generation: int) -> bool:
	return visible and generation == _entrance_generation


func _cancel_bonus_collection() -> void :
	_bonus_collect_generation += 1
	_bonus_pot_collecting = false
	if is_instance_valid(_board):
		_board.stop_bonus_entry_feedback()


func _play_bonus_restart_entrance() -> void :
	await GameRestartFlow.run(self)


func _layout_rank_bar() -> void :
	if _rank_bar == null:
		return
	_rank_bar.scale = Vector2.ONE
	_rank_bar.pivot_offset = Vector2.ZERO
	_rank_bar.apply_layout(144.0 + UiMetrics.safe_insets().x)

func _board_top() -> float:
	return _base_board_top()

func play_rank_collect() -> bool:
	var rules_burst: bool = _rules_guide_round and _rank_collectible_type < 0
	var burst_motion: Dictionary = {}
	if rules_burst:
		burst_motion = {
			"pop_duration": WIN_COIN_POP_DUR, 
			"pop_distance_min": WIN_COIN_POP_DIST_MIN, 
			"pop_distance_max": WIN_COIN_POP_DIST_MAX, 
			"stagger": WIN_COIN_FLY_STAGGER, 
			"fly_duration": WIN_COIN_FLY_DUR, 
			"fly_speed_random": WIN_COIN_FLY_SPEED_RAND, 
			"arc_height": WIN_COIN_ARC_HEIGHT, 
			"arc_random": WIN_COIN_ARC_RAND, 
		}
	return await _rank_round.play_collect(self, _rank_collect_source, rules_burst, burst_motion)

func _rank_collect_source(index: int) -> Vector2:
	var generation: int = _end_flow_generation
	if _rank_collectible_type >= 0 and _rank_gift_slot >= 0:
		index = _rank_gift_slot
	var rect: Rect2 = _quota.cup_global_rect(index, null)
	if _rules_guide_round:
		return rect.get_center()

	var view: Rect2 = _quota.view_global_rect()
	var needs_scroll: bool = not view.encloses(rect)
	if _rank_collectible_type >= 0 and _rank_gift_slot >= 0:

		needs_scroll = not _quota.is_cup_fully_visible(index)
	_quota.reveal_slot(index)
	if needs_scroll:

		var deadline: int = Time.get_ticks_msec() + int(JuiceQuotaBar.AUTO_REVEAL_DUR * 1000.0)
		while visible and generation == _end_flow_generation and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	var texture: Texture2D = _board.target_icon_for_type(_rank_collectible_type) if _rank_collectible_type >= 0 else null
	return _quota.cup_global_rect(index, texture).get_center()

func _restore_rank_collectible_rule(restore: Dictionary) -> void :
	var saved: Variant = restore.get("rank_collectible_rule")
	if saved is Dictionary:
		_level_model.rank_collectible_rule = (saved as Dictionary).duplicate(true)


func _rank_collect_count(level: JuiceLevel) -> int:
	var activity: Dictionary = UserState.get_rank_current_entity()
	if not RankManager.is_valid_rank_in_game() or not bool(activity.get("collectible_column_count", false)):
		return level.groups_total
	var rule: Dictionary = _resolve_rank_collectible_rule()
	_level_model.rank_collectible_rule = rule
	var chosen: int = int(rule.get("type", -1))
	if int(rule.get("collectible_index", -1)) >= 0 and _level_model.rank_collectible_candidates(_bonus_type).has(chosen):
		return level.cup_caps[level.jar_seq.find(chosen)]
	return level.groups_total

func _resolve_rank_collectible_rule() -> Dictionary:
	var rule: Dictionary = _level_model.rank_collectible_rule
	var candidates: Array[int] = _level_model.rank_collectible_candidates(_bonus_type)
	var activity: Dictionary = UserState.get_rank_current_entity()
	var active_activity: bool = RankManager.is_valid_rank_in_game()
	var activity_id: String = String(activity.get("event_id", ""))
	var activity_index: int = RankManager.get_collectible_index()
	if rule.is_empty():
		var chosen: int = -1
		if not _tutorial_active and active_activity and activity_index >= 0:
			chosen = _pick_remaining_rank_collectible_type(candidates)
		rule = {"type": chosen, "collectible_index": activity_index if active_activity else _rank_round.collectible_index, 
			"season_id": activity_id if active_activity else _rank_round.season_id}
	elif active_activity and (int(rule.get("collectible_index", -1)) != activity_index\
	or String(rule.get("season_id", "")) != activity_id):

		rule = rule.duplicate(true)
		if activity_index >= 0 and not candidates.has(int(rule.get("type", -1))) and not _tutorial_active:
			rule["type"] = _pick_remaining_rank_collectible_type(candidates)
		rule["collectible_index"] = activity_index
		rule["season_id"] = activity_id
	return rule

func _pick_remaining_rank_collectible_type(candidates: Array[int]) -> int:
	var collected: Array = _board.state().get("cups", [])
	var remaining: Array[int] = []
	for type_id: int in candidates:
		if not collected.has(type_id):
			remaining.append(type_id)
	return remaining[randi_range(0, remaining.size() - 1)] if not remaining.is_empty() else -1

func _configure_rank_collectible(_resumed: bool) -> void :
	var rule: Dictionary = _resolve_rank_collectible_rule()
	_level_model.rank_collectible_rule = rule
	var candidates: Array[int] = _level_model.rank_collectible_candidates(_bonus_type)
	var chosen: int = int(rule.get("type", -1))
	var index: int = int(rule.get("collectible_index", -1))
	_rank_collectible_type = chosen if candidates.has(chosen) and index >= 0 and index < _skin_resources.default_skin.rank_collectible_elements.size() else -1
	_skin_refreshing = true
	_board.set_rank_collectible(_rank_collectible_type, index if _rank_collectible_type >= 0 else -1)
	_quota.apply_skin(_skin_resources)
	_skin_refreshing = false
	var cups: Array = _board.state().get("cups", [])
	_rank_gift_slot = cups.find(_rank_collectible_type) if _rank_collectible_type >= 0 else -1
	_prepare_rank_gift_flight()

func _rank_gift_empty_texture() -> Texture2D:
	var visual: JuiceSkinVisual = _skin_resources.rank_collectible_visual(&"empty_container")
	return visual.texture if visual != null else null

func _discard_prepared_rank_gift_flight() -> void :
	if is_instance_valid(_prepared_rank_gift_flight):
		_prepared_rank_gift_flight.reset_now()
		_prepared_rank_gift_flight.queue_free()
	_prepared_rank_gift_flight = null

func _prepare_rank_gift_flight() -> void :
	_discard_prepared_rank_gift_flight()
	if _rank_collectible_type < 0 or _skin_resources == null or _fly_layer == null:
		return
	var texture: Texture2D = _board.target_icon_for_type(_rank_collectible_type)
	if texture == null:
		return
	_prepared_rank_gift_flight = JuiceRankGiftFlight.new()
	_prepared_rank_gift_flight.prepare(texture, _rank_gift_empty_texture())
	_fly_layer.add_child(_prepared_rank_gift_flight)

func _acquire_rank_gift_flight(texture: Texture2D) -> JuiceRankGiftFlight:
	var gift: JuiceRankGiftFlight = _prepared_rank_gift_flight if is_instance_valid(_prepared_rank_gift_flight)\
	else JuiceRankGiftFlight.new()
	_prepared_rank_gift_flight = null
	gift.prepare(texture, _rank_gift_empty_texture())
	if gift.get_parent() == null:
		_fly_layer.add_child(gift)
	return gift


func _warm_rank_gift_textures(resources: JuiceSkinResolver, active: Callable) -> bool:
	if not active.call():
		return false
	if DisplayServer.get_name() == "headless":
		return true

	var template: JuiceSkinResolver = JuiceSkinResolver.new(resources.default_skin, resources.active_skin)
	template.set_rank_collectible(&"", 0)
	var empty: JuiceSkinVisual = template.rank_collectible_visual(&"empty_container")
	if empty == null:
		return active.call()
	var textures: Array[Texture2D] = [empty.texture]
	for index: int in resources.default_skin.rank_collectible_elements.size():
		template.set_rank_collectible(&"", index)
		var full: JuiceSkinVisual = template.rank_collectible_visual(&"target_icon")
		if full != null and not textures.has(full.texture):
			textures.append(full.texture)
	if _rank_gift_warmed_textures == textures:
		return active.call()
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "RankGiftTextureWarmup"
	viewport.world_2d = World2D.new()
	viewport.size = Vector2i(48 * textures.size(), 96)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	for index: int in textures.size():
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = textures[index]
		sprite.scale = Vector2.ONE * (40.0 / maxf(1.0, textures[index].get_size().x))
		sprite.position = Vector2(24.0 + float(index) * 48.0, 48.0)
		viewport.add_child(sprite)
	for _frame: int in 2:
		await get_tree().process_frame
		if not active.call():
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			viewport.queue_free()
			return false
		await RenderingServer.frame_post_draw
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.queue_free()
	if active.call():
		_rank_gift_warmed_textures = textures
	return active.call()

func _start_rank_gift_flight(slot: int, from_rect: Rect2) -> void :
	var texture: Texture2D = _board.target_icon_for_type(_rank_collectible_type)
	var gift: JuiceRankGiftFlight = _acquire_rank_gift_flight(texture)
	var dst: Callable = _quota.cup_global_rect.bind(slot, texture)
	var times: = Vector4(CUP_BLOOM_DUR, CUP_FLY_RISE_DUR, CUP_FLY_HOLD_DUR, CUP_FLY_DUR)
	var tw: Tween = gift.play(from_rect, dst, times, CUP_FLY_RISE, CUP_FLY_SPINE_PREROLL_LEAD, CUP_FLY_HOLD_RISE_RATIO)

	_append_cup_flight_sound(tw.set_parallel(true), false, slot)
	var rec: Dictionary = {"tw": tw, "gift_visual": gift, "slot": slot, 
		"tex": texture, "tint": _board.color_for_type(_rank_collectible_type)}
	_cup_flights.append(rec)
	tw.finished.connect(_on_cup_flight_finished.bind(rec), CONNECT_ONE_SHOT)


func get_end_flow_generation() -> int:
	return _end_flow_generation


func _on_same_color_merge_sound_requested(pitch: float) -> void :
	ABManager.dye_at_same_color_flower_merge_sfx()
	var selected_id: StringName = &"juice_move"
	if ABManager.same_color_flower_merge_sfx.is_merge_sfx_set1_enabled():
		selected_id = &"juice_merge_set1"
	elif ABManager.same_color_flower_merge_sfx.is_merge_sfx_set2_enabled():
		selected_id = &"juice_merge_set2"
	var sound: StringName = _skin_resources.sound_id(&"juice_move", selected_id)\
	if _skin_resources != null else selected_id
	AudioManager.play_sfx(sound, 1.0, pitch)



func _play_major_sound(id: StringName, preview: bool = false, slot: int = -1, 
		flight_sound: Dictionary = {}) -> void :
	var selected_id: StringName = id
	var experiment_eligible: bool = not preview and not is_endless()\
	and ( not is_instance_valid(_board) or not _board.tutorial_demo_only)
	if experiment_eligible:
		if id == &"juice_burst":
			ABManager.dye_at_combo_sfx_style()
		if id in [&"juice_burst", &"juice_quota"] and ABManager.combo_sfx_style.is_new_combo_sfx_enabled():
			selected_id = &"juice_burst_set1" if id == &"juice_burst"\
			else StringName("combo_set1_level%d" % clampi(_combo_sfx_counts.get(slot, 1), 1, 8))
	if not preview and id == &"juice_quota":
		_combo_sfx_counts.erase(slot)
	if not AudioManager.is_sfx_enabled():
		return

	if preview:
		_play_skin_sound(id)
		return
	var volume: float = 1.2 if id == &"juice_pick" or id == &"juice_burst" else 1.0

	var sound: StringName = _skin_resources.sound_id(id, selected_id) if _skin_resources != null else selected_id
	if flight_sound.has("pending") and id == &"juice_quota" and selected_id != id and sound == selected_id:


		flight_sound["id"] = sound
		flight_sound["volume"] = volume
		flight_sound["cue"] = maxf(0.0, CUP_FLY_DUR - (0.1 if selected_id == &"combo_set1_level2" else 0.09))
		return
	AudioManager.play_sfx(sound, volume)



func _append_cup_flight_sound(tween: Tween, preview: bool, slot: int) -> void :
	var flight_sound: Dictionary = {"pending": true}
	tween.tween_callback(_play_major_sound.bind(&"juice_quota", preview, slot, flight_sound))
	tween.tween_method(_cup_flight_sound_step.bind(flight_sound), 0.0, CUP_FLY_DUR, CUP_FLY_DUR)\
	.set_trans(Tween.TRANS_LINEAR)


func _cup_flight_sound_step(elapsed: float, flight_sound: Dictionary) -> void :
	if not flight_sound.has("id") or elapsed < float(flight_sound["cue"]):
		return
	AudioManager.play_sfx(flight_sound["id"], float(flight_sound["volume"]))
	flight_sound.erase("id")



func return_home(params: Dictionary = {}) -> void :
	if _home_navigation_running or not visible:
		return
	_home_navigation_generation += 1
	var generation: int = _home_navigation_generation
	_home_navigation_running = true
	await HomeNavigationFlow.run(self, params, func() -> bool:
		return is_instance_valid(self) and generation == _home_navigation_generation and _home_navigation_running)
	if is_instance_valid(self) and generation == _home_navigation_generation:
		_home_navigation_running = false



func begin_home_navigation() -> void :
	_teardown_root_swap_guide()
	var generation: int = _home_navigation_generation
	_play_timer.pause(&"home_navigation")
	_save_progress("exit")
	_flush_play_time("time_exit")
	LevelManager.flush()
	if not _tracking_background_reported:
		report_game_exit(TrackingEvents.EXIT_TYPE_RETURN_HOME)
	_home_navigation_saved = true
	_cancel_game_start()
	_end_flow_generation += 1
	_hint_cancel()
	_board.cancel_active_drag()

	var roots: Array[Node] = [self]
	for route: String in ["finish", "rank_game_finish", "rank_change", "rank_new_season", "rank_introduction", "rank_season_win", "game_dead_toast", "reset_confirm", "prop_unlock", "special_challenge_reward", "finish_ad_reward"]:
		var dialog: Node = SceneManager.get_page(route)
		if dialog != null and dialog.visible:
			roots.append(dialog)
	var batch_started: int = Time.get_ticks_usec()
	for root: Node in roots:
		_home_navigation_nodes.append({"node": root, "mode": root.process_mode})
		root.process_mode = Node.PROCESS_MODE_DISABLED
		var pending: Array[Node] = [root]
		while not pending.is_empty():
			var node: Node = pending.pop_back()
			if node is BaseButton:
				_home_navigation_nodes.append({"node": node, "disabled": node.disabled})
				node.disabled = true
			if node != root and node.process_mode != Node.PROCESS_MODE_INHERIT and node.process_mode != Node.PROCESS_MODE_DISABLED:
				_home_navigation_nodes.append({"node": node, "mode": node.process_mode})
				node.process_mode = Node.PROCESS_MODE_DISABLED
			pending.append_array(node.get_children())
			if Time.get_ticks_usec() - batch_started >= 2000:
				await get_tree().process_frame
				if not is_instance_valid(self) or generation != _home_navigation_generation or not _home_navigation_running:
					return
				batch_started = Time.get_ticks_usec()


func _restore_home_navigation_nodes() -> void :
	for state: Dictionary in _home_navigation_nodes:
		if not is_instance_valid(state.node):
			continue
		if state.has("mode"):
			state.node.process_mode = state.mode
		else:
			state.node.disabled = state.disabled
	_home_navigation_nodes.clear()


func cancel_home_navigation() -> void :
	_restore_home_navigation_nodes()
	_play_timer.resume(&"home_navigation")
	_home_navigation_saved = false
	_home_navigation_running = false



func show_daily_first_win_checkin() -> bool:
	var generation: int = _end_flow_generation
	var result: Dictionary = _daily_checkin_round.completion()
	if result.is_empty():
		return visible and generation == _end_flow_generation
	ABManager.dye_at_daily_first_win_checkin()
	if not bool(result["enabled"]):
		_daily_checkin_round.mark_presented()
		return visible and generation == _end_flow_generation
	result["coins_after"] = UserState.get_coins()
	result["coins_before"] = UserState.get_coins() - int(result["reward_coins"])
	result["on_reward_collected"] = _sync_daily_checkin_coin_huds.bind(generation)
	var dialog = SceneManager.show_dlg("daily_first_win_checkin", {"settlement": result})
	if dialog == null:
		_sync_daily_checkin_coin_huds(generation)
		refresh_economy_ui()
		return visible and generation == _end_flow_generation
	while visible and generation == _end_flow_generation and not dialog.is_closed():
		await get_tree().process_frame
	_sync_daily_checkin_coin_huds(generation)
	SceneManager.hide_dlg("daily_first_win_checkin")
	while visible and generation == _end_flow_generation and dialog.visible:
		await get_tree().process_frame
	if visible and generation == _end_flow_generation:
		refresh_economy_ui()
	return visible and generation == _end_flow_generation



func _sync_daily_checkin_coin_huds(generation: int) -> void :
	if not visible or generation != _end_flow_generation:
		return
	_daily_checkin_round.mark_presented()
	_refresh_coin_hud()
	var home_page: Node = SceneManager.get_page("home")
	if home_page != null and home_page.has_method("refresh_coin_hud"):
		home_page.call("refresh_coin_hud")



func is_endless() -> bool:
	return play_mode == PlayMode.ENDLESS


func endless_generation() -> int:
	return _endless_generation


func endless_session() -> JuiceEndlessSession:
	return _endless_controller.session if is_instance_valid(_endless_controller) else null


func start_endless(seed_value: Variant = null, skip_entrance: bool = false, entered_page: bool = false) -> void :
	if _prop_ad_in_flight:
		return
	_reset_time_bonus()
	_rank_collectible_type = -1
	_rank_gift_slot = -1
	if is_instance_valid(_board):
		_board.set_rank_collectible(-1, -1, false)
	play_mode = PlayMode.ENDLESS
	_endless_requested_seed = seed_value
	_endless_skip_entrance = skip_entrance
	_endless_generation += 1
	if _endless_context != null:
		_endless_context.aborted = true
	if is_instance_valid(_endless_controller):
		_endless_controller.cancel()
	_hint_cancel()
	_kill_entrance_tween()
	_cancel_ui_entrance()
	if _components_ready:
		_cancel_cup_flights()
	var ctx: = EndlessGameStartFlow.Context.new(self, _endless_generation, skip_entrance)
	ctx.params["play_enter_haptic"] = entered_page
	_endless_context = ctx
	show()
	_endless_start_count += 1
	await ENDLESS_START.run(ctx)
	_endless_start_count -= 1


func prepare_endless_view(ctx: EndlessGameStartFlow.Context) -> bool:
	if not is_node_ready():
		await ready
	var prepared: bool = await _prepare_for_show(ctx.active)
	if not prepared or not ctx.active():
		return false
	SceneManager.attach_button_feedback(self)
	ABManager.allow_root_swapping.reload_value()
	_skin_generation += 1
	var generation: int = _skin_generation
	var active: Callable = func() -> bool:
		return ctx.active() and generation == _skin_generation
	return await _prepare_skin_resources(active)


func begin_endless_round(_ctx: EndlessGameStartFlow.Context) -> void :
	_freeze_complete_prop_group()
	_teardown_root_swap_guide(true)
	_root_swap_guide_endless_id = LevelManager.new_transient_game_id()
	if _ctx.skip_opening_banner:
		_timed_clock_flight.dock_direct(_timer_alarm)
	else:
		_timed_clock_flight.prepare_target(_timer_alarm)
	ABManager.dye_at_new_guide()
	_freeze_rules_guide_group()
	if is_mainline_timed_endless():
		_reset_end_flow_state()
	_win_committed = false
	_win_completion_payload = {}
	_win_completion_iq = {}
	_win_coin_reported = false
	_tutorial_active = false
	_playfield_ready = false
	_bonus_type = -1
	_level_model = null
	_tracking_common = null
	_iq_round.reset(false, 0)
	_christmas_theme_enabled = ABManager.christmas_theme.is_christmas_theme_enabled()
	_apply_game_visuals()
	_board.set_ambient_sway_enabled(true)
	_configure_root_swapping()
	_quota.setup_endless()
	_quota.set_iq_layout_enabled(true)
	_iq_progress.show()
	_endless_mask.hide()
	_level_label.show()
	_level_label.add_theme_font_size_override("font_size", 64)
	_level_label.position = Vector2.ZERO
	_level_label.size = Vector2(_level_block.size.x, 76.0)
	_sync_level_card()
	_endless_display_seconds = -1
	_hard_badge.hide()
	_special_challenge_chest.hide()
	(_prop_ui["rope"]["btn"] as Control).hide()
	_back_btn.disabled = false
	_set_reset_buttons_disabled(false)
	if _endless_requested_seed == null:
		var value: int = _endless_rng.randi()
		if _endless_seed >= 0 and posmod(value, JuiceEndlessSettings.INITIAL_LAYOUTS.size()) == posmod(_endless_seed, JuiceEndlessSettings.INITIAL_LAYOUTS.size()):
			value += 1
		_endless_seed = value
	else:
		_endless_seed = int(_endless_requested_seed)
	if not is_instance_valid(_endless_controller):
		_endless_controller = JuiceEndlessController.new()
		add_child(_endless_controller)
		_endless_controller.attach(_board)
		_endless_controller.status_changed.connect(_refresh_endless_hud)
		_endless_controller.time_added.connect(_on_endless_time_added)
		_endless_controller.round_finished.connect(_on_endless_finished)
	_board.set_entrance_lock(true)
	_endless_controller.start(_endless_seed, false)

	_board.set_flowers_alpha(1.0)
	if _endless_background_paused:
		_endless_controller.pause(&"background")
	_play_timer.arm(0)
	_refresh_coin_hud()
	_layout()
	_prepare_ui_entrance()
	_set_ui_entrance_preparing(false)
	_refresh_prop_btns(true)
	set_process(true)


func play_endless_entrance(ctx: EndlessGameStartFlow.Context) -> void :
	entrance_style = EntranceStyle.SLIDE_WIND
	if ctx.skip_playfield_enter:
		_cancel_ui_entrance()
		_board.show()
		_playfield_ready = true
		_board.set_entrance_lock(false)
	else:
		await play_playfield_entrance(ctx)


func activate_endless_round() -> void :
	if is_mainline_timed_endless():
		ABManager.dye_at_level_target_coins()
		_round_target_coins = ABManager.level_target_coins.coins_per_target()
		if not UserState.begin_timed_endless(String(_mainline_timed_offer["instance_id"]), _round_target_coins):
			SortLogger.error("限时挑战开局保存失败，保留入口重试")
			_endless_context.aborted = true
			return
	if is_mainline_timed_endless():
		setup_endless_tracking_context()
		report_game_start()
	_endless_controller.activate_after_entry()
	_board.set_root_adjudication_suspended(false)
	_refresh_endless_hud()
	_refresh_prop_btns(true)


func _endless_can_use_props() -> bool:
	return is_instance_valid(_endless_controller) and _playfield_ready\
	and (_endless_controller.can_move() or _endless_controller.can_operate_dead())




func _update_endless_time_warning(delta: float) -> void :
	if not is_visible_in_tree() or not is_endless() or (_endless_context != null and _endless_context.aborted) or not is_instance_valid(_endless_controller) or _endless_controller.session == null or not _endless_controller.end_reason.is_empty():
		_reset_endless_time_warning()
		return
	var remaining: int = _endless_controller.remaining_ms()
	if remaining <= 0:
		_reset_endless_time_warning()
		return
	var now: int = _endless_controller.elapsed_ms()
	var clock_delta: float = maxf(0.0, float(now - _endless_warning_clock_ms) / 1000.0) if _endless_warning_clock_ms >= 0 else 0.0
	_endless_warning_clock_ms = now
	var enabled: bool = remaining <= ENDLESS_WARNING_MS
	_endless_warning_envelope = move_toward(_endless_warning_envelope, 1.0 if enabled else 0.0, delta / 0.4)
	var urgent: bool = remaining <= ENDLESS_WARNING_URGENT_MS
	if enabled:
		_endless_warning_phase = fmod(_endless_warning_phase + clock_delta * TAU / (1.1 if urgent else 1.6), TAU)
	elif _endless_warning_envelope <= 0.0:
		_endless_warning_phase = 0.0
	var pulse: float = (1.0 - cos(_endless_warning_phase)) * 0.5
	var alpha: float = lerpf(0.06, 0.36 if urgent else 0.3, pulse) * _endless_warning_envelope
	var mat: ShaderMaterial = _endless_time_warning.material as ShaderMaterial
	mat.set_shader_parameter("viewport_size", UiMetrics.viewport_size())
	mat.set_shader_parameter("strength", alpha)
	_endless_time_warning.visible = _endless_warning_envelope > 0.0


func _reset_endless_time_warning() -> void :
	_endless_warning_envelope = 0.0
	_endless_warning_phase = 0.0
	_endless_warning_clock_ms = -1
	_endless_time_warning.hide()
	(_endless_time_warning.material as ShaderMaterial).set_shader_parameter("strength", 0.0)


func _refresh_endless_hud() -> void :
	if not is_endless() or not _components_ready or not is_instance_valid(_endless_controller) or _endless_controller.session == null:
		return
	_quota.set_collected_count(int(_endless_controller.session.state["done"]))
	var remaining: int = _endless_controller.remaining_ms()
	_iq_progress.set_countdown_progress(float(remaining) / float(JuiceEndlessSettings.INITIAL_TIME_MS))
	var seconds: int = ceili(float(remaining) / 1000.0)
	if seconds != _endless_display_seconds:
		_endless_display_seconds = seconds
		_timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
		_layout_endless_timer()


func _on_endless_finished(cups: int, reason: String) -> void :
	_reset_endless_time_warning()
	if not is_endless():
		return
	_reset_time_bonus()
	_hide_dead_toast()
	if is_mainline_timed_endless():
		if _timed_finish_running or not prepare_mainline_timed_reward(reason, cups):
			return
		_timed_finish_running = true

		_report_endless_result(reason)
		_hint_cancel()
		_cancel_cup_flights()
		_quota.set_endless_cups(_board.cup_textures(), _board.cup_colors(), cups)
		_back_btn.disabled = true
		endless_finished.emit(cups, reason)
		var finish_generation: int = _end_flow_generation
		await MainlineTimedEndlessEndFlow.run(self, int(_timed_result["after_level"]))
		if finish_generation == _end_flow_generation:
			_timed_finish_running = false
		return
	_hint_cancel()
	_cancel_cup_flights()
	_quota.set_endless_cups(_board.cup_textures(), _board.cup_colors(), cups)
	_endless_message.text = "本局结束\n%s\n已收 %d 盆" % [_endless_controller.end_message(), cups]
	_endless_mask.show()
	_refresh_endless_hud()
	_refresh_prop_btns()
	endless_finished.emit(cups, reason)


func pause_endless(reason: StringName = &"menu", timer_only: bool = false) -> void :
	if is_instance_valid(_endless_controller):
		_endless_controller.pause(reason, timer_only)


func resume_endless(reason: StringName = &"menu") -> void :
	if is_instance_valid(_endless_controller):
		_endless_controller.resume(reason)


func stop_endless() -> void :
	if is_node_ready():
		_timed_clock_flight.reset_now()
	if is_node_ready():
		_reset_endless_time_warning()
	_reset_time_bonus()
	if is_instance_valid(_timer_row):
		_timer_row.hide()
	_set_ui_entrance_preparing(false)
	_endless_generation += 1
	if _endless_context != null:
		_endless_context.aborted = true
	_cancel_opening_banner_input_lock()
	if _start_banner != null:
		_start_banner.hide_now()
	_hide_timed_reward_now()
	_hint_cancel()
	if is_instance_valid(_endless_controller):
		_endless_controller.cancel()
	_kill_entrance_tween()
	_cancel_ui_entrance()
	if _components_ready:
		_cancel_cup_flights()
	if is_instance_valid(_board):
		_board.cancel_active_drag()
		_board.set_input_enabled(false)
		_board.set_process(true)
	_play_timer.disarm()
	if is_instance_valid(_endless_mask):
		_endless_mask.hide()
	set_process(false)


func suspend_external_play() -> void :
	_teardown_root_swap_guide()
	_external_play_suspended = true
	_play_timer.pause(&"external_preview")
	if is_endless():
		pause_endless(&"external_preview")
		if is_mainline_timed_endless() and _timed_result.is_empty():
			if not UserState.checkpoint_timed_endless(String(_mainline_timed_offer["instance_id"]), _endless_cups()):
				SortLogger.error("限时挑战调试暂停检查点保存失败")
	_hint_cancel()
	if is_instance_valid(_board):
		_board.cancel_active_drag()


func resume_external_play() -> void :
	_external_play_suspended = false
	_play_timer.resume(&"external_preview")
	if is_endless():
		resume_endless(&"external_preview")
	_refresh_coin_hud()
	if _components_ready:
		_refresh_prop_btns()


func finish_endless_resource_requests(active: Callable) -> void :
	if _components == null:
		return
	_components.cancel()
	await _components.wait_idle()
	var paths: PackedStringArray = []
	for path: String in COMPONENT_SCENES["core"].values():
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			paths.append(path)

	if not paths.is_empty() and active.call():
		await _components.ensure_resources(paths, active)



func prepare_skin(ctx: GameStartContext) -> bool:
	_skin_generation += 1
	_pending_special_theme_assignment.clear()
	var generation: int = _skin_generation
	var active: Callable = func() -> bool:
		return visible and not ctx.aborted and ctx == _start_flow_context and generation == _skin_generation
	var model: JuiceLevelModel = _level_model
	if model == null or not active.call():
		return false
	var assignment: Dictionary = _resolve_special_theme_assignment(model, 
		should_run_tutorial_now(ctx.current_state), bool(ctx.params.get("special_reward_pending", false)))
	var prepared: bool = await _prepare_skin_resources(active, StringName(assignment["skin_id"]))
	if not prepared or not active.call():
		return false
	assignment["model"] = model
	_pending_special_theme_assignment = assignment
	return true



func _resolve_special_theme_assignment(model: JuiceLevelModel, tutorial: bool, reward_pending: bool) -> Dictionary:
	var special: bool = model.is_special_challenge()
	if not tutorial and not reward_pending and ABManager.special_theme.should_dye_on_level_enter(model.level_id, special):
		ABManager.dye_at_special_theme()
	var key: String = model.challenge_instance_id if special else "level:%d" % model.level_id
	return JuiceSpecialThemeResolver.resolve(model.level_id, special, model.challenge_instance_id, 
		model.special_theme_skin_id, tutorial, reward_pending, 
		ABManager.special_theme.should_use_theme(model.level_id, special), 
		UserState.get_special_theme_assignment(model.round_kind, key), UserState.get_special_theme_next_sequence())



func _commit_special_theme_assignment() -> bool:
	if _pending_special_theme_assignment.is_empty():
		return true
	var assignment: Dictionary = _pending_special_theme_assignment
	if assignment["model"] != _level_model or not visible:
		return false
	if assignment.has("sequence") and not UserState.commit_special_theme_assignment(
			assignment["round_kind"], assignment["round_key"], assignment["skin_id"], int(assignment["sequence"])):
		return false
	_level_model.special_theme_skin_id = String(assignment["skin_id"])
	_pending_special_theme_assignment = {}
	return true


func _prepare_skin_resources(active: Callable, skin_id: StringName = &"default") -> bool:
	var resources: JuiceSkinResolver = await GameSkinPreparer.prepare_resources(skin_catalog, skin_id, 
		get_tree(), active)
	if resources == null or not active.call():
		return false
	var started: int = Time.get_ticks_usec()
	_apply_skin_resources(resources, false)
	_log_skin_preparation(skin_id, "apply", started)
	var preparer: = GameEffectsPreparer.new()
	started = Time.get_ticks_usec()
	await preparer.run(self, active, resources)
	_log_skin_preparation(skin_id, "effects", started)
	if _components.is_ready("rank") and not await _warm_rank_gift_textures(resources, active):
		return false
	return active.call() and (DisplayServer.get_name() == "headless" or not preparer.should_run(null))



func request_next_skin_preparation() -> void :
	if not _win_committed or not is_instance_valid(_board):
		return
	var generation: int = _end_flow_generation
	if _next_skin_preparation_generation == generation:
		return
	_next_skin_preparation_generation = generation
	_prepare_next_skin(generation)


func _prepare_next_skin(generation: int) -> void :
	var active: Callable = func() -> bool:
		return is_inside_tree() and visible and generation == _end_flow_generation and not _next_pressed
	await get_tree().process_frame
	if not active.call():
		return
	var descriptor: Dictionary = LevelManager.preview_next_round_descriptor()
	var preview: Dictionary = await GameSkinPreparer.preview_skin(descriptor, get_tree(), active)
	if preview.is_empty() or preview["skin_id"] == "default" or not active.call():
		return
	var id: StringName = StringName(preview["skin_id"])
	var loader: = JuiceSkinLoader.new()
	var resources: JuiceSkinResolver = await loader.load_skin(skin_catalog, id, get_tree(), active)
	if resources == null or not active.call():
		return
	var can_work: Callable = func() -> bool: return _can_prepare_next_skin(generation)
	while active.call():
		if not await SceneManager.wait_preparation_permission(active, can_work):
			return

		var actual: Dictionary = await GameSkinPreparer.preview_skin(
			LevelManager.preview_next_round_descriptor(), get_tree(), active)
		if not active.call() or actual.is_empty():
			return
		if actual["skin_id"] != String(id):
			_next_skin_preparation_generation = -1
			request_next_skin_preparation()
			return
		var work_active: Callable = func() -> bool: return active.call() and can_work.call()
		resources = await GameSkinPreparer.prepare_resources(skin_catalog, id, get_tree(), work_active, "next_round")
		if resources == null:
			if not active.call():
				return
			if can_work.call():
				return
			continue
		if DisplayServer.get_name() == "headless":
			return
		var started: int = Time.get_ticks_usec()
		if await GameEffectsPreparer.prepare_mystery(_board, resources, work_active, Callable(), true):
			_log_skin_preparation(id, "background_effects", started)
			return
		if active.call():
			await get_tree().process_frame


func _can_prepare_next_skin(generation: int) -> bool:
	if not visible or generation != _end_flow_generation or _next_pressed or _home_navigation_running\
	or _hint_guide_background_paused or _finish_ad_busy or _finish_interstitial_busy\
	or not _complete_shown or not is_finish_presentation_complete()\
	or not PagePreparationCoordinator.can_prepare_background() or _has_cup_flights() or _board.is_busy():
		return false

	var ad_button: FinishAdButton = _complete_panel.get_node_or_null("AdButton") as FinishAdButton
	return ad_button == null or not ad_button.visible or not ad_button.get_settled_reward().is_empty()


func _log_skin_preparation(skin_id: StringName, stage: String, started: int) -> void :
	SortLogger.info("[SkinPrepare] skin=%s stage=%s elapsed_ms=%.2f" % [skin_id, stage, 
		(Time.get_ticks_usec() - started) / 1000.0])

func _skin_can_switch() -> bool:
	return (visible and _playfield_ready and not _end_flow_running and not _has_cup_flights()
		and ( not is_endless() or _endless_can_use_props())
		and _fly_end_tweens.is_empty() and not _board.is_busy() and not _board.has_active_drag()
		and not _board.is_drop_returning() and not _board.has_skin_demo() and not _board.has_skin_effects()
		and _tutorial_dir == null and _tutorial_layer == null and _mystery_layer == null
		and (_lock_guide == null or not _lock_guide.is_open())
		and not _board.is_entrance_motion_active() and not _progress_bling.is_playing() and not _progress_full_active
		and not _board.has_active_hint() and (_sunlight_guide == null or not _sunlight_guide.is_open()))

func _switch_skin(id: StringName) -> void :
	if not _skin_can_switch():
		SceneManager.show_toast("请等拖拽、收集和引导演示结束后再切换皮肤")
		return
	_skin_generation += 1
	var generation: int = _skin_generation
	var active: Callable = func() -> bool: return visible and generation == _skin_generation
	var resources: JuiceSkinResolver = await GameSkinPreparer.prepare_resources(skin_catalog, id, get_tree(), active, "cheat")
	if not active.call():
		return
	if resources == null:
		SceneManager.show_toast("皮肤准备失败，请查看错误日志")
		return
	if not _skin_can_switch():
		SceneManager.show_toast("盘面正在操作，本次皮肤切换未执行")
		return
	_apply_skin_resources(resources, true)
	SceneManager.show_toast("已切换皮肤：%s" % resources.active_skin.display_name)

func _apply_skin_resources(resources: JuiceSkinResolver, refresh: bool) -> void :
	if _skin_resources != null and _skin_resources.active_skin == resources.active_skin\
	and _skin_resources.default_skin == resources.default_skin:
		return
	_clear_skin_flight_pools()
	if _rank_collectible_type >= 0 and _level_model != null:
		var slot: int = _board.slot_for_type(_rank_collectible_type)
		if slot >= 0 and slot < JuiceTheme.COLOR_KEYS.size():
			resources.set_rank_collectible(JuiceTheme.COLOR_KEYS[slot], 
				int(_level_model.rank_collectible_rule.get("collectible_index", -1)))
	_skin_resources = resources
	_quota.apply_skin(resources)
	_progress_bling.apply_skin(resources)
	_skin_refreshing = true
	_board.apply_skin(resources, refresh)
	if refresh:
		_refresh_skin_quota()
	_skin_refreshing = false
	if refresh:
		_prepare_rank_gift_flight()
	_skin_loader.commit(resources)

func _refresh_skin_quota() -> void :
	if is_endless():
		_quota.set_endless_cups(_board.cup_textures(), _board.cup_colors(), int(_board.state().get("done", 0)))
		return
	var hidden_slots: Array[int] = []
	var cups: Array = _board.state().get("cups", [])
	for index: int in cups.size():
		if int(cups[index]) == _bonus_type and _bonus_type >= 0:
			hidden_slots.append(index)
	_quota.set_cups(_board.cup_textures(), _board.cup_colors(), hidden_slots)

func _clear_skin_flight_pools() -> void :
	_discard_prepared_rank_gift_flight()
	for pool: Array in [_fly_pool, _bloom_pool, _hover_pool, _pot_petal_pool]:
		for node: Node in pool:
			if is_instance_valid(node):
				node.queue_free()
		pool.clear()
	for pool: Array in _butterfly_pools:
		for node: Node in pool:
			if is_instance_valid(node):
				node.queue_free()
		pool.clear()

func _cmd_skin(args: Array[String]) -> void :
	if args.size() == 1 and args[0] == "list":
		SceneManager.show_toast("可用皮肤：%s" % ", ".join(PackedStringArray(skin_catalog.paths.keys())))
	elif args.size() == 1 and args[0] == "inspect":
		if _skin_resources != null:
			SortLogger.info("[skin] %s; slots=%s" % [_skin_resources.identity(), _board.skin_color_slots()])
			SceneManager.show_toast("当前皮肤：%s；未配置项使用默认皮肤" % _skin_resources.identity())
	elif args.size() == 2 and args[0] == "use":
		await _switch_skin(StringName(args[1]))
	else:
		SceneManager.show_toast("skin list / skin use <已登记ID> / skin inspect；default / cat / bird")


func _freeze_complete_sounds() -> void :
	ABManager.dye_at_complete_sfx_style()
	var selected_id: StringName = &"level_complete"
	_finish_cart_appear_sound_id = &"finish_cart_appear"
	if ABManager.complete_sfx_style.is_simple_style_enabled():
		selected_id = &"level_complete_simple"
		_finish_cart_appear_sound_id = &"finish_cart_appear_iterated"
	elif ABManager.complete_sfx_style.is_rich_style_enabled():
		selected_id = &"level_complete_rich"
		_finish_cart_appear_sound_id = &"finish_cart_appear_iterated"

	_level_complete_sound_id = _skin_resources.sound_id(&"level_complete", selected_id)\
	if _skin_resources != null else selected_id


func _play_complete_sound() -> void :
	AudioManager.play_sfx(_level_complete_sound_id)


func _play_skin_sound(id: StringName, volume: float = 1.0, pitch: float = 1.0) -> void :
	AudioManager.play_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id, volume, pitch)

func _stop_skin_sound(id: StringName) -> void :
	AudioManager.stop_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id)




func _shake_style() -> int:
	return ABManager.shake_v2.get_style()


func _play_game_haptic(event: int) -> int:
	return HapticManager.play_event(HapticProfiles.shake_event_for(event, _shake_style()))


func _play_move_haptic() -> void :
	var style: int = _shake_style()
	if style <= 0:
		HapticManager.play_event(HapticProfiles.Event.MOVE_OK)
	elif bool(_board.move_feedback_info().get("same_color_connection", false)):
		HapticManager.play_event(HapticProfiles.shake_event_for(HapticProfiles.Event.FLOWER_MERGE, style))



func _on_board_drop_target_entered(_col: int) -> void :
	if _board.tutorial_demo_only:
		return
	var style: int = _shake_style()
	if style > 0:
		HapticManager.play_event(HapticProfiles.shake_event_for(HapticProfiles.Event.MOVE_OK, style))



func play_finish_coin_haptic() -> int:
	var style: int = _shake_style()
	if style > 0:
		return HapticManager.play_event(HapticProfiles.shake_event_for(HapticProfiles.Event.COIN_FLY, style))
	return 0



func _play_game_enter_haptic(ctx) -> void :
	if ctx == null or ctx.aborted or not visible or not bool(ctx.params.get("play_enter_haptic", false)):
		return
	ctx.params.erase("play_enter_haptic")
	ABManager.dye_at_game_enter_haptic()
	if ABManager.game_enter_haptic.should_play_enter_haptic():
		_game_enter_haptic = HapticManager.play_event(HapticProfiles.Event.GAME_ENTER)


func is_mainline_timed_endless() -> bool:
	return is_endless() and not _mainline_timed_offer.is_empty()


func _endless_cups() -> int:
	return int(_endless_controller.session.state["done"]) if is_instance_valid(_endless_controller) and _endless_controller.session != null else 0


func settle_mainline_timed_endless(reason: String, cups: int) -> bool:
	if not is_mainline_timed_endless() or not _timed_result.is_empty():
		return true
	var offer: Dictionary = UserState.get_timed_endless_offer()

	if offer.get("status", "") == "reward_pending":
		return true
	if offer.get("status", "") != "playing":
		return reason == "exit"
	var completed: Dictionary = UserState.complete_timed_endless(String(_mainline_timed_offer["instance_id"]), cups, reason)
	if completed.is_empty():
		SortLogger.error("限时挑战结算保存失败，保留状态重试")
		return false
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	completed.merge(TimedEndlessRules.result(cups, rng), true)
	_timed_result = completed
	_round_target_coins = int(completed["coins_per_pot"])
	_win_coin_before = int(completed["before"])
	_win_coin_reward = int(completed["coins"])
	_won_level_num = int(completed["after_level"])
	_win_committed = true
	_next_pressed = false
	_complete_shown = false
	_end_flow_generation += 1
	if _win_coin_reward > 0:
		_report_coin_change(TrackingEvents.COIN_REASON_GAME_END, _win_coin_reward)
	return true




func _report_endless_result(reason: String) -> void :
	if not is_mainline_timed_endless():
		return
	if reason == "time_up":
		report_game_end()
	else:
		report_game_over()


func prepare_mainline_timed_finish() -> bool:
	var generation: int = _end_flow_generation
	var active: Callable = func() -> bool:
		return visible and is_mainline_timed_endless() and generation == _end_flow_generation
	_components.set_work_permission(Callable())
	if not await _components.ensure_resources(PackedStringArray([GamePagePreparation.WIN_COIN_PATH]), active):
		return false
	return await SceneManager.prepare_page_for_display("timed_endless_reward", active) != null and active.call()


func prepare_mainline_timed_reward(reason: String, cups: int) -> bool:
	if not _timed_result.is_empty():
		return true
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var result: Dictionary = UserState.prepare_timed_endless_reward(
		String(_mainline_timed_offer["instance_id"]), cups, reason, TimedEndlessRules.result(cups, rng))
	if result.is_empty():
		SortLogger.error("限时挑战待领取结果保存失败，保留实例")
		return false
	_initialize_timed_reward(result)
	return true


func _initialize_timed_reward(result: Dictionary) -> void :
	_timed_result = result.duplicate(true)
	_round_target_coins = int(result["coins_per_pot"])
	_win_coin_reward = int(result["coins"])
	_won_level_num = int(result["after_level"])
	_win_committed = false
	_next_pressed = false
	_complete_shown = false
	_end_flow_generation += 1


func show_timed_reward_dialog() -> void :
	_timed_reward_owned = true
	SceneManager.show_dlg("timed_endless_reward", {"result": _timed_result, "coin_hud": _coin_hud})


func await_timed_reward_claim(ctx) -> bool:
	var dialog: TimedEndlessRewardDialog = SceneManager.get_page("timed_endless_reward") as TimedEndlessRewardDialog
	while ctx.active() and _timed_reward_owned and is_instance_valid(dialog) and dialog.visible:
		if dialog.has_claim_request():
			var result: Dictionary = UserState.claim_timed_endless_reward(String(_timed_result["instance_id"]))
			if not result.is_empty():
				_timed_result = result
				_win_coin_before = int(result["before"])
				_win_coin_reward = int(result["coins"])
				_win_committed = true
				if _win_coin_reward > 0:
					_report_coin_change(TrackingEvents.COIN_REASON_GAME_END, _win_coin_reward)
				return true
			SortLogger.error("限时挑战领取保存失败，保留奖励重试")
			dialog.retry_claim()
		await get_tree().process_frame
	return false


func close_timed_reward_dialog(ctx) -> Rect2:
	var dialog: TimedEndlessRewardDialog = SceneManager.get_page("timed_endless_reward") as TimedEndlessRewardDialog
	if not ctx.active() or not is_instance_valid(dialog):
		ctx.aborted = true
		return Rect2()
	var source: Rect2 = dialog.coin_source_rect()
	if not await dialog.prepare_collection() or not ctx.active():
		ctx.aborted = true
		return Rect2()
	ctx.coin_parent = dialog
	return source


func _hide_timed_reward_now() -> void :
	if not _timed_reward_owned:
		return
	_timed_reward_owned = false
	var dialog: TimedEndlessRewardDialog = SceneManager.get_page("timed_endless_reward") as TimedEndlessRewardDialog
	if is_instance_valid(dialog):
		dialog.hide_panel()



func _restore_round_for_show() -> void :
	_home_navigation_generation += 1
	_restore_home_navigation_nodes()
	_home_navigation_running = false
	_home_navigation_saved = false
	_play_timer.resume(&"home_navigation")
	if is_node_ready():
		_timed_clock_flight.reset_now()
		if is_instance_valid(_timer_row):
			_timer_row.hide()
		_reset_time_bonus()



func _hide_round_view() -> void :
	if is_node_ready():
		_timed_clock_flight.reset_now()
	visible = false
	_reset_time_bonus()
	if is_instance_valid(_board):
		_board.hide()
	hide_complete_panel_now()


func _layout_endless_timer() -> void :
	if not is_node_ready() or not is_endless() or not is_instance_valid(_timer_row):
		return
	_timer_row.size = Vector2(_iq_progress.size.x, ENDLESS_TIMER_HEIGHT)
	_timer_row.position = Vector2(0.0, _timer_track.position.y - ENDLESS_TIMER_HEIGHT - ENDLESS_TIMER_TRACK_GAP)
	_timer_row.show()
	var font: Font = _timer_label.get_theme_font("font")
	var font_size: int = _timer_label.get_theme_font_size("font_size")

	var width: float = maxf(font.get_string_size("88:88", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, 
		font.get_string_size(_timer_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var image_size: Vector2 = Vector2(80.0, 80.0)
	var gap: float = 8.0

	var left: float = (_timer_row.size.x - image_size.x - gap - width) * 0.5
	_timer_alarm.position = Vector2(left, 0.0)
	_timer_alarm.size = image_size
	_timer_alarm.show()
	_timer_label.position = Vector2(left + image_size.x + gap, 2.0)
	_timer_label.size = Vector2(width, 76.0)
	_layout_time_bonus()



func _on_endless_time_added(milliseconds: int) -> void :
	if not is_endless() or not visible or milliseconds <= 0:
		return
	_iq_progress.begin_countdown_lead()
	_reset_time_bonus()
	_refresh_endless_hud()
	_time_bonus.text = "+%ds" % (milliseconds / 1000)
	_set_time_bonus_progress(0.0)
	_time_bonus.show()
	_time_bonus_tween = create_tween()
	_time_bonus_tween.tween_method(_set_time_bonus_progress, 0.0, 1.0, TIME_BONUS_ENTER_DUR)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_time_bonus_tween.tween_interval(TIME_BONUS_HOLD_DUR)
	_time_bonus_tween.tween_method(_set_time_bonus_progress, 1.0, 2.0, TIME_BONUS_EXIT_DUR)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_time_bonus_tween.finished.connect(_reset_time_bonus, CONNECT_ONE_SHOT)


func _set_time_bonus_progress(progress: float) -> void :
	_time_bonus.self_modulate.a = progress if progress <= 1.0 else 2.0 - progress
	_time_bonus_offset_y = (1.0 - progress) * TIME_BONUS_RISE
	_layout_time_bonus()


func _layout_time_bonus() -> void :
	_time_bonus.size = TIME_BONUS_SIZE
	_time_bonus.position = Vector2(_timer_label.position.x + _timer_label.size.x + TIME_BONUS_GAP, 
		_timer_label.position.y + (_timer_label.size.y - _time_bonus.size.y) * 0.5 + _time_bonus_offset_y)



func _reset_time_bonus() -> void :
	if _time_bonus_tween != null and _time_bonus_tween.is_valid():
		_time_bonus_tween.kill()
	_time_bonus_tween = null
	_time_bonus_offset_y = 0.0
	if is_instance_valid(_time_bonus):
		_time_bonus.hide()
		_time_bonus.self_modulate.a = 0.0
		_layout_time_bonus()

var _motion_preview_only: bool = false
var _motion_preview_generation: int = 0
var _motion_preview_gifts: Array[JuiceRankGiftFlight] = []

func prepare_rank_collectible_motion_preview(index: int, count: int, rules: bool, active: Callable) -> bool:
	if OS.has_feature("rel") or not active.call():
		return false
	_motion_preview_only = true
	if LevelManager.level_data_changed.is_connected(_on_finish_level_data_changed):
		LevelManager.level_data_changed.disconnect(_on_finish_level_data_changed)
	show()
	if not await _ensure_component_groups(["core", "rank"] as Array[String], active):
		return false
	if _fly_layer == null:
		for i: int in 4:
			_build_prop_button(i)
			await get_tree().process_frame
			if not active.call():
				return false
		_build_fly_layer()
		_build_entrance_pot_layer()
	var resources: JuiceSkinResolver = await _skin_loader.load_skin(skin_catalog, &"default", get_tree(), active)
	if resources == null or not active.call():
		return false
	if not await _warm_rank_gift_textures(resources, active):
		return false
	_skin_resources = resources
	cancel_rank_motion_preview()
	_rules_guide_round = rules
	_iq_round.enabled = false
	_components_ready = true
	_entrance_alpha = 1.0
	_entrance_dx = 0.0
	_entrance_dy = 0.0
	_board.tutorial_demo_only = true
	if not _board.major_sound_requested.is_connected(_play_major_sound):
		_board.major_sound_requested.connect(_play_major_sound)
	_board.motion_preview_speed = 1.0
	_board.apply_skin(resources, false)
	var incoming: Array[String] = []
	for i: int in count - 2:
		incoming.append("1|1,1,1")
	incoming.append("-|")
	var raw: Dictionary = {"id": 21, "capacity": 3, "targetCups": count, 
		"initial": ["0|0,0", "1|1,1,1", "-|0"], "incoming": incoming}
	var level: JuiceLevel = JuiceLevel.from_dict(raw)
	if not level.validate().is_empty():
		SortLogger.error("Rank motion preview fixture: %s" % level.validate())
		return false
	_level_model = JuiceLevelModel.new()
	_level_model.raw = raw
	_level_model.juice = level
	_level_model.rank_collectible_rule = {"type": 0, "collectible_index": index, "season_id": "motion-preview"}
	var state: Dictionary = JuiceRules.make_state(level)
	state["cols"] = [[0, 0] as Array[int], [0] as Array[int], [] as Array[int]]
	state["jars"] = [0, -1, -1] as Array[int]
	state["done"] = count - 1
	state["late_left"] = 0
	var cups: Array[int] = []
	for i: int in count - 1:
		cups.append(1)
	state["cups"] = cups
	_board.setup(level, state, PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]))
	_board.set_rank_collectible(0, index)
	_rank_collectible_type = 0
	_rank_gift_slot = count - 1
	_quota.apply_skin(resources)
	_quota.set_rules_layout_enabled(rules)
	_quota.setup(count)
	_quota.set_cups(_board.cup_textures(), _board.cup_colors())
	_layout()
	_board.show()
	_board.set_input_enabled(false)
	_rank_fly.show()
	_rank_round.prepare_motion_preview(count, 1000, index, 
		resources.active_skin.rank_collectible_elements[index].texture, _rank_bar, _rank_fly)
	_prepare_rank_gift_flight()
	return active.call()

func rank_motion_preview_rect() -> Rect2:
	var blender: JuiceBlender = _board._blender_nodes.get(0) as JuiceBlender
	var body: Sprite2D = blender.get_node("Body") as Sprite2D
	return body.global_transform * body.get_rect()

func play_rank_motion_preview_gift(from_rect: Rect2, slot: int) -> Tween:
	var tex: Texture2D = _board.target_icon_for_type(0)
	_quota.reveal_slot(slot)
	var gift: JuiceRankGiftFlight = _acquire_rank_gift_flight(tex)
	_motion_preview_gifts.append(gift)
	var tw: Tween = gift.play(from_rect, _quota.cup_global_rect.bind(slot, tex), 
		Vector4(CUP_BLOOM_DUR, CUP_FLY_RISE_DUR, CUP_FLY_HOLD_DUR, CUP_FLY_DUR), 
		CUP_FLY_RISE, CUP_FLY_SPINE_PREROLL_LEAD, CUP_FLY_HOLD_RISE_RATIO)
	tw.finished.connect( func() -> void :
		if is_instance_valid(gift):
			_quota.push_sunlight_round_cup(slot, tex, Color.WHITE)
			_play_major_sound(&"juice_quota", true, slot)
			gift.hide()
	, CONNECT_ONE_SHOT)
	return tw

func rank_motion_preview_fill_gift() -> void :
	_quota.push_sunlight_round_cup(_rank_gift_slot, _board.target_icon_for_type(0), Color.WHITE)

func rank_motion_preview_source(_index: int) -> Vector2:
	var generation: int = _motion_preview_generation
	_quota.reveal_slot(_rank_gift_slot)
	while is_instance_valid(self) and is_visible_in_tree() and generation == _motion_preview_generation and _quota._scroll_tween != null\
	and _quota._scroll_tween.is_valid() and _quota._scroll_tween.is_running():
		await get_tree().process_frame
	if generation != _motion_preview_generation or not is_visible_in_tree():
		return Vector2.ZERO
	return _quota.cup_global_rect(_rank_gift_slot, _board.target_icon_for_type(0)).get_center()

func cancel_rank_motion_preview() -> void :
	_motion_preview_generation += 1
	_discard_prepared_rank_gift_flight()
	if _components != null:
		_components.cancel()
	_rank_round.cancel()
	if is_instance_valid(_quota):
		_quota._kill_all_pops()
		if _quota._scroll_tween != null and _quota._scroll_tween.is_valid():
			_quota._scroll_tween.kill()
		_quota._scroll_tween = null
	for gift: JuiceRankGiftFlight in _motion_preview_gifts:
		if is_instance_valid(gift):
			gift.reset_now()
			gift.queue_free()
	_motion_preview_gifts.clear()
	if is_instance_valid(_board):
		_board.motion_preview_speed = 0.0
		_board.reset_skin_effects()


func clock_preview_target_rect() -> Rect2:
	if is_endless():
		return _timer_alarm.get_global_rect() if is_instance_valid(_timer_alarm) else Rect2()
	var rect: Rect2 = _level_label.get_global_rect()
	var ratio: float = rect.size.x / maxf(_level_label.size.x, 1.0)
	var font: Font = _level_label.get_theme_font("font")
	var width: float = font.get_string_size(_level_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 
		_level_label.get_theme_font_size("font_size")).x * ratio
	var ink_left: float = rect.position.x
	if _level_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		ink_left += (rect.size.x - width) * 0.5
	elif _level_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		ink_left += rect.size.x - width
	return Rect2(Vector2(ink_left - 88.0 * ratio, rect.get_center().y - 40.0 * ratio), Vector2.ONE * 80.0 * ratio)


func show_endless_opening_banner(ctx) -> bool:
	if not ctx.active():
		return false
	var input_generation: int = _begin_opening_banner_input_lock()
	var finished: bool = await _start_banner.show_timed_challenge(_timed_clock_flight, _timer_alarm, ctx.active)
	if not ctx.active():
		return false
	_end_opening_banner_input_lock(input_generation)
	return finished



func _layout_christmas_background() -> void :
	if not is_node_ready() or not _christmas_theme_enabled:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	for i: int in _christmas_decorations.size():
		var decoration: TextureRect = _christmas_decorations[i]
		decoration.position = vp * _christmas_theme.decoration_anchors[i] + _christmas_theme.decoration_rects[i].position
		decoration.size = _christmas_theme.decoration_rects[i].size
		decoration.rotation = 0.0
		decoration.flip_h = false
		decoration.flip_v = false
