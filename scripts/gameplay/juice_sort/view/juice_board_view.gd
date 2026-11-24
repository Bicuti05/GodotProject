class_name JuiceBoardView
extends Control











































const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const CH = preload("res://scripts/gameplay/juice_sort/core/juice_challenge.gd")
const COL_MARK_SCENE: PackedScene = preload("res://scripts/gameplay/juice_sort/view/juice_col_mark.tscn")
const LOCK_OVERLAY_SCENE: PackedScene = preload("res://scripts/gameplay/juice_sort/view/juice_lock_overlay.tscn")
const WOOD_DOOR_LOCK_SCENE: PackedScene = preload("res://scripts/gameplay/juice_sort/view/wood_door_lock.tscn")
const CLOSED_TASK_NONE: = -1
const ROOT_CLOSED_SLICE_MS: = 8
const ROOT_CLOSED_MAX_STATES: = 8000
const ROOT_CLOSED_CACHE_MAX: = 2
const DEATH_TASK_NONE: = -1
const CHALLENGE_TASK_NONE: = -1
const LUCKY_TASK_NONE: = -1


const CHALLENGE_MS_CAP: = 200

const CHALLENGE_CACHE_MAX: = 32

const DEATH_ATTRIBUTION_OPT: = {"node_cap": 3000, "ms_cap": 120}


const SAFE_RETURN_MAX_STEPS: = 5
const SAFE_RETURN_OPT: = {"node_cap": 3000, "state_cap": 8000, "ms_cap": 200}
const HINT_UNWINNABLE_REASON: = "hint_unwinnable"



class RootClosedJob extends RefCounted:
	static var retired: Array = []
	var ctx: Dictionary = {}
	var result: Dictionary = {"completed": false, "closed": false}
	var key: String = ""
	var generation: int = 0
	var level_identity: int = 0
	var task_id: int = -1
	var budget_ms: int = ROOT_CLOSED_SLICE_MS
	var now: Callable = Time.get_ticks_msec
	var opts: Dictionary = {}
	var cancelled: = Semaphore.new()
	var reaper_tree: SceneTree = null

	func run() -> void :
		var slice_opts: Dictionary = opts.duplicate()
		slice_opts["now"] = now
		result.merge(S.advance_root_closed_search(ctx, budget_ms, slice_opts), true)

		if ( not bool(result.get("continuable", false)) and not bool(result.get("recoverable", false)))\
		or cancelled.try_wait():
			ctx.clear()

	func retire(tree: SceneTree) -> void :
		cancelled.post()
		reaper_tree = tree
		retired.append(self)
		tree.process_frame.connect(reap)
		reap()

	func discard() -> void :
		ctx.clear()

	func reap() -> void :
		if task_id == -1 or not WorkerThreadPool.is_task_completed(task_id):
			return
		WorkerThreadPool.wait_for_task_completion(task_id)
		task_id = -1

		if not ctx.is_empty():
			task_id = WorkerThreadPool.add_task(discard, false, "juice root search cleanup")
			return
		result.clear()
		if is_instance_valid(reaper_tree) and reaper_tree.process_frame.is_connected(reap):
			reaper_tree.process_frame.disconnect(reap)
		reaper_tree = null
		retired.erase(self)


signal moved(steps: int)

signal automatic_settlement_requested()

signal calculation_timed_out(diagnostic: Dictionary)

signal player_operated()

signal long_link_triggered(geometry: Dictionary)


signal move_attempted(info: Dictionary)

signal new_rope_appeared(info: Dictionary)






signal cup_collected(fruit_type: int, nth: int, color: Color, from_rect_global: Rect2)






signal cups_changed()


signal major_sound_requested(id: StringName, preview: bool)

signal same_color_merge_sound_requested(pitch: float)
signal error_feedback_requested(reason: int)
signal move_rejected(reason: int)

signal blank_dropped()

signal locked_grabbed(col: int)



signal move_blocked(src: int, j: int, dst: int)


signal drag_started(col: int, j: int)

signal drop_target_entered(col: int)

signal drag_ended()

signal settled()

signal endless_refill_requested()
signal won()


signal dead(reason: String)

signal dead_attributed(attribution: int, reason: String, steps: int)



signal challenge_detected(kind: int, info: Dictionary)

signal revealed_undo_touched()

signal mystery_auto_unlock_requested()




signal lucky_reveal_detected(cells: Array)








const ROPE_TOP_BODY_ROWS: = 108.0
const ROPE_MID_BODY_ROWS: = 76.0
const ROPE_TIP_ROWS: = 94.0

const ROPE_TOP_VISIBLE_ROW: = 4.0
const ROPE_BOTTOM_VISIBLE_ROWS: = 86.0
const ROPE_HANG_Y_OFFSET: = 8.0








const ROPE_MID_SHADOW_ROW: = 80.0

const ROPE_MID_BODY_COLS: = 60.0

const ROPE_BOT_SHADOW_ROWS: = 0.0
















const PULSE_GLOW_WIDTH: = 1.65
const PULSE_GLOW_ALPHA: = 0.3

const SLAM_FLOAT_SCALE: = 1.08


const SLAM_FLOAT_RISE: = 12.0
const SLAM_TAIL: = 0.16






const BONUS_DEPOSIT_STAGGER: = 0.14
const BONUS_DEPOSIT_FLY_DUR: = 0.56
const SLAM_FLY_DUR: = 0.35







const SLAM_FLY_Z: = 90




const SLAM_FLY_K: = 0.55



const SLAM_FLY_SHRINK_RATIO: = 0.7






const SLAM_FLY_WAVE_AMP: = 50.0




const SLAM_FLY_WAVE_AMP_GROWTH: = 1.2


const SLAM_FLY_WAVE_CYCLES: = 2.0





const SLAM_FLY_WAVE_DECAY: = 0.7



const SLAM_TRAIL_HEAD_ALPHA: = 0.75



const SLAM_TRAIL_LIFETIME: = 0.2



const SLAM_TRAIL_WIDTH_RATIO: = 0.1575




const BURST_DUR: = 0.4

const BURST_PULSE_SCALE: = 1.5
const BURST_PULSE_UP_DUR: = 0.12
const BURST_PULSE_DOWN_DUR: = 0.12


const CONNECTION_PULSE_SCALE: = 1.3
const CONNECTION_PULSE_UP_DUR: = 0.18
const CONNECTION_PULSE_DOWN_DUR: = 0.18







const ROPE_PETAL_DENSITY_PER_10PX: = 0.48

const ROPE_PETAL_SIZE: = 16.0



const ROPE_PETAL_SIZE_MIN_RATIO: = 0.4
const ROPE_PETAL_SIZE_MAX_RATIO: = 1.92

const ROPE_PETAL_SPEED_MIN: = 140.0
const ROPE_PETAL_SPEED_MAX: = 350.0

const ROPE_PETAL_END_SPEED_RATIO: = 0.1


const ROPE_PETAL_GRAVITY: = 90.0

const ROPE_PETAL_LIFETIME: = 0.7
const ROPE_PETAL_LIFETIME_RAND: = 0.3


const ROPE_PETAL_FADE_FROM: = 0.7


const ROPE_PETAL_SPIN_MIN: = 180.0
const ROPE_PETAL_SPIN_MAX: = 350.0




const ROPE_STAR_TEX: Texture2D = preload("res://assets/effect/texture/point/ef_point_004.png")

const ROPE_STAR_EMIT_DUR: = 0.6
const ROPE_STAR_LIFETIME: = 0.255

const ROPE_STAR_RATE: = 15.0



const ROPE_STAR_SIZE_MAX_RATIO: = 0.5
const ROPE_STAR_SIZE_MIN_RATIO: = 1.0 / 3.0

const ROPE_STAR_COLOR: = Color(1.0, 0.93, 0.55)





const UNLOCK_SPINE_SCENE: PackedScene = preload("res://assets/spine/effect_flower_unlock/effect_flower_unlock.tscn")
const UNLOCK_SPINE_ANIM: = &"play"




const UNLOCK_SPINE_REF_SIZE: = Vector2(190.1, 774.88)
const UNLOCK_SPINE_REF_CENTER: = Vector2(-8.05, -0.8)


const UNLOCK_LEAF_TEX: Texture2D = preload("res://assets/effect/texture/point/ef_point_009a.png")
const UNLOCK_LEAF_COUNT: = 24


const UNLOCK_LEAF_SIZE_RATIO: = 0.3
const UNLOCK_LEAF_SIZE_RANDOMNESS: = 0.3

const UNLOCK_LEAF_LIFETIME: = 1.0
const UNLOCK_LEAF_LIFETIME_RAND: = 0.3


const UNLOCK_LEAF_SPEED_MIN: = 120.0
const UNLOCK_LEAF_SPEED_MAX: = 300.0
const UNLOCK_LEAF_END_SPEED_RATIO: = 0.1
const UNLOCK_LEAF_GRAVITY: = 100.0




const UNLOCK_GLOW_TEX: Texture2D = preload("res://assets/effect/texture/glow/ef_glow_002.png")
const UNLOCK_GLOW_COUNT: = 14
const UNLOCK_GLOW_LIFETIME: = 1.0
const UNLOCK_GLOW_LIFETIME_RAND: = 0.3

const UNLOCK_GLOW_SIZE_RATIO: = 0.175

const UNLOCK_GLOW_SPEED_MIN: = 30.0
const UNLOCK_GLOW_SPEED_MAX: = 90.0
const UNLOCK_GLOW_GRAVITY: = -20.0


const UNLOCK_STAR_COUNT_SCALE: = 0.5
const UNLOCK_STAR_SIZE_SCALE: = 1.5







const MYSTERY_POP_SCALE_PEAK: = 1.4
const MYSTERY_POP_SCALE_DIP: = 0.95


const MYSTERY_POP_UP_DUR: = 0.09
const MYSTERY_POP_DIP_DUR: = 0.105
const MYSTERY_POP_SETTLE_DUR: = 0.105





const MYSTERY_PETAL_DELAY: = 0.1
const MYSTERY_PETAL_TEX = JuiceMysteryRevealEffects.MYSTERY_PETAL_TEX
const MYSTERY_GLOW_TEX = JuiceMysteryRevealEffects.MYSTERY_GLOW_TEX
const MYSTERY_GLOW_YELLOW_REF = JuiceMysteryRevealEffects.MYSTERY_GLOW_YELLOW_REF
const MYSTERY_FLASH_TEX = JuiceMysteryRevealEffects.MYSTERY_FLASH_TEX
const MYSTERY_STAR_TEX = JuiceMysteryRevealEffects.MYSTERY_STAR_TEX





const COLLECT_BLENDER_LINGER: = 2.0 / 60.0




const SLAM_MOUTH_RATIO: = 0.22




const COLLECT_LEAD_DUR: = 0.22


const RETURN_Z: = 9

const RETURN_SETTLE_EPS: = 1.0


const CAPSULE_WIDEN: = 1.15


const CAPSULE_GAP: = 4.0


const GHOST_FADE_DUR: = 0.26

const SLIDE_DUR: = 0.32

const DOMINO_PER_COL: = 0.026
const DOMINO_MAX: = 0.09

const PLANT_DUR: = 0.62
const PLANT_STAG: = 0.12
const PLANT_LAG: = 0.14



const EASE_RATE: = 9.0



const SWAY_AMP_RATIO: = 0.03

const SWAY_OMEGA: = 1.25

const SWAY_OMEGA2: = 0.61

const SWAY_PHASE_PER_COL: = 1.7































const ENTRANCE_WIND_ACCEL_GAIN: = 3.0

const WOOD_LOCK_ENTRANCE_SWAY_RATIO: = 0.35
const ENTRANCE_WIND_OMEGA: = 9.0











const ENTRANCE_WIND_ZETA: = 0.45















const WIND_CURVE_POW: = 2.0





const WIND_LEAN_RATIO: = 0.3






const WIND_RIGID_TAIL_PX: = 8.0









const WIND_RIGID_VEL_PX: = 64.0

const WIND_SETTLE_PX: = 1.0
const WIND_SETTLE_PX_PER_SEC: = 2.0


const DRAG_SCALE: = 1.08
const DRAG_LEADING_FLOWER_SCALE: = 1.3
const DRAG_MATCH_HIGHLIGHT_PERIOD: = 2.4
const DRAG_GAP_RATIO: = 0.96























const DRAG_CHAIN_OMEGA: = 28.0




const DRAG_CHAIN_ZETA: = 1.0


const DRAG_CHAIN_MAX_SLOPE: = 0.55


const DRAG_TILT_RATIO: = 0.8
const DRAG_TILT_MAX: = 0.35


const DRAG_TILT_RATE: = 12.0

const DRAG_HEAD_TILT_RATIO: = 0.45





const DRAG_SWAY_AMP_RATIO: = 0.02
const DRAG_SWAY_OMEGA: = 2.1
const DRAG_SWAY_PHASE_PER_IDX: = 1.1

const DROP_SLACK: = 60.0

const DROP_OVERLAP_FRUIT_RATIO: = 0.5
const DROP_TARGET_RANGE_SCALE: = 1.0
const DROP_SRC_NEIGHBOR_FRUIT_RATIO: = 0.15
const DROP_SAME_EMPTY_FRUIT_RATIO: = 0.15
var _location_judge_settings: Dictionary = {}
const DROP_LEGAL_RANGE_SCALE: = 1.2
const DROP_INVALID_RANGE_SCALE: = 0.8
const DROP_SOURCE_EXIT_RATIO: = 0.2


@export var bead_fruit_textures: Array[Texture2D] = []

@export var group_halo_set: JuiceGroupHaloSet = null



var _bonus_idle_fx: BonusPigIdleFx = null
var _bonus_entry_fx: BonusCoinEntryFx = null
@export var bonus_idle_scene: PackedScene
@export var bonus_entry_scene: PackedScene
var _bonus_type: int = -1

var _bonus_skip_reason: String = ""

var _bonus_candidate: bool = false

var _bonus_v2: bool = false

var _bonus_plan_pending: Dictionary = {}

var _bonus_recolor_from: int = -1
var _bonus_recolor_to: int = -1

@export var bonus_coin_texture: Texture2D
@export var bonus_pig_texture: Texture2D
@export var bead_blender_textures: Array[Texture2D] = []
@export var bead_blender_full_textures: Array[Texture2D] = []
@export var bead_blender_empty_texture: Texture2D = null

const EMPTY_POT_HEIGHT_SHELF_OFFSET: float = 11.6875
const NEW_POT_VISIBLE_HEIGHT: float = 130.0

const NEW_POT_VISIBLE_WIDTH: float = 156.0
const NEW_POT_MIN_GAP: float = 8.0
@export var sunlight_fruit_texture: Texture2D = null
@export var sunlight_blender_texture: Texture2D = null
@export var sunlight_full_blender_texture: Texture2D = null
var _mystery_effect_sets: Dictionary[String, JuiceMysteryRevealEffects] = {}
var _common_skin_emitters: Array[GPUParticles2D] = []

var _skin_emitters: Array[GPUParticles2D]:
	get: return skin_particle_emitters()
var _skin_resources: JuiceSkinResolver
var _rank_collectible_type: int = -1
signal bird_house_hovered(visual: JuiceBirdCollection)

var _bird_layer: Node2D
var _bird_collections: Array[JuiceBirdCollection] = []
var _bird_handoffs: Dictionary = {}
var _skin_arrays: Dictionary[StringName, Array] = {}
var _skin_empty_visuals: Dictionary[Texture2D, JuiceSkinVisual] = {}
var _skin_empty_visible_size: Vector2 = Vector2.ZERO

var _melt_generation: int = 0
@onready var _sunlight_fx: SunlightFx = $SunlightFx
@onready var _sunlight_collector: JuiceBlender = $SunlightCollector
var _ice_shatter_fx: JuiceIceShatterFx = null
var _sunlight_batches: Array[Dictionary] = []
var _sunlight_collection_queue: Array[Dictionary] = []
var _sunlight_flight: Dictionary = {}
var _sunlight_active_batch: Dictionary = {}
signal sunlight_collector_landed(nth: int)






@export var rope_top_textures: Array[Texture2D] = []
@export var rope_mid_textures: Array[Texture2D] = []
@export var rope_bottom_textures: Array[Texture2D] = []
@export var rope_park_top_texture: Texture2D = null
@export var rope_park_mid_texture: Texture2D = null
@export var rope_park_bottom_texture: Texture2D = null


@export var new_background_hover_fill_texture: Texture2D = null
@export var new_background_hover_glow_texture: Texture2D = null
@export var invalid_drop_hover_fill_texture: Texture2D = null
@export var invalid_drop_hover_glow_texture: Texture2D = null
var _normal_drop_hover_fill_texture: Texture2D = null
var _normal_drop_hover_glow_texture: Texture2D = null
var _normal_drop_hover_tint: Color = Color.WHITE
var _drop_hover_fill: JuiceCapsuleRect = null
var _drop_hover_glow: JuiceCapsuleRect = null
var _default_hover_fill_texture: Texture2D = null
var _default_hover_glow_texture: Texture2D = null

@export var rope_petal_texture: Texture2D = null






var _blender_layer: Node2D = null
var _fruit_layer: Node2D = null
var _flowers_fade_tween: Tween = null
var _fx_layer: Node2D = null





var _fly_trails: FireworkTrails = null
var _complete_column_trails: FireworkTrails = null

var _rank_collectible_fly_trails: FireworkTrails = null
var _bonus_gold_trails: BonusGoldTrails = null


var _rope_petal_pool: Array[GPUParticles2D] = []
var _rope_whole_petal_pool: Array[GPUParticles2D] = []
var _connection_pending: Array[Dictionary] = []
var _connection_effects: Array[Node2D] = []
var _rope_petal_shader_mat: ShaderMaterial = null
var _rope_petal_ramp: GradientTexture1D = null


var _rope_star_pool: Array[GPUParticles2D] = []
var _rope_particle_lifecycles: Dictionary[GPUParticles2D, GpuParticleLifecycle] = {}
var _connection_particles_warmed: bool = false
var _connection_particles_warming: bool = false
var cold_start_optimized: bool = false
var _connection_particles_preparing: bool = false
var _connection_preparation_generation: int = 0
var _connection_prepared_petals: Array[GPUParticles2D] = []
var _connection_prepared_stars: GPUParticles2D
var _connection_instances_ready: bool = false
var _first_pickup_logged: bool = false
var _first_pickup_times: PackedInt64Array = PackedInt64Array()

var _unlock_spine_pool: Array[SpineSprite] = []
var _unlock_leaf_pool: Array[GPUParticles2D] = []
var _unlock_glow_pool: Array[GPUParticles2D] = []
var _unlock_glow_ramp: GradientTexture1D = null
var _wood_unlock_pool: Array[WoodDoorLock] = []
var _wood_unlock_live: Array[WoodDoorLock] = []
var _wood_unlock_offsets: Dictionary[WoodDoorLock, float] = {}

var _wood_unlock_tokens: Dictionary[WoodDoorLock, int] = {}

var _wood_lock_bottom_limit: float = INF

var _wood_lock_layout: bool = false
const WOOD_LOCK_BOTTOM_PADDING: float = 8.0


static var _lock_visual_version: int = 0
var _rope_star_add_mat: CanvasItemMaterial = null
var _rope_star_scale_curve: CurveTexture = null



var _mystery_reveal_generation: int = 0




var _warming_effects: bool = false
var _warm_effect_releases: Dictionary[CanvasItem, Callable] = {}
var _warm_effect_tweens: Array[Tween] = []


var _drop_hover: Control = null
var _hint_target: Control = null

var _plank: Sprite2D = null
var _second_plank: Sprite2D = null

var _col_marks_layer: Control = null
var _lock_layer: Control = null
var _hint_hand: JuiceHandDemo = null


var _drag_rope_layer: Node2D = null
var _fruit_pool: JuiceNodePool = null
var _blender_pool: JuiceNodePool = null



var _demo_pool: JuiceNodePool = null

var _level: JuiceLevel = null

@export var tutorial_demo_only: bool = false

var motion_preview_speed: float = 1.0
var _state: Dictionary = {}
var _allow_root_swapping_enabled: bool = false
var _play_after_dead_pending: bool = false
var _play_after_dead_enabled: bool = false
var _root_adjudication_suspended: bool = false
var _root_ready_settling: bool = false
var _root_ready_deposits: Array = []
var _lay: = JuiceLayout.new()

var _skin: JuiceSkin = JuiceSkin.bead()

var _slots: PackedInt32Array = PackedInt32Array()
var _order: Array[int] = []
var _slot_of: Dictionary = {}

var _initial_slot_of: Dictionary = {}



var _bonus_handoff_source: JuiceBlender = null
var _bonus_preview_state: Dictionary = {}
var _fruit_nodes: Dictionary = {}

var _same_color_highlight_enabled: bool = false
var _drag_match_highlight_fruits: Array[JuiceFruit] = []
var _blender_nodes: Dictionary = {}
@export var capacity_label_scene: PackedScene
var _capacity_labels_layer: Control = null
var _capacity_label_nodes: Dictionary = {}
var _capacity_label_pool: Array[JuiceRopeCapacityLabel] = []

var _capacity_knots_enabled: bool = false

var _legacy_replenish_pending: Dictionary = {}


@export var garden_pot_layer: Node2D = null


var _keep_revealed_on_undo: bool = false



var _t: float = 0.0












var _content_dx: float = 0.0
var _wind_active: bool = false
var _wind_amp: float = 0.0
var _wind_vel: float = 0.0


var _entrance_motion_active: bool = false
var _entrance_time_pending: bool = false
var _entrance_target_time: float = 0.0
var _wind_time: float = 0.0
var _wind_duration: float = 0.0
var _wind_start_dx: float = 0.0
var _wind_drive_coeffs: Vector2 = Vector2.ZERO
var _wind_decay_coeffs: Vector2 = Vector2.ZERO
var _wind_free_coeffs: Vector2 = Vector2.ZERO
var _steps: int = 0

var _empty_rope_feedback: Dictionary = {}
const LONG_LINK_GAP_MSEC: int = 10000
var _last_player_placement_msec: int = -1

var _move_attempt_count: int = 0
var _successful_link_count: int = 0
var _over: String = ""
var _input_enabled: bool = true
var _endless_session: JuiceEndlessSession = null
var _endless_move_guard: Callable = Callable()

var _entrance_lock: bool = false


var _hint_lock: bool = false




var _closed_task_id: int = CLOSED_TASK_NONE
var _closed_task_key: String = ""
var _closed_task_result: Dictionary = {}

var _root_closed_job: RootClosedJob = null
var _root_closed_generation: int = 0

var _root_closed_cache: Dictionary = {}
var _root_closed_max_states: int = ROOT_CLOSED_MAX_STATES
var _root_closed_budget_ms: int = ROOT_CLOSED_SLICE_MS

var _root_closed_now: Callable = Time.get_ticks_msec
var _root_closed_opts: Dictionary = {}

var _death_task_id: int = DEATH_TASK_NONE




var _challenge_task_id: int = CHALLENGE_TASK_NONE
var _challenge_task_key: String = ""
var _challenge_task_gen: int = 0
var _challenge_task_result: Dictionary = {}
var _challenge_generation: int = 0

var _challenge_cache: Dictionary = {}

var _challenge_last_key: String = ""

var _challenge_suppressed_by_undo: bool = false


var _lucky_task_id: int = LUCKY_TASK_NONE
var _lucky_task_key: String = ""
var _lucky_task_gen: int = 0
var _lucky_task_result: Dictionary = {}

var _lucky_seen: Dictionary = {}


var _resumed_round: bool = false
var _death_task_result: Dictionary = {}
var _death_task_request: Dictionary = {}
var _death_pending: Dictionary = {}
var _death_generation: int = 0


var _safe_return_steps: int = -1
var _safe_return_generation: int = 0
var _safe_task_id: int = DEATH_TASK_NONE
var _safe_task_result: Dictionary = {}
var _safe_task_generation: int = 0
var _death_attribution: int = S.DeathAttribution.UNKNOWN


var _drag: Dictionary = {}


var _hover_col: int = -1

var _rule_col_marks: bool = false

var _return: Array[JuiceFruit] = []

const COMPLETE_COLUMN_EXCHANGE_DUR: float = 0.26
const COMPLETE_COLUMN_GATHER_DUR: float = 0.46
const COMPLETE_COLUMN_FEEDBACK_UP_DUR: float = 0.14
const COMPLETE_COLUMN_FEEDBACK_DOWN_DUR: float = 0.12
const COMPLETE_COLUMN_FEEDBACK_RESTORE_DUR: float = 0.1
const COMPLETE_COLUMN_FEEDBACK_DUR: float = COMPLETE_COLUMN_FEEDBACK_UP_DUR\
+ COMPLETE_COLUMN_FEEDBACK_DOWN_DUR + COMPLETE_COLUMN_FEEDBACK_RESTORE_DUR
const COMPLETE_COLUMN_LAUNCH_DUR: float = 0.1
const COMPLETE_COLUMN_BRAKE_EXTRA_DUR: float = 0.08
const COMPLETE_COLUMN_MOTION_EXTRA_DUR: float = (COMPLETE_COLUMN_LAUNCH_DUR + COMPLETE_COLUMN_BRAKE_EXTRA_DUR) * 0.5
const COMPLETE_COLUMN_TIMING_RANDOM_RATIO: float = 0.25
const COMPLETE_COLUMN_DEPARTURE_RANDOM_RATIO: float = 0.4
const COMPLETE_COLUMN_BRAKE_RATIO: float = 0.15
const COMPLETE_COLUMN_FLIGHT_BRAKE_RATIO: float = 0.45
const COMPLETE_COLUMN_ARRIVAL_OFFSET: Vector2 = Vector2(0.0, -15.0)
const COMPLETE_COLUMN_RESTORE_RATIO: float = 0.1
const COMPLETE_COLUMN_FLOAT_SCALE: float = 1.2
const COMPLETE_COLUMN_PULLBACK_RATIO: float = 0.45
const COMPLETE_COLUMN_ARC_HEIGHT_RATIO: float = 0.9
const COMPLETE_COLUMN_TRAIL_WIDTH_RATIO: float = 0.25
const COMPLETE_COLUMN_TRAIL_ALPHA: float = 0.75
const COMPLETE_COLUMN_TRAIL_LIFETIME: float = 0.24
const COMPLETE_COLUMN_FLY_DUR: float = COMPLETE_COLUMN_FEEDBACK_DUR\
+ COMPLETE_COLUMN_GATHER_DUR * (1.0 + COMPLETE_COLUMN_DEPARTURE_RANDOM_RATIO)\
+ COMPLETE_COLUMN_MOTION_EXTRA_DUR
var _complete_column_flight: Dictionary = {}
var _complete_column_fx_pool: Array[CompleteColumnFlowerFx] = []

var _complete_column_fail_reason: String = ""

var _complete_column_deposits: Array = []




var _hint: Dictionary = {}



var _hint_hl: Dictionary = {}




var _move_gate: Callable = Callable()




var _grab_gate: Callable = Callable()








var _run_hl: Dictionary = {}

var _tutorial_target_hl: Dictionary = {}

var _four_goal_tutorial_visuals: bool = false


var _tutorial_pot_hl_col: int = -1



var _col_mark_pool: Array[JuiceColMark] = []
var _col_mark_live: Array[JuiceColMark] = []

var _lock_overlay_pool: Array[JuiceLockOverlay] = []
var _lock_overlay_live: Array[JuiceLockOverlay] = []
var _col_mark_spec: Dictionary = {}
const TUTORIAL_MUTED_COLUMN_ALPHA: = 0.45

const TUTORIAL_MUTED_ROPE_ALPHA: = 0.15
var _tutorial_dimmed_items: Dictionary = {}










var _run_demo: Dictionary = {}


var _demo_nodes: Array[JuiceFruit] = []
var _demo_rope_root: Node2D = null
var _demo_rope_nodes: Array[Sprite2D] = []


var _move_feedback_info: Dictionary = {}


var _shake: Dictionary = {}
var _wood_reject_hidden: Dictionary = {}
var _color_reject_hold: Dictionary = {}
var _new_error_animation_enabled: bool = false
var _capacity_error_hint: Dictionary = {}
var _last_rejected_target: int = -1


var _sway_enabled: bool = true


var _ambient_sway_enabled: bool = true


var _visual_token_seq: int = 0
var _visual_token_by_col: Dictionary = {}
var _visual_x: Dictionary = {}
var _planned_x: Dictionary = {}



var _shift_queue: Array[Dictionary] = []

var _collect_hold_since: float = -1.0
var _collect_hold_until: float = -1.0


var _last_col_x: Dictionary = {}




var _beats: Array = []

var _trail_preview_settle_pending: bool = false


var _over_signal_pending: bool = false
var _pending_dead_reason: String = ""

var _collect_glow_texture: GradientTexture2D = null



var _history: Array = []
const MAX_PERSISTED_UNDO_STEPS: = 10
const EMPTY_ROPE_FEEDBACK_HISTORY_STEPS: int = 10


func _ready() -> void :
	add_to_group(&"juice_lock_visual_boards")
	_sunlight_fx.finished.connect(_on_sunlight_finished)
	_ice_shatter_fx = JuiceIceShatterFx.new()
	_ice_shatter_fx.skin_resources = _skin_resources
	_ice_shatter_fx.name = "IceShatterFx"
	_ice_shatter_fx.visible = false
	_ice_shatter_fx.burst_z_index = SLAM_FLY_Z + 3
	add_child(_ice_shatter_fx)
	_ice_shatter_fx.top_level = true
	_ice_shatter_fx.global_transform = Transform2D.IDENTITY
	_ice_shatter_fx.finished.connect(_finish_shatter_collection_if_ready)
	visibility_changed.connect(_on_lock_visual_visibility_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP






	clip_contents = true
	_build_collect_glow_texture()
	_ensure_refs()
	set_process(true)


static func get_lock_visual_version() -> int:
	return _lock_visual_version


static func set_lock_visual_version(version: int) -> void :
	var selected: int = version if version in [1, 3] else 0
	if _lock_visual_version == selected:
		return
	_lock_visual_version = selected
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.call_group(&"juice_lock_visual_boards", &"_apply_lock_visual_version")


func resolved_lock_visual_version() -> int:
	return _lock_visual_version if _lock_visual_version != 0 else 3


func _on_lock_visual_visibility_changed() -> void :
	if not is_visible_in_tree():
		_clear_wood_unlock_effects()


func _apply_lock_visual_version() -> void :
	if _state.is_empty():
		return
	_clear_wood_unlock_effects()
	if resolved_lock_visual_version() == 3 and not _wood_lock_layout and _level_has_locks(_level):
		_wood_lock_layout = true
	if _wood_lock_layout and is_finite(_wood_lock_bottom_limit):
		_solve_layout()
		_snap_all_home()
		_refresh_capacity_labels()
		return
	_refresh_lock_overlays()


func _build_collect_glow_texture() -> void :
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.91, 0.48, 0.34), 
		Color(1.0, 0.73, 0.16, 0.22), 
		Color(1.0, 0.58, 0.08, 0.08), 
		Color(1.0, 0.48, 0.04, 0.0), 
	])
	_collect_glow_texture = GradientTexture2D.new()
	_collect_glow_texture.width = 128
	_collect_glow_texture.height = 512
	_collect_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_collect_glow_texture.fill_from = Vector2(0.5, 0.5)
	_collect_glow_texture.fill_to = Vector2(1.0, 0.5)
	_collect_glow_texture.gradient = gradient


func _exit_tree() -> void :
	_restore_tutorial_column_opacity()
	cancel_bird_collections()
	reset_skin_effects()
	if is_instance_valid(_ice_shatter_fx):
		_ice_shatter_fx.stop()
	_cancel_melt_effects()
	_clear_wood_unlock_effects()
	_stop_drag_match_highlight(true)
	if is_instance_valid(_bonus_idle_fx):
		_bonus_idle_fx.queue_free()
		_bonus_idle_fx = null
	if is_instance_valid(_bonus_entry_fx):
		_bonus_entry_fx.queue_free()
		_bonus_entry_fx = null
	_clear_complete_column_flight()

	_cancel_closed_check()
	if _root_closed_job != null:
		_root_closed_job.retire(get_tree())
		_root_closed_job = null
		_closed_task_id = CLOSED_TASK_NONE
		_closed_task_result = {}
	if _death_task_id != DEATH_TASK_NONE:
		WorkerThreadPool.wait_for_task_completion(_death_task_id)
		_death_task_id = DEATH_TASK_NONE
	if _safe_task_id != DEATH_TASK_NONE:
		WorkerThreadPool.wait_for_task_completion(_safe_task_id)
		_safe_task_id = DEATH_TASK_NONE


func _ensure_refs() -> void :
	if _fruit_pool != null:
		return
	_blender_layer = get_node_or_null("BlenderLayer")
	_fruit_layer = get_node_or_null("FruitLayer")
	_fx_layer = get_node_or_null("FxLayer")
	_drop_hover = get_node_or_null("DropHoverHighlight") as Control
	_drop_hover_fill = _drop_hover.get_node("Fill") as JuiceCapsuleRect
	_drop_hover_glow = _drop_hover.get_node("Glow") as JuiceCapsuleRect
	_default_hover_fill_texture = _drop_hover_fill.texture
	_default_hover_glow_texture = _drop_hover_glow.texture
	_normal_drop_hover_fill_texture = _default_hover_fill_texture
	_normal_drop_hover_glow_texture = _default_hover_glow_texture
	_normal_drop_hover_tint = _drop_hover_glow.self_modulate
	_hint_target = get_node_or_null("HintTargetHighlight") as Control
	_plank = get_node_or_null("PlankLayer") as Sprite2D
	_col_marks_layer = get_node_or_null("ColMarks") as Control
	_lock_layer = get_node_or_null("LockLayer") as Control
	_capacity_labels_layer = get_node_or_null("CapacityLabels") as Control
	_hint_hand = get_node_or_null("FxLayer/HintHand") as JuiceHandDemo
	_drag_rope_layer = get_node_or_null("DragRopeLayer") as Node2D
	if _drag_rope_layer != null and not _drag_rope_layer.draw.is_connected(_draw_drag_rope):
		_drag_rope_layer.draw.connect(_draw_drag_rope)
	_fruit_pool = get_node_or_null("FruitPool") as JuiceNodePool
	_blender_pool = get_node_or_null("BlenderPool") as JuiceNodePool
	_demo_pool = get_node_or_null("DemoFruitPool") as JuiceNodePool
	if _fruit_pool == null or _blender_pool == null or _demo_pool == null\
	or _fruit_layer == null:
		push_error("JuiceBoardView: 场景结构不完整(缺 FruitPool / DemoFruitPool / BlenderPool / FruitLayer)")







func apply_skin(resources: JuiceSkinResolver, refresh: bool = true) -> void :
	for effects: JuiceMysteryRevealEffects in _mystery_effect_sets.values():
		if effects.skin_resources == _skin_resources and not effects.preparing:
			effects.reset_immediate()
	_mystery_reveal_generation += 1
	var previous_effects: Array = _skin_effect_textures()
	_skin_resources = resources
	if _ice_shatter_fx != null:
		_ice_shatter_fx.skin_resources = resources
	_rebuild_skin_arrays()
	_clear_changed_skin_effect_pools(previous_effects, _skin_effect_textures())
	if refresh and _level != null:
		var same_color: bool = _same_color_highlight_enabled
		_rebuild_nodes()
		_same_color_highlight_enabled = same_color

func _rebuild_skin_arrays() -> void :
	_skin_arrays.clear()
	_skin_empty_visuals.clear()
	_skin_empty_visible_size = Vector2.ZERO
	if _skin_resources == null:
		return
	for field: StringName in [&"element", &"empty_container", &"completed_container", &"rope_top", &"rope_mid", &"rope_bottom"]:
		var textures: Array[Texture2D] = []
		for key: String in JuiceTheme.COLOR_KEYS:
			var visual: JuiceSkinVisual = _skin_resources.color_visual(key, field)
			textures.append(visual.texture)
			if field == &"empty_container":
				_skin_empty_visuals[visual.texture] = visual
		_skin_arrays[field] = textures
	var parking: JuiceSkinVisual = _skin_resources.single_visual(&"parking_container")
	_skin_empty_visuals[parking.texture] = parking
	for visual: JuiceSkinVisual in _skin_empty_visuals.values():
		if visual.source_bounds.has_area():

			var visible_size: Vector2 = visual.source_bounds.size
			visible_size.y += maxf( - visual.offset.y, 0.0)
			_skin_empty_visible_size = _skin_empty_visible_size.max(visible_size * visual.size_correction)
	rope_petal_texture = effect_texture(&"rope_petal", rope_petal_texture)

func skin_resources() -> JuiceSkinResolver:
	return _skin_resources

func set_rank_collectible(type_id: int, index: int, refresh: bool = true) -> void :
	_rank_collectible_type = type_id if index >= 0 else -1
	if _skin_resources == null:
		return
	var color: StringName = &""
	if type_id >= 0 and type_id < _slots.size():
		color = JuiceTheme.COLOR_KEYS[_slots[type_id]]
	_skin_resources.set_rank_collectible(color, index)
	_rank_collectible_type = type_id if color != &"" and _skin_resources.rank_collectible_index >= 0 else -1
	var revealed: bool = false
	if _level != null and _rank_collectible_type >= 0:
		var shown: JuiceLevel = R.level_with_revealed_type(_level, _rank_collectible_type)
		revealed = R.reveal_type(_state, _rank_collectible_type) > 0 or shown != _level
		_level = shown
		if revealed:
			_cancel_closed_check()
			_invalidate_death_attribution()
			_reset_challenge_check()
			if _over == "dead":
				_over = ""
				_over_signal_pending = false
				_pending_dead_reason = ""
	apply_skin(_skin_resources, refresh)
	if revealed and refresh:
		_check_over()

func is_rank_collectible_type(type_id: int) -> bool:
	return _rank_collectible_type >= 0 and JuiceLevel.true_type(type_id) == _rank_collectible_type

func element_visual(type_id: int) -> JuiceSkinVisual:
	var actual: int = JuiceLevel.true_type(type_id)
	if (_skin_resources == null or actual < 0 or actual >= _slots.size()
			or _is_bonus_type(actual) or (_level != null and _level.is_sunlight_type(actual))):
		return null
	return _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[_slots[actual]], &"element")

func mystery_visual() -> JuiceSkinVisual:
	return _skin_resources.single_visual(&"mystery_element") if _skin_resources != null else null

func target_icon_for_type(type_id: int) -> Texture2D:
	var visual: JuiceSkinVisual = target_visual_for_type(type_id)
	return visual.texture if visual != null else _texture_for_full_blender(type_id)

func target_icon_for_slot(slot: int) -> Texture2D:
	if _skin_resources == null or slot < 0 or slot >= JuiceTheme.COLOR_KEYS.size():
		return full_blender_texture_for_slot(slot)
	return _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[slot], &"target_icon").texture

func target_visual_for_type(type_id: int) -> JuiceSkinVisual:
	if (_skin_resources == null or type_id < 0 or type_id >= _slots.size()
			or _is_bonus_type(type_id) or (_level != null and _level.is_sunlight_type(type_id))):
		return null
	return _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[_slots[type_id]], &"target_icon")

func lock_visual(type_id: int) -> JuiceSkinVisual:
	if _skin_resources == null or type_id < 0 or type_id >= _slots.size():
		return null
	return _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[_slots[type_id]], &"lock_icon")

func lock_icon(type_id: int) -> Texture2D:
	var visual: JuiceSkinVisual = lock_visual(type_id)
	return visual.texture if visual != null else _texture_for_fruit(type_id)

func effect_texture(field: StringName, fallback: Texture2D) -> Texture2D:
	return _skin_resources.effect_texture(field, fallback) if _skin_resources != null else fallback


func collection_particle_texture(slot: int) -> Texture2D:
	return _skin_resources.collection_particle_texture(slot) if _skin_resources != null else null

func mystery_particle_texture(slot: int) -> Texture2D:
	return _skin_resources.mystery_particle_texture(slot) if _skin_resources != null else null


func _skin_effect_textures() -> Array:
	var whole: Array = [effect_texture(&"rank_collectible_connection_01", null), 
		effect_texture(&"rank_collectible_connection_02", null)]
	var mystery: Array = [effect_texture(&"mystery_petal", MYSTERY_PETAL_TEX)]
	for slot: int in JuiceTheme.COLOR_KEYS.size():
		whole.append(collection_particle_texture(slot))
		whole.append(_skin_resources.color_texture(JuiceTheme.COLOR_KEYS[slot], &"feather") if _skin_resources != null else null)
		mystery.append(mystery_particle_texture(slot))
	return [[effect_texture(&"rope_petal", rope_petal_texture)], 
		[effect_texture(&"rope_star", ROPE_STAR_TEX)], whole, 
		[effect_texture(&"unlock_leaf", UNLOCK_LEAF_TEX)], 
		[effect_texture(&"unlock_glow", UNLOCK_GLOW_TEX)], mystery, 
		[effect_texture(&"mystery_glow", MYSTERY_GLOW_TEX)], 
		[effect_texture(&"mystery_flash", MYSTERY_FLASH_TEX)], 
		[effect_texture(&"mystery_star", MYSTERY_STAR_TEX)]]

func _play_skin_sound(id: StringName, volume: float = 1.0, pitch: float = 1.0) -> void :
	AudioManager.play_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id, volume, pitch)

func _stop_skin_sound(id: StringName) -> void :
	AudioManager.stop_sfx(_skin_resources.sound_id(id, id) if _skin_resources != null else id)

func _clear_changed_skin_effect_pools(previous: Array, current: Array) -> void :

	if previous[0] != current[0] or previous[1] != current[1]\
	or _connection_particles_preparing or _connection_particles_warming:
		_cancel_connection_preparation()
	var pools: Array = [_rope_petal_pool, _rope_star_pool, _rope_whole_petal_pool, 
		_unlock_leaf_pool, _unlock_glow_pool]
	for index: int in pools.size():
		if previous[index] == current[index]:
			continue
		var pool: Array = pools[index]
		for node: Node in pool:
			if is_instance_valid(node):
				if node is GPUParticles2D and node.has_meta(&"skin_lifecycle"):
					(node.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
				_rope_particle_lifecycles.erase(node)
				_common_skin_emitters.erase(node)
				node.queue_free()
		pool.clear()




func set_allow_root_swapping_enabled(enabled: bool) -> void :
	_allow_root_swapping_enabled = enabled



func set_play_after_dead_enabled(enabled: bool) -> void :
	_play_after_dead_pending = enabled


func is_play_after_dead_enabled() -> bool:
	return _play_after_dead_enabled



func can_play_after_dead() -> bool:
	return _play_after_dead_enabled and _over == "dead"\
	and _pending_dead_reason in ["stuck", "loop"]



func set_root_adjudication_suspended(suspended: bool) -> void :
	if _root_adjudication_suspended == suspended:
		return
	_root_adjudication_suspended = suspended
	if suspended:
		_invalidate_root_closed_check()
	else:
		_check_over()


func setup(level: JuiceLevel, state: Dictionary = {}, 
		color_slots: PackedInt32Array = PackedInt32Array(), endless_session: JuiceEndlessSession = null, 
		initial_slots: Dictionary = {}) -> void :
	_endless_session = endless_session
	_endless_move_guard = Callable()
	reset_skin_effects()
	_last_player_placement_msec = -1
	stop_bonus_entry_feedback()
	if is_instance_valid(_bonus_idle_fx):
		_bonus_idle_fx.stop()
	_empty_rope_feedback.clear()
	end_entrance_wind()
	_ensure_refs()
	_invalidate_death_attribution()


	_clear_hint()


	if not _drag.is_empty():
		_clear_drag_visual()
	_flush_return()
	clear_capacity_error_hint()
	_level = level
	_wood_lock_layout = resolved_lock_visual_version() == 3 and _level_has_locks(level)
	_state = state if not state.is_empty() else R.make_state(level)
	_state["allow_root_swapping"] = _allow_root_swapping_enabled
	_play_after_dead_enabled = _play_after_dead_pending and _allow_root_swapping_enabled
	_root_ready_deposits.clear()
	_root_ready_settling = false
	_cancel_closed_check()
	_reset_challenge_check()
	_resumed_round = false
	_slots = JuiceTheme.resolve_slots(level.id, level.types, color_slots)
	_apply_bonus_plan(level)
	if _bonus_type < 0 and level.has_sunlight() and level.board_frozen_pots.has(true):
		_slots = JuiceTheme.sunlight_pot_slots(_slots, level.sunlight_type)
	_steps = 0
	_move_attempt_count = 0
	_successful_link_count = 0
	_over = ""
	_drag = {}
	_hover_col = -1
	_place_drop_hover()
	_shake.clear()
	_shift_queue.clear()
	_collect_hold_since = -1.0
	_collect_hold_until = -1.0
	_visual_token_seq = 0
	_visual_token_by_col.clear()
	_visual_x.clear()
	_planned_x.clear()
	_last_col_x.clear()
	_clear_all_fly_trails()
	_clear_all_burst_state()
	_beats.clear()
	_trail_preview_settle_pending = false
	_over_signal_pending = false
	_pending_dead_reason = ""
	_history.clear()
	_clear_run_highlight()
	_clear_tutorial_pot_highlight()
	clear_col_marks()
	_run_demo = {}
	_rebuild_order(initial_slots)
	_rebuild_nodes()
	cups_changed.emit()
	_check_over()
	_refresh_lock_overlays()


func endless_undo_floor() -> int:
	var floor_done: int = int(_state.get("done", 0))
	for entry: Dictionary in _history:
		var before: Dictionary = (entry["rec"] as Dictionary).get("endless_before", {})
		if not before.is_empty():
			floor_done = mini(floor_done, int(before["state"]["done"]))
	return floor_done


func setup_endless(session: JuiceEndlessSession, move_guard: Callable = Callable()) -> void :
	setup(session.level, session.state, PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), session)
	_endless_move_guard = move_guard
	set_input_enabled(true)






func _rebuild_order(initial_slots: Dictionary = {}) -> void :
	_order.clear()
	_initial_slot_of.clear()
	if _two_rows():
		var jar_index: int = 0
		var park_slot: int = 10
		for ci: int in _level.columns:
			if _level.board_jars[ci] == JuiceLevel.NO_JAR:
				_initial_slot_of[ci] = park_slot
				park_slot += 1
			else:
				_initial_slot_of[ci] = jar_index / _level.layout_columns * 5 + jar_index % _level.layout_columns
				jar_index += 1
		if not initial_slots.is_empty():
			_initial_slot_of = initial_slots.duplicate()
	var gone: Array[bool] = _state["gone"]
	for ci in (_state["cols"] as Array).size():
		if not gone[ci]:
			_order.append(ci)
	_reindex_slots()


func _two_rows() -> bool:
	return _level != null and _level.layout_rows == 2


func _row_of(ci: int) -> int:
	if not _two_rows():
		return 0
	var slot: int = int(_initial_slot_of.get(ci, -1))
	return slot / 5 if slot >= 0 and slot < 10 else -1


func _row_y(ci: int) -> float:
	if not _two_rows():
		return 0.0
	var slot: int = int(_initial_slot_of.get(ci, -1))
	if slot >= 10:
		return _lay.slot_offset_y(slot)
	if ci >= _level.columns:
		return _lay.slot_offset_y(12 if _level.initial_parks == 2 else 11)
	return _lay.row_pitch if _row_of(ci) == 1 else 0.0


func _reindex_slots() -> void :
	_slot_of.clear()
	if _two_rows():
		var next: Array[int] = [0, 5]
		for ci: int in _order:
			var row: int = _row_of(ci)
			if row < 0:
				_slot_of[ci] = int(_initial_slot_of[ci]) if _initial_slot_of.has(ci) else 12 if _level.initial_parks == 2 else 11
			else:
				_slot_of[ci] = next[row]
				next[row] += 1
		return
	for i in _order.size():
		_slot_of[_order[i]] = i





func _reslot_after_collect(ci: int, keep: bool) -> void :
	_order.erase(ci)
	if keep:
		_order.append(ci)
	_reindex_slots()


func _rebuild_nodes() -> void :
	_restore_tutorial_column_opacity()
	cancel_bird_collections()
	_clear_wood_unlock_effects()
	_stop_drag_match_highlight(true)
	_same_color_highlight_enabled = false
	_cancel_melt_effects()
	stop_bonus_entry_feedback()
	end_bonus_collection_preview()

	_clear_complete_column_flight()
	_complete_column_deposits.clear()
	_recycle_capacity_labels()
	_legacy_replenish_pending.clear()


	_clear_demo_fruits()
	_return.clear()
	_fruit_pool.release_all()
	_blender_pool.release_all()
	_fruit_nodes.clear()
	_blender_nodes.clear()
	if _level == null or _state.is_empty():
		queue_redraw()
		return
	_solve_layout()
	_reset_visual_positions()
	var cols: Array = _state["cols"]
	for ci in _order:
		_make_blender(ci)
		var list: Array[JuiceFruit] = []
		var col: Array[int] = cols[ci]
		for idx in col.size():
			var f: JuiceFruit = _make_fruit(ci, idx, col[idx])
			if f != null:
				f.position = _home_pos_swayed(ci, idx)
				list.append(f)
		_fruit_nodes[ci] = list
	_refresh_blenders()
	_sync_last_col_x()


	_apply_run_highlight()
	_apply_tutorial_pot_highlight()
	_apply_tutorial_column_opacity()
	queue_redraw()
	_refresh_lock_overlays()



func set_capacity_knots_enabled(enabled: bool) -> void :
	_capacity_knots_enabled = enabled
	_ensure_refs()
	_refresh_capacity_labels()



func set_wood_lock_bottom_limit(bottom_limit: float) -> void :
	if _wood_lock_bottom_limit == bottom_limit or (is_finite(_wood_lock_bottom_limit)\
	and is_finite(bottom_limit) and is_equal_approx(_wood_lock_bottom_limit, bottom_limit)):
		return
	_wood_lock_bottom_limit = bottom_limit
	if _level != null and not _state.is_empty():
		_solve_layout()
		_snap_all_home()
		_refresh_capacity_labels()


func _level_has_locks(level: JuiceLevel) -> bool:
	for lock: Dictionary in level.board_locks:
		if not lock.is_empty():
			return true
	for entry: Dictionary in level.incoming:
		if not (entry.get("lock", {}) as Dictionary).is_empty():
			return true
	return false


func _recycle_capacity_labels() -> void :
	for label: JuiceRopeCapacityLabel in _capacity_label_nodes.values():
		label.reset_for_pool()
		_capacity_label_pool.append(label)
	_capacity_label_nodes.clear()



func _refresh_capacity_labels() -> void :
	if _capacity_labels_layer == null:
		return
	_capacity_labels_layer.visible = _capacity_knots_enabled
	if not _capacity_knots_enabled or _level == null or _state.is_empty():
		_recycle_capacity_labels()
		return
	for ci: int in _capacity_label_nodes.keys():
		if not _slot_of.has(ci):
			var old_label: JuiceRopeCapacityLabel = _capacity_label_nodes[ci]
			old_label.reset_for_pool()
			_capacity_label_pool.append(old_label)
			_capacity_label_nodes.erase(ci)
	var cols: Array = _state["cols"]
	for ci: int in _order:
		var label: JuiceRopeCapacityLabel = _capacity_label_nodes.get(ci)
		if label == null:
			label = _capacity_label_pool.pop_back() if not _capacity_label_pool.is_empty() else null
			if label == null:
				label = capacity_label_scene.instantiate() as JuiceRopeCapacityLabel
				_capacity_labels_layer.add_child(label)
			_capacity_label_nodes[ci] = label
		label.set_capacity((cols[ci] as Array).size(), _col_cap(ci))
		var top: float = _capacity_label_top(ci) + _row_y(ci)
		label.size = Vector2(_lay.col_w, JuiceRopeCapacityLabel.HEIGHT)
		label.position = Vector2(_col_x(ci) + _content_dx - label.size.x * 0.5, top)
		label.visible = true



func _capacity_label_top(ci: int = -1) -> float:

	var mark_height: float = JuiceColMark.MARK_SIZE if _has_col_mark_guide() else 0.0
	var bottom: float = _col_rope_bottom(ci) if ci >= 0 else _lay.rope_bottom
	return bottom + _lay.fruit_d * JuiceLayout.TRACK_BOTTOM_FRUIT_RATIO\
	+ mark_height + JuiceRopeCapacityLabel.MASK_GAP







func _solve_layout() -> void :
	var slots: int = maxi(1, (_state.get("cols", []) as Array).size())
	_solve_layout_rect(Rect2(Vector2.ZERO, size), slots)
	if _capacity_knots_enabled:
		var last_row_y: float = 0.0
		for ci: int in _order:
			last_row_y = maxf(last_row_y, _row_y(ci))
		var row_pitch: float = _lay.row_pitch
		var text_bottom_limit: float = size.y - last_row_y
		if _two_rows():

			text_bottom_limit = minf(text_bottom_limit, row_pitch)
		var layout_height: float = size.y

		for pass_index: int in 8:
			var overflow: float = _capacity_label_top() + JuiceRopeCapacityLabel.HEIGHT - text_bottom_limit
			if overflow <= 0.01:
				break
			layout_height -= overflow * 2.0 if _two_rows() else overflow
			_solve_layout_rect(Rect2(Vector2.ZERO, Vector2(size.x, layout_height)), slots)
			_lay.row_pitch = row_pitch
	if _wood_lock_layout and resolved_lock_visual_version() == 3 and is_finite(_wood_lock_bottom_limit):

		var row_offset: float = _lay.row_pitch if _two_rows() else 0.0
		_lay.fit_rope_bottom(_wood_lock_bottom_limit - row_offset - WOOD_LOCK_BOTTOM_PADDING)
	_place_plank()


func _solve_layout_rect(rect: Rect2, slots: int) -> void :
	if _two_rows():
		_lay.solve_two_rows(rect, _level.capacity, _skin, slots > _level.columns and _level.initial_parks == 2, _level.layout_columns)
	else:
		_lay.solve(rect, slots, _level.capacity, _skin, 
			maxi(1, _level.columns))
	_lay.hang_top += ROPE_HANG_Y_OFFSET * (0.8 if _two_rows() else 1.0)














func _place_plank() -> void :
	if _plank == null or _plank.texture == null:
		return
	_plank.scale = Vector2(1.0, 0.8 if _two_rows() else 1.0)
	_plank.position = Vector2(
		size.x * 0.5 - _plank.texture.get_width() * 0.5, 
		_lay.plank_top)

	if _two_rows():
		if _second_plank == null:
			_second_plank = Sprite2D.new()
			_second_plank.centered = _plank.centered
			_second_plank.z_index = _plank.z_index
			add_child(_second_plank)
			move_child(_second_plank, _plank.get_index() + 1)
		_second_plank.scale = _plank.scale
		_second_plank.texture = _plank.texture
		_second_plank.modulate = _plank.modulate
		_second_plank.position = _plank.position + Vector2(0.0, _lay.row_pitch)
		_second_plank.visible = true
	elif _second_plank != null:
		_second_plank.visible = false
	_sync_ice_shatter_shelves()


func _sync_ice_shatter_shelves() -> void :
	if is_instance_valid(_ice_shatter_fx):
		_ice_shatter_fx.set_shelves(_plank, _second_plank)


func _empty_pot_content_rect(texture: Texture2D) -> Rect2:
	return _skin_empty_visuals[texture].content_rect if _skin_empty_visuals.has(texture) else Rect2()



func _empty_pot_bottom_y(texture: Texture2D, slot: int) -> float:
	if texture == null:
		return NAN
	var visual: JuiceSkinVisual = _skin_empty_visuals.get(texture)
	if visual == null or not visual.source_bounds.has_area():
		return NAN
	var rect: Rect2 = _lay.blender_rect(slot)
	var ratio: float = minf(rect.size.x / visual.content_rect.size.x, 
		rect.size.y / visual.content_rect.size.y) * JuiceBlender.NEW_EMPTY_POT_SCALE
	return rect.get_center().y + (visual.source_bottom - visual.content_rect.get_center().y) * ratio


func _empty_pot_available_height() -> float:
	if _skin_empty_visible_size.y > 0.0:
		for texture: Texture2D in _skin_empty_visuals:
			if _skin_empty_visuals[texture].source_bounds.has_area():
				return maxf(_empty_pot_bottom_y(texture, 0) - _lay.content_top, 0.0)
	var shelf_scale: float = 0.8 if _two_rows() else 1.0
	var available: float = _lay.plank_top - _lay.content_top + EMPTY_POT_HEIGHT_SHELF_OFFSET * shelf_scale
	return maxf(available, 0.0)


func _empty_pot_max_ratio() -> float:
	var pitch: float = _pot_pitch_for_slot(0)
	var visible_size: Vector2 = _skin_empty_visible_size if _skin_empty_visible_size.y > 0.0\
	else Vector2(NEW_POT_VISIBLE_WIDTH, NEW_POT_VISIBLE_HEIGHT)
	var width_ratio: float = maxf(pitch - NEW_POT_MIN_GAP, 0.0) / visible_size.x
	return minf(_empty_pot_available_height() / visible_size.y, width_ratio)


func _empty_pot_source_bottom(texture: Texture2D) -> float:
	return _skin_empty_visuals[texture].source_bottom if _skin_empty_visuals.has(texture) else 0.0


func _make_fruit(ci: int, idx: int, type_id: int) -> JuiceFruit:
	var f: JuiceFruit = _fruit_pool.acquire(_fruit_layer) as JuiceFruit
	if f == null:
		return null
	f.col = ci
	f.idx = idx
	var hidden: bool = JuiceLevel.is_hidden(type_id)
	var frozen: bool = JuiceLevel.is_frozen(type_id)


	var real_texture: Texture2D = _texture_for_fruit(type_id)
	var texture: Texture2D = null if hidden else real_texture
	f.setup(texture, type_id, _lay.fruit_d, 
		bonus_coin_texture.get_size() if _is_bonus_type(type_id) else _skin.fruit_tex_size, hidden, frozen, element_visual(type_id), mystery_visual(), effect_texture(&"landing_star", null), 
		_halo_texture_for(real_texture), _halo_canvas_ratio_for(real_texture))
	f.set_sunlight(_level.is_sunlight_type(type_id) and not JuiceLevel.is_hidden(type_id))
	return f



func _halo_texture_for(texture: Texture2D) -> Texture2D:
	return group_halo_set.halo_for(texture) if group_halo_set != null else null


func _halo_canvas_ratio_for(texture: Texture2D) -> float:
	return group_halo_set.canvas_ratio_for(texture) if group_halo_set != null else 0.0


func _make_blender(ci: int) -> JuiceBlender:
	return _make_blender_for_type(ci, int((_state["jars"] as Array[int])[ci]))


func _make_blender_for_type(ci: int, jar: int) -> JuiceBlender:
	var b: JuiceBlender = _blender_pool.acquire(_blender_layer) as JuiceBlender
	if b == null:
		return null
	b.col = ci
	var texture: Texture2D = _texture_for_blender(jar)
	b.set_target(texture, _texture_for_full_blender(jar), jar, _empty_pot_content_rect(texture), 
		_empty_pot_source_bottom(texture))
	b.set_skin_visuals(_skin_empty_visuals.get(texture), completed_visual(jar))
	var slot: int = maxi(0, int(_slot_of.get(ci, 0)))
	b.set_ice_max_width(_pot_ice_width_for_slot(slot))
	b.place(_lay.blender_rect(slot), _skin, _empty_pot_bottom_y(texture, slot), _empty_pot_max_ratio())
	b.position.x = _col_x(ci)
	b.set_shelves(_plank, _second_plank)
	b.set_ice_behind_shelves(true)
	b.set_sunlight(_level.is_sunlight_type(jar), 
		float(R.progress_at(_state, ci)) / maxf(1.0, float(_level.capacity)), _sunlight_fx.settings)
	b.set_frozen(R.is_frozen_pot(_state, ci))
	_blender_nodes[ci] = b
	if _is_bonus_type(jar):
		_bind_bonus_idle(b)
	return b



func _refresh_blenders() -> void :
	for ci in _blender_nodes:
		var b: JuiceBlender = _blender_nodes[ci]
		if b == null or not is_instance_valid(b):
			continue
		var slot: int = int(_slot_of.get(ci, -1))
		if slot < 0:
			continue
		b.set_shelves(_plank, _second_plank)
		b.set_ice_behind_shelves(true)
		var rect: Rect2 = _lay.blender_rect(slot)
		rect.position.x = _col_x(ci) - rect.size.x * 0.5
		b.set_ice_max_width(_pot_ice_width_for_slot(slot))
		b.place(rect, _skin, _empty_pot_bottom_y(b._target_texture, slot), _empty_pot_max_ratio())

		var base_tint: Color = _tutorial_dimmed_items.get(b, Color.WHITE)
		b.modulate.a = base_tint.a * TUTORIAL_MUTED_COLUMN_ALPHA if _tutorial_dimmed_items.has(b) else 1.0
		b.set_ready(R.deposit_ready(_state, ci) > 0)
		if not _melt_surface_held(b):
			b.set_frozen(R.is_frozen_pot(_state, ci))
		b.set_sunlight(_level.is_sunlight_type(b.want_type), 
			float(R.progress_at(_state, ci)) / maxf(1.0, float(_level.capacity)), _sunlight_fx.settings)


func _pot_pitch_for_slot(slot: int) -> float:
	var pitch: float = _lay.col_w
	if _two_rows() and _lay.top_extra_rope and _lay.slot_offset_y(slot) == 0.0:
		pitch *= float(_level.layout_columns) / float(_level.layout_columns + 1)
	return pitch


func _pot_ice_width_for_slot(slot: int) -> float:
	return _pot_pitch_for_slot(slot) * 0.99


func _texture_for_fruit(type_id: int) -> Texture2D:
	if type_id < 0:
		return null
	var actual: int = JuiceLevel.true_type(type_id)
	if _level != null and _level.is_sunlight_type(actual) and sunlight_fruit_texture != null:
		return sunlight_fruit_texture
	if actual >= _slots.size():
		return null
	if _is_bonus_type(actual) and bonus_coin_texture != null:
		return bonus_coin_texture
	var slot: int = _slots[actual]
	var texs: Array[Texture2D] = _fruit_textures()
	return texs[slot] if slot >= 0 and slot < texs.size() else null


func _fruit_textures() -> Array[Texture2D]:
	return _skin_arrays[&"element"] if _skin_arrays.has(&"element") else bead_fruit_textures


func _blender_textures() -> Array[Texture2D]:
	return _skin_arrays[&"empty_container"] if _skin_arrays.has(&"empty_container") else bead_blender_textures


func _full_blender_textures() -> Array[Texture2D]:
	return _skin_arrays[&"completed_container"] if _skin_arrays.has(&"completed_container") else bead_blender_full_textures




func sunlight_guide_visuals() -> Array[Dictionary]:
	var visuals: Array[Dictionary] = []
	if _level == null or not _level.has_sunlight():
		return visuals
	var has_sun: bool = false
	var has_collector: bool = false
	var has_ice: bool = false
	for ci: int in _order:
		var blender: JuiceBlender = _blender_nodes.get(ci) as JuiceBlender
		if is_instance_valid(blender) and blender.is_visible_in_tree():
			if _level.is_sunlight_type(blender.want_type) or R.is_frozen_pot(_state, ci):
				_append_sunlight_guide_sprites(blender, visuals)
				has_collector = has_collector or _level.is_sunlight_type(blender.want_type)
				has_ice = has_ice or R.is_frozen_pot(_state, ci)
		if R.is_locked(_state, ci):
			continue
		var fruits: Array = _fruit_nodes.get(ci, [])
		var column: Array = (_state["cols"] as Array)[ci]
		for index: int in fruits.size():
			var fruit: JuiceFruit = fruits[index]
			if not JuiceLevel.is_hidden(int(column[index]))\
			and _level.is_sunlight_type(fruit.fruit_type) and fruit.is_visible_in_tree():
				_append_sunlight_guide_sprites(fruit, visuals)
				has_sun = true
	if not has_sun or not has_collector or not has_ice:
		return []
	for index: int in visuals.size():
		visuals[index]["order"] = index
	visuals.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["z"]) == int(b["z"]):
			return int(a["order"]) < int(b["order"])
		return int(a["z"]) < int(b["z"]))
	return visuals


func _append_sunlight_guide_sprites(node: Node, visuals: Array[Dictionary]) -> void :
	if node is Sprite2D:
		var sprite: Sprite2D = node as Sprite2D
		if sprite.is_visible_in_tree() and sprite.texture != null:
			var z: int = sprite.z_index
			var ancestor: CanvasItem = null if sprite.is_set_as_top_level() else (sprite.get_parent() as CanvasItem)
			var relative: bool = sprite.z_as_relative
			while ancestor != null and relative:
				z += ancestor.z_index
				relative = ancestor.z_as_relative
				ancestor = null if ancestor.is_set_as_top_level() else (ancestor.get_parent() as CanvasItem)
			visuals.append({"source": weakref(sprite), "z": z - (1 if sprite.show_behind_parent else 0)})
	for child: Node in node.get_children():
		_append_sunlight_guide_sprites(child, visuals)


func _texture_for_blender(type_id: int) -> Texture2D:
	if _level != null and _level.is_sunlight_type(type_id) and sunlight_blender_texture != null:
		return sunlight_blender_texture
	if _is_bonus_type(type_id) and bonus_pig_texture != null:
		return bonus_pig_texture
	if type_id < 0 or type_id >= _slots.size():
		if _skin_resources != null:
			return _skin_resources.single_visual(&"parking_container").texture
		return bead_blender_empty_texture
	var slot: int = _slots[type_id]
	var texs: Array[Texture2D] = _blender_textures()
	return texs[slot] if slot >= 0 and slot < texs.size() else null


func _texture_for_full_blender(type_id: int) -> Texture2D:
	if _level != null and _level.is_sunlight_type(type_id) and sunlight_full_blender_texture != null:
		return sunlight_full_blender_texture
	if type_id < 0 or type_id >= _slots.size():
		return null
	if _is_bonus_type(type_id) and bonus_pig_texture != null:
		return bonus_pig_texture
	return full_blender_texture_for_slot(_slots[type_id])




func full_blender_texture_for_type(type_id: int) -> Texture2D:
	return _texture_for_full_blender(type_id)



func full_blender_texture_for_slot(slot: int) -> Texture2D:
	var texs: Array[Texture2D] = _full_blender_textures()
	return texs[slot] if slot >= 0 and slot < texs.size() else null


func color_for_type(type_id: int) -> Color:
	if _level != null and _level.is_sunlight_type(type_id):
		return JuiceTheme.SUN_COLOR
	if type_id < 0 or type_id >= _slots.size():
		return JuiceTheme.PARK_COLOR
	return JuiceTheme.color_of_slot(_slots[type_id], _skin)



func _beat_flower_color(beat: Dictionary) -> Color:
	if beat.has("preview_color"):
		return beat["preview_color"]
	return color_for_type(int(beat["fruit"]))





func slot_for_type(type_id: int) -> int:
	if type_id < 0 or type_id >= _slots.size():
		return -1
	return _slots[type_id]





func set_bonus_candidate(enabled: bool, v2: bool = false) -> void :
	_bonus_candidate = enabled
	_bonus_v2 = v2


func bonus_type() -> int:
	return _bonus_type



func bonus_skip_reason() -> String:
	return _bonus_skip_reason




func _apply_bonus_plan(level: JuiceLevel) -> void :
	_bonus_recolor_from = -1
	_bonus_recolor_to = -1
	_bonus_skip_reason = ""
	var plan: Dictionary = {}
	if not _bonus_plan_pending.is_empty():
		plan = _bonus_plan_pending
	elif _bonus_candidate:
		plan = JuiceBonusLevel.pick_plan(level, _slots, _bonus_v2)
		_bonus_skip_reason = String(plan.get("reason", JuiceBonusLevel.REASON_NONE))
	_bonus_plan_pending = {}
	_bonus_candidate = false
	_bonus_skip_reason = String(plan.get("reason", JuiceBonusLevel.REASON_NONE))
	var type_id: int = int(plan.get("type", JuiceBonusLevel.NO_BONUS_TYPE))
	if not JuiceBonusLevel.is_valid_bonus_type(level, type_id):
		_bonus_type = -1
		return
	_bonus_type = type_id
	var from_type: int = int(plan.get("recolor_from", -1))
	var to_type: int = int(plan.get("recolor_to", -1))
	if from_type >= 0 and from_type < _slots.size() and to_type >= 0 and to_type < _slots.size()\
	and from_type != to_type:
		_slots[from_type] = _slots[to_type]
		_bonus_recolor_from = from_type
		_bonus_recolor_to = to_type



func _is_bonus_type(type_id: int) -> bool:
	return _bonus_type >= 0 and type_id == _bonus_type


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED and _level != null:
		_solve_layout()
		_snap_all_home()
		_refresh_lock_overlays()











func _col_x(ci: int) -> float:
	var token: Variant = _visual_token_by_col.get(ci)
	if token != null and _visual_x.has(int(token)):
		return float(_visual_x[int(token)])
	return _base_x(ci)











func _center_offset_x() -> float:
	if _lay == null or _two_rows():
		return 0.0
	var visible: int = _order.size()
	if visible <= 0:
		return 0.0
	return float(_lay.slots_total - visible) * _lay.col_w * 0.5



func _row_center_offset_x(slot: int) -> float:
	if not _two_rows():
		return 0.0
	var row_y: float = _lay.slot_offset_y(slot)
	var visible: int = 0
	for ci: int in _order:
		if _lay.slot_offset_y(int(_slot_of.get(ci, -1))) == row_y:
			visible += 1
	var top_extra: bool = row_y == 0.0 and _lay.top_extra_rope
	var total: int = _level.layout_columns + 1 + (1 if top_extra else 0)
	var pitch: float = _lay.col_w
	if top_extra:
		pitch *= float(_level.layout_columns) / float(_level.layout_columns + 1)
	return float(total - visible) * pitch * 0.5


func _new_visual_token(ci: int, x: float) -> int:
	_visual_token_seq += 1
	var token: int = _visual_token_seq
	_visual_token_by_col[ci] = token
	_visual_x[token] = x
	_planned_x[token] = x
	return token


func _reset_visual_positions() -> void :
	_visual_token_by_col.clear()
	_visual_x.clear()
	_planned_x.clear()
	for ci in _order:
		_new_visual_token(int(ci), _base_x(int(ci)))


func _planned_col_x(ci: int) -> float:
	var token: Variant = _visual_token_by_col.get(ci)
	if token != null and _planned_x.has(int(token)):
		return float(_planned_x[int(token)])
	return _col_x(ci)


func _base_x(ci: int) -> float:
	var slot: int = int(_slot_of.get(ci, -1))
	if slot >= 0:
		return _lay.slot_center_x(slot) + _center_offset_x() + _row_center_offset_x(slot)

	for beat: Dictionary in _beats:
		if int(beat["col"]) == ci:
			return float(beat["ghost_x"])
	return -9999.0


func _shake_dx(ci: int) -> float:
	var s: Variant = _shake.get(ci)
	if s == null:
		return 0.0
	if resolved_lock_visual_version() == 3 and not _state.is_empty() and R.is_locked(_state, ci):
		return 0.0
	var t: float = float(s)
	return sin(t * 44.0) * maxf(0.0, 1.0 - t / 0.32) * (_lay.fruit_d * 0.09)







func _sway_slope(ci: int) -> float:

	if resolved_lock_visual_version() == 3 and not _state.is_empty() and R.is_locked(_state, ci):
		return 0.0
	return _idle_sway_slope(ci)



func _idle_sway_slope(ci: int, cap: int = -1) -> float:
	if not _ambient_sway_on() or _lay == null:
		return 0.0

	var bottom: float = _lay.rope_bottom_for(cap) if cap >= 0 else _col_rope_bottom(ci)
	var span: float = maxf(bottom - _lay.hang_top, 1.0)
	var p: float = float(ci) * SWAY_PHASE_PER_COL
	var w: float = sin(_t * SWAY_OMEGA + p) * 0.78 + sin(_t * SWAY_OMEGA2 + p * 1.7) * 0.22
	return _lay.fruit_d * SWAY_AMP_RATIO * w / span



func _sway_dx(ci: int, y: float) -> float:
	if not _sway_enabled or _lay == null:
		return 0.0
	return _sway_slope(ci) * (y - _lay.hang_top - _row_y(ci))



func _wind_is_rigid() -> bool:
	if not _wind_active or _lay == null:
		return false
	var span: float = maxf(_lay.rope_bottom - _lay.hang_top, 1.0)

	return absf(_wind_amp) * span > WIND_RIGID_TAIL_PX\
	or absf(_wind_vel) * span > WIND_RIGID_VEL_PX






func _wind_curve_dx(y: float) -> float:
	if _lay == null or is_zero_approx(_wind_amp):
		return 0.0
	var span: float = maxf(_lay.rope_bottom - _lay.hang_top, 1.0)
	var u: float = clampf((y - _lay.hang_top) / span, 0.0, 1.0)
	var shape: float = WIND_LEAN_RATIO * u\
	+ (1.0 - WIND_LEAN_RATIO) * pow(u, WIND_CURVE_POW)
	return _wind_amp * span * shape




func _wind_curve_slope(y: float) -> float:
	if _lay == null or is_zero_approx(_wind_amp):
		return 0.0
	var span: float = maxf(_lay.rope_bottom - _lay.hang_top, 1.0)
	var u: float = clampf((y - _lay.hang_top) / span, 0.0, 1.0)
	return _wind_amp * (WIND_LEAN_RATIO\
	+ (1.0 - WIND_LEAN_RATIO) * WIND_CURVE_POW * pow(u, WIND_CURVE_POW - 1.0))







func set_content_offset_x(dx: float) -> void :
	if is_equal_approx(_content_dx, dx):
		return
	_content_dx = dx
	_ensure_refs()

	for c: Control in [_drop_hover, _hint_target, _col_marks_layer, _lock_layer]:
		if c != null:
			c.position.x = dx
	for n: Node2D in [_blender_layer, _fruit_layer, _fx_layer]:
		if n != null:
			n.position.x = dx
	queue_redraw()


func begin_entrance_wind(start_dx: float, duration: float) -> void :
	end_entrance_wind()
	_entrance_motion_active = true
	_wind_active = _sway_enabled
	_wind_start_dx = start_dx
	_wind_duration = duration
	set_content_offset_x(start_dx)


	var span: float = maxf(_lay.rope_bottom - _lay.hang_top, 1.0)
	var b: float = PI / duration
	var alpha: float = ENTRANCE_WIND_ZETA * ENTRANCE_WIND_OMEGA
	var wd: float = ENTRANCE_WIND_OMEGA * sqrt(1.0 - ENTRANCE_WIND_ZETA * ENTRANCE_WIND_ZETA)
	var detune: float = ENTRANCE_WIND_OMEGA * ENTRANCE_WIND_OMEGA - b * b
	var damping: float = 2.0 * alpha * b
	var q: float = start_dx * b * b * ENTRANCE_WIND_ACCEL_GAIN / (2.0 * span)
	_wind_drive_coeffs = Vector2(detune, damping) * (q / (detune * detune + damping * damping))
	_wind_decay_coeffs = Vector2( - _wind_drive_coeffs.x, 
		( - b * _wind_drive_coeffs.y - alpha * _wind_drive_coeffs.x) / wd)
	var end_state: Vector2 = _entrance_wind_state(duration)
	_wind_free_coeffs = Vector2(end_state.x, (end_state.y + alpha * end_state.x) / wd)



func set_entrance_time(time: float) -> void :
	if not _entrance_motion_active or time < _entrance_target_time:
		return
	_entrance_target_time = clampf(time, 0.0, _wind_duration)
	_entrance_time_pending = true


func is_entrance_motion_active() -> bool:
	return _entrance_motion_active



func set_reveal_memory_enabled(enabled: bool) -> void :
	_keep_revealed_on_undo = enabled



func can_auto_unlock_mystery() -> bool:
	return not tutorial_demo_only and _endless_session == null and _over != "win"\
	and not (_play_after_dead_enabled and _over == "dead")\
	and R.mystery_auto_unlock_eligible(_state, _level)



func auto_unlock_mystery() -> bool:
	if not can_auto_unlock_mystery():
		return false
	var result: Dictionary = R.apply_mystery_auto_unlock(_state, _level)
	if result.is_empty():
		return false
	if not _history.is_empty():
		var rec: Dictionary = (_history.back() as Dictionary)["rec"]
		rec["auto_unlock_before"] = result["before"]
		rec["auto_unlock_deposits"] = result["deposits"]
	_clear_hint()
	_clear_run_highlight()
	_cancel_closed_check()
	_invalidate_death_attribution()
	_invalidate_safe_return()
	_over = ""
	_over_signal_pending = false
	_pending_dead_reason = ""
	_apply_reveals(result["revealed"] as Array)
	var deposits: Array = result["deposits"]
	if not deposits.is_empty():
		_enqueue_beats(deposits)

		if not _history.is_empty():
			var moved_col: int = int((_history.back() as Dictionary)["rec"].get("dst", -1))
			for deposit: Dictionary in deposits:
				if int(deposit["col"]) == moved_col:
					_empty_rope_feedback.clear()
	_refresh_blenders()
	_play_lock_unlock_effects(result["unlocked"] as Array)
	_refresh_lock_overlays()
	queue_redraw()
	return true



func check_over_after_auto_unlock() -> void :
	_check_over()


func has_active_drag() -> bool:
	return not _drag.is_empty()



func end_entrance_wind() -> void :
	_entrance_motion_active = false
	_entrance_time_pending = false
	_entrance_target_time = 0.0
	_wind_active = false
	_wind_amp = 0.0
	_wind_vel = 0.0
	_wind_time = 0.0
	_wind_duration = 0.0
	_wind_start_dx = 0.0
	_wind_drive_coeffs = Vector2.ZERO
	_wind_decay_coeffs = Vector2.ZERO
	_wind_free_coeffs = Vector2.ZERO
	queue_redraw()



func _advance_entrance_wind(delta: float) -> void :
	if _lay == null or delta <= 0.0:
		return
	if _entrance_motion_active:
		if not _entrance_time_pending:
			return
		_wind_time = _entrance_target_time
		_entrance_time_pending = false
		_entrance_motion_active = _wind_time < _wind_duration
		var dx: float = _wind_start_dx * (1.0 + cos(PI * _wind_time / _wind_duration)) * 0.5
		set_content_offset_x(dx)
	elif _wind_active:
		_wind_time += delta
	else:
		return
	if not _wind_active:
		return
	var state: Vector2 = _entrance_wind_state(_wind_time)
	_wind_amp = state.x
	_wind_vel = state.y

	var span: float = maxf(_lay.rope_bottom - _lay.hang_top, 1.0)
	var tail_px: float = absf(_wind_amp) * span
	var tail_vel_px: float = absf(_wind_vel) * span
	if not _entrance_motion_active and tail_px < WIND_SETTLE_PX\
	and tail_vel_px < WIND_SETTLE_PX_PER_SEC:
		_wind_active = false
		_wind_amp = 0.0
		_wind_vel = 0.0



func _entrance_wind_state(time: float) -> Vector2:
	var alpha: float = ENTRANCE_WIND_ZETA * ENTRANCE_WIND_OMEGA
	var wd: float = ENTRANCE_WIND_OMEGA * sqrt(1.0 - ENTRANCE_WIND_ZETA * ENTRANCE_WIND_ZETA)
	var age: float = time if time <= _wind_duration else time - _wind_duration
	var coeffs: Vector2 = _wind_decay_coeffs if time <= _wind_duration else _wind_free_coeffs
	var c: float = cos(wd * age)
	var s: float = sin(wd * age)
	var decay: float = exp( - alpha * age)
	var amp: float = decay * (coeffs.x * c + coeffs.y * s)
	var vel: float = decay * (( - alpha * coeffs.x + wd * coeffs.y) * c
		+ ( - alpha * coeffs.y - wd * coeffs.x) * s)
	if time <= _wind_duration:
		var b: float = PI / _wind_duration
		var drive_c: float = cos(b * time)
		var drive_s: float = sin(b * time)
		amp += _wind_drive_coeffs.x * drive_c + _wind_drive_coeffs.y * drive_s
		vel += b * ( - _wind_drive_coeffs.x * drive_s + _wind_drive_coeffs.y * drive_c)
	return Vector2(amp, vel)



func set_sway_enabled(on: bool) -> void :
	if _sway_enabled == on:
		return
	_sway_enabled = on


	if not on:
		_wind_active = false
		_wind_amp = 0.0
		_wind_vel = 0.0
	queue_redraw()



func set_ambient_sway_enabled(on: bool) -> void :
	if _ambient_sway_enabled == on:
		return
	_ambient_sway_enabled = on
	queue_redraw()


func _ambient_sway_on() -> bool:
	return _sway_enabled and _ambient_sway_enabled


func _home_pos(ci: int, idx: int) -> Vector2:
	return Vector2(_col_x(ci), _lay.fruit_y(idx) + _row_y(ci))













func _home_pos_swayed(ci: int, idx: int) -> Vector2:
	var p: Vector2 = _home_pos(ci, idx)
	p.x += _sway_dx(ci, p.y)
	return p




func _snap_all_home() -> void :
	for ci in _order:
		var token: Variant = _visual_token_by_col.get(ci)
		if token != null:
			_visual_x[int(token)] = _base_x(int(ci))
			_planned_x[int(token)] = _base_x(int(ci))
	_rebuild_col_marks()
	for ci in _fruit_nodes:
		var list: Array[JuiceFruit] = _fruit_nodes[ci]
		for i in list.size():
			if is_instance_valid(list[i]):
				list[i].set_diameter(_lay.fruit_d)
				if list[i].top_level:
					continue
				list[i].position = _home_pos_swayed(ci, i)
				list[i].rotation = 0.0
				list[i].scale = Vector2.ONE
	_refresh_blenders()



	_refresh_lock_overlays()
	_sync_last_col_x()
	queue_redraw()


func _sync_last_col_x() -> void :
	_last_col_x.clear()
	for ci in _order:
		_last_col_x[ci] = _col_x(ci)





func is_busy() -> bool:
	return not _complete_column_flight.is_empty()\
	or not _beats.is_empty() or not _shift_queue.is_empty() or not _sunlight_batches.is_empty()




func is_drop_returning() -> bool:
	return not _return.is_empty()










func is_entrance_wind_active() -> bool:
	return _wind_active








func is_entrance_wind_strong() -> bool:
	return _wind_is_rigid()





func fade_flowers_out(dur: float) -> void :
	_kill_flowers_fade_tween()
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return
	_flowers_fade_tween = layer.create_tween()
	_flowers_fade_tween.tween_property(layer, "modulate:a", 0.0, dur)





func set_flowers_alpha(a: float) -> void :

	_kill_flowers_fade_tween()
	var layer: Node2D = _resolve_fruit_layer()
	if layer != null:
		layer.modulate.a = a


func _kill_flowers_fade_tween() -> void :
	if _flowers_fade_tween != null and _flowers_fade_tween.is_valid():
		_flowers_fade_tween.kill()
	_flowers_fade_tween = null



func _resolve_fruit_layer() -> Node2D:
	if _fruit_layer == null:
		_fruit_layer = get_node_or_null("FruitLayer")
	return _fruit_layer



func _ensure_fly_trails() -> FireworkTrails:
	if is_instance_valid(_fly_trails):
		return _fly_trails
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	_fly_trails = FireworkTrails.new()
	_fly_trails.name = "FlyTrails"




	_fly_trails.z_index = SLAM_FLY_Z
	layer.add_child(_fly_trails)
	layer.move_child(_fly_trails, 0)
	return _fly_trails




func _ensure_rank_collectible_fly_trails() -> FireworkTrails:
	if is_instance_valid(_rank_collectible_fly_trails):
		return _rank_collectible_fly_trails
	if _blender_layer == null:
		_blender_layer = get_node_or_null("BlenderLayer")
	if _blender_layer == null:
		return null
	_rank_collectible_fly_trails = FireworkTrails.new()
	_rank_collectible_fly_trails.name = "RankCollectibleFlyTrails"
	_rank_collectible_fly_trails.z_index = 0
	_blender_layer.add_child(_rank_collectible_fly_trails)
	_blender_layer.move_child(_rank_collectible_fly_trails, 0)
	return _rank_collectible_fly_trails




func _clear_all_fly_trails() -> void :
	for beat: Dictionary in _beats:
		var ribbons: Array = beat.get("trail_ribbons", [])
		for r in ribbons:
			if r != null:
				(r as FireworkTrails.Ribbon).detach()
	if is_instance_valid(_fly_trails):
		_fly_trails.clear_all()
	if is_instance_valid(_complete_column_trails):
		_complete_column_trails.clear_all()
	if is_instance_valid(_rank_collectible_fly_trails):
		_rank_collectible_fly_trails.clear_all()
	if is_instance_valid(_bonus_gold_trails):
		_bonus_gold_trails.clear_all()





func _clear_all_burst_state() -> void :
	_connection_pending.clear()
	for effect: Node2D in _connection_effects.duplicate():
		if is_instance_valid(effect):
			if effect is GPUParticles2D and _rope_particle_lifecycles.has(effect):
				if effect.has_meta(&"rope_star_tween"):
					_release_rope_star_emitter(effect)
				else:
					_release_rope_petal_emitter(effect)
			else:
				effect.queue_free()
	_connection_effects.clear()
	for beat: Dictionary in _beats:
		for tw in (beat.get("burst_tweens", []) as Array):
			if tw != null and (tw as Tween).is_valid():
				(tw as Tween).kill()
		for f: JuiceFruit in (beat.get("nodes", []) as Array):
			if is_instance_valid(f):
				f.scale = Vector2.ONE


func set_input_enabled(on: bool) -> void :
	_input_enabled = on
	if not on:
		_cancel_drag()



func set_entrance_lock(on: bool) -> void :
	if _entrance_lock == on:
		return
	_entrance_lock = on
	if on:
		_cancel_drag()




func cancel_active_drag() -> void :
	_cancel_drag()




func set_hint_lock(on: bool) -> void :
	if _hint_lock == on:
		return
	_hint_lock = on
	if on:
		_cancel_drag()



func _can_play_block_reason() -> String:




	if not _input_enabled:
		return "input_locked"
	if _entrance_lock:
		return "entrance_lock"
	if _hint_lock:
		return "hint_lock"
	if not _complete_column_flight.is_empty():
		return "flight"
	if not is_zero_approx(_content_dx):
		return "entrance_motion"
	if _over != "" and not can_play_after_dead():
		return "board_over"
	if _level == null or _state.is_empty() or (_state["cols"] as Array).is_empty():
		return "no_level"
	return ""


func _can_play() -> bool:
	return _can_play_block_reason().is_empty()


func _gui_input(e: InputEvent) -> void :
	if not _can_play():
		return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = e
		if mb.pressed:
			var input_started: int = Time.get_ticks_usec() if OS.is_debug_build() and not _first_pickup_logged else 0
			note_player_operation()
			_begin_drag(mb.position, input_started > 0 and not tutorial_demo_only)




			if not _drag.is_empty():
				_clear_hint()
				if not _first_pickup_times.is_empty():
					_log_first_pickup(input_started)
		elif not _drag.is_empty():

			if not _location_judge_settings.is_empty():
				_drag["pos"] = mb.position
				_update_hover(false)
			_drop_at()
	elif e is InputEventMouseMotion and not _drag.is_empty():
		_drag["pos"] = (e as InputEventMouseMotion).position
		_update_hover()









func _hit_fruit(pos: Vector2) -> Dictionary:
	var hit: Dictionary = {}
	var best_d: float = INF
	for ci in _order:
		var h: Dictionary = _hit_fruit_in_col(pos, int(ci))
		if h.is_empty():
			continue
		var d: float = float(h["d"])
		if d < best_d:
			best_d = d
			hit = {"col": int(h["col"]), "j": int(h["j"]), "at": h["at"] as Vector2}
	return hit








func _hit_fruit_in_col(pos: Vector2, ci: int) -> Dictionary:
	if _replenish_column_pending(ci):
		return {}
	var cols: Array = _state["cols"]
	if ci < 0 or ci >= cols.size() or (cols[ci] as Array).is_empty():
		return {}
	var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
	if list.is_empty():
		return {}
	var band: float = minf(_lay.col_w * 0.5, _lay.fruit_d * 0.5 + 22.0)


	var j: int = -1
	var best_d: float = INF
	var best_at: Vector2 = Vector2.ZERO
	for i in list.size():
		if not is_instance_valid(list[i]):
			continue
		var at: Vector2 = _fruit_layer_pos(list[i])
		var d: float = _fruit_hit_dist(pos, at, band)
		if d < best_d:
			best_d = d
			j = i
			best_at = at
	if j < 0 or best_d > _lay.fruit_d * 0.5 + 16.0:
		return {}
	return {"col": ci, "j": j, "d": best_d, "at": best_at}



func _fruit_hit_dist(pos: Vector2, center: Vector2, band: float) -> float:
	if absf(pos.x - center.x) > band:
		return INF
	return absf(pos.y - center.y)




func set_drop_settings(settings: Dictionary) -> void :
	_location_judge_settings = settings.duplicate()


func _hit_column(pos: Vector2, src: int, j: int) -> int:
	if _location_judge_settings.is_empty():
		return _hit_column_old(pos, src, j)
	return _hit_column_new(pos, src, j)


func _hit_column_old(pos: Vector2, src: int, j: int) -> int:
	var overlap: int = -1
	var overlap_d: float = INF
	var legal: int = -1
	var legal_d: float = INF
	var filled: int = -1
	var filled_d: float = INF
	var best: int = -1
	var best_d: float = INF
	var pair: Vector2i = _drop_neighbor_pair(pos.x, pos.y)

	var same_empty: bool = _is_same_empty_pair(pair, src, j)
	var fruit_ratio: float = DROP_OVERLAP_FRUIT_RATIO
	if _is_src_neighbor_pair(pair, src, j):
		fruit_ratio = DROP_SRC_NEIGHBOR_FRUIT_RATIO
	elif same_empty:
		fruit_ratio = DROP_SAME_EMPTY_FRUIT_RATIO
	var cols: Array = _state["cols"]
	var overlap_half_w: float = _lay.col_w * 0.5\
	+ _lay.fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO * fruit_ratio
	for ci in _order:
		if _replenish_column_pending(ci):
			continue
		var row_y: float = _row_y(ci)
		var in_drop_y: bool = pos.y > _lay.plank_top + row_y and pos.y < _col_rope_bottom(ci) + _lay.gap + row_y
		var x: float = _col_x(ci)
		var dx: float = absf(pos.x - x)
		if in_drop_y and dx <= overlap_half_w:
			if dx < overlap_d:
				overlap_d = dx
				overlap = ci
			if R.move_info(_state, src, j, ci) > 0:
				if dx < legal_d:
					legal_d = dx
					legal = ci
				if same_empty and not (cols[ci] as Array).is_empty() and dx < filled_d:
					filled_d = dx
					filled = ci
		var edge: float = maxf(0.0, dx - _lay.col_w * 0.5)
		var dy: float = 0.0
		if pos.y < _lay.hang_top + row_y:
			dy = _lay.hang_top + row_y - pos.y
		elif pos.y > _col_rope_bottom(ci) + _lay.gap + row_y:
			dy = pos.y - (_col_rope_bottom(ci) + _lay.gap + row_y)
		var d: float = sqrt(edge * edge + dy * dy)
		if d < best_d:
			best_d = d
			best = ci
	if filled >= 0:
		return filled
	if legal >= 0:
		return legal
	if overlap >= 0:
		return overlap
	return best if best_d <= DROP_SLACK else -1



func _drop_neighbor_pair(pos_x: float, pos_y: float = NAN) -> Vector2i:
	var left: int = -1
	var left_x: float = - INF
	var right: int = -1
	var right_x: float = INF
	for ci in _order:
		if _replenish_column_pending(ci):
			continue
		if _two_rows() and not is_nan(pos_y) and (pos_y < _lay.plank_top + _row_y(ci)
				or pos_y > _col_rope_bottom(ci) + _lay.gap + _row_y(ci)):
			continue
		var x: float = _col_x(ci)
		if x <= pos_x and x > left_x:
			left_x = x
			left = ci
		elif x > pos_x and x < right_x:
			right_x = x
			right = ci
	return Vector2i(left, right)



func _is_src_neighbor_pair(pair: Vector2i, src: int, j: int) -> bool:
	if pair.x < 0 or pair.y < 0:
		return false
	if pair.x == src:
		return R.move_info(_state, src, j, pair.y) > 0
	if pair.y == src:
		return R.move_info(_state, src, j, pair.x) > 0
	return false




func _is_same_empty_pair(pair: Vector2i, src: int, j: int) -> bool:
	if pair.x < 0 or pair.y < 0 or pair.x == src or pair.y == src:
		return false
	if R.move_info(_state, src, j, pair.x) <= 0 or R.move_info(_state, src, j, pair.y) <= 0:
		return false
	var cols: Array = _state["cols"]
	if (cols[pair.x] as Array).is_empty() == (cols[pair.y] as Array).is_empty():
		return false
	var filled: int = pair.y if (cols[pair.x] as Array).is_empty() else pair.x
	return not R.is_root_swap(_state, src, j, filled)


func _hit_column_new(pos: Vector2, src: int, j: int) -> int:
	var edge_target: int = _page_edge_drop_target(pos, src, j)
	if edge_target >= 0:
		return edge_target
	var neighbor_target: int = _source_neighbor_drop_target(pos, src, j)
	if neighbor_target >= 0:
		return neighbor_target
	var overlap: int = -1
	var overlap_d: float = INF
	var placement: int = -1
	var legal_target: int = -1
	var legal_target_d: float = INF
	var best: int = -1
	var best_d: float = INF
	var base_half_w: float = (_lay.col_w * 0.5
		+ _lay.fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO * DROP_OVERLAP_FRUIT_RATIO)
	for ci in _order:
		if _replenish_column_pending(ci):
			continue
		var row_y: float = _row_y(ci)
		var in_drop_y: bool = pos.y > _lay.plank_top + row_y and pos.y < _col_rope_bottom(ci) + _lay.gap + row_y
		var x: float = _col_x(ci)
		var dx: float = absf(pos.x - x)
		var legal: bool = ci != src and R.move_info(_state, src, j, ci) > 0
		var scale: float = DROP_TARGET_RANGE_SCALE if ci == src else (float(_location_judge_settings.get("legal", DROP_LEGAL_RANGE_SCALE)) if legal else float(_location_judge_settings.get("invalid", DROP_INVALID_RANGE_SCALE)))
		var overlap_half_w: float = base_half_w * scale
		if in_drop_y and dx <= overlap_half_w:
			if dx < overlap_d:
				overlap_d = dx
				overlap = ci
			if legal:
				if dx < legal_target_d:
					legal_target_d = dx
					legal_target = ci
			elif ci == src:
				placement = src
		var edge: float = maxf(0.0, dx - _lay.col_w * 0.5)
		var dy: float = 0.0
		if pos.y < _lay.hang_top + row_y:
			dy = _lay.hang_top + row_y - pos.y
		elif pos.y > _col_rope_bottom(ci) + _lay.gap + row_y:
			dy = pos.y - (_col_rope_bottom(ci) + _lay.gap + row_y)
		var d: float = sqrt(edge * edge + dy * dy)

		if dx <= overlap_half_w and d < best_d:
			best_d = d
			best = ci
	if legal_target >= 0:
		return legal_target
	if placement >= 0:
		return placement
	if overlap >= 0:
		return overlap
	return best if best_d <= DROP_SLACK else -1



func _page_edge_drop_target(pos: Vector2, src: int, j: int) -> int:
	var flower_half: float = _lay.fruit_d * 0.65
	var screen_margin: float = _lay.fruit_d
	if pos.x < - screen_margin or pos.x > size.x + screen_margin:
		return -1
	var left: int = -1
	var right: int = -1
	var left_x: float = INF
	var right_x: float = - INF
	for ci: int in _order:
		if _replenish_column_pending(ci):
			continue
		var row_y: float = _row_y(ci)
		if pos.y <= _lay.plank_top + row_y or pos.y >= _col_rope_bottom(ci) + _lay.gap + flower_half + row_y:
			continue
		var x: float = _col_x(ci)
		if x < left_x:
			left_x = x
			left = ci
		if x > right_x:
			right_x = x
			right = ci
	var target: int = -1
	if left >= 0 and pos.x <= left_x - _lay.col_w * 0.5:
		target = left
	elif right >= 0 and pos.x >= right_x + _lay.col_w * 0.5:
		target = right
	return target if target >= 0 and target != src and R.move_info(_state, src, j, target) > 0 else -1



func _source_neighbor_drop_target(pos: Vector2, src: int, j: int) -> int:
	if not _slot_of.has(src) or _replenish_column_pending(src):
		return -1
	var row_y: float = _row_y(src)
	if pos.y <= _lay.plank_top + row_y or pos.y >= _col_rope_bottom(src) + _lay.gap + row_y:
		return -1
	var source_x: float = _col_x(src)
	var offset: float = pos.x - source_x
	var limit: float = (_lay.col_w * 0.5 + _lay.fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO * DROP_OVERLAP_FRUIT_RATIO) * DROP_TARGET_RANGE_SCALE
	if absf(offset) > limit:
		return -1
	var has_neighbor: bool = false
	var selected: int = -1
	var selected_rank: int = 2
	var selected_d: float = INF
	var cols: Array = _state["cols"]
	for ci: int in _order:
		if ci == src or _replenish_column_pending(ci) or not _slot_of.has(ci):
			continue
		if absi(int(_slot_of[ci]) - int(_slot_of[src])) != 1 or not is_equal_approx(_row_y(ci), row_y):
			continue
		var neighbor_x: float = _col_x(ci)
		if R.move_info(_state, src, j, ci) <= 0:
			continue
		has_neighbor = true
		var delta: float = neighbor_x - source_x
		var exit_distance: float = absf(delta) * DROP_SOURCE_EXIT_RATIO
		if offset * delta <= 0.0 or absf(offset) <= exit_distance or is_equal_approx(absf(offset), exit_distance):
			continue
		var rank: int = 1 if (cols[ci] as Array).is_empty() else 0
		var distance: float = absf(pos.x - neighbor_x)
		if rank < selected_rank or (rank == selected_rank and distance < selected_d):
			selected = ci
			selected_rank = rank
			selected_d = distance
	return selected if selected >= 0 else (src if has_neighbor else -1)


func _begin_drag(pos: Vector2, trace_pickup: bool = false) -> void :
	var times: PackedInt64Array = PackedInt64Array()
	if trace_pickup:
		times.append(Time.get_ticks_usec())
	clear_capacity_error_hint()
	_cancel_color_reject_hold()
	var locked_col: int = _hit_wood_locked_column(pos)
	var h: Dictionary = {"col": locked_col, "j": 0} if locked_col >= 0 else _hit_fruit(pos)
	if h.is_empty():
		return
	var ci: int = int(h["col"])
	var j: int = int(h["j"])
	if R.is_locked(_state, ci):
		_start_column_reject_shake(ci)
		_play_skin_sound(&"move_rejected")
		locked_grabbed.emit(ci)
		queue_redraw()
		return
	var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
	if j >= list.size():
		return


	if _grab_gate.is_valid() and not bool(_grab_gate.call(ci, j)):
		return
	if trace_pickup:
		times.append(Time.get_ticks_usec())

	var block: Array[JuiceFruit] = []
	for i in range(j, list.size()):
		var f: JuiceFruit = list[i]
		if not is_instance_valid(f):
			continue


		f.stop_breathing_group_highlight(true)
		_return.erase(f)
		_set_drag_top_level(f, true)
		f.z_index = 10
		block.append(f)
	if block.is_empty():
		return

	var inv: Transform2D = get_global_transform().affine_inverse()
	var chain_xs: = PackedFloat32Array()
	var chain_vx: = PackedFloat32Array()
	for f: JuiceFruit in block:
		chain_xs.append((inv * f.global_position).x)
		chain_vx.append(0.0)
	_drag = {
		"col": ci, "j": j, "nodes": block, 



		"grab": pos - (h["at"] as Vector2), 
		"pos": pos, 

		"grip": 0.0, 



		"xs": chain_xs, 
		"vx": chain_vx, 
		"shown": chain_xs.duplicate(), 
		"rot": PackedFloat32Array(), 
	}
	if trace_pickup:
		times.append(Time.get_ticks_usec())
	_request_major_sound(&"juice_pick", tutorial_demo_only)
	if trace_pickup:
		times.append(Time.get_ticks_usec())
	drag_started.emit(ci, j)
	if trace_pickup:
		times.append(Time.get_ticks_usec())
	_advance_drag_match_highlight()

	_update_hover()

	block[0].z_index = 11


	if _has_col_mark_guide() and not _move_gate.is_valid():
		_set_rule_col_marks(ci, j)
	if trace_pickup:
		times.append(Time.get_ticks_usec())
		_first_pickup_times = times



func _log_first_pickup(input_started: int) -> void :
	var times: PackedInt64Array = _first_pickup_times
	var finished: int = Time.get_ticks_usec()
	_first_pickup_logged = true
	_first_pickup_times = PackedInt64Array()
	SortLogger.info("[FirstPickup] total_ms=%.3f input_ms=%.3f hit_gate_ms=%.3f nodes_ms=%.3f sound_ms=%.3f callbacks_ms=%.3f hover_marks_ms=%.3f hint_ms=%.3f" % [
		float(finished - input_started) / 1000.0, float(times[0] - input_started) / 1000.0, 
		float(times[1] - times[0]) / 1000.0, float(times[2] - times[1]) / 1000.0, 
		float(times[3] - times[2]) / 1000.0, float(times[4] - times[3]) / 1000.0, 
		float(times[5] - times[4]) / 1000.0, float(finished - times[5]) / 1000.0])



func _has_col_mark_guide() -> bool:
	return _level != null and _level.id >= 1 and _level.id <= 3







func _drag_head_pos() -> Vector2:
	if _drag.is_empty():
		return Vector2.ZERO
	return (_drag["pos"] as Vector2) - (_drag["grab"] as Vector2)



func _update_hover(notify_entry: bool = true) -> void :
	_hover_col = _hit_column(_drag_head_pos(), int(_drag["col"]), int(_drag["j"]))\
	if not _drag.is_empty() else -1
	_place_drop_hover()
	if notify_entry:
		_update_drop_target_entry()



func _update_drop_target_entry() -> void :
	if _drag.is_empty():
		return
	var target: int = -1
	var src: int = int(_drag["col"])
	var j: int = int(_drag["j"])
	if not tutorial_demo_only and _hover_col != src and _slot_of.has(_hover_col)\
	and R.move_info(_state, src, j, _hover_col) > 0\
	and not R.is_root_swap(_state, src, j, _hover_col):
		var selected_mark: bool = _has_col_mark_guide()\
		and (_col_mark_spec.get("guides", []) as Array).has(_hover_col)
		if selected_mark or (_drop_hover != null and _drop_hover.visible):
			target = _hover_col
	var previous: int = int(_drag.get("entered_target", -1))
	_drag["entered_target"] = target
	if target >= 0 and target != previous:
		drop_target_entered.emit(target)


func _drop_at() -> void :
	if _drag.is_empty():
		return
	var src: int = int(_drag["col"])
	var j: int = int(_drag["j"])
	var target: int = _hit_column(_drag_head_pos(), src, j)
	var ctx: = JuiceDropContext.new(self, src, j, target)
	ctx.root_swapped = R.is_root_swap(_state, src, j, target)
	ctx.long_link_geometry = {} if ctx.root_swapped else capture_long_link_placement(target)
	JuiceDropFlow.run(ctx)

	if not ctx.handled:
		SortLogger.error("JuiceDropFlow: synchronous drop handling was delayed")
		JuiceDropFlow.finish_now(ctx)



func _finish_drag_for_drop() -> void :
	_stop_drag_match_highlight()
	_clear_drag_visual()
	_drag = {}
	_hover_col = -1
	_place_drop_hover()
	drag_ended.emit()


func _classify_drop(ctx) -> void :


	if ctx.target < 0 or ctx.target == ctx.src:
		ctx.outcome = JuiceDropContext.Outcome.CANCEL
		return


	if _move_gate.is_valid() and not bool(_move_gate.call(ctx.src, ctx.j, ctx.target)):
		ctx.outcome = JuiceDropContext.Outcome.BLOCKED
		return
	if R.move_info(_state, ctx.src, ctx.j, ctx.target) > 0:
		ctx.root_swapped = R.is_root_swap(_state, ctx.src, ctx.j, ctx.target)
		ctx.outcome = JuiceDropContext.Outcome.VALID
		return
	ctx.outcome = JuiceDropContext.Outcome.REJECTED
	ctx.reason = R.reject_reason(_state, ctx.src, ctx.j, ctx.target)


func _handle_blocked_drop(src: int, j: int, target: int) -> void :
	_start_column_reject_shake(target)
	_play_skin_sound(&"move_rejected")
	move_blocked.emit(src, j, target)
	queue_redraw()


func _handle_rejected_drop(src: int, j: int, target: int, reason: int) -> void :
	_last_rejected_target = target
	if reason in [R.Reject.COLOR, R.Reject.FULL, R.Reject.MYSTERY, R.Reject.FROZEN]:
		error_feedback_requested.emit(reason)



	if reason == R.Reject.COLOR or reason == R.Reject.FULL\
	or reason == R.Reject.LOCKED or reason == R.Reject.MYSTERY or reason == R.Reject.FROZEN:
		var info: Dictionary = _tracking_move_info(_state, src, j, target)
		info["is_link"] = 0
		info["is_finished_order"] = 0
		info["after_empty_rope_num"] = info["before_empty_rope_num"]
		info["after_possible_moves"] = info["before_possible_moves"]
		info["reject_reason"] = reason
		_move_attempt_count += 1
		move_attempted.emit(info)
	if reason in [R.Reject.COLOR, R.Reject.MYSTERY, R.Reject.FROZEN] and _new_error_animation_enabled:
		_shake.erase(target)
		var flowers: Array[JuiceFruit] = _fruit_nodes.get(target, [] as Array[JuiceFruit])
		if not flowers.is_empty() and is_instance_valid(flowers.back()):
			_start_color_reject_hold(src, j, flowers.back())
	else:
		_start_column_reject_shake(target)
	_play_skin_sound(&"move_rejected")
	move_rejected.emit(reason)
	queue_redraw()




func play_reject_feedback(target: int) -> void :
	if target < 0 or target >= (_state.get("cols", []) as Array).size():
		return
	_start_column_reject_shake(target)
	_play_skin_sound(&"move_rejected")
	queue_redraw()


func _apply_valid_drop(src: int, j: int, target: int, same_color_connection: bool = false) -> bool:
	return _do_move(src, j, target, true, same_color_connection)


func move_feedback_info() -> Dictionary:
	return _move_feedback_info.duplicate()



func capture_long_link_placement(target: int) -> Dictionary:
	if target < 0:
		return {}
	var target_count: int = (_fruit_nodes.get(target, []) as Array).size()

	if target_count == 0:
		return {}
	var dst_pos: Vector2 = _home_pos(target, target_count) + Vector2(_content_dx, 0.0)
	var transform: Transform2D = get_global_transform()
	return {"center": transform * dst_pos, "width": _lay.fruit_d * transform.x.length()}



func record_valid_placement(geometry: Dictionary) -> void :
	if geometry.is_empty():
		return
	var now_msec: int = Time.get_ticks_msec()
	var previous_msec: int = _last_player_placement_msec
	_last_player_placement_msec = now_msec
	if previous_msec < 0 or now_msec - previous_msec < LONG_LINK_GAP_MSEC:
		return
	long_link_triggered.emit(geometry)



func capture_connection(src: int, j: int, dst: int) -> Dictionary:
	if R.is_root_swap(_state, src, j, dst) or R.move_info(_state, src, j, dst) <= 0:
		return {}
	var source: Array[JuiceFruit] = _fruit_nodes.get(src, [] as Array[JuiceFruit])
	var target: Array[JuiceFruit] = _fruit_nodes.get(dst, [] as Array[JuiceFruit])
	if j < 0 or j >= source.size() or target.is_empty():
		return {}
	var leading: JuiceFruit = source[j]
	var bottom: JuiceFruit = target.back()
	if leading.fruit_type < 0 or JuiceLevel.is_hidden(leading.fruit_type)\
	or JuiceLevel.is_hidden(bottom.fruit_type)\
	or JuiceLevel.connection_type(leading.fruit_type) != JuiceLevel.connection_type(bottom.fruit_type):
		return {}
	return {"leading": leading, "bottom": bottom, "dst": dst, 
		"index": target.size(), "type": JuiceLevel.connection_type(leading.fruit_type), "started": _t}


func queue_connection_feedback(connection: Dictionary) -> void :
	if connection.is_empty():
		return

	var target: Array[JuiceFruit] = _fruit_nodes.get(int(connection["dst"]), [] as Array[JuiceFruit])
	if not target.has(connection["leading"]) or not target.has(connection["bottom"]):
		return
	_connection_pending.append(connection)


func _advance_connection_feedback() -> void :
	for i in range(_connection_pending.size() - 1, -1, -1):
		var entry: Dictionary = _connection_pending[i]
		var leading: JuiceFruit = entry["leading"]
		var bottom: JuiceFruit = entry["bottom"]
		if not is_instance_valid(leading) or not is_instance_valid(bottom):
			_connection_pending.remove_at(i)
			continue
		var target: Array[JuiceFruit] = _fruit_nodes.get(int(entry["dst"]), [] as Array[JuiceFruit])
		if not target.has(leading) or not target.has(bottom)\
		or leading.col != int(entry["dst"]) or leading.idx != int(entry["index"])\
		or JuiceLevel.connection_type(leading.fruit_type) != int(entry["type"])\
		or JuiceLevel.connection_type(bottom.fruit_type) != int(entry["type"]) or bottom.col != leading.col\
		or bottom.idx + 1 != leading.idx or not leading.visible or not bottom.visible:
			_connection_pending.remove_at(i)
			continue

		var expected_gap: float = (_lay.fruit_y(leading.idx) - _lay.fruit_y(bottom.idx))\
		* _fruit_layer.global_scale.y
		var aligned: bool = absf(leading.global_position.x - bottom.global_position.x)\
		< leading.diameter() * 0.08 and absf(leading.global_position.y\
		- bottom.global_position.y - expected_gap) < leading.diameter() * 0.15
		if not aligned and _t - float(entry["started"]) < 0.5:
			continue
		_connection_pending.remove_at(i)
		if aligned:
			_play_connection_feedback(leading, bottom)
	for i in range(_connection_effects.size() - 1, -1, -1):
		if not is_instance_valid(_connection_effects[i]):
			_connection_effects.remove_at(i)


func _play_connection_feedback(leading: JuiceFruit, bottom: JuiceFruit) -> void :
	leading.play_connection_pop(CONNECTION_PULSE_SCALE, CONNECTION_PULSE_UP_DUR, CONNECTION_PULSE_DOWN_DUR)
	bottom.play_connection_pop(CONNECTION_PULSE_SCALE, CONNECTION_PULSE_UP_DUR, CONNECTION_PULSE_DOWN_DUR)
	var coin_debris: bool = _is_bonus_type(leading.fruit_type)
	var feather: Texture2D = feather_for_type(JuiceLevel.connection_type(leading.fruit_type))
	var tint: Color = Color.WHITE if coin_debris else color_for_type(JuiceLevel.connection_type(leading.fruit_type))
	var collection_texture: Texture2D = feather if feather != null else (null if coin_debris else collection_particle_texture(
		slot_for_type(JuiceLevel.connection_type(leading.fruit_type))))

	var clockwise_texture: Texture2D = collection_texture
	var counterclockwise_texture: Texture2D = collection_texture
	var clockwise_size_scale: float = 1.0
	var counterclockwise_size_scale: float = 1.0
	if is_rank_collectible_type(JuiceLevel.connection_type(leading.fruit_type)):
		clockwise_texture = effect_texture(&"rank_collectible_connection_01", collection_texture)
		counterclockwise_texture = effect_texture(&"rank_collectible_connection_02", collection_texture)

		var inherited_size_scale: float = _skin_resources.collection_particle_size_correction(collection_texture, true)\
		if _skin_resources != null and feather == null else 1.0
		if clockwise_texture != collection_texture:
			clockwise_size_scale = inherited_size_scale
		if counterclockwise_texture != collection_texture:
			counterclockwise_size_scale = inherited_size_scale
	var layer: Node2D = _resolve_fruit_layer()
	var leading_pos: Vector2 = layer.to_local(leading.global_position)
	var bottom_pos: Vector2 = layer.to_local(bottom.global_position)
	var radius: float = leading.diameter() * 0.5
	var top_y: float = minf(leading_pos.y, bottom_pos.y) - radius
	var bot_y: float = maxf(leading_pos.y, bottom_pos.y) + radius
	var x: float = (leading_pos.x + bottom_pos.x) * 0.5
	if not _level.is_sunlight_type(leading.fruit_type):
		var total: int = maxi(2, int(round((bot_y - top_y) / 10.0 * ROPE_PETAL_DENSITY_PER_10PX)))
		var half: int = total / 2
		var clockwise: GPUParticles2D = _fire_rope_petals(x, top_y, bot_y, half, 
			ROPE_PETAL_SPIN_MIN, ROPE_PETAL_SPIN_MAX, tint, coin_debris, clockwise_texture, true, clockwise_size_scale)
		var counterclockwise: GPUParticles2D = _fire_rope_petals(x, top_y, bot_y, total - half, 
			- ROPE_PETAL_SPIN_MAX, - ROPE_PETAL_SPIN_MIN, tint, coin_debris, counterclockwise_texture, true, counterclockwise_size_scale)
		for effect: GPUParticles2D in [clockwise, counterclockwise]:
			if effect != null:
				_connection_effects.append(effect)
	var full_length: float = maxf(1.0, _lay.rope_bottom - _lay.rope_visible_top)
	var stars: GPUParticles2D = _spawn_rope_stars(x, (bot_y - top_y) / full_length, 
		1.0, 0.0, Vector2(top_y, bot_y))
	if stars != null:
		_connection_effects.append(stars)


func _cancel_drag() -> void :
	if _drag.is_empty():
		return
	_stop_drag_match_highlight()
	_clear_drag_visual()
	_drag = {}
	_hover_col = -1
	_place_drop_hover()
	drag_ended.emit()
	queue_redraw()




func _clear_drag_visual() -> void :
	if _rule_col_marks:
		clear_col_marks()
	for f: JuiceFruit in (_drag.get("nodes", []) as Array):
		if is_instance_valid(f):
			f.z_index = RETURN_Z
			if not _return.has(f):
				_return.append(f)


func _set_drag_top_level(fruit: JuiceFruit, on: bool) -> void :
	if fruit.top_level == on:
		return
	var transform_before: Transform2D = fruit.global_transform
	fruit.top_level = on
	fruit.global_transform = transform_before



func _fruit_layer_pos(fruit: JuiceFruit) -> Vector2:
	if fruit.top_level:
		return _fruit_layer.get_global_transform().affine_inverse() * fruit.global_position
	return fruit.position


func _set_fruit_layer_pos(fruit: JuiceFruit, pos: Vector2) -> void :
	if fruit.top_level:
		fruit.global_position = _fruit_layer.get_global_transform() * pos
	else:
		fruit.position = pos






func try_move(src: int, j: int, dst: int) -> bool:
	if _over != "" and not can_play_after_dead():
		return false
	return _do_move(src, j, dst)


func _do_move(src: int, j: int, dst: int, player_drop: bool = false, same_color_connection: bool = false) -> bool:
	_move_feedback_info.clear()
	var dead_attempt: bool = can_play_after_dead()
	if _endless_session != null and _endless_move_guard.is_valid() and not bool(_endless_move_guard.call()):
		return false
	_empty_rope_feedback.clear()

	if not _complete_column_flight.is_empty():
		return false
	if _replenish_column_pending(src) or _replenish_column_pending(dst):
		return false
	var tracking_info: Dictionary = _tracking_move_info(_state, src, j, dst)

	var player_completed_column: bool = player_drop and _move_fills_column(src, j, dst)
	var empty_rope_operation_key: String = ""

	if player_drop and j == 0 and not R.is_root_swap(_state, src, j, dst)\
	and int(tracking_info["before_empty_rope_num"]) == 0\
	and _empty_rope_feedback_history_ready():
		empty_rope_operation_key = _empty_rope_feedback_operation_key(src, j, dst)
	var rec: Dictionary = _endless_session.apply_move(src, j, dst) if _endless_session != null\
	else R.apply_move(_state, _level, src, j, dst)
	if rec.is_empty():
		return false

	_challenge_suppressed_by_undo = false
	var head: int = int(rec.get("head", 0))
	if not tutorial_demo_only:
		var pitch: float = (500.0 + float(posmod(head, 8)) * 44.0) / 500.0
		if player_drop and same_color_connection and same_color_merge_sound_requested.has_connections():
			same_color_merge_sound_requested.emit(pitch)
		else:
			_play_skin_sound(&"juice_move", 1.0, pitch)


	_history.append({"rec": rec, "order": _order.duplicate()})
	if _endless_session != null and _history.size() > JuiceEndlessSettings.HISTORY_LIMIT:
		_history.pop_front()

	_clear_hint()
	_clear_run_highlight()
	if bool(rec.get("root_swapped", false)):
		_swap_nodes(src, dst)
	else:
		_move_nodes(src, j, dst, int(rec["k"]))
	_steps += 1
	var deposits: Array = rec["deposits"]
	if dead_attempt:
		_invalidate_death_attribution()
		if not deposits.is_empty():
			SortLogger.error("JuiceBoardView: 严格死局徒手移动产生真实收盆，CLOSED闭包失效 steps=%d state=%s"\
			%[_steps, R.state_key(_state)])
	if not deposits.is_empty():
		_enqueue_beats(deposits)
	var revealed: Array = rec.get("revealed", []) as Array
	_apply_reveals(revealed)
	_refresh_blenders()


	_play_lock_unlock_effects(rec.get("unlocked", []) as Array)
	_refresh_lock_overlays()
	tracking_info["is_link"] = 1
	tracking_info["is_finished_order"] = 0 if deposits.is_empty() else 1
	tracking_info["after_empty_rope_num"] = _tracking_empty_rope_count(_state)
	(_history.back() as Dictionary)["after_empty_rope_num"] = int(tracking_info["after_empty_rope_num"])
	tracking_info["after_possible_moves"] = R.useful_moves(_state).size()
	_move_attempt_count += 1
	_successful_link_count += 1
	_invalidate_safe_return()

	var moved_flowers_collected: bool = false
	for deposit: Dictionary in deposits:
		if int(deposit["col"]) == dst:
			moved_flowers_collected = true
			break

	if not empty_rope_operation_key.is_empty() and not moved_flowers_collected\
	and _empty_rope_feedback_white_pots_allowed()\
	and (_state["caps"] as Array[int])[src] > 0\
	and ((_state["cols"] as Array)[src] as Array).is_empty():
		var track: Rect2 = _lay.track_rect(int(_slot_of[src]), _col_cap(src))
		var center: Vector2 = Vector2(_col_x(src) + _content_dx, track.position.y + track.size.y * 0.7)
		_empty_rope_feedback = {"center": get_global_transform() * center, 
			"width": track.size.x * get_global_transform().x.length(), 
			"operation_key": empty_rope_operation_key, 
			"rope_geometry": _empty_rope_spiral_geometry.bind(src, int(_visual_token_by_col[src]))}
	move_attempted.emit(tracking_info)

	var completed_col: int = -1
	if player_completed_column and not moved_flowers_collected:
		completed_col = dst
	_move_feedback_info = {"player_drop": player_drop, "same_color_connection": same_color_connection, 
		"root_swapped": bool(rec.get("root_swapped", false)), "completed_col": completed_col, 
		"src": src, "j": j, "dst": dst}
	moved.emit(_steps)
	_move_feedback_info.clear()
	if _endless_session != null and not deposits.is_empty():
		endless_refill_requested.emit()
	_empty_rope_feedback.clear()
	if dead_attempt and _over == "dead" and _endless_session == null:

		_start_death_attribution(_pending_dead_reason)
		_start_safe_return_search()
	_check_over()
	_start_lucky_reveal_check(rec)
	queue_redraw()
	return true



func _move_fills_column(src: int, j: int, dst: int) -> bool:
	if not bool(_state.get("allow_root_swapping", false)) or R.is_root_swap(_state, src, j, dst):
		return false
	var k: int = R.move_info(_state, src, j, dst)
	if k <= 0:
		return false
	var cols: Array = _state["cols"]
	var caps: Array[int] = _state["caps"]
	var source: Array[int] = cols[src]
	var target: Array[int] = cols[dst]
	if target.size() + k != caps[dst]:
		return false

	if j == 0 and source.size() == caps[src] and target.is_empty():
		var flower_type: int = source[0]
		if flower_type >= 0 and not JuiceLevel.is_hidden(flower_type) and not JuiceLevel.is_frozen(flower_type):
			var already_complete: bool = true
			for flower: int in source:
				if flower != flower_type:
					already_complete = false
					break
			if already_complete:
				return false
	return true






func _tracking_move_info(st: Dictionary, src: int, j: int, dst: int) -> Dictionary:
	var cols: Array = st["cols"]
	var lifted: Array[int] = cols[src]
	var target: Array[int] = cols[dst]
	var lifted_types: Dictionary = {}
	var target_types: Dictionary = {}
	var question_count: int = 0
	for i in range(j, lifted.size()):
		var fruit_type: int = lifted[i]
		lifted_types[JuiceLevel.true_type(fruit_type)] = true
		if JuiceLevel.is_hidden(fruit_type):
			question_count += 1
	for fruit_type: int in target:
		target_types[JuiceLevel.true_type(fruit_type)] = true
	return {
		"finished_orders_num": int(st["done"]), 
		"left_orders_num": -1 if _endless_session != null else _level.groups_total - int(st["done"]), 
		"before_empty_rope_num": _tracking_empty_rope_count(st), 
		"before_total_rope_num": _tracking_total_rope_count(st), 
		"before_possible_moves": R.useful_moves(st).size(), 
		"move_tiles_info": {
			"tile_type_num": lifted_types.size(), "tile_total_num": lifted.size() - j, 
			"question_tile_num": question_count, "before_coordinate": [int(_slot_of[src]) + 1, j + 1], 
		}, 
		"target_tiles_info": {
			"tile_type_num": target_types.size(), "tile_total_num": target.size(), 
			"after_coordinate": [int(_slot_of[dst]) + 1, 
				1 if R.is_root_swap(st, src, j, dst) else target.size() + 1], 
		}, 
	}


func _tracking_empty_rope_count(st: Dictionary) -> int:
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var count: int = 0
	for i in cols.size():
		if caps[i] > 0 and (cols[i] as Array).is_empty():
			count += 1
	return count



func _empty_rope_feedback_history_ready() -> bool:
	if _history.size() < EMPTY_ROPE_FEEDBACK_HISTORY_STEPS:
		return false
	for i in range(_history.size() - EMPTY_ROPE_FEEDBACK_HISTORY_STEPS, _history.size()):
		if int((_history[i] as Dictionary).get("after_empty_rope_num", -1)) != 0:
			return false
	return true



func _empty_rope_feedback_white_pots_allowed() -> bool:
	var count: int = 0
	var caps: Array[int] = _state["caps"]
	for ci in caps.size():
		if caps[ci] > 0 and R.is_park(_state, ci):
			count += 1
			if count >= 2:
				return false
	return true



func _empty_rope_feedback_operation_key(src: int, j: int, dst: int) -> String:
	var st: Dictionary = _state.duplicate()
	var cols: Array = []
	for col: Array[int] in _state["cols"]:
		var types: Array[int] = []
		for fruit_type: int in col:
			types.append(JuiceLevel.true_type(fruit_type))
		cols.append(types)
	st["cols"] = cols
	return ("%s>%d/%d/%d" % [R.state_key(st), src, j, dst]).sha256_text()



func take_empty_rope_feedback() -> Dictionary:
	var info: Dictionary = _empty_rope_feedback
	_empty_rope_feedback = {}
	return info



func _empty_rope_spiral_geometry(ci: int, token: int) -> Dictionary:
	if int(_visual_token_by_col.get(ci, -1)) != token:
		return {}
	var row_y: float = roundf(_row_y(ci))
	var top_y: float = _lay.rope_visible_top
	var bottom_y: float = _col_rope_bottom(ci)
	var x: float = _col_x(ci) + _content_dx
	var top: Vector2 = Vector2(x + _rope_base_dx(top_y, ci), top_y + row_y)
	var bottom: Vector2 = Vector2(x + _rope_base_dx(bottom_y, ci), bottom_y + row_y)
	var transform: Transform2D = get_global_transform()
	return {"top": transform * top, "bottom": transform * bottom, 
		"width": _lay.track_rect(int(_slot_of[ci]), _col_cap(ci)).size.x * transform.x.length()}




func _tracking_total_rope_count(st: Dictionary) -> int:
	var caps: Array[int] = st["caps"]
	var count: int = 0
	for cap: int in caps:
		if cap > 0:
			count += 1
	return count


func _move_nodes(src: int, j: int, dst: int, k: int) -> void :
	var s: Array[JuiceFruit] = _fruit_nodes.get(src, [] as Array[JuiceFruit])
	var d: Array[JuiceFruit] = _fruit_nodes.get(dst, [] as Array[JuiceFruit])
	for _i in k:
		if j >= s.size():
			break
		var f: JuiceFruit = s.pop_at(j)
		f.col = dst
		d.append(f)
	_fruit_nodes[src] = s
	_fruit_nodes[dst] = d
	_reindex(src)
	_reindex(dst)



func _swap_nodes(src: int, dst: int) -> void :
	var s: Array[JuiceFruit] = _fruit_nodes.get(src, [] as Array[JuiceFruit])
	var d: Array[JuiceFruit] = _fruit_nodes.get(dst, [] as Array[JuiceFruit])
	_fruit_nodes[src] = d
	_fruit_nodes[dst] = s
	for ci: int in [src, dst]:
		for fruit: JuiceFruit in _fruit_nodes[ci]:
			if not is_instance_valid(fruit):
				continue
			fruit.col = ci
			fruit.stop_breathing_group_highlight(true)
			_set_drag_top_level(fruit, true)
			fruit.z_index = RETURN_Z
			if not _return.has(fruit):
				_return.append(fruit)
		_reindex(ci)


func _reindex(ci: int) -> void :
	var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
	for i in list.size():
		if is_instance_valid(list[i]):
			list[i].idx = i


func _apply_reveals(revealed: Array) -> void :
	for entry: Dictionary in _resolve_reveals(revealed):
		_reveal_fruit(entry["node"] as JuiceFruit, int(entry["type"]))




func _resolve_reveals(revealed: Array) -> Array:
	var resolved: Array = []
	for entry: Dictionary in revealed:
		var ci: int = int(entry.get("col", -1))
		var idx: int = int(entry.get("index", -1))
		var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
		if idx < 0 or idx >= list.size() or not is_instance_valid(list[idx]):
			continue
		resolved.append({"node": list[idx], "type": int(entry.get("type", -1))})
	return resolved



func _apply_node_reveals(resolved: Array) -> void :
	for entry: Dictionary in resolved:
		var node: Variant = entry.get("node")
		if is_instance_valid(node):
			_reveal_fruit(node as JuiceFruit, int(entry.get("type", -1)))



func _reveal_fruit(fruit: JuiceFruit, type_id: int) -> void :
	if is_rank_collectible_type(type_id):
		return

	var coin_reveal: bool = _is_bonus_type(type_id) and bonus_coin_texture != null
	var color: Color = MYSTERY_GLOW_YELLOW_REF if coin_reveal else color_for_type(type_id)
	var sun_reveal: bool = _level.is_sunlight_type(type_id)
	fruit.reveal(_texture_for_fruit(type_id), type_id, color, sun_reveal)


	fruit.flower_shown.connect(_on_mystery_flower_shown.bind(fruit), CONNECT_ONE_SHOT)

	if sun_reveal:
		return


	var petal_tw: Tween = create_tween()
	var particle: Texture2D = null if coin_reveal else mystery_particle_texture(slot_for_type(type_id))
	var generation: int = _mystery_reveal_generation
	var reveal_position: Vector2 = fruit.global_position
	petal_tw.tween_callback( func() -> void :
		if generation != _mystery_reveal_generation or not is_inside_tree():
			return
		_spawn_mystery_reveal_petals(reveal_position, color, coin_reveal, particle)
	).set_delay(MYSTERY_PETAL_DELAY)

	_spawn_mystery_reveal_glow(fruit.global_position, color)

	_spawn_mystery_reveal_star(fruit.global_position, color)




func _on_mystery_flower_shown(fruit: JuiceFruit) -> void :
	if not is_instance_valid(fruit):
		return
	fruit.set_sunlight(_level.is_sunlight_type(fruit.fruit_type))
	if _level.is_sunlight_type(fruit.fruit_type):
		return
	fruit.play_reveal_pop(MYSTERY_POP_SCALE_PEAK, MYSTERY_POP_SCALE_DIP, 
		MYSTERY_POP_UP_DUR, MYSTERY_POP_DIP_DUR, MYSTERY_POP_SETTLE_DUR)











func show_hint(r: Dictionary) -> bool:
	if r.is_empty() or _over != "" or is_busy() or not _drag.is_empty():
		return false
	var mv: Dictionary = r.get("move", {})
	if mv.is_empty():
		return false
	if move_info(_state_ref(), int(mv["src"]), int(mv["j"]), int(mv["dst"])) <= 0:
		return false
	_clear_hint()
	_hint = {"src": int(mv["src"]), "j": int(mv["j"]), "dst": int(mv["dst"])}
	if not _show_hint_visuals():
		_clear_hint()
		return false
	return true


func has_active_hint() -> bool:
	return not _hint.is_empty()







func add_rope() -> bool:
	if _endless_session != null and _endless_move_guard.is_valid() and not bool(_endless_move_guard.call()):
		return false
	if _level == null or _state.is_empty() or is_busy() or _over != "" or has_rope():
		return false
	_clear_hint()
	_clear_run_highlight()
	var from: Dictionary = {}
	for c in _order:
		from[c] = _planned_col_x(c)
	var ci: int = R.add_rope(_state, _level.capacity)
	if ci < 0:
		return false
	if bool(_state.get("allow_root_swapping", false)):
		_invalidate_root_closed_check()
	_invalidate_death_attribution()
	_order.append(ci)
	for raw_entry: Variant in _history:
		var entry: Dictionary = raw_entry as Dictionary
		var rec: Dictionary = entry.get("rec", {}) as Dictionary
		for snapshot_key: String in ["snap", "auto_unlock_before"]:
			var snap: Dictionary = rec.get(snapshot_key, {}) as Dictionary
			if not snap.is_empty() and R.add_rope(snap, _level.capacity) != ci:
				push_error("JuiceBoardView: 撤销快照补额外绳失败")
				_history.clear()
				break
		if _history.is_empty():
			break
		var endless_before: Dictionary = rec.get("endless_before", {}) as Dictionary
		if not endless_before.is_empty() and R.add_rope(endless_before["state"], _level.capacity) != ci:
			SortLogger.error("JuiceBoardView: 无尽撤销快照补额外绳失败")
			_history.clear()
			break
		var saved_order: Array[int] = entry.get("order", [] as Array[int]) as Array[int]
		saved_order.append(ci)
	_reindex_slots()
	_solve_layout()

	for list: Array[JuiceFruit] in _fruit_nodes.values():
		for fruit: JuiceFruit in list:
			if is_instance_valid(fruit):
				fruit.set_diameter(_lay.fruit_d)
	var offscreen_x: float = size.x + _lay.col_w * 1.2
	var start_x: float = offscreen_x
	_new_visual_token(ci, start_x)

	_fruit_nodes[ci] = [] as Array[JuiceFruit]
	for c in _blender_nodes:
		var blender: JuiceBlender = _blender_nodes[c]
		if is_instance_valid(blender):
			blender.place(_lay.blender_rect(int(_slot_of[c])), _skin, 
				_empty_pot_bottom_y(blender._target_texture, int(_slot_of[c])), _empty_pot_max_ratio())
			blender.position.x = float(from[c])
	var new_blender: JuiceBlender = _make_blender(ci)
	from[ci] = start_x
	if new_blender != null:
		new_blender.position.x = start_x
	_enqueue_shift(from, offscreen_x, _t)
	_check_over()
	return true











func revive_with_rope() -> bool:
	if _endless_session != null:
		return false
	if _level == null or _state.is_empty() or is_busy() or has_rope():
		return false
	var was_over: String = _over
	_over = ""
	if not add_rope():
		_over = was_over
		return false
	return true


func has_rope() -> bool:
	return bool(_state.get("extra_rope_used", false)) if not _state.is_empty() else false


func _state_ref() -> Dictionary:
	return _state


func move_info(st: Dictionary, src: int, j: int, dst: int) -> int:
	return R.move_info(st, src, j, dst)







func set_col_marks(guide: int, src: int, errors: Array, extra_guides: Array[int] = []) -> void :
	_restore_tutorial_column_opacity()
	var guides: Array[int] = [guide]
	for ci: int in extra_guides:
		if ci != src and not guides.has(ci):
			guides.append(ci)
	_col_mark_spec = {"guides": guides, "src": src, "errors": errors.duplicate()}
	_apply_tutorial_column_opacity()
	_rebuild_col_marks()




func _set_rule_col_marks(src: int, j: int) -> void :
	_restore_tutorial_column_opacity()
	var guides: Array[int] = []
	for ci: int in _order:
		if ci == src:
			continue
		if R.move_info(_state, src, j, ci) > 0 and not R.is_root_swap(_state, src, j, ci):
			guides.append(ci)
	_rule_col_marks = true
	_col_mark_spec = {"guides": guides, "src": src, "errors": []}
	_rebuild_col_marks()


func clear_col_marks() -> void :
	_restore_tutorial_column_opacity()
	_rule_col_marks = false
	_col_mark_spec = {}
	_recycle_col_marks()


func _apply_tutorial_column_opacity() -> void :
	if not _four_goal_tutorial_visuals:
		return
	for raw: Variant in (_col_mark_spec.get("errors", []) as Array):
		var ci: int = int(raw)
		_dim_tutorial_column_item(_blender_nodes.get(ci))
		for flower: Variant in (_fruit_nodes.get(ci, []) as Array):
			_dim_tutorial_column_item(flower)
	queue_redraw()



func _dim_tutorial_column_item(item: Variant) -> void :
	if not is_instance_valid(item) or not item is CanvasItem or _tutorial_dimmed_items.has(item):
		return
	var original: Color = item.modulate
	_tutorial_dimmed_items[item] = original
	item.modulate = Color(original.r, original.g, original.b, original.a * TUTORIAL_MUTED_COLUMN_ALPHA)


func _restore_tutorial_column_opacity() -> void :
	for item: Variant in _tutorial_dimmed_items:
		if is_instance_valid(item):
			item.modulate = _tutorial_dimmed_items[item]
	_tutorial_dimmed_items.clear()
	queue_redraw()


func _recycle_col_marks() -> void :
	for m: JuiceColMark in _col_mark_live:
		if is_instance_valid(m):
			m.visible = false
			_col_mark_pool.append(m)
	_col_mark_live.clear()


func _rebuild_col_marks() -> void :
	_recycle_col_marks()
	if _col_mark_spec.is_empty() or _col_marks_layer == null:
		return
	for raw: Variant in (_col_mark_spec.get("guides", []) as Array):
		_place_col_mark(int(raw), JuiceColMark.Kind.OK)
	for raw: Variant in (_col_mark_spec.get("errors", []) as Array):
		_place_col_mark(int(raw), JuiceColMark.Kind.BAD)
	_refresh_col_mark_selection()



func _refresh_col_mark_selection() -> void :
	var selected_col: int = _hover_col if _has_col_mark_guide() and not _drag.is_empty() else -1
	for mark: JuiceColMark in _col_mark_live:
		mark.set_selected(int(mark.get_meta(&"col")) == selected_col)


func _place_col_mark(col: int, kind: JuiceColMark.Kind) -> void :
	if col < 0 or not _slot_of.has(col):
		return
	var m: JuiceColMark = _col_mark_pool.pop_back() if not _col_mark_pool.is_empty() else null
	if m == null:
		m = COL_MARK_SCENE.instantiate() as JuiceColMark
		_col_marks_layer.add_child(m)
	var r: Rect2 = _col_capsule_rect(col)
	m.position = r.position
	m.size = r.size
	m.set_meta(&"col", col)

	m.glow_blue = _drop_hover_glow.texture
	m.set_kind(JuiceColMark.Kind.MUTED if kind == JuiceColMark.Kind.BAD and not _rule_col_marks and _four_goal_tutorial_visuals else kind)
	m.modulate = Color.WHITE
	m.visible = true
	_col_mark_live.append(m)



func _refresh_col_mark_positions() -> void :
	for mark: JuiceColMark in _col_mark_live:
		var col: int = int(mark.get_meta(&"col"))
		if not _slot_of.has(col):
			mark.visible = false
			continue
		var r: Rect2 = _col_capsule_rect(col)
		mark.position = r.position
		mark.size = r.size
		mark.visible = true






func set_run_demo_pos(col: int, j: int, head_global: Vector2) -> void :
	_set_run_demo_local(col, j, get_global_transform().affine_inverse() * head_global)



func set_run_demo_source_visible(show_source: bool) -> void :
	if _run_demo.is_empty():
		return
	var flowers: Array = _fruit_nodes.get(int(_run_demo["col"]), [])
	for index: int in range(int(_run_demo["j"]), flowers.size()):
		if is_instance_valid(flowers[index]):
			(flowers[index] as JuiceFruit).visible = show_source



func commit_run_demo_move(dst: int) -> bool:
	if _run_demo.is_empty():
		return false
	var src: int = int(_run_demo["col"])
	var j: int = int(_run_demo["j"])
	if R.move_info(_state, src, j, dst) <= 0:
		set_run_demo_source_visible(true)
		clear_run_demo_pos()
		return false
	var flowers: Array = _fruit_nodes.get(src, [])
	for index: int in _demo_nodes.size():
		var flower: JuiceFruit = flowers[j + index] as JuiceFruit
		flower.global_position = _demo_nodes[index].global_position
		flower.visible = true
	clear_run_demo_pos()
	return try_move(src, j, dst)





func _set_run_demo_local(col: int, j: int, head: Vector2) -> void :
	if _run_demo.is_empty() or int(_run_demo["col"]) != col or int(_run_demo["j"]) != j\
	or _demo_nodes.is_empty():
		_spawn_demo_fruits(col, j)
	_run_demo = {"col": col, "j": j, "head": head}
	_place_demo_fruits()


func clear_run_demo_pos() -> void :
	if _run_demo.is_empty() and _demo_nodes.is_empty():
		return
	_run_demo = {}
	_clear_demo_fruits()











func _spawn_demo_fruits(col: int, j: int) -> void :
	_clear_demo_fruits()
	if _demo_pool == null or _fx_layer == null or _level == null:
		return
	var cols: Array = _state.get("cols", [])
	if col < 0 or col >= cols.size() or j < 0:
		return
	var types: Array[int] = cols[col]
	var tutorial_demo: bool = not _run_hl.is_empty()\
	and int(_run_hl["col"]) == col and int(_run_hl["j"]) == j
	for i in range(j, types.size()):
		var f: JuiceFruit = _demo_pool.acquire(_fx_layer) as JuiceFruit
		if f == null:
			continue
		var type_id: int = types[i]
		var hidden: bool = JuiceLevel.is_hidden(type_id)
		var frozen: bool = JuiceLevel.is_frozen(type_id)
		f.setup(null if hidden else _texture_for_fruit(type_id), type_id, _lay.fruit_d, 
			bonus_coin_texture.get_size() if _is_bonus_type(type_id) else _skin.fruit_tex_size, hidden, frozen, element_visual(type_id), mystery_visual(), effect_texture(&"landing_star", null))
		f.set_sunlight(_level.is_sunlight_type(type_id) and not JuiceLevel.is_hidden(type_id))

		var tutorial_color: Color = color_for_type(JuiceLevel.true_type(type_id)) if _four_goal_tutorial_visuals else Color(1.0, 0.78, 0.05, 0.9)
		f.set_hint_highlight( not tutorial_demo or i == j, tutorial_demo and i == j, tutorial_color)
		_demo_nodes.append(f)




func _place_demo_fruits() -> void :
	if _demo_nodes.is_empty() or _run_demo.is_empty():
		return
	var head: Vector2 = _run_demo["head"]
	var first_index: int = int(_run_demo["j"])
	var col: int = int(_run_demo["col"])
	var tutorial_demo: bool = _four_goal_tutorial_visuals and not _run_hl.is_empty()\
	and int(_run_hl["col"]) == col and int(_run_hl["j"]) == first_index
	var sources: Array = _fruit_nodes.get(col, [])
	var fx_inverse: Transform2D = _fx_layer.get_global_transform().affine_inverse()
	var travel: Vector2 = fx_inverse.basis_xform(
		get_global_transform() * head - fruit_global_pos(col, first_index))
	for i in _demo_nodes.size():
		var f: JuiceFruit = _demo_nodes[i]
		if not is_instance_valid(f):
			continue

		if not is_equal_approx(f.diameter(), _lay.fruit_d):
			f.set_diameter(_lay.fruit_d)


		if tutorial_demo and first_index + i < sources.size()\
		and is_instance_valid(sources[first_index + i]):
			var source: JuiceFruit = sources[first_index + i] as JuiceFruit
			var pose: Transform2D = fx_inverse * source.global_transform
			pose.origin += travel
			f.transform = pose
			continue
		f.position = head + Vector2(0.0, _lay.fruit_y(first_index + i) - _lay.fruit_y(first_index))
	if _four_goal_tutorial_visuals:
		_sync_demo_rope()



func _sync_demo_rope() -> void :
	var texture: Texture2D = _rope_mid_tex(-1)
	var pieces: Array[Dictionary] = []
	if texture != null and _demo_nodes.size() >= 2 and _fx_layer != null:
		if not is_instance_valid(_demo_rope_root):
			_demo_rope_root = Node2D.new()
			_demo_rope_root.name = "DemoRope"
			_fx_layer.add_child(_demo_rope_root)
			_fx_layer.move_child(_demo_rope_root, 0)
		var inverse: Transform2D = _demo_rope_root.get_global_transform().affine_inverse()
		var tex_w: float = float(texture.get_width())
		var raw_w: float = maxf(4.0, _lay.rope_scale_d * _skin.rope_tex_w_ratio)
		var step: float = maxf(roundf(ROPE_MID_BODY_ROWS * raw_w / tex_w), 1.0)
		var k: float = step / ROPE_MID_BODY_ROWS
		var box_w: float = tex_w * k
		for index: int in range(_demo_nodes.size() - 1):
			var a: Vector2 = inverse * _demo_nodes[index].global_position
			var b: Vector2 = inverse * _demo_nodes[index + 1].global_position
			var y0: float = roundf(a.y)
			var span: float = roundf(b.y) - y0
			if span <= 0.5:
				continue
			var slope: float = (b.x - a.x) / (b.y - a.y)
			var shear: = Transform2D(Vector2.RIGHT, Vector2(slope, 1.0), Vector2( - slope * y0, 0.0))
			var left: float = a.x - box_w * 0.5
			pieces.append({"rect": Rect2(left, y0, box_w, span + ROPE_BOT_SHADOW_ROWS * k), 
				"region": Rect2(0, ROPE_MID_SHADOW_ROW, tex_w, 1), "shear": shear})
			var full: int = int(floor(span / step))
			for tile: int in full:
				pieces.append({"rect": Rect2(left, y0 + tile * step, ROPE_MID_BODY_COLS * k, step), 
					"region": Rect2(0, 0, ROPE_MID_BODY_COLS, ROPE_MID_BODY_ROWS), "shear": shear})
			var rest: float = span - full * step
			if rest > 0.5:
				pieces.append({"rect": Rect2(left, y0 + full * step, ROPE_MID_BODY_COLS * k, rest), 
					"region": Rect2(0, 0, ROPE_MID_BODY_COLS, rest / k), "shear": shear})
	while _demo_rope_nodes.size() < pieces.size():
		var sprite: = Sprite2D.new()
		sprite.visible = false
		sprite.centered = false
		sprite.region_enabled = true
		_demo_rope_root.add_child(sprite)
		_demo_rope_nodes.append(sprite)
	for index: int in _demo_rope_nodes.size():
		var sprite: Sprite2D = _demo_rope_nodes[index]
		if index >= pieces.size():
			sprite.hide()
			sprite.texture = null
			sprite.material = null
			continue
		var piece: Dictionary = pieces[index]
		var rect: Rect2 = piece.rect
		var region: Rect2 = piece.region
		sprite.texture = texture
		sprite.region_rect = region
		sprite.transform = (piece.shear as Transform2D) * Transform2D(
			Vector2(rect.size.x / region.size.x, 0), Vector2(0, rect.size.y / region.size.y), rect.position)
		sprite.material = material
		sprite.show()


func _clear_demo_fruits() -> void :
	for sprite: Sprite2D in _demo_rope_nodes:
		sprite.hide()
		sprite.texture = null
		sprite.material = null
	if _demo_nodes.is_empty():
		return
	for f: JuiceFruit in _demo_nodes:
		if is_instance_valid(f) and _demo_pool != null:
			_demo_pool.release(f)
	_demo_nodes.clear()




func set_move_gate(gate: Callable = Callable()) -> void :
	_move_gate = gate



func has_move_gate(gate: Callable = Callable()) -> bool:
	return _move_gate.is_valid() and (gate.is_null() or _move_gate == gate)




func set_grab_gate(gate: Callable = Callable()) -> void :
	_grab_gate = gate


func has_grab_gate(gate: Callable = Callable()) -> bool:
	return _grab_gate.is_valid() and (gate.is_null() or _grab_gate == gate)



func clear_owned_input_gates(move_gate: Callable, grab_gate: Callable) -> void :
	if move_gate.is_valid() and has_move_gate(move_gate):
		set_move_gate()
	if grab_gate.is_valid() and has_grab_gate(grab_gate):
		set_grab_gate()




func set_four_goal_tutorial_visuals(enabled: bool) -> void :
	_restore_tutorial_column_opacity()
	_clear_run_highlight()
	_clear_demo_fruits()
	_four_goal_tutorial_visuals = enabled
	clear_col_marks()


func set_run_highlight(col: int, j: int, on: bool) -> void :
	if not on:
		_clear_run_highlight()
		return
	if not _run_hl.is_empty() and (int(_run_hl["col"]) != col or int(_run_hl["j"]) != j):
		_clear_run_highlight()
	_run_hl = {"col": col, "j": j}
	_apply_run_highlight()


func _clear_run_highlight() -> void :
	_clear_tutorial_target_highlight()
	if _run_hl.is_empty():
		return
	_set_tutorial_grab_highlight(int(_run_hl["col"]), int(_run_hl["j"]), false)
	_run_hl = {}


func _apply_run_highlight() -> void :
	_apply_tutorial_target_highlight()
	if _run_hl.is_empty():
		return
	if not _set_tutorial_grab_highlight(int(_run_hl["col"]), int(_run_hl["j"]), true):

		_clear_run_highlight()
		return


func _set_tutorial_grab_highlight(col: int, j: int, on: bool) -> bool:
	var list: Array = _fruit_nodes.get(col, [])
	if j < 0 or j >= list.size() or not is_instance_valid(list[j]):
		return false
	var fruit: JuiceFruit = list[j] as JuiceFruit
	var tutorial_color: Color = color_for_type(JuiceLevel.true_type(fruit.fruit_type)) if _four_goal_tutorial_visuals else Color(1.0, 0.78, 0.05, 0.9)
	fruit.set_hint_highlight(on, on, tutorial_color)
	return true



func set_tutorial_target_highlight(col: int, enabled: bool) -> void :
	_clear_tutorial_target_highlight()
	if not enabled:
		return
	var list: Array = _fruit_nodes.get(col, [])
	if list.is_empty():
		return
	_tutorial_target_hl = {"col": col, "j": list.size() - 1}
	_apply_tutorial_target_highlight()


func _clear_tutorial_target_highlight() -> void :
	if _tutorial_target_hl.is_empty():
		return
	_set_tutorial_grab_highlight(int(_tutorial_target_hl.col), int(_tutorial_target_hl.j), false)
	_tutorial_target_hl = {}


func _apply_tutorial_target_highlight() -> void :
	if _tutorial_target_hl.is_empty():
		return
	if not _set_tutorial_grab_highlight(int(_tutorial_target_hl.col), int(_tutorial_target_hl.j), true):
		_tutorial_target_hl = {}



func set_tutorial_pot_highlight(col: int, enabled: bool) -> void :
	_clear_tutorial_pot_highlight()
	if not enabled:
		return
	var blender: Variant = _blender_nodes.get(col)
	if blender == null or not is_instance_valid(blender):
		return
	_tutorial_pot_hl_col = col
	_apply_tutorial_pot_highlight()


func _clear_tutorial_pot_highlight() -> void :
	if _tutorial_pot_hl_col < 0:
		return
	var old: Variant = _blender_nodes.get(_tutorial_pot_hl_col)
	if old != null and is_instance_valid(old):
		(old as JuiceBlender).set_hint_highlight(false)
	_tutorial_pot_hl_col = -1


func _apply_tutorial_pot_highlight() -> void :
	if _tutorial_pot_hl_col < 0:
		return
	var blender: Variant = _blender_nodes.get(_tutorial_pot_hl_col)
	if blender != null and is_instance_valid(blender):
		(blender as JuiceBlender).set_hint_highlight(true)



func _each_run_fruit(col: int, j: int, on: bool) -> bool:
	var list: Array = _fruit_nodes.get(col, [])
	if j < 0 or j >= list.size():
		return false
	for i in range(j, list.size()):
		var f: Variant = list[i]
		if f == null or not is_instance_valid(f):
			continue
		(f as JuiceFruit).set_hint_highlight(on)
	return true












func fruit_global_pos(col: int, idx: int) -> Vector2:
	return get_global_transform() * _home_pos(col, idx)




func tutorial_focus_visuals(src: int, j: int, dst: int, focus_source: bool = false) -> Dictionary:
	var slot: int = int(_slot_of.get(dst, -1))
	var blender: Variant = _blender_nodes.get(dst)
	if slot < 0 or not is_instance_valid(blender) or not blender.visible:
		return {}
	var pot: Sprite2D = blender.get_node("Body") as Sprite2D
	if pot.texture == null:
		return {}
	var sources: Array[Dictionary] = []
	var list: Array = _fruit_nodes.get(src, [])
	for index: int in range(list.size() - 1, j - 1, -1):
		if index < 0 or not is_instance_valid(list[index]):
			continue
		var fruit: JuiceFruit = list[index] as JuiceFruit
		var body: Sprite2D = fruit.get_node("Body") as Sprite2D
		if fruit.visible and body.visible and body.texture != null:
			sources.append(_tutorial_sprite_visual(body))
	var demos: Array[Dictionary] = []
	if int(_run_demo.get("col", -1)) == src and int(_run_demo.get("j", -1)) == j:
		for index: int in range(_demo_nodes.size() - 1, -1, -1):
			var fruit: JuiceFruit = _demo_nodes[index]
			if not is_instance_valid(fruit) or not fruit.visible:
				continue
			var body: Sprite2D = fruit.get_node("Body") as Sprite2D
			if body.visible and body.texture != null:
				demos.append(_tutorial_sprite_visual(body))
	var demo_ropes: Array[Dictionary] = []
	if not demos.is_empty():
		for sprite: Sprite2D in _demo_rope_nodes:
			if sprite.visible and sprite.texture != null:
				demo_ropes.append(_tutorial_sprite_visual(sprite))
	var source_capsule: Rect2 = get_global_transform() * _col_capsule_rect(src) if focus_source else Rect2()
	return {"pot": _tutorial_sprite_visual(pot), 
		"capsule_rect": get_global_transform() * _col_capsule_rect(dst), 
		"source_capsule_rect": source_capsule, 
		"sources": sources, "demos": demos, "demo_ropes": demo_ropes, 
		"drag_ropes": _tutorial_drag_rope_visuals()}




func _tutorial_drag_rope_visuals() -> Array[Dictionary]:
	var visuals: Array[Dictionary] = []
	var nodes: Array = _drag.get("nodes", [])
	var texture: Texture2D = _rope_mid_tex(-1)
	if nodes.size() < 2 or texture == null:
		return visuals
	var board_transform: Transform2D = get_global_transform()
	var inverse: Transform2D = board_transform.affine_inverse()
	var tex_w: float = float(texture.get_width())
	var raw_w: float = maxf(4.0, _lay.rope_scale_d * _skin.rope_tex_w_ratio)
	var step: float = maxf(roundf(ROPE_MID_BODY_ROWS * raw_w / tex_w), 1.0)
	var k: float = step / ROPE_MID_BODY_ROWS
	var box_w: float = tex_w * k
	for index: int in range(nodes.size() - 1):
		if not is_instance_valid(nodes[index]) or not is_instance_valid(nodes[index + 1]):
			continue
		var a: Vector2 = inverse * (nodes[index] as JuiceFruit).global_position
		var b: Vector2 = inverse * (nodes[index + 1] as JuiceFruit).global_position
		var y0: float = roundf(a.y)
		var span: float = roundf(b.y) - y0
		if span <= 0.5:
			continue
		var slope: float = (b.x - a.x) / (b.y - a.y)
		var shear: = Transform2D(Vector2.RIGHT, Vector2(slope, 1.0), Vector2( - slope * y0, 0.0))
		var left: float = a.x - box_w * 0.5
		var pieces: Array[Dictionary] = [{"rect": Rect2(left, y0, box_w, span + ROPE_BOT_SHADOW_ROWS * k), 
			"region": Rect2(0, ROPE_MID_SHADOW_ROW, tex_w, 1)}]
		var full: int = int(floor(span / step))
		for tile: int in full:
			pieces.append({"rect": Rect2(left, y0 + tile * step, ROPE_MID_BODY_COLS * k, step), 
				"region": Rect2(0, 0, ROPE_MID_BODY_COLS, ROPE_MID_BODY_ROWS)})
		var rest: float = span - full * step
		if rest > 0.5:
			pieces.append({"rect": Rect2(left, y0 + full * step, ROPE_MID_BODY_COLS * k, rest), 
				"region": Rect2(0, 0, ROPE_MID_BODY_COLS, rest / k)})
		for piece: Dictionary in pieces:
			var rect: Rect2 = piece.rect
			var region: Rect2 = piece.region
			visuals.append({"texture": texture, "transform": board_transform * shear * Transform2D(
				Vector2(rect.size.x / region.size.x, 0), Vector2(0, rect.size.y / region.size.y), rect.position), 
				"material": material, "modulate": Color.WHITE, "centered": false, "offset": Vector2.ZERO, 
				"region_enabled": true, "region_rect": region, "hframes": 1, "vframes": 1, "frame": 0, 
				"flip_h": false, "flip_v": false})
	return visuals


func _tutorial_sprite_visual(sprite: Sprite2D) -> Dictionary:
	var tint: Color = sprite.self_modulate
	var ancestor: CanvasItem = sprite
	while ancestor != null:
		tint *= ancestor.modulate
		ancestor = ancestor.get_parent() as CanvasItem
	return {"texture": sprite.texture, "transform": sprite.get_global_transform(), 
		"rect": sprite.get_rect(), "material": sprite.material, "modulate": tint, 
		"centered": sprite.centered, "offset": sprite.offset, 
		"region_enabled": sprite.region_enabled, "region_rect": sprite.region_rect, 
		"hframes": sprite.hframes, "vframes": sprite.vframes, "frame": sprite.frame, 
		"flip_h": sprite.flip_h, "flip_v": sprite.flip_v}



func drop_global_pos(col: int) -> Vector2:
	var cols: Array = _state.get("cols", [])
	var n: int = (cols[col] as Array).size() if col >= 0 and col < cols.size() else 0
	return get_global_transform() * _home_pos(col, n)



func pot_top_global_y() -> float:
	return (get_global_transform() * Vector2(0.0, _lay.blender_top)).y




func rope_bottom_global_y() -> float:
	return (get_global_transform() * Vector2(0.0, _lay.rope_bottom + _lay.row_pitch)).y




func track_bottom_global_y() -> float:
	return (get_global_transform() * Vector2(0.0, _lay.track_bottom() + _lay.row_pitch)).y













func locked_column_global_rect(ci: int) -> Rect2:
	var slot: int = int(_slot_of.get(ci, -1))
	if slot < 0 or _state.is_empty():
		return Rect2()
	var s: float = _lay.fruit_d / JuiceLockOverlay.DESIGN_FRUIT_D
	var r: Rect2 = _lock_column_rect(slot)
	if s <= 0.0 or r.size.y <= 0.0:
		return Rect2()
	var w: float = JuiceLockOverlay.FRAME_W * s
	var local: = Rect2(_col_x(ci) - w * 0.5, r.position.y, w, r.size.y)
	return get_global_transform() * local



func pot_progress() -> Vector2i:
	if _level == null or _state.is_empty():
		return Vector2i.ZERO
	return Vector2i(int(_state["done"]), int(_level.groups_total))



func locked_column_width_ratio(ci: int) -> float:
	var slot: int = int(_slot_of.get(ci, -1))
	return _capsule_rect(slot).size.x / _lay.fruit_d if slot >= 0 and _lay != null else 0.0



func fruit_texture(type_id: int) -> Texture2D:
	return _texture_for_fruit(type_id)






func _clear_hint() -> void :
	if not _hint_hl.is_empty():
		_each_run_fruit(int(_hint_hl["col"]), int(_hint_hl["j"]), false)
		_hint_hl = {}
	if _hint_target != null:
		_hint_target.visible = false
	_stop_hint_demo()
	_hint = {}







func _stop_hint_demo() -> void :
	if _hint_hand != null and _hint_hand.is_playing():
		_hint_hand.stop()
		clear_run_demo_pos()







func _show_hint_visuals() -> bool:
	var src: int = int(_hint.get("src", -1))
	var j: int = int(_hint.get("j", -1))
	var dst: int = int(_hint.get("dst", -1))
	var src_list: Array = _fruit_nodes.get(src, [])
	if j < 0 or j >= src_list.size() or not _slot_of.has(dst):
		return false
	var cols: Array = _state.get("cols", [])
	if dst < 0 or dst >= cols.size() or _hint_target == null or _hint_hand == null:
		return false
	if not _each_run_fruit(src, j, true):
		return false
	_hint_hl = {"col": src, "j": j}


	var dst_slot: int = int(_slot_of[dst])
	var target_rect: Rect2 = _capsule_rect(dst_slot)
	_hint_target.position = target_rect.position
	_hint_target.size = target_rect.size
	_hint_target.visible = true

	var target_index: int = 0 if R.is_root_swap(_state, src, j, dst) else (cols[dst] as Array).size()
	_hint_hand.play(_home_pos(src, j), _home_pos(dst, target_index))
	return true




func _sync_hint_demo() -> void :
	if _hint.is_empty() or _hint_hand == null:
		return
	var head: Vector2 = _hint_hand.head()
	if head == Vector2.INF:
		return
	_set_run_demo_local(int(_hint["src"]), int(_hint["j"]), head)


func can_undo() -> bool:
	return not _history.is_empty() and _over != "win"\
	and ( not is_busy() or not _sunlight_batches.is_empty())








func undo(back_steps: int = 1) -> bool:
	if not can_undo():
		return false
	if bool(_state.get("allow_root_swapping", false)):
		_invalidate_root_closed_check()
	_cancel_melt_effects()

	_challenge_suppressed_by_undo = true

	_challenge_last_key = ""
	_invalidate_death_attribution()
	_clear_hint()
	_clear_run_highlight()
	if not _drag.is_empty():
		_clear_drag_visual()


	var count: int = clampi(back_steps, 1, _history.size())
	var touched_questions: int = 0
	var entry: Dictionary = {}
	for _i: int in count:
		entry = _history.pop_back()
		if _endless_session != null:
			_endless_session.undo_move(entry["rec"])
		else:
			touched_questions += R.undo_move(_state, entry["rec"] as Dictionary, _keep_revealed_on_undo, _rank_collectible_type)
	_order = (entry["order"] as Array[int]).duplicate()
	_steps = maxi(0, _steps - count)

	_over = ""
	_over_signal_pending = false
	_pending_dead_reason = ""
	_drag = {}
	_hover_col = -1
	_place_drop_hover()
	_shake.clear()
	_shift_queue.clear()
	_collect_hold_since = -1.0
	_collect_hold_until = -1.0
	_visual_token_by_col.clear()
	_visual_x.clear()
	_planned_x.clear()
	_clear_all_fly_trails()
	_clear_all_burst_state()
	_beats.clear()
	_reindex_slots()
	_rebuild_nodes()
	cups_changed.emit()
	_refresh_lock_overlays()
	if touched_questions > 0:
		revealed_undo_touched.emit()
	mystery_auto_unlock_requested.emit()
	_check_over()
	return true


func history_size() -> int:
	return _history.size()







func last_move_deposits() -> Array:
	if not _root_ready_deposits.is_empty():
		return _root_ready_deposits.duplicate(true)

	if not _complete_column_deposits.is_empty():
		return _complete_column_deposits.duplicate(true)
	if _history.is_empty():
		return []
	var rec: Dictionary = (_history[-1] as Dictionary)["rec"]
	var deposits: Array = (rec.get("deposits", []) as Array).duplicate(true)
	deposits.append_array(rec.get("auto_unlock_deposits", []) as Array)
	return deposits



func blender_rect_global(ci: int) -> Rect2:
	var blender: Variant = _blender_nodes.get(ci)
	if not is_instance_valid(blender) or not blender.visible:
		return Rect2()
	var body: Sprite2D = blender.get_node("Body") as Sprite2D
	if body.texture == null:
		return Rect2()
	return body.get_global_transform() * body.get_rect()


func last_move() -> Dictionary:
	if _history.is_empty():
		return {}
	var rec: Dictionary = (_history[-1] as Dictionary)["rec"]
	if not (rec.get("deposits", []) as Array).is_empty()\
	or not (rec.get("auto_unlock_deposits", []) as Array).is_empty():
		return {}
	return {"src": int(rec["src"]), "j": int(rec["j"]), "dst": int(rec["dst"]), 
		"k": int(rec["k"]), "root_swapped": bool(rec.get("root_swapped", false))}












func snapshot() -> Dictionary:
	return {
		"state": R.state_to_dict(_state), 
		"order": _order.duplicate(), 
		"initial_slot_of": _initial_slot_of.duplicate(), 
		"undo_history": _serialize_undo_history(), 
		"move_attempt_count": _move_attempt_count, 
		"successful_link_count": _successful_link_count, 
		"hint_dead": _over == "dead" and _pending_dead_reason == HINT_UNWINNABLE_REASON, 
		"dead": _over == "dead", 
		"bonus_type": _bonus_type, 
		"bonus_recolor_from": _bonus_recolor_from, 
		"bonus_recolor_to": _bonus_recolor_to, 
	}



func restore(level: JuiceLevel, blob: Dictionary, 
		color_slots: PackedInt32Array = PackedInt32Array()) -> bool:
	var st: Dictionary = R.state_from_dict(blob.get("state", {}), level)
	if st.is_empty():
		return false
	var initial_slots: Dictionary = {}
	if level.layout_rows == 2:
		if blob.has("initial_slot_of"):
			var raw_slots: Variant = blob["initial_slot_of"]
			if not (raw_slots is Dictionary) or raw_slots.size() != level.columns:
				return false
			var seen_slots: Dictionary = {}
			for ci: int in level.columns:
				var raw_slot: Variant = raw_slots.get(ci, raw_slots.get(str(ci)))
				if not (raw_slot is int or raw_slot is float) or int(raw_slot) != raw_slot:
					return false
				var slot: int = int(raw_slot)
				var valid_slot: bool = slot >= 0 and (slot < level.layout_columns
					or slot >= 5 and slot < 5 + level.init_jars - level.layout_columns
					or slot >= 10 and slot < 10 + level.initial_parks)
				if not valid_slot or seen_slots.has(slot):
					return false
				initial_slots[ci] = slot
				seen_slots[slot] = true
		elif not level.has_variable_caps():

			for ci: int in level.columns:
				var jar_index: int = ci - level.initial_parks
				initial_slots[ci] = 10 + ci if ci < level.initial_parks\
				else jar_index / level.layout_columns * 5 + jar_index % level.layout_columns
	var rules_changed: bool = bool(st.get("allow_root_swapping", false)) != _allow_root_swapping_enabled

	_bonus_plan_pending = {
		"type": int(blob.get("bonus_type", JuiceBonusLevel.NO_BONUS_TYPE)), 
		"recolor_from": int(blob.get("bonus_recolor_from", -1)), 
		"recolor_to": int(blob.get("bonus_recolor_to", -1)), 
	}
	setup(level, st, color_slots, null, initial_slots)
	_resumed_round = true
	_move_attempt_count = maxi(0, int(blob.get("move_attempt_count", 0)))
	_successful_link_count = maxi(0, int(blob.get("successful_link_count", 0)))

	var saved: Array = blob.get("order", [])
	var ok: bool = saved.size() == _order.size()
	if ok:
		var seen: Dictionary = {}
		for v: Variant in saved:
			if not _slot_of.has(int(v)) or seen.has(int(v)):
				ok = false
				break
			seen[int(v)] = true
	if ok:
		_order.clear()
		for v: Variant in saved:
			_order.append(int(v))
		_reindex_slots()
		_snap_all_home()
	else:
		push_warning("juice_sort: 存档里的格位顺序不合法,回落成按列号排")
	_restore_undo_history(level, blob.get("undo_history"))
	if not rules_changed and not bool(_state.get("allow_root_swapping", false))\
	and bool(blob.get("hint_dead", false)) and _over == "":
		mark_hint_unwinnable()

	_challenge_last_key = ""
	_start_challenge_check()
	return true





func _serialize_undo_history() -> Array:
	var out: Array = []
	var first: int = maxi(0, _history.size() - MAX_PERSISTED_UNDO_STEPS)
	for i in range(first, _history.size()):
		var entry: Dictionary = _history[i] as Dictionary
		var rec: Dictionary = entry.get("rec", {}) as Dictionary
		var encoded_rec: Dictionary = {
			"src": int(rec.get("src", -1)), 
			"j": int(rec.get("j", -1)), 
			"dst": int(rec.get("dst", -1)), 
			"k": int(rec.get("k", 0)), 
			"head": int(rec.get("head", -1)), 
			"root_swapped": bool(rec.get("root_swapped", false)), 
			"had_deposits": not (rec.get("deposits", []) as Array).is_empty(), 
			"revealed": (rec.get("revealed", []) as Array).duplicate(true), 
			"hidden_spawns": (rec.get("hidden_spawns", []) as Array).duplicate(true), 
		}
		var snap: Dictionary = rec.get("snap", {}) as Dictionary
		if not snap.is_empty():
			encoded_rec["snap"] = R.state_to_dict(snap)
		var auto_unlock_before: Dictionary = rec.get("auto_unlock_before", {}) as Dictionary
		if not auto_unlock_before.is_empty():
			encoded_rec["auto_unlock_before"] = R.state_to_dict(auto_unlock_before)
			encoded_rec["had_auto_unlock_deposits"] = not (rec.get("auto_unlock_deposits", []) as Array).is_empty()
		out.append({"rec": encoded_rec, "order": (entry["order"] as Array[int]).duplicate(), 
			"after_empty_rope_num": int(entry.get("after_empty_rope_num", -1))})
	return out



func _restore_undo_history(level: JuiceLevel, raw: Variant) -> void :
	_history.clear()
	if raw == null:
		return
	if not (raw is Array):
		push_warning("juice_sort: 存档撤销历史不是数组,忽略撤销历史")
		return
	var source: Array = raw as Array
	var first: int = maxi(0, source.size() - MAX_PERSISTED_UNDO_STEPS)
	var restored: Array = []
	for i in range(first, source.size()):
		var entry: Dictionary = _undo_entry_from_dict(source[i], level)
		if entry.is_empty():
			push_warning("juice_sort: 存档第 %d 条撤销记录不合法,忽略全部撤销历史" % (i + 1))
			return
		restored.append(entry)
	_history = restored


func _undo_entry_from_dict(raw: Variant, level: JuiceLevel) -> Dictionary:
	if not (raw is Dictionary):
		return {}
	var d: Dictionary = raw as Dictionary
	var raw_rec: Variant = d.get("rec")
	var raw_order: Variant = d.get("order")
	if not (raw_rec is Dictionary) or not (raw_order is Array):
		return {}
	var encoded_rec: Dictionary = raw_rec as Dictionary
	var src: int = int(encoded_rec.get("src", -1))
	var j: int = int(encoded_rec.get("j", -1))
	var dst: int = int(encoded_rec.get("dst", -1))
	var k: int = int(encoded_rec.get("k", 0))
	var root_swapped: bool = bool(encoded_rec.get("root_swapped", false))
	var max_columns: int = (_state.get("cols", []) as Array).size()
	if src < 0 or src >= max_columns or dst < 0 or dst >= max_columns or src == dst\
	or j < 0 or j >= level.capacity or k <= 0 or k > level.capacity:
		return {}
	if root_swapped and j != 0:
		return {}
	var order: Array[int] = []
	var seen: Dictionary = {}
	for value: Variant in raw_order as Array:
		var ci: int = int(value)
		if ci < 0 or ci >= max_columns or seen.has(ci):
			return {}
		seen[ci] = true
		order.append(ci)
	if order.is_empty():
		return {}
	var had_deposits: bool = bool(encoded_rec.get("had_deposits", false))
	var has_snap: bool = encoded_rec.has("snap")

	if had_deposits != has_snap:
		return {}
	var snap: Dictionary = {}
	if has_snap:
		if not (encoded_rec["snap"] is Dictionary):
			return {}
		snap = R.state_from_dict(encoded_rec["snap"] as Dictionary, level)
		if snap.is_empty():
			return {}
	var auto_unlock_before: Dictionary = {}
	if encoded_rec.has("auto_unlock_before"):
		if not (encoded_rec["auto_unlock_before"] is Dictionary):
			return {}
		auto_unlock_before = R.state_from_dict(encoded_rec["auto_unlock_before"] as Dictionary, level)
		if auto_unlock_before.is_empty() or R.mystery_auto_unlock_candidate(auto_unlock_before, level).is_empty():
			return {}
	elif bool(encoded_rec.get("had_auto_unlock_deposits", false)):
		return {}
	var revealed: Array = []
	var raw_revealed: Variant = encoded_rec.get("revealed", [])
	if not (raw_revealed is Array):
		return {}
	for raw_reveal: Variant in raw_revealed as Array:
		if not (raw_reveal is Dictionary):
			return {}
		var reveal: Dictionary = raw_reveal as Dictionary
		var reveal_col: int = int(reveal.get("col", -1))
		var reveal_index: int = int(reveal.get("index", -1))
		var before: int = int(reveal.get("before", -1))
		var type_id: int = int(reveal.get("type", -1))
		if reveal_col < 0 or reveal_col >= max_columns or reveal_index < 0\
		or reveal_index >= level.capacity or not JuiceLevel.is_hidden(before)\
		or JuiceLevel.true_type(before) != type_id:
			return {}
		revealed.append({"col": reveal_col, "index": reveal_index, 
			"before": before, "type": type_id})

	var hidden_spawns: Array = []
	var raw_spawns: Variant = encoded_rec.get("hidden_spawns", [])
	if not (raw_spawns is Array):
		return {}
	for raw_spawn: Variant in raw_spawns as Array:
		if not (raw_spawn is Dictionary):
			return {}
		var spawn: Dictionary = raw_spawn as Dictionary
		var spawn_col: int = int(spawn.get("col", -1))
		var spawn_index: int = int(spawn.get("index", -1))
		var spawn_key: String = String(spawn.get("key", ""))
		if spawn_col < 0 or spawn_col >= max_columns or spawn_index < 0\
		or spawn_index >= level.capacity or spawn_key.is_empty():
			return {}
		hidden_spawns.append({"col": spawn_col, "index": spawn_index, "key": spawn_key})
	var deposits: Array = [{}] if had_deposits else []
	return {
		"rec": {
			"src": src, 
			"j": j, 
			"dst": dst, 
			"k": k, 
			"head": int(encoded_rec.get("head", -1)), 
			"root_swapped": root_swapped, 
			"deposits": deposits, 
			"revealed": revealed, 
			"unlocked": [] as Array, 
			"snap": snap, 
			"hidden_spawns": hidden_spawns, 
			"auto_unlock_before": auto_unlock_before, 
			"auto_unlock_deposits": [{}] if bool(encoded_rec.get("had_auto_unlock_deposits", false)) else [], 
		}, 
		"order": order, 
		"after_empty_rope_num": int(d.get("after_empty_rope_num", -1)), 
	}



func cup_colors() -> PackedColorArray:
	var out: PackedColorArray = PackedColorArray()
	if _state.is_empty():
		return out
	for t: int in (_state["cups"] as Array[int]):
		out.append(color_for_type(t))
	return out




func cup_textures() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if _state.is_empty():
		return out
	for t: int in (_state["cups"] as Array[int]):
		out.append(target_icon_for_type(t))
	return out













func set_sunlight_layer(layer: Node2D) -> void :
	_bird_layer = layer
	_sunlight_fx.reparent(layer)
	_sunlight_collector.reparent(layer)
	_ice_shatter_fx.reparent(layer)


func _melt_surface_held(surface: Node2D) -> bool:
	for batch: Dictionary in _sunlight_batches:
		if not bool(batch["released"]) and (batch["flowers"] as Array).has(surface):
			return true
	return false


func _capture_melt_batch(deposit: Dictionary) -> Dictionary:
	var flowers: Array[Node2D] = []
	for entry: Dictionary in deposit.get("melted", []) as Array:
		var column_index: int = int(entry["col"])
		var fruit_index: int = int(entry["index"])
		var nodes: Array[JuiceFruit] = _fruit_nodes.get(column_index, [] as Array[JuiceFruit])
		if fruit_index < 0 or fruit_index >= nodes.size():
			continue
		var fruit: JuiceFruit = nodes[fruit_index]
		if is_instance_valid(fruit):
			fruit.fruit_type = int(entry["type"])
			flowers.append(fruit)
	for entry: Dictionary in deposit.get("thawed_pots", []) as Array:
		var blender: JuiceBlender = _blender_nodes.get(int(entry["col"])) as JuiceBlender
		if is_instance_valid(blender):
			flowers.append(blender)
	var batch: Dictionary = {"nth": int(deposit["nth"]), "flowers": flowers, 
		"generation": _melt_generation, "released": false, "cancelled": false, 
		"shatter": not (deposit.get("thawed_pots", []) as Array).is_empty()
			and (deposit.get("melted", []) as Array).is_empty()}
	_sunlight_batches.append(batch)
	return batch


func start_sunlight_collection(nth: int, from_rect: Rect2, dst_rect: Rect2, 
		destination: Callable = Callable()) -> void :
	var batch: Dictionary = {}
	for candidate: Dictionary in _sunlight_batches:
		if int(candidate["nth"]) == nth:
			batch = candidate
			break
	if batch.is_empty():
		return
	_sunlight_collection_queue.append({"nth": nth, "from": from_rect, 
		"dst": dst_rect, "destination": destination, "batch": batch})
	_start_next_sunlight_collection()


func _start_next_sunlight_collection() -> void :
	if not _sunlight_flight.is_empty() or not _sunlight_active_batch.is_empty()\
	or _sunlight_collection_queue.is_empty():
		return
	var flight: Dictionary = _sunlight_collection_queue.pop_front()
	_sunlight_active_batch = flight["batch"]
	var inverse: Transform2D = (_sunlight_collector.get_parent() as CanvasItem).get_global_transform().affine_inverse()
	flight["from"] = inverse * (flight["from"] as Rect2)
	flight["dst"] = inverse * (flight["dst"] as Rect2)
	flight["clock"] = 0.0
	_sunlight_flight = flight
	_sunlight_collector.set_target(sunlight_blender_texture, sunlight_full_blender_texture, _level.sunlight_type)
	_sunlight_collector.set_sunlight(true, 1.0, _sunlight_fx.settings)
	_sunlight_collector.sample_sunlight_flight(flight["from"], flight["dst"], 0.0)
	_sunlight_collector.show()
	if bool(_sunlight_active_batch["shatter"]):
		_ice_shatter_fx.play(_sunlight_active_batch["flowers"] as Array)
		_release_melt_batch(_sunlight_active_batch)


func _tick_sunlight_collection(delta: float) -> void :
	if not _sunlight_flight.is_empty():
		_sunlight_flight["clock"] = float(_sunlight_flight["clock"]) + delta
		var destination: Callable = _sunlight_flight["destination"]
		if destination.is_valid():
			var inverse: Transform2D = (_sunlight_collector.get_parent() as CanvasItem).get_global_transform().affine_inverse()
			_sunlight_flight["dst"] = inverse * (destination.call() as Rect2)
		var progress: float = float(_sunlight_flight["clock"]) / _sunlight_fx.settings.collector_duration
		_sunlight_collector.sample_sunlight_flight(_sunlight_flight["from"], _sunlight_flight["dst"], progress)
		if progress >= 1.0:
			var nth: int = int(_sunlight_flight["nth"])
			var generation: int = _melt_generation
			_sunlight_flight.clear()
			_sunlight_collector.hide()
			sunlight_collector_landed.emit(nth)
			if generation != _melt_generation or _sunlight_active_batch.is_empty():
				return
			if bool(_sunlight_active_batch["shatter"]):
				_finish_shatter_collection_if_ready()
			else:
				var viewport: Vector2 = UiMetrics.viewport_size()
				var bottom: float = minf(viewport.y, global_position.y + size.y)
				var inverse: Transform2D = (_sunlight_fx.get_parent() as CanvasItem).get_global_transform().affine_inverse()
				_sunlight_fx.play(inverse * Rect2(0.0, 0.0, viewport.x, bottom), 
					_sunlight_active_batch["flowers"] as Array)
	if _sunlight_fx.is_running() and not _sunlight_active_batch.is_empty()\
	and float(_sunlight_fx.get("_clock")) >= _sunlight_fx.ice_melt_duration():
		_release_melt_batch(_sunlight_active_batch)


func _finish_shatter_collection_if_ready() -> void :
	if not _sunlight_active_batch.is_empty() and bool(_sunlight_active_batch["shatter"])\
	and _sunlight_flight.is_empty() and not _ice_shatter_fx.is_running():
		_on_sunlight_finished()


func _release_melt_batch(batch: Dictionary) -> void :
	if bool(batch.get("released", false)):
		return
	batch["released"] = true
	if batch == _sunlight_active_batch and _sunlight_fx.is_running():
		_sunlight_fx.finish_melting()
	for flower: Node2D in batch["flowers"]:
		if is_instance_valid(flower):
			flower.call("set_frozen", false)


func _on_sunlight_finished() -> void :
	if _sunlight_active_batch.is_empty():
		return
	_release_melt_batch(_sunlight_active_batch)
	_sunlight_batches.erase(_sunlight_active_batch)
	_sunlight_active_batch = {}
	_start_next_sunlight_collection()
	_check_over()
	if not is_busy():
		settled.emit()


func cancel_sunlight_animation() -> void :
	_cancel_melt_effects()


func _cancel_melt_effects() -> void :
	_melt_generation += 1
	_sunlight_collection_queue.clear()
	_sunlight_flight.clear()
	if is_instance_valid(_sunlight_fx):
		_sunlight_fx.stop()
	if is_instance_valid(_ice_shatter_fx):
		_ice_shatter_fx.stop()
	if is_instance_valid(_sunlight_collector):
		_sunlight_collector.hide()
	for batch: Dictionary in _sunlight_batches:
		batch["cancelled"] = true
		_release_melt_batch(batch)
	_sunlight_batches.clear()
	_sunlight_active_batch = {}


func _enqueue_beats(deposits: Array, preserve_positions: bool = false) -> void :
	if is_instance_valid(_bonus_idle_fx):
		_bonus_idle_fx.stop()
	var lead: float = _collect_lead_dur(deposits)
	var waiting_shift: Dictionary = {}
	if not _shift_queue.is_empty() and bool(_shift_queue[0].get("started", false)):
		waiting_shift = _shift_queue[0]
	var melt_batch: Dictionary = {}
	for deposit_index in deposits.size():
		var d: Dictionary = deposits[deposit_index]
		var wait_for_melt: Dictionary = melt_batch
		if bool(d.get("sun", false)):
			melt_batch = _capture_melt_batch(d)
		var t0: float = _t + lead
		var ci: int = int(d["col"])
		var row_y: float = _row_y(ci)
		var new_rope: Dictionary = d.get("new_rope", {}) as Dictionary
		if not new_rope.is_empty():
			new_rope_appeared.emit(new_rope)
		var q: int = int(d["q"])
		var burst_dur: float = BURST_DUR + GHOST_FADE_DUR + BONUS_DEPOSIT_FLY_DUR + float(maxi(0, q - 1)) * BONUS_DEPOSIT_STAGGER if _is_bonus_type(int(d["fruit"])) else BURST_DUR
		var bird: bool = (_skin_resources != null and _skin_resources.active_skin.id == &"bird"
			and not is_rank_collectible_type(int(d["fruit"]))
			and not _is_bonus_type(int(d["fruit"])) and not _level.is_sunlight_type(int(d["fruit"]))
			and _skin_resources.color_texture(JuiceTheme.COLOR_KEYS[slot_for_type(int(d["fruit"]))], &"door_atlas") != null
			and is_instance_valid(_bird_layer))
		if bird:
			burst_dur = JuiceBirdCollection.RISE_DURATION
		var visual_token: int = int(_visual_token_by_col.get(ci, -1))
		if visual_token < 0:
			visual_token = _new_visual_token(ci, _col_x(ci))
		_release_wood_unlock_for_token(visual_token)


		var ghost_x: float = float(_visual_x.get(visual_token, _col_x(ci))) - _shake_dx(ci)
		_legacy_replenish_pending.erase(visual_token)
		var ghost_nodes: Array[JuiceFruit] = \
		(_fruit_nodes.get(ci, [] as Array[JuiceFruit]) as Array[JuiceFruit]).duplicate()
		for active_batch: Dictionary in _sunlight_batches:
			if bool(active_batch["released"]):
				continue
			for flower: JuiceFruit in ghost_nodes:
				if (active_batch["flowers"] as Array).has(flower):
					wait_for_melt = active_batch
					break
		_fruit_nodes[ci] = [] as Array[JuiceFruit]


		var lead_from: = PackedVector2Array()
		var lead_scale: = PackedFloat32Array()
		var lead_rot: = PackedFloat32Array()



		var spin_deg: = PackedFloat32Array()

		var trail_ribbons: Array = []
		trail_ribbons.resize(ghost_nodes.size())
		for i in ghost_nodes.size():
			var fruit: JuiceFruit = ghost_nodes[i]
			var slot_pos: = Vector2(ghost_x, _lay.fruit_y(i) + row_y)
			spin_deg.append(randf_range(90.0, 180.0))
			if not is_instance_valid(fruit):
				lead_from.append(slot_pos)
				lead_scale.append(1.0)
				lead_rot.append(0.0)
				continue
			lead_from.append(_fruit_layer_pos(fruit))
			lead_scale.append(fruit.scale.x)
			lead_rot.append(fruit.rotation)
			if lead > 0.0:



				_return.erase(fruit)

			elif waiting_shift.is_empty() and not preserve_positions:
				_set_drag_top_level(fruit, false)
				fruit.position = slot_pos

		var ghost_blender: JuiceBlender = null
		var old_blender: Variant = _blender_nodes.get(ci)
		for active_batch: Dictionary in _sunlight_batches:
			if not bool(active_batch["released"]) and (active_batch["flowers"] as Array).has(old_blender):
				wait_for_melt = active_batch
		if old_blender != null and is_instance_valid(old_blender):
			ghost_blender = old_blender as JuiceBlender
			_blender_nodes.erase(ci)
			ghost_blender.position.x = ghost_x

		var incoming: Dictionary = d["incoming"] if _endless_session != null else _level.incoming_at(int(d["nth"]))
		var collect_shift: Dictionary = _enqueue_replacement(ci, incoming, 
			d["spawns"], t0 + _slam_len(q, burst_dur, bird), ghost_x, wait_for_melt, waiting_shift)
		var ghost_rect: Rect2 = Rect2(ghost_x - _lay.blender_display_w * 0.5, 
			_lay.blender_top + _lay.blender_h - _lay.blender_display_h + row_y, 
			_lay.blender_display_w, _lay.blender_display_h)
		var beat: Dictionary = {
			"col": ci, "fruit": int(d["fruit"]), "q": q, "nth": int(d["nth"]), 
			"sun": bool(d.get("sun", false)), "melted": d.get("melted", []) as Array, 
			"melt_batch": wait_for_melt, "melt_waiting": not wait_for_melt.is_empty(), 
			"melt_shift": collect_shift, 
			"sun_batch": melt_batch if bool(d.get("sun", false)) else {}, 
			"spawns": (d["spawns"] as Array), 
			"t0": t0 if waiting_shift.is_empty() else INF, 
			"waiting_shift": waiting_shift, 
			"waiting_since": _t, 
			"collect_shift": collect_shift, 
			"ghost_x": ghost_x, 
			"ghost_top": ghost_rect.position.y, 
			"row_y": row_y, 
			"ghost_h": ghost_rect.size.y, 
			"ghost_w": ghost_rect.size.x, 
			"visual_token": visual_token, 
			"lead": lead, 
			"lead_start": _t, 
			"lead_from": lead_from, 
			"lead_scale": lead_scale, 
			"lead_rot": lead_rot, 
			"lead_done": lead <= 0.0, 
			"started": false, 
			"cup_sent": false, 
			"blender_released": false, 
			"burst_started": false, 
			"burst_dur": burst_dur, 
			"bird": bird, 
			"bird_visual": null, 
			"bird_visual_started": false, 
			"burst_tweens": [], 
			"nodes": ghost_nodes, 
			"blender": ghost_blender, 
			"spin_deg": spin_deg, 
			"trail_ribbons": trail_ribbons, 
		}
		_beats.append(beat)
	_reindex_all()





func _slam_len(_q: int, burst: float = BURST_DUR, bird: bool = false) -> float:
	if bird:
		return burst + SLAM_FLY_DUR + maxf(JuiceBirdCollection.BIRD_STAGGER, float(maxi(0, _q - 1)) * JuiceBirdCollection.BIRD_STAGGER) + JuiceBirdCollection.FEEDBACK_RETURN_DURATION + SLAM_TAIL
	if burst > BURST_DUR:
		return burst + SLAM_TAIL
	return burst + GHOST_FADE_DUR + SLAM_FLY_DUR + SLAM_TAIL



func _burst_dur(beat: Dictionary) -> float:
	return float(beat.get("burst_dur", BURST_DUR))


func _beat_len(q: int, spawns: Array, burst: float = BURST_DUR, bird: bool = false) -> float:
	var n: int = 0
	for s: Dictionary in spawns:
		n = maxi(n, (s["types"] as Array).size())
	var plant: float = PLANT_LAG + PLANT_DUR + maxi(0, n - 1) * PLANT_STAG
	return _slam_len(q, burst, bird) + maxf(SLIDE_DUR, plant)


func _advance_beats() -> void :
	if _beats.is_empty():
		return
	var done: Array = []
	for beat: Dictionary in _beats:
		if _advance_waiting_collect(beat):
			continue
		if _advance_melt_wait(beat):
			continue
		var age: float = _t - float(beat["t0"])

		if bool(beat.get("preview", false)) and age < 0.0:
			continue
		if not bool(beat["started"]):
			beat["started"] = true
			if bool(beat.get("preview", false)):
				for preview_fruit: JuiceFruit in (beat["nodes"] as Array):
					if is_instance_valid(preview_fruit):
						preview_fruit.visible = true
				var preview_blender: Variant = beat.get("blender")
				if preview_blender != null and is_instance_valid(preview_blender):
					(preview_blender as CanvasItem).visible = true
			beat["ghost_x"] = float(_visual_x.get(int(beat["visual_token"]), beat["ghost_x"]))
		var q: int = int(beat["q"])
		var slam_tail: float = SLAM_TAIL
		var slam: float = _slam_len(q, _burst_dur(beat), bool(beat.get("bird", false)))


		_update_slam_nodes(beat, age)








		if age >= slam - slam_tail and not bool(beat["cup_sent"]):
			beat["cup_sent"] = true
			if not bool(beat.get("preview", false)) and _is_bonus_type(int(beat["fruit"])) and not bool(beat.get("bonus_sequential", false)):
				_start_bonus_entry_feedback(beat)

			if not bool(beat.get("preview", false)):

				if _collect_hold_until <= _t:
					_collect_hold_since = _t
				_collect_hold_until = maxf(_collect_hold_until, _t + slam_tail)
				var pot: = Rect2(
					float(beat["ghost_x"]) - float(beat["ghost_w"]) * 0.5, 
					float(beat["ghost_top"]), float(beat["ghost_w"]), float(beat["ghost_h"]))
				if _is_bonus_type(int(beat["fruit"])):
					var source: JuiceBlender = beat.get("blender") as JuiceBlender
					if is_instance_valid(source):
						var body: Sprite2D = source.get_node("Body") as Sprite2D
						var actual: Rect2 = body.global_transform * body.get_rect()
						_bonus_handoff_source = source
						pot = Rect2(actual.position - global_position, actual.size)
					var feedback_time: float = BonusCoinEntryFx.LIFE + float(mini(q, 6) - 1) * BonusCoinEntryFx.STAGGER
					_collect_hold_until = maxf(_collect_hold_until, _t + feedback_time)
				elif is_rank_collectible_type(int(beat["fruit"])):
					var source: JuiceBlender = beat.get("blender") as JuiceBlender
					if is_instance_valid(source):
						var body: Sprite2D = source.get_node("Body") as Sprite2D
						var actual: Rect2 = body.global_transform * body.get_rect()
						pot = Rect2(actual.position - global_position, actual.size)
				var bird_visual: JuiceBirdCollection = beat.get("bird_visual") as JuiceBirdCollection
				if is_instance_valid(bird_visual):
					bird_visual.fill()
					_bird_handoffs[int(beat["nth"])] = bird_visual
				cup_collected.emit(int(beat["fruit"]), int(beat["nth"]), 
					color_for_type(int(beat["fruit"])), 
					Rect2(global_position + pot.position, pot.size))
				if _level.is_sunlight_type(int(beat["fruit"])):
					var collector: JuiceBlender = beat.get("blender") as JuiceBlender
					if is_instance_valid(collector):
						collector.hide()

				var pending_reveals: Array = beat.get("pending_reveals", []) as Array
				if not pending_reveals.is_empty():
					beat["pending_reveals"] = []
					_apply_node_reveals(pending_reveals)

		var bonus_linger: float = BonusCoinEntryFx.LIFE + float(mini(q, 6) - 1) * BonusCoinEntryFx.STAGGER if _is_bonus_type(int(beat["fruit"])) else COLLECT_BLENDER_LINGER


		if not bool(beat.get("preview", false))\
		and age >= slam - slam_tail + bonus_linger and bool(beat["cup_sent"])\
		and not bool(beat["blender_released"]) and not _is_bonus_type(int(beat["fruit"])):
			beat["blender_released"] = true
			var old_blender: Variant = beat.get("blender")
			if old_blender != null and is_instance_valid(old_blender):
				_blender_pool.release(old_blender as JuiceBlender)
			beat["blender"] = null

		var preview_end: float = _slam_len(q) if bool(beat.get("preview", false))\
		else _beat_len(q, beat["spawns"] as Array, _burst_dur(beat), bool(beat.get("bird", false)))
		if _is_bonus_type(int(beat["fruit"])):
			preview_end = maxf(preview_end, slam - slam_tail + bonus_linger + 0.02)
		if age >= preview_end:
			_finish_beat(beat)
			done.append(beat)

	var finished_real: = false
	for b in done:
		if not bool(b.get("preview", false)):
			finished_real = true
		_beats.erase(b)
	var real_left: = false
	for beat: Dictionary in _beats:
		if not bool(beat.get("preview", false)):
			real_left = true
			break
	if finished_real and not real_left and not _beats.is_empty():
		_trail_preview_settle_pending = true
	if _beats.is_empty() and _shift_queue.is_empty():
		if not finished_real and not _trail_preview_settle_pending:
			return
		_trail_preview_settle_pending = false
		_snap_all_home()
		_check_over()
		settled.emit()












func _collect_lead_dur(deposits: Array) -> float:


	var lead: float = 0.0
	for beat: Dictionary in _beats:
		if not bool(beat.get("preview", false)) and float(beat["lead_start"]) == _t:
			lead = maxf(lead, float(beat["lead"]))
	if _return.is_empty():
		return lead
	var cols: Dictionary = {}
	for d: Dictionary in deposits:
		cols[int(d["col"])] = true
	for f: JuiceFruit in _return:
		if is_instance_valid(f) and cols.has(f.col):
			return maxf(lead, COLLECT_LEAD_DUR)
	return lead





func _update_lead_nodes(beat: Dictionary, elapsed: float, lead: float, follow_sway: bool = false) -> void :
	var x: float = float(beat["ghost_x"])
	var row_y: float = float(beat.get("row_y", 0.0))
	var slope: float = _idle_sway_slope(int(beat["col"]), int(beat["q"])) if follow_sway else 0.0
	var nodes: Array = beat["nodes"]
	var from: PackedVector2Array = beat["lead_from"]
	var from_scale: PackedFloat32Array = beat["lead_scale"]
	var from_rot: PackedFloat32Array = beat["lead_rot"]
	var e: float = 1.0 - pow(1.0 - clampf(elapsed / lead, 0.0, 1.0), 3.0)
	for j in nodes.size():
		var f: JuiceFruit = nodes[j]
		if not is_instance_valid(f) or j >= from.size():
			continue
		f.visible = true
		var home: Vector2 = Vector2(x, _lay.fruit_y(j) + row_y)
		if follow_sway:
			home.x += slope * (home.y - _lay.hang_top - row_y)
		_set_fruit_layer_pos(f, from[j].lerp(home, e))
		var s: float = lerpf(from_scale[j], 1.0, e)
		f.scale = Vector2(s, s)
		f.rotation = lerpf(from_rot[j], 0.0, e)



func _advance_melt_wait(beat: Dictionary) -> bool:
	if not bool(beat.get("melt_waiting", false)):
		return false
	var batch: Dictionary = beat["melt_batch"]
	if not bool(batch.get("released", false)):
		var lead: float = float(beat["lead"])
		_update_lead_nodes(beat, _t - float(beat["lead_start"]) if lead > 0.0 else 1.0, 
			lead if lead > 0.0 else 1.0, true)
		return true
	beat["melt_waiting"] = false
	beat["t0"] = _t
	var shift: Dictionary = beat["melt_shift"]
	shift["start_at"] = maxf(float(shift["start_at"]), float(beat["t0"]) + _slam_len(int(beat["q"]), _burst_dur(beat), bool(beat.get("bird", false))))
	return false


func _advance_waiting_collect(beat: Dictionary) -> bool:
	var waiting_shift: Dictionary = beat.get("waiting_shift", {})
	if waiting_shift.is_empty():
		return false
	var x: float = float(_visual_x.get(int(beat["visual_token"]), beat["ghost_x"]))
	var dx: float = x - float(beat["ghost_x"])
	beat["ghost_x"] = x
	var from: PackedVector2Array = beat["lead_from"]
	for j: int in from.size():
		from[j].x += dx
	beat["lead_from"] = from
	var elapsed: float = _t - float(beat["waiting_since"])
	var lead: float = float(beat["lead"])
	_update_lead_nodes(beat, elapsed if lead > 0.0 else 1.0, lead if lead > 0.0 else 1.0, true)
	var blender: Variant = beat.get("blender")
	if blender != null and is_instance_valid(blender):
		(blender as JuiceBlender).position.x = x
	if not bool(waiting_shift.get("finished", false)):
		return true


	var remaining_lead: float = maxf(0.0, lead - elapsed)
	var nodes: Array = beat["nodes"]
	var from_scale: PackedFloat32Array = beat["lead_scale"]
	var from_rot: PackedFloat32Array = beat["lead_rot"]
	for j: int in nodes.size():
		var fruit: JuiceFruit = nodes[j]
		if not is_instance_valid(fruit):
			continue
		from[j] = _fruit_layer_pos(fruit)
		from_scale[j] = fruit.scale.x
		from_rot[j] = fruit.rotation
		if remaining_lead <= 0.0:
			_set_drag_top_level(fruit, false)
			fruit.z_index = 0
	beat["lead_from"] = from
	beat["lead_scale"] = from_scale
	beat["lead_rot"] = from_rot
	beat["lead"] = remaining_lead
	beat["lead_start"] = _t
	beat["lead_done"] = remaining_lead <= 0.0
	var start_at: float = _t + remaining_lead
	beat["t0"] = start_at
	var collect_shift: Dictionary = beat["collect_shift"]
	if not collect_shift.is_empty():
		collect_shift["waiting_collects"] = int(collect_shift.get("waiting_collects", 0)) - 1
		collect_shift["start_at"] = maxf(float(collect_shift["start_at"]), float(beat["t0"]) + _slam_len(int(beat["q"]), _burst_dur(beat), bool(beat.get("bird", false))))
	beat.erase("waiting_shift")
	beat.erase("waiting_since")
	beat.erase("collect_shift")
	return false










func _update_burst_stage(beat: Dictionary, age: float) -> void :
	if not bool(beat.get("burst_started", false)):
		beat["burst_started"] = true
		_request_major_sound(&"juice_burst", tutorial_demo_only or bool(beat.get("preview", false)))
		_start_burst_pulse(beat)
		var row_y: float = float(beat.get("row_y", 0.0))
		var rope_range: Vector2 = _beat_rope_range(beat)
		if _is_bonus_type(int(beat["fruit"])):
			_start_bonus_coin_burst(beat)
		elif not _level.is_sunlight_type(int(beat["fruit"])):
			var slot: int = int(beat.get("preview_slot", slot_for_type(int(beat["fruit"]))))
			_spawn_rope_petals(float(beat["ghost_x"]), _beat_flower_color(beat), row_y, false, rope_range, 
				_beat_feather(beat) if _beat_feather(beat) != null else collection_particle_texture(slot), int(beat["fruit"]))
		if not _is_bonus_type(int(beat["fruit"])):
			_spawn_rope_stars(float(beat["ghost_x"]), 1.0, 1.0, row_y, rope_range)



func _beat_rope_range(beat: Dictionary) -> Vector2:
	var row_y: float = float(beat.get("row_y", 0.0))
	return Vector2(_lay.rope_visible_top, _lay.rope_bottom_for(int(beat["q"]))) + Vector2.ONE * row_y



func _finish_coin_trail(beat: Dictionary, ribbon: FireworkTrails.Ribbon) -> void :
	if _is_bonus_type(int(beat["fruit"])) and is_instance_valid(_bonus_gold_trails):
		_bonus_gold_trails.absorb_into_slot(ribbon, 1.0, SLAM_TRAIL_HEAD_ALPHA)
	else:
		ribbon.detach()

func _absorb_coin_trail(beat: Dictionary, index: int, progress: float) -> void :
	if not _is_bonus_type(int(beat["fruit"])) or not is_instance_valid(_bonus_gold_trails):
		return
	var ribbons: Array = beat.get("trail_ribbons", [])
	if index < ribbons.size() and ribbons[index] != null:
		_bonus_gold_trails.absorb_into_slot(ribbons[index], progress, SLAM_TRAIL_HEAD_ALPHA)





func _start_burst_pulse(beat: Dictionary) -> void :
	var nodes: Array = beat["nodes"]
	var q: int = maxi(1, nodes.size())
	var pulse_dur: float = BURST_PULSE_UP_DUR + BURST_PULSE_DOWN_DUR
	var pulse_window: float = JuiceBirdCollection.RISE_DURATION if bool(beat.get("bird", false)) else BURST_DUR
	var pulse_speed: float = minf(1.0, pulse_window / pulse_dur)
	var stagger: float = maxf(0.0, pulse_window - pulse_dur * pulse_speed) / maxf(1.0, float(q - 1))
	var tweens: Array = beat["burst_tweens"]
	for i in nodes.size():
		var node: JuiceFruit = nodes[i]
		if not is_instance_valid(node):
			continue
		node.scale = Vector2.ONE
		node.z_index = SLAM_FLY_Z

		var tw: = node.create_tween()
		tweens.append(tw)
		if i > 0:
			tw.tween_interval(stagger * float(i))
		tw.tween_property(node, "scale", Vector2.ONE * BURST_PULSE_SCALE, BURST_PULSE_UP_DUR * pulse_speed)\
		.set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "scale", Vector2.ONE, BURST_PULSE_DOWN_DUR * pulse_speed)\
		.set_ease(Tween.EASE_IN)






func _beat_feather(beat: Dictionary) -> Texture2D:
	return feather_for_type(int(beat["fruit"])) if bool(beat.get("bird", false)) else null


func feather_for_type(type_id: int) -> Texture2D:
	if _skin_resources == null or _skin_resources.active_skin.id != &"bird"\
	or _is_bonus_type(type_id) or _level.is_sunlight_type(type_id):
		return null
	var slot: int = slot_for_type(type_id)
	return _skin_resources.color_texture(JuiceTheme.COLOR_KEYS[slot], &"feather") if slot >= 0 else null


func _spawn_rope_petals(ghost_x: float, tint: Color, row_y: float = 0.0, coin_debris: bool = false, 
		local_range: Vector2 = Vector2.ZERO, collection_texture: Texture2D = null, type_id: int = -1) -> void :
	var top_y: float = _lay.rope_visible_top + row_y
	var bot_y: float = _lay.rope_bottom + row_y
	if local_range.y > local_range.x:
		top_y = local_range.x
		bot_y = local_range.y
	var length: float = maxf(1.0, bot_y - top_y)
	var total: int = maxi(2, int(round(length / 10.0 * ROPE_PETAL_DENSITY_PER_10PX)))
	var half: int = total / 2

	var clockwise_texture: Texture2D = collection_texture
	var counterclockwise_texture: Texture2D = collection_texture
	var clockwise_size_scale: float = 1.0
	var counterclockwise_size_scale: float = 1.0
	if not coin_debris and is_rank_collectible_type(type_id):
		clockwise_texture = effect_texture(&"rank_collectible_connection_01", collection_texture)
		counterclockwise_texture = effect_texture(&"rank_collectible_connection_02", collection_texture)

		var inherited_size_scale: float = _skin_resources.collection_particle_size_correction(collection_texture)\
		if _skin_resources != null and feather_for_type(type_id) == null else 1.0
		if clockwise_texture != collection_texture:
			clockwise_size_scale = inherited_size_scale
		if counterclockwise_texture != collection_texture:
			counterclockwise_size_scale = inherited_size_scale
	_fire_rope_petals(ghost_x, top_y, bot_y, half, ROPE_PETAL_SPIN_MIN, ROPE_PETAL_SPIN_MAX, 
		tint, coin_debris, clockwise_texture, false, clockwise_size_scale)
	_fire_rope_petals(ghost_x, top_y, bot_y, total - half, 
		- ROPE_PETAL_SPIN_MAX, - ROPE_PETAL_SPIN_MIN, tint, coin_debris, counterclockwise_texture, false, counterclockwise_size_scale)




func _fire_rope_petals(x: float, top_y: float, bot_y: float, amount: int, 
		spin_min: float, spin_max: float, tint: Color, coin_debris: bool = false, 
		collection_texture: Texture2D = null, for_connection: bool = false, 
		size_scale: float = 1.0, speed_scale: float = 1.0, 
		particle_z: int = SLAM_FLY_Z - 1) -> GPUParticles2D:
	if amount <= 0 or (rope_petal_texture == null and collection_texture == null):
		return null
	var p: GPUParticles2D = _acquire_rope_petal_emitter(coin_debris or collection_texture != null)
	if p == null:
		return null
	var lifecycle: GpuParticleLifecycle = _rope_particle_lifecycles[p]
	lifecycle.reconfigure(_configure_rope_petals.bind(p, x, top_y, bot_y, amount, 
		spin_min, spin_max, tint, coin_debris, collection_texture, for_connection))
	p.z_index = particle_z
	var material: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	material.scale_min *= size_scale
	material.scale_max *= size_scale
	material.initial_velocity_min *= speed_scale
	material.initial_velocity_max *= speed_scale
	if not coin_debris:
		_apply_rank_collectible_particle_size(material, collection_texture, for_connection)
	lifecycle.play()
	return p



func _apply_rank_collectible_particle_size(material: ParticleProcessMaterial, texture: Texture2D, for_connection: bool) -> void :
	if _skin_resources == null or texture == null:
		return
	var width_range: Vector2 = _skin_resources.rank_collectible_particle_size(texture, for_connection)
	if width_range == Vector2.ZERO:
		return
	var texture_width: float = maxf(1.0, float(texture.get_width()))
	material.scale_min = width_range.x / texture_width
	material.scale_max = width_range.y / texture_width

func _configure_rope_petals(p: GPUParticles2D, x: float, top_y: float, bot_y: float, amount: int, 
		spin_min: float, spin_max: float, tint: Color, coin_debris: bool = false, 
		collection_texture: Texture2D = null, for_connection: bool = false) -> void :
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial

	var whole_texture: bool = coin_debris or collection_texture != null
	p.texture = bonus_coin_texture if coin_debris else (collection_texture if collection_texture != null else rope_petal_texture)
	p.material = null if whole_texture else _ensure_rope_petal_shader_mat()
	pm.particle_flag_disable_z = true
	var length: float = maxf(1.0, bot_y - top_y)
	var bird_feather: bool = collection_texture != null and _skin_resources != null and _skin_resources.active_skin.id == &"bird"
	p.top_level = bird_feather
	var emission_transform: = Transform2D(0.0, Vector2(x, (top_y + bot_y) * 0.5))
	if bird_feather:
		p.global_transform = (p.get_parent() as Node2D).global_transform * emission_transform
	else:
		p.transform = emission_transform
	p.amount = amount
	p.lifetime = ROPE_PETAL_LIFETIME
	pm.lifetime_randomness = ROPE_PETAL_LIFETIME_RAND
	p.one_shot = true
	p.explosiveness = 1.0


	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.5, length * 0.5, 0.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = ROPE_PETAL_SPEED_MIN
	pm.initial_velocity_max = ROPE_PETAL_SPEED_MAX

	pm.gravity = Vector3(0.0, ROPE_PETAL_GRAVITY, 0.0)



	var petal_v0_mid: float = (ROPE_PETAL_SPEED_MIN + ROPE_PETAL_SPEED_MAX) * 0.5
	var petal_damping: float = petal_v0_mid * (1.0 - ROPE_PETAL_END_SPEED_RATIO) / ROPE_PETAL_LIFETIME
	pm.damping_min = petal_damping
	pm.damping_max = petal_damping
	pm.angular_velocity_min = spin_min
	pm.angular_velocity_max = spin_max

	var cell_px: float = maxf(1.0, float(p.texture.get_width()) * (1.0 if whole_texture else 0.5))
	var s: float = ROPE_PETAL_SIZE / cell_px
	pm.scale_min = s * ROPE_PETAL_SIZE_MIN_RATIO
	pm.scale_max = s * ROPE_PETAL_SIZE_MAX_RATIO
	if coin_debris:

		pm.scale_min = 40.0 / float(bonus_coin_texture.get_width())
		pm.scale_max = 58.0 / float(bonus_coin_texture.get_width())
	elif collection_texture != null and _skin_resources != null and not bird_feather:
		var size_correction: float = _skin_resources.collection_particle_size_correction(collection_texture, for_connection)
		pm.scale_min *= size_correction
		pm.scale_max *= size_correction


	pm.anim_speed_min = 0.0
	pm.anim_speed_max = 0.0
	pm.anim_offset_min = 0.0
	pm.anim_offset_max = 1.0
	pm.color_ramp = _ensure_rope_petal_ramp()

	p.modulate = Color.WHITE if collection_texture != null and not coin_debris else tint

	p.visibility_rect = Rect2(-400.0, - length * 0.5 - 400.0, 800.0, length + 800.0)




func _ensure_rope_petal_shader_mat() -> ShaderMaterial:
	if _rope_petal_shader_mat == null:
		_rope_petal_shader_mat = ShaderMaterial.new()
		_rope_petal_shader_mat.shader = preload(
			"res://assets/effect/shader/particle_atlas_cell.gdshader")
		_rope_petal_shader_mat.set_shader_parameter("h_frames", 2.0)
		_rope_petal_shader_mat.set_shader_parameter("v_frames", 2.0)
	return _rope_petal_shader_mat



func _ensure_rope_petal_ramp() -> GradientTexture1D:
	if cold_start_optimized:
		return _ensure_rope_petal_ramp_optimized()
	if _rope_petal_ramp == null:


		var g: = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, ROPE_PETAL_FADE_FROM, 1.0])
		g.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), 
		])
		_rope_petal_ramp = GradientTexture1D.new()
		_rope_petal_ramp.gradient = g
	return _rope_petal_ramp


func _acquire_rope_petal_emitter(whole_texture: bool = false) -> GPUParticles2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var p: GPUParticles2D
	var pool: Array[GPUParticles2D] = _rope_whole_petal_pool if whole_texture else _rope_petal_pool
	if not pool.is_empty():
		p = pool.pop_back()
	else:
		p = GPUParticles2D.new()
		p.visible = false
		p.emitting = false
		p.visibility_rect = Rect2(-400.0, -400.0, 800.0, 800.0)
		p.texture = rope_petal_texture
		p.material = _ensure_rope_petal_shader_mat()
		var pm: = ParticleProcessMaterial.new()
		pm.particle_flag_disable_z = true
		p.process_material = pm

		p.z_index = SLAM_FLY_Z - 1
		p.local_coords = false
		_configure_rope_petals(p, 0.0, 0.0, 1.0, 1, 
			ROPE_PETAL_SPIN_MIN, ROPE_PETAL_SPIN_MAX, Color.WHITE)
		p.finished.connect(_release_rope_petal_emitter.bind(p))
	p.set_meta(&"whole_petal", whole_texture)
	if p.get_parent() != layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		layer.add_child(p)
	_prepare_rope_particle_lifecycle(p)
	return p


func _release_rope_petal_emitter(particle: Variant) -> void :
	if not is_instance_valid(particle):
		return
	var p: GPUParticles2D = particle as GPUParticles2D
	if p == null or p.has_meta(&"connection_warming"):
		return
	var pool: Array[GPUParticles2D] = _rope_whole_petal_pool if bool(p.get_meta(&"whole_petal", false)) else _rope_petal_pool
	if pool.has(p):
		return
	_rope_particle_lifecycles[p].reset_immediate()
	_connection_effects.erase(p)
	pool.append(p)








func _spawn_rope_stars(x: float, count_scale: float = 1.0, size_scale: float = 1.0, 
		row_y: float = 0.0, local_range: Vector2 = Vector2.ZERO) -> GPUParticles2D:
	var p: GPUParticles2D = _acquire_rope_star_emitter()
	if p == null:
		return null
	var lifecycle: GpuParticleLifecycle = _rope_particle_lifecycles[p]
	lifecycle.reconfigure(_configure_rope_stars.bind(p, x, count_scale, size_scale, row_y, local_range))
	lifecycle.play()
	var tw: Tween = p.create_tween()
	p.set_meta(&"rope_star_tween", tw)
	tw.tween_interval(ROPE_STAR_EMIT_DUR)
	tw.tween_callback(lifecycle.stop_with_tail)
	tw.tween_interval(ROPE_STAR_LIFETIME + 0.05)
	tw.tween_callback(_release_rope_star_emitter.bind(p))
	return p


func _configure_rope_stars(p: GPUParticles2D, x: float, count_scale: float, size_scale: float, 
		row_y: float, local_range: Vector2) -> void :
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	var top_y: float = _lay.rope_visible_top + row_y
	var bot_y: float = _lay.rope_bottom + row_y
	if local_range.y > local_range.x:
		top_y = local_range.x
		bot_y = local_range.y
	var length: float = maxf(1.0, bot_y - top_y)
	p.position = Vector2(x, (top_y + bot_y) * 0.5)
	p.lifetime = ROPE_STAR_LIFETIME
	p.amount = maxi(1, ceili(ROPE_STAR_RATE * ROPE_STAR_LIFETIME * count_scale))
	p.one_shot = false
	p.explosiveness = 0.0
	pm.lifetime_randomness = 0.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX


	var spawn_w: float = _lay.fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO
	pm.emission_box_extents = Vector3(spawn_w * 0.5, length * 0.5, 0.0)

	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 0.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	pm.gravity = Vector3.ZERO

	var tex_w: float = maxf(1.0, float(effect_texture(&"rope_star", ROPE_STAR_TEX).get_width()))
	pm.scale_min = _lay.fruit_d * ROPE_STAR_SIZE_MIN_RATIO * size_scale / tex_w
	pm.scale_max = _lay.fruit_d * ROPE_STAR_SIZE_MAX_RATIO * size_scale / tex_w
	pm.scale_curve = _ensure_rope_star_scale_curve()
	p.modulate = ROPE_STAR_COLOR
	p.visibility_rect = Rect2( - spawn_w * 0.5 - 100.0, - length * 0.5 - 100.0, 
		spawn_w + 200.0, length + 200.0)



func _ensure_rope_star_add_mat() -> CanvasItemMaterial:
	if _rope_star_add_mat == null:
		_rope_star_add_mat = CanvasItemMaterial.new()
		_rope_star_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _rope_star_add_mat


func _ensure_rope_star_scale_curve() -> CurveTexture:
	if cold_start_optimized:
		return _ensure_rope_star_scale_curve_optimized()
	if _rope_star_scale_curve == null:
		var c: = Curve.new()
		c.add_point(Vector2(0.0, 0.0))
		c.add_point(Vector2(0.5, 1.0))
		c.add_point(Vector2(1.0, 0.0))
		_rope_star_scale_curve = CurveTexture.new()
		_rope_star_scale_curve.curve = c
	return _rope_star_scale_curve


func _acquire_rope_star_emitter() -> GPUParticles2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var p: GPUParticles2D
	if not _rope_star_pool.is_empty():
		p = _rope_star_pool.pop_back()
	else:
		p = GPUParticles2D.new()
		p.visible = false
		p.emitting = false
		p.visibility_rect = Rect2(-100.0, -100.0, 200.0, 200.0)
		p.texture = effect_texture(&"rope_star", ROPE_STAR_TEX)


		p.material = _ensure_rope_star_add_mat()
		var pm: = ParticleProcessMaterial.new()
		pm.particle_flag_disable_z = true
		p.process_material = pm

		p.z_index = SLAM_FLY_Z + 1
		p.local_coords = false
		_configure_rope_stars(p, 0.0, 1.0, 1.0, 0.0, Vector2(0.0, 1.0))
	if p.get_parent() != layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		layer.add_child(p)
	_prepare_rope_particle_lifecycle(p)
	return p


func _release_rope_star_emitter(particle: Variant) -> void :
	if not is_instance_valid(particle):
		return
	var p: GPUParticles2D = particle as GPUParticles2D
	if p == null or _rope_star_pool.has(p) or p.has_meta(&"connection_warming"):
		return
	if p.has_meta(&"rope_star_tween"):
		var tw: Tween = p.get_meta(&"rope_star_tween") as Tween
		if tw != null and tw.is_valid():
			tw.kill()
		p.remove_meta(&"rope_star_tween")
	_rope_particle_lifecycles[p].reset_immediate()
	_connection_effects.erase(p)
	_rope_star_pool.append(p)



func _prepare_rope_particle_lifecycle(p: GPUParticles2D) -> void :
	if _rope_particle_lifecycles.has(p):
		return
	var lifecycle: = GpuParticleLifecycle.new()
	lifecycle.prepare([p], 2, _rope_particles_render_ready)
	_rope_particle_lifecycles[p] = lifecycle
	p.set_meta(&"skin_lifecycle", lifecycle)
	_common_skin_emitters.append(p)


func _rope_particles_render_ready() -> bool:
	if not is_inside_tree() or not is_visible_in_tree():
		return false
	var viewport: Viewport = get_viewport()
	return not viewport is SubViewport or (viewport as SubViewport).render_target_update_mode != SubViewport.UPDATE_DISABLED


func is_connection_particles_warmed() -> bool:
	return _connection_particles_warmed




func warm_connection_particles_render(active: Callable = Callable(), full_warmup: bool = true, checkpoint: Callable = Callable()) -> bool:
	if cold_start_optimized:
		return await warm_connection_particles_render_optimized(active, full_warmup, checkpoint)
	if _connection_particles_warmed:
		return true
	if DisplayServer.get_name() == "headless" or _connection_particles_warming or (active.is_valid() and not active.call()):
		return false
	var viewport: SubViewport = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer:
		SortLogger.error("JuiceBoardView connection warmup requires a detached SubViewport")
		return false
	if rope_petal_texture == null:
		SortLogger.error("JuiceBoardView connection warmup textures missing")
		return false
	_ensure_refs()
	_connection_preparation_generation += 1
	var generation: int = _connection_preparation_generation
	_connection_particles_warming = true
	var fruit_d: float = _lay.fruit_d if _lay.fruit_d > 0.0 else JuiceLockOverlay.DESIGN_FRUIT_D
	var layer: Node2D = _resolve_fruit_layer()
	var center: Vector2 = layer.get_global_transform_with_canvas().affine_inverse() * (Vector2(viewport.size) * 0.5)
	var top_y: float = center.y - fruit_d
	var bot_y: float = center.y + fruit_d
	var amount: int = maxi(1, int(round((bot_y - top_y) / 10.0 * ROPE_PETAL_DENSITY_PER_10PX)) / 2)
	var completed: bool = true
	var guard: Callable = func() -> bool:
		return is_inside_tree() and get_viewport() == viewport and generation == _connection_preparation_generation\
		and ( not active.is_valid() or active.call())
	for i: int in 3:
		if not guard.call():
			completed = false
			break
		var emitter: GPUParticles2D
		var saved_fruit_d: float = _lay.fruit_d
		_lay.fruit_d = fruit_d
		if i < 2:
			emitter = _acquire_rope_petal_emitter()
			emitter.set_meta(&"connection_warming", true)
			_connection_prepared_petals.append(emitter)
			var spin_min: float = ROPE_PETAL_SPIN_MIN if i == 0 else - ROPE_PETAL_SPIN_MAX
			var spin_max: float = ROPE_PETAL_SPIN_MAX if i == 0 else - ROPE_PETAL_SPIN_MIN
			_rope_particle_lifecycles[emitter].reconfigure(_configure_rope_petals.bind(emitter, 
				center.x, top_y, bot_y, amount, spin_min, spin_max, Color.WHITE))
		else:
			emitter = _acquire_rope_star_emitter()
			emitter.set_meta(&"connection_warming", true)
			_connection_prepared_stars = emitter
			_rope_particle_lifecycles[emitter].reconfigure(_configure_rope_stars.bind(emitter, 
				center.x, 1.0, 1.0, 0.0, Vector2(top_y, bot_y)))
		_lay.fruit_d = saved_fruit_d
		var stage: String = "connection_petals_%d" % i if i < 2 else "connection_stars"
		NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:%s" % stage)

		if not await _rope_particle_lifecycles[emitter].pre_render(guard, (0.12 if i < 2 else 0.05) if full_warmup else 0.0):
			completed = false
			break
		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:%s" % stage)
	if generation != _connection_preparation_generation:
		return false
	_release_prepared_connection_particles()
	_connection_particles_warming = false
	_connection_particles_warmed = completed and guard.call()
	return _connection_particles_warmed











func warm_effects_render(active: Callable = Callable(), ice: bool = true, mystery: bool = true, full_warmup: bool = true, checkpoint: Callable = Callable()) -> bool:
	if cold_start_optimized:
		return await warm_effects_render_optimized(active, ice, mystery, full_warmup, checkpoint)
	if active.is_valid() and not active.call():
		return false
	if mystery:
		var guard: Callable = active if active.is_valid() else func() -> bool: return is_inside_tree()
		if not await mystery_effects_for_skin(_skin_resources).prepare_render(self, guard, full_warmup):
			return false
		if not ice:
			return true
		mystery = false
	var viewport: = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer:
		SortLogger.error("JuiceBoardView warmup requires a detached SubViewport")
		return false
	_ensure_refs()
	_warming_effects = true

	var saved_fruit_d: float = _lay.fruit_d
	if _lay.fruit_d <= 0.0:
		_lay.fruit_d = JuiceLockOverlay.DESIGN_FRUIT_D

	var global_center: Vector2 = Vector2(viewport.size) * 0.5
	var center: Vector2 = get_global_transform().affine_inverse() * global_center
	var area: = Vector2(_lay.fruit_d * 1.2, _lay.fruit_d * 4.0)
	var tint: Color = Color.WHITE

	var spawns: Array[Callable] = [
		_spawn_unlock_spine.bind(center, area), 
		_spawn_unlock_leaves.bind(center, area), 
		_spawn_unlock_glows.bind(center, area, tint), 
		_spawn_mystery_reveal_petals.bind(global_center, tint, false, mystery_particle_texture(0)), 
		_spawn_mystery_reveal_glow.bind(global_center, tint), 
		_spawn_mystery_reveal_flash.bind(global_center, tint), 
		_spawn_mystery_reveal_star.bind(global_center, tint), 
	]

	var spawn_names: PackedStringArray = [
		"unlock_spine", "unlock_leaves", "unlock_glows", "mystery_petals", 
		"mystery_glow", "mystery_flash", "mystery_star", 
	]
	var completed: bool = true
	var guard: Callable = func() -> bool:
		return is_inside_tree() and get_viewport() == viewport and ( not active.is_valid() or active.call())
	for i in spawns.size():
		if (i < 3 and not ice) or (i >= 3 and not mystery):
			continue
		if active.is_valid() and not active.call():
			completed = false
			break
		NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:%s" % spawn_names[i])
		var previous_nodes: Array = _warm_effect_releases.keys()
		spawns[i].call()

		for node: CanvasItem in _warm_effect_releases:
			if node is GPUParticles2D and not previous_nodes.has(node):
				var lifecycle: GpuParticleLifecycle = node.get_meta(&"skin_lifecycle")
				if not await lifecycle.pre_render(guard, 0.12 if full_warmup else 0.0):
					completed = false
					break
		await RenderingServer.frame_post_draw
		if not completed:
			break

		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:%s" % spawn_names[i])

	NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:flush")
	_clear_warm_effects()
	_warming_effects = false
	for i in 2:
		await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:flush")
	_lay.fruit_d = saved_fruit_d
	return completed and ( not active.is_valid() or active.call())

func _track_warm_effect(node: CanvasItem, release: Callable) -> void :
	if _warming_effects:
		_warm_effect_releases[node] = release


func _create_warm_effect_tween(node: Node) -> Tween:
	var tw: Tween = node.create_tween()
	if _warming_effects:
		_warm_effect_tweens.append(tw)
	return tw


func _clear_warm_effects() -> void :

	for tw: Tween in _warm_effect_tweens:
		if tw.is_valid():
			tw.kill()
	_warm_effect_tweens.clear()
	for node: CanvasItem in _warm_effect_releases:
		if not is_instance_valid(node):
			continue
		if node is GPUParticles2D:

			(node.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
		_warm_effect_releases[node].call()
	_warm_effect_releases.clear()


func _play_lock_unlock_effects(unlocked: Array) -> void :
	for entry: Dictionary in unlocked:
		var ci: int = int(entry.get("col", -1))
		var overlay: JuiceLockOverlay = null
		for o: JuiceLockOverlay in _lock_overlay_live:
			if is_instance_valid(o) and o.visible and o.col == ci:
				overlay = o
		if overlay == null:
			continue
		if overlay.uses_wood_door():
			_spawn_wood_lock_unlock(overlay)
			continue

		var center: = Vector2(overlay.position.x + overlay.size.x * 0.5, 
			overlay.position.y + overlay.size.y * 0.5)
		_spawn_unlock_spine(center, overlay.size)
		_spawn_unlock_leaves(center, overlay.size)
		var col_type: int = int((_state["jars"] as Array[int])[ci])
		_spawn_unlock_glows(center, overlay.size, _unlock_glow_tint(col_type))
		_spawn_rope_stars(center.x, UNLOCK_STAR_COUNT_SCALE, UNLOCK_STAR_SIZE_SCALE)





func _unlock_glow_tint(type_id: int) -> Color:
	if _is_bonus_type(type_id):
		return JuiceTheme.color_of_slot(JuiceBonusLevel.YELLOW_SLOT, _skin)
	return color_for_type(type_id)


func _spawn_wood_lock_unlock(overlay: JuiceLockOverlay) -> WoodDoorLock:
	_stop_wood_reject_feedback(overlay.col)
	_shake.erase(overlay.col)
	var visual_token: int = int(_visual_token_by_col.get(overlay.col, -1))
	var source: WoodDoorLock = overlay.wood_door_view()
	if visual_token < 0 or not is_instance_valid(source) or _fx_layer == null:
		return null
	var effect: WoodDoorLock = _wood_unlock_pool.pop_back() if not _wood_unlock_pool.is_empty() else null
	if effect == null:
		effect = WOOD_DOOR_LOCK_SCENE.instantiate() as WoodDoorLock
	effect.configure(source.size, source.condition_texture(), source.remaining_count(), source.skin_visual(), source.skin_resources())
	effect.z_index = SLAM_FLY_Z + 2
	effect.col = overlay.col
	if effect.get_parent() == null:
		_fx_layer.add_child(effect)
		effect.finished.connect(_release_wood_lock_unlock.bind(effect))
	var placement: Transform2D = _fx_layer.get_global_transform().affine_inverse() * source.get_global_transform()
	effect.pivot_offset = Vector2.ZERO
	effect.position = placement.origin
	effect.rotation = placement.get_rotation()
	effect.scale = placement.get_scale()
	_wood_unlock_live.append(effect)
	_wood_unlock_tokens[effect] = visual_token
	if effect.col >= 0:
		_wood_unlock_offsets[effect] = effect.position.x - _col_x(effect.col)
	effect.play_shatter()
	return effect


func _release_wood_lock_unlock(effect: Variant) -> void :
	if not is_instance_valid(effect) or _wood_unlock_pool.has(effect):
		return
	effect.stop()
	_wood_unlock_live.erase(effect)
	_wood_unlock_offsets.erase(effect)
	_wood_unlock_tokens.erase(effect)
	_wood_unlock_pool.append(effect)



func _release_wood_unlock_for_token(visual_token: int) -> void :
	for effect: WoodDoorLock in _wood_unlock_live.duplicate():
		if int(_wood_unlock_tokens.get(effect, -1)) == visual_token:
			_release_wood_lock_unlock(effect)


func _clear_wood_unlock_effects() -> void :
	_clear_wood_reject_feedback()
	for effect: WoodDoorLock in _wood_unlock_live.duplicate():
		_release_wood_lock_unlock(effect)


func _update_wood_unlock_positions() -> void :
	for effect: WoodDoorLock in _wood_unlock_live.duplicate():
		var visual_token: int = int(_wood_unlock_tokens.get(effect, -1))
		if visual_token < 0 or not _slot_of.has(effect.col)\
		or int(_visual_token_by_col.get(effect.col, -1)) != visual_token:
			_release_wood_lock_unlock(effect)
			continue
		effect.position.x = _col_x(effect.col) + float(_wood_unlock_offsets.get(effect, 0.0))




func _spawn_unlock_spine(center: Vector2, area: Vector2) -> void :
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return
	var spr: SpineSprite = _unlock_spine_pool.pop_back() if not _unlock_spine_pool.is_empty()\
	else (UNLOCK_SPINE_SCENE.instantiate() as SpineSprite)
	if spr == null:
		return
	_track_warm_effect(spr, _release_unlock_spine.bind(spr))
	spr.visible = false

	spr.z_index = SLAM_FLY_Z + 2


	var s: float = _lay.fruit_d / JuiceLockOverlay.DESIGN_FRUIT_D
	var k: float = minf(JuiceLockOverlay.VINE_TEX_W * s / UNLOCK_SPINE_REF_SIZE.x, 
		area.y / UNLOCK_SPINE_REF_SIZE.y)
	spr.scale = Vector2.ONE * k

	spr.position = center - UNLOCK_SPINE_REF_CENTER * k
	if spr.get_parent() != layer:
		if spr.get_parent() != null:
			spr.get_parent().remove_child(spr)
		layer.add_child(spr)
	var skel: SpineSkeleton = spr.get_skeleton()
	var anim: SpineAnimationState = spr.get_animation_state()
	if skel == null or anim == null:
		spr.visible = true
		return
	anim.clear_tracks()
	skel.set_to_setup_pose()
	anim.set_animation(UNLOCK_SPINE_ANIM, false, 0)
	anim.update(0.0)
	anim.apply(skel)
	skel.update_world_transform(SpineConstant.Physics_Update)
	spr.visible = true
	var anim_def: SpineAnimation = skel.get_data().find_animation(UNLOCK_SPINE_ANIM)
	var dur: float = anim_def.get_duration() if anim_def != null else 1.5
	var tw: Tween = _create_warm_effect_tween(spr)
	tw.tween_interval(dur + 0.05)
	tw.tween_callback(_release_unlock_spine.bind(spr))


func _release_unlock_spine(spr: SpineSprite) -> void :
	if spr == null or not is_instance_valid(spr) or _unlock_spine_pool.has(spr):
		return
	var anim: SpineAnimationState = spr.get_animation_state()
	if anim != null:
		anim.clear_tracks()
	spr.visible = false
	_unlock_spine_pool.append(spr)





func _spawn_unlock_leaves(center: Vector2, area: Vector2) -> void :
	var p: GPUParticles2D = _acquire_unlock_leaf_emitter()
	if p == null:
		return
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	p.position = center
	p.amount = UNLOCK_LEAF_COUNT
	p.lifetime = UNLOCK_LEAF_LIFETIME
	pm.lifetime_randomness = UNLOCK_LEAF_LIFETIME_RAND
	p.one_shot = true
	p.explosiveness = 1.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x * 0.5, area.y * 0.5, 0.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = UNLOCK_LEAF_SPEED_MIN
	pm.initial_velocity_max = UNLOCK_LEAF_SPEED_MAX
	pm.gravity = Vector3(0.0, UNLOCK_LEAF_GRAVITY, 0.0)


	var v_mid: float = (UNLOCK_LEAF_SPEED_MIN + UNLOCK_LEAF_SPEED_MAX) * 0.5
	var damping: float = v_mid * (1.0 - UNLOCK_LEAF_END_SPEED_RATIO) / UNLOCK_LEAF_LIFETIME
	pm.damping_min = damping
	pm.damping_max = damping
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	var tex_w: float = maxf(1.0, float(effect_texture(&"unlock_leaf", UNLOCK_LEAF_TEX).get_width()))
	var base: float = _lay.fruit_d * UNLOCK_LEAF_SIZE_RATIO / tex_w
	pm.scale_min = base * (1.0 - UNLOCK_LEAF_SIZE_RANDOMNESS * 0.5)
	pm.scale_max = base * (1.0 + UNLOCK_LEAF_SIZE_RANDOMNESS * 0.5)
	pm.anim_speed_min = 0.0
	pm.anim_speed_max = 0.0
	pm.anim_offset_min = 0.0
	pm.anim_offset_max = 1.0
	pm.color_ramp = _ensure_rope_petal_ramp()
	p.modulate = Color.WHITE
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).play()


func _acquire_unlock_leaf_emitter() -> GPUParticles2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var p: GPUParticles2D
	if not _unlock_leaf_pool.is_empty():
		p = _unlock_leaf_pool.pop_back()
	else:
		p = GPUParticles2D.new()
		p.visible = false
		p.emitting = false
		p.visibility_rect = Rect2(-1400, -1400, 2800, 2800)
		p.texture = effect_texture(&"unlock_leaf", UNLOCK_LEAF_TEX)
		p.material = _ensure_rope_petal_shader_mat()
		var pm: = ParticleProcessMaterial.new()
		pm.particle_flag_disable_z = true
		p.process_material = pm
		p.z_index = SLAM_FLY_Z + 1
		p.local_coords = false
		p.finished.connect(_release_unlock_leaf_emitter.bind(p))
	if not p.has_meta(&"skin_lifecycle"):
		var lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
		lifecycle.prepare([p], 2, func() -> bool: return visible and modulate.a > 0.01)
		p.set_meta(&"skin_lifecycle", lifecycle)
		_common_skin_emitters.append(p)
	else:
		(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	if p.get_parent() != layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		layer.add_child(p)
	_track_warm_effect(p, _release_unlock_leaf_emitter.bind(p))
	return p


func _release_unlock_leaf_emitter(p: GPUParticles2D) -> void :
	if p == null or not is_instance_valid(p) or _unlock_leaf_pool.has(p):
		return
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	_unlock_leaf_pool.append(p)




func _spawn_unlock_glows(center: Vector2, area: Vector2, tint: Color) -> void :
	var p: GPUParticles2D = _acquire_unlock_glow_emitter()
	if p == null:
		return
	var pm: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	p.position = center
	p.amount = UNLOCK_GLOW_COUNT
	p.lifetime = UNLOCK_GLOW_LIFETIME
	pm.lifetime_randomness = UNLOCK_GLOW_LIFETIME_RAND
	p.one_shot = true
	p.explosiveness = 1.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(area.x * 0.5, area.y * 0.5, 0.0)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = UNLOCK_GLOW_SPEED_MIN
	pm.initial_velocity_max = UNLOCK_GLOW_SPEED_MAX
	pm.gravity = Vector3(0.0, UNLOCK_GLOW_GRAVITY, 0.0)
	var s: float = _lay.fruit_d * UNLOCK_GLOW_SIZE_RATIO / maxf(1.0, float(effect_texture(&"unlock_glow", UNLOCK_GLOW_TEX).get_width()))
	pm.scale_min = s
	pm.scale_max = s
	pm.color_ramp = _ensure_unlock_glow_ramp()
	p.modulate = tint
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).play()



func _ensure_unlock_glow_ramp() -> GradientTexture1D:
	if _unlock_glow_ramp == null:
		var g: = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), 
		])
		_unlock_glow_ramp = GradientTexture1D.new()
		_unlock_glow_ramp.gradient = g
	return _unlock_glow_ramp


func _acquire_unlock_glow_emitter() -> GPUParticles2D:
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	var p: GPUParticles2D
	if not _unlock_glow_pool.is_empty():
		p = _unlock_glow_pool.pop_back()
	else:
		p = GPUParticles2D.new()
		p.visible = false
		p.emitting = false
		p.visibility_rect = Rect2(-1400, -1400, 2800, 2800)
		p.texture = effect_texture(&"unlock_glow", UNLOCK_GLOW_TEX)
		var pm: = ParticleProcessMaterial.new()
		pm.particle_flag_disable_z = true
		p.process_material = pm

		p.z_index = SLAM_FLY_Z + 1
		p.local_coords = false
		p.finished.connect(_release_unlock_glow_emitter.bind(p))
	if not p.has_meta(&"skin_lifecycle"):
		var lifecycle: GpuParticleLifecycle = GpuParticleLifecycle.new()
		lifecycle.prepare([p], 2, func() -> bool: return visible and modulate.a > 0.01)
		p.set_meta(&"skin_lifecycle", lifecycle)
		_common_skin_emitters.append(p)
	else:
		(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	if p.get_parent() != layer:
		if p.get_parent() != null:
			p.get_parent().remove_child(p)
		layer.add_child(p)
	_track_warm_effect(p, _release_unlock_glow_emitter.bind(p))
	return p


func _release_unlock_glow_emitter(p: GPUParticles2D) -> void :
	if p == null or not is_instance_valid(p) or _unlock_glow_pool.has(p):
		return
	(p.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()
	_unlock_glow_pool.append(p)






func _spawn_mystery_reveal_petals(pos: Vector2, tint: Color, coin_debris: bool = false, 
		skin_particle: Texture2D = null) -> void :
	var effects: JuiceMysteryRevealEffects = _active_mystery_effects()
	effects._spawn_mystery_reveal_petals(pos, tint, coin_debris, skin_particle)

func _spawn_mystery_reveal_glow(pos: Vector2, tint: Color) -> void :
	_active_mystery_effects()._spawn_mystery_reveal_glow(pos, tint)

func _spawn_mystery_reveal_flash(pos: Vector2, tint: Color) -> void :
	_active_mystery_effects()._spawn_mystery_reveal_flash(pos, tint)

func _spawn_mystery_reveal_star(pos: Vector2, tint: Color) -> void :
	_active_mystery_effects()._spawn_mystery_reveal_star(pos, tint)

func _fire_mystery_petals(pos: Vector2, tint: Color, amount: int, 
		spin_min: float, spin_max: float, coin_debris: bool = false, skin_particle: Texture2D = null) -> void :
	_active_mystery_effects()._fire_mystery_petals(pos, tint, amount, spin_min, spin_max, coin_debris, skin_particle)


func mystery_effects_for_skin(resources: JuiceSkinResolver) -> JuiceMysteryRevealEffects:
	var paths: PackedStringArray = resources.warmup_asset_paths("mystery_reveal") if resources != null else PackedStringArray([
		MYSTERY_PETAL_TEX.resource_path, MYSTERY_GLOW_TEX.resource_path, MYSTERY_FLASH_TEX.resource_path, 
		MYSTERY_STAR_TEX.resource_path, "-", "-", "-", "-", "-", "-", "-", "-", "-", "-"])
	var key: String = "|".join(paths)
	var effects: JuiceMysteryRevealEffects = _mystery_effect_sets.get(key) as JuiceMysteryRevealEffects
	if not is_instance_valid(effects):
		effects = JuiceMysteryRevealEffects.new()
		effects.name = "MysteryRevealEffects"
		_mystery_effect_sets[key] = effects
		add_child(effects)
	effects.configure(resources, _lay.fruit_d if _lay.fruit_d > 0.0 else JuiceLockOverlay.DESIGN_FRUIT_D, 
		bonus_coin_texture, ROPE_PETAL_SIZE, ROPE_PETAL_SIZE_MIN_RATIO, ROPE_PETAL_SIZE_MAX_RATIO, SLAM_FLY_Z)
	return effects

func _active_mystery_effects() -> JuiceMysteryRevealEffects:
	var effects: JuiceMysteryRevealEffects = mystery_effects_for_skin(_skin_resources)
	effects.bind_layer(_resolve_fruit_layer())
	return effects

func skin_particle_emitters() -> Array[GPUParticles2D]:
	var result: Array[GPUParticles2D] = _common_skin_emitters.duplicate()
	for effects: JuiceMysteryRevealEffects in _mystery_effect_sets.values():
		result.append_array(effects.emitters)
	return result


static func sample_bonus_coin_motion(home: Vector2, mouth: Vector2, index: int, age: float) -> Dictionary:
	var fly_age: float = age - BURST_DUR - GHOST_FADE_DUR - float(index) * BONUS_DEPOSIT_STAGGER
	var lift: float = smoothstep(0.0, GHOST_FADE_DUR, age - BURST_DUR)
	var floated: Vector2 = home + Vector2(0.0, - SLAM_FLOAT_RISE * lift)
	if fly_age <= 0.0:
		return {"center": floated, "scale": 1.0, "done": false, "flight": false, "enter": 0.0}
	var u: float = clampf(fly_age / BONUS_DEPOSIT_FLY_DUR, 0.0, 1.0)

	var overhead: = mouth + Vector2(0.0, -100.0)
	var rise: float = smoothstep(0.0, 0.72, u)
	var fall: float = clampf((u - 0.72) / 0.28, 0.0, 1.0)
	var side: float = -1.0 if index % 2 == 0 else 1.0
	var center: Vector2 = floated.lerp(overhead, rise) + Vector2(side * 36.0 * sin(PI * rise), 0.0)
	if u >= 0.72:
		center = overhead.lerp(mouth, fall * fall)
	var enter: float = smoothstep(0.92, 1.0, u)
	return {"center": center, "scale": lerpf(1.0, 0.72, rise) * lerpf(1.0, 0.15, enter), 
		"done": u >= 1.0, "flight": true, "enter": enter}


func _update_bonus_deposit_nodes(beat: Dictionary, age: float) -> void :
	beat["bonus_sequential"] = true
	if age < BURST_DUR:
		_update_burst_stage(beat, age)
		return
	var x: float = float(beat["ghost_x"])
	var mouth: = Vector2(x, float(beat["ghost_top"]) + float(beat["ghost_h"]) * SLAM_MOUTH_RATIO)
	var nodes: Array = beat["nodes"]
	var ribbons: Array = beat["trail_ribbons"]
	var arrived: Dictionary = beat.get("bonus_arrived", {})
	beat["bonus_arrived"] = arrived
	for j: int in nodes.size():
		var coin: JuiceFruit = nodes[j]
		if not is_instance_valid(coin):
			continue
		var home: = Vector2(x, _lay.fruit_y(j) + float(beat.get("row_y", 0.0)))
		var motion: Dictionary = sample_bonus_coin_motion(home, mouth, j, age)
		_set_drag_top_level(coin, true)
		_set_fruit_layer_pos(coin, motion.center)
		coin.global_scale = _fruit_layer.global_scale * float(motion.scale)
		coin.rotation = 0.0
		coin.z_index = SLAM_FLY_Z
		coin.modulate.a = 1.0
		coin.visible = not bool(motion.done)
		if motion.done:
			if not arrived.has(j):
				arrived[j] = true
				_play_skin_sound(&"bonus_coin_impact")
				_ensure_bonus_entry_feedback().start(global_position + mouth, 1, beat.get("blender") as JuiceBlender, true)
			if j < ribbons.size() and ribbons[j] != null:
				_finish_coin_trail(beat, ribbons[j] as FireworkTrails.Ribbon)
				ribbons[j] = null
			continue
		if motion.flight:
			_absorb_coin_trail(beat, j, float(motion.enter))
			if j < ribbons.size() and ribbons[j] == null:
				ribbons[j] = _ensure_bonus_gold_trails().add_ribbon(coin, _lay.fruit_d * SLAM_TRAIL_WIDTH_RATIO, 
					_beat_flower_color(beat), SLAM_TRAIL_HEAD_ALPHA, SLAM_TRAIL_LIFETIME)


func take_bird_handoff(nth: int) -> JuiceBirdCollection:
	var visual: JuiceBirdCollection = _bird_handoffs.get(nth) as JuiceBirdCollection
	_bird_handoffs.erase(nth)
	if is_instance_valid(visual):
		_bird_collections.erase(visual)

		for beat: Dictionary in _beats:
			if int(beat["nth"]) == nth:
				beat["bird_visual"] = null
	return visual


func cancel_bird_collections() -> void :
	for visual: JuiceBirdCollection in _bird_collections:
		if is_instance_valid(visual):
			visual.hide()
			visual.queue_free()
	_bird_collections.clear()
	_bird_handoffs.clear()


func _advance_bird_house(beat: Dictionary, age: float) -> void :
	if age < 0.0:
		return
	if not bool(beat["bird_visual_started"]):
		beat["bird_visual_started"] = true
		var blender: JuiceBlender = beat.get("blender") as JuiceBlender
		if not is_instance_valid(blender):
			return
		var body: Sprite2D = blender.get_node("Body") as Sprite2D
		var source: Rect2 = _bird_layer.global_transform.affine_inverse() * (body.global_transform * body.get_rect())
		var visual: = JuiceBirdCollection.new()
		visual.setup(_skin_resources.active_skin, 
			_skin_resources.color_visual(JuiceTheme.COLOR_KEYS[slot_for_type(int(beat["fruit"]))], &"empty_container"), 
			completed_visual(int(beat["fruit"])), source, 
			_skin_resources.color_texture(JuiceTheme.COLOR_KEYS[slot_for_type(int(beat["fruit"]))], &"door_atlas"), 
			_skin_resources.color_texture(JuiceTheme.COLOR_KEYS[slot_for_type(int(beat["fruit"]))], &"open_house"))
		_bird_layer.add_child(visual)
		_bird_collections.append(visual)
		beat["bird_visual"] = visual
		blender.hide()
	var visual: JuiceBirdCollection = beat.get("bird_visual") as JuiceBirdCollection
	if is_instance_valid(visual) and not bool(beat["cup_sent"]):
		visual.advance_open(age)
		var entry_duration: float = maxf(JuiceBirdCollection.BIRD_STAGGER, 
			float(maxi(0, int(beat["q"]) - 1)) * JuiceBirdCollection.BIRD_STAGGER)
		visual.advance_entry_feedback(age - JuiceBirdCollection.RISE_DURATION - SLAM_FLY_DUR, entry_duration)
		if age >= JuiceBirdCollection.RISE_DURATION and not bool(beat.get("bird_hover_sent", false)):
			beat["bird_hover_sent"] = true
			bird_house_hovered.emit(visual)


func _update_slam_nodes(beat: Dictionary, age: float) -> void :
	var x: float = float(beat["ghost_x"])
	var mouth: Vector2 = Vector2(x, 
		float(beat["ghost_top"]) + float(beat["ghost_h"]) * SLAM_MOUTH_RATIO)
	var nodes: Array = beat["nodes"]

	var lead: float = float(beat.get("lead", 0.0))
	if lead > 0.0 and age < 0.0:
		_update_lead_nodes(beat, lead + age, lead)
		return
	if not bool(beat.get("lead_done", true)):
		_update_lead_nodes(beat, lead, lead)
		beat["lead_done"] = true
		for f_done: JuiceFruit in nodes:
			if is_instance_valid(f_done):
				_set_drag_top_level(f_done, false)
				f_done.z_index = 0
	var arrival_positions: PackedVector2Array = beat.get("complete_column_arrival", PackedVector2Array())
	if not arrival_positions.is_empty():
		var arrival_progress: float = smoothstep(0.0, BURST_PULSE_UP_DUR, age)
		for index: int in nodes.size():
			var fruit: JuiceFruit = nodes[index]
			if not is_instance_valid(fruit):
				continue
			var home: Vector2 = Vector2(x, _lay.fruit_y(index) + float(beat["row_y"]))
			_set_fruit_layer_pos(fruit, arrival_positions[index].lerp(home, arrival_progress))
		if arrival_progress >= 1.0:
			beat.erase("complete_column_arrival")
	if _is_bonus_type(int(beat["fruit"])) and not bool(beat.get("preview", false)):
		_update_bonus_deposit_nodes(beat, age)
		return
	var bird: bool = bool(beat.get("bird", false))
	if bird:
		_advance_bird_house(beat, age)
		var visual: JuiceBirdCollection = beat.get("bird_visual") as JuiceBirdCollection
		if is_instance_valid(visual):
			mouth = get_global_transform().affine_inverse() * visual.mouth_global_position()



	var burst: float = _burst_dur(beat)
	if age < burst:
		if not bird or age < BURST_DUR:
			_update_burst_stage(beat, age)
		return
	age -= burst
	if bird:
		for tween: Tween in beat["burst_tweens"]:
			if tween.is_valid():
				tween.kill()
		(beat["burst_tweens"] as Array).clear()
		age += GHOST_FADE_DUR
	var spin_deg: PackedFloat32Array = beat["spin_deg"]
	var trail_ribbons: Array = beat["trail_ribbons"]
	for j in nodes.size():
		var f: JuiceFruit = nodes[j]
		if not is_instance_valid(f):
			continue
		f.visible = true
		f.z_index = SLAM_FLY_Z

		f.modulate.a = 1.0

		var home: Vector2 = Vector2(x, _lay.fruit_y(j) + float(beat.get("row_y", 0.0)))
		if age < GHOST_FADE_DUR:





			var motion: Dictionary = sample_collection_motion(home, mouth, j, age)
			f.position = motion["center"]
			f.scale = Vector2.ONE * float(motion["scale"])
			f.rotation = 0.0
			continue



		var fly_age: float = age - GHOST_FADE_DUR
		if bird:
			fly_age = maxf(0.0, fly_age - float(j) * JuiceBirdCollection.BIRD_STAGGER)
		var u: float = clampf(fly_age / SLAM_FLY_DUR, 0.0, 1.0)
		if u >= 1.0:
			if bird:
				var arrivals: Dictionary = beat.get("bird_arrivals", {})
				if not arrivals.has(j):
					arrivals[j] = true
					beat["bird_arrivals"] = arrivals
					if j == 1:
						var visual: JuiceBirdCollection = beat.get("bird_visual") as JuiceBirdCollection
						if is_instance_valid(visual):
							visual.fill()
					var feather: Texture2D = _beat_feather(beat)
					if j == 0 and feather != null and not bool(beat.get("bird_feather_sent", false)):
						beat["bird_feather_sent"] = true
						var amount: int = randi_range(9, 12)
						beat["bird_feather_amount"] = amount
						_fire_rope_petals(mouth.x, mouth.y, mouth.y, amount, 
							- ROPE_PETAL_SPIN_MAX, ROPE_PETAL_SPIN_MAX, Color.WHITE, false, feather, false, 1.3, 1.2, SLAM_FLY_Z + 2)
			f.visible = false

			var done_ribbon: Variant = trail_ribbons[j] if j < trail_ribbons.size() else null
			if done_ribbon != null:
				_finish_coin_trail(beat, done_ribbon as FireworkTrails.Ribbon)
				trail_ribbons[j] = null
			continue
		var eased: float = 1.0 - cos(u * PI * 0.5)





		var arc_dir: float = -1.0 if j % 2 == 0 else 1.0


		var flight_home: Vector2 = home + Vector2(0.0, SLAM_FLOAT_RISE) if bird else home
		var motion: Dictionary = sample_collection_motion(flight_home, mouth, j, 
			GHOST_FADE_DUR + fly_age if bird else age)
		if bird:
			_set_drag_top_level(f, true)
			_set_fruit_layer_pos(f, motion["center"])
		else:
			f.position = motion["center"]





		f.scale = Vector2.ONE * float(motion["scale"])
		if bird:
			var entry: float = smoothstep(SLAM_FLY_DUR - 0.1, SLAM_FLY_DUR, fly_age)
			f.scale *= lerpf(1.0, 0.25, entry)
		if _is_bonus_type(int(beat["fruit"])):

			var enter: float = smoothstep(SLAM_FLY_DUR - 0.08, SLAM_FLY_DUR, fly_age)
			f.scale *= lerpf(1.0, 0.15, enter)
			f.modulate.a = 1.0 - smoothstep(0.55, 1.0, enter)
			_absorb_coin_trail(beat, j, enter)





		var rot_dir: float = - arc_dir
		f.rotation = sin(eased * PI * 2.0) * 0.12 if bird else deg_to_rad(spin_deg[j]) * rot_dir * eased

		if j < trail_ribbons.size() and trail_ribbons[j] == null:
			var trails: FireworkTrails
			if _is_bonus_type(int(beat["fruit"])):
				trails = _ensure_bonus_gold_trails()
			elif is_rank_collectible_type(int(beat["fruit"])):
				trails = _ensure_rank_collectible_fly_trails()
			else:
				trails = _ensure_fly_trails()
			if trails != null:
				trail_ribbons[j] = trails.add_ribbon(
					f, _lay.fruit_d * SLAM_TRAIL_WIDTH_RATIO, 
					_beat_flower_color(beat), 
					SLAM_TRAIL_HEAD_ALPHA, SLAM_TRAIL_LIFETIME)




func _enqueue_shift(from_by_col: Dictionary, base_x: float, start_at: float) -> void :
	var from: Dictionary = {}
	var dst: Dictionary = {}
	var delay: Dictionary = {}
	for c in _order:
		var ci: int = int(c)
		var token: Variant = _visual_token_by_col.get(ci)
		if token == null:
			continue
		var visual_token: int = int(token)
		var from_x: float = float(from_by_col.get(ci, 
			_planned_x.get(visual_token, _base_x(ci))))
		var dst_x: float = _base_x(ci)
		from[visual_token] = from_x
		dst[visual_token] = dst_x
		delay[visual_token] = minf(DOMINO_MAX, 
			(absf(from_x - base_x) / maxf(1.0, _lay.col_w)) * DOMINO_PER_COL)
		if not _visual_x.has(visual_token):
			_visual_x[visual_token] = from_x
		_planned_x[visual_token] = dst_x
	_shift_queue.append({
		"start_at": start_at, 
		"dur": SLIDE_DUR, 
		"from": from, 
		"dst": dst, 
		"delay": delay, 
		"started": false, 
		"collect_batch": false, 
		"sfx": true, 
	})
	_sync_last_col_x()





func _enqueue_replacement(ci: int, inc: Dictionary, spawns: Array, start_at: float, 
		ghost_x: float, wait_for_melt: Dictionary = {}, waiting_shift: Dictionary = {}) -> Dictionary:
	var from: Dictionary = {}
	for c: int in _order:
		if c != ci:
			from[c] = _planned_col_x(c)
	var slot: String = String(inc.get("slot", JuiceLevel.SLOT_RETIRE))
	var keep: bool = slot != JuiceLevel.SLOT_RETIRE
	_reslot_after_collect(ci, keep)
	_visual_token_by_col.erase(ci)
	_solve_layout()
	if keep:
		var jar: int = int(inc.get("jar", R.NO_JAR)) if slot == JuiceLevel.SLOT_JAR else R.NO_JAR
		var start_x: float = size.x + _lay.col_w * 1.2
		_new_visual_token(ci, start_x)
		var blender: JuiceBlender = _make_blender_for_type(ci, jar)
		if blender != null:
			from[ci] = start_x
			blender.position.x = start_x
	var shift: Dictionary = _enqueue_collect_shift(from, ghost_x, start_at)
	if not wait_for_melt.is_empty() and not bool(wait_for_melt["released"]):
		var held: Array = shift.get("melt_batches", [])
		if not held.has(wait_for_melt):
			held.append(wait_for_melt)
		shift["melt_batches"] = held
	if not waiting_shift.is_empty():
		shift["waiting_collects"] = int(shift.get("waiting_collects", 0)) + 1

	_spawn_nodes(spawns)
	return shift


func _enqueue_collect_shift(from_by_col: Dictionary, base_x: float, start_at: float) -> Dictionary:
	var shift: Dictionary = {}
	if not _shift_queue.is_empty():
		var tail: Dictionary = _shift_queue[-1]
		if bool(tail.get("collect_batch", false)) and not bool(tail.get("started", false)):
			shift = tail
	if shift.is_empty():
		shift = {
			"start_at": start_at, 
			"dur": SLIDE_DUR, 
			"from": {}, 
			"dst": {}, 
			"delay": {}, 
			"bases": [base_x], 
			"started": false, 
			"collect_batch": true, 
			"sfx": true, 
		}
		_shift_queue.append(shift)
	else:
		shift["start_at"] = maxf(float(shift["start_at"]), start_at)
		(shift["bases"] as Array).append(base_x)

	var old_from: Dictionary = shift["from"]
	var from: Dictionary = {}
	var dst: Dictionary = {}
	var delay: Dictionary = {}
	var bases: Array = shift["bases"]
	for c in _order:
		var ci: int = int(c)
		var token: Variant = _visual_token_by_col.get(ci)
		if token == null:
			continue
		var visual_token: int = int(token)
		var from_x: float = float(old_from.get(visual_token, from_by_col.get(ci, 
			_planned_x.get(visual_token, _base_x(ci)))))
		var dst_x: float = _base_x(ci)
		var nearest_base: float = INF
		for raw_base: Variant in bases:
			nearest_base = minf(nearest_base, absf(from_x - float(raw_base)))
		from[visual_token] = from_x
		dst[visual_token] = dst_x
		delay[visual_token] = minf(DOMINO_MAX, 
			(nearest_base / maxf(1.0, _lay.col_w)) * DOMINO_PER_COL)
		if not _visual_x.has(visual_token):
			_visual_x[visual_token] = from_x
		_planned_x[visual_token] = dst_x
	shift["from"] = from
	shift["dst"] = dst
	shift["delay"] = delay
	_sync_last_col_x()
	return shift


func _advance_shifts() -> void :
	if _t < _collect_hold_until:
		return
	if _collect_hold_since >= 0.0:

		if not _shift_queue.is_empty():
			var held_shift: Dictionary = _shift_queue[0]
			if bool(held_shift["started"]):
				held_shift["start_at"] = float(held_shift["start_at"]) + _t - _collect_hold_since
			else:
				held_shift["start_at"] = maxf(float(held_shift["start_at"]), _t)
		_collect_hold_since = -1.0
		_collect_hold_until = -1.0

	if _shift_queue.is_empty():
		return
	var first_shift_in_call: bool = true
	while not _shift_queue.is_empty():
		var shift: Dictionary = _shift_queue[0]
		for batch: Dictionary in shift.get("melt_batches", []) as Array:
			if not bool(batch.get("released", false)):
				return

		if int(shift.get("waiting_collects", 0)) > 0:
			return
		if _t < float(shift["start_at"]):
			return
		if not bool(shift.get("started", false)):

			if not first_shift_in_call:
				shift["start_at"] = _t
			shift["started"] = true
			if bool(shift.get("sfx", false)):
				_play_skin_sound(&"juice_whoosh")
		var from: Dictionary = shift["from"]
		var dst: Dictionary = shift["dst"]
		var delay: Dictionary = shift["delay"]
		var complete: bool = true
		for raw_token: Variant in dst:
			var token: int = int(raw_token)
			var token_start: float = float(shift["start_at"]) + float(delay.get(token, 0.0))
			if _t >= token_start and _legacy_replenish_pending.has(token):
				for flower: JuiceFruit in (_legacy_replenish_pending[token] as Array):
					flower.visible = true
				_legacy_replenish_pending.erase(token)
			var u: float = clampf((_t - token_start) / float(shift["dur"]), 0.0, 1.0)
			var eased: float = 1.0 - pow(1.0 - u, 3.0)
			_visual_x[token] = lerpf(float(from[token]), float(dst[token]), eased)
			if u < 1.0:
				complete = false
		if not complete:
			return
		shift["finished"] = true
		_shift_queue.pop_front()
		first_shift_in_call = false


	_refresh_blenders()
	_refresh_lock_overlays()
	if _beats.is_empty() and _shift_queue.is_empty():
		_trail_preview_settle_pending = false
		_snap_all_home()
		_check_over()
		settled.emit()
	elif not _beats.is_empty():
		var shift_real_left: = false
		for beat: Dictionary in _beats:
			if not bool(beat.get("preview", false)):
				shift_real_left = true
				break
		if not shift_real_left:
			_trail_preview_settle_pending = true



func _replenish_column_pending(ci: int) -> bool:
	var token: int = int(_visual_token_by_col.get(ci, -1))
	if _legacy_replenish_pending.has(token):
		return true
	return false



func _spawn_nodes(spawns: Array) -> void :
	for s: Dictionary in spawns:
		var ci: int = int(s["col"])
		var token: int = int(_visual_token_by_col.get(ci, -1))

		var waiting: bool = _col_x(ci) > size.x
		if waiting and not _legacy_replenish_pending.has(token):
			_legacy_replenish_pending[token] = []
		var types: Array = s["types"]
		var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
		for i in types.size():
			var idx: int = list.size()
			var f: JuiceFruit = _make_fruit(ci, idx, int(types[i]))
			if f == null:
				continue
			var side: float = 1.0 if idx % 2 == 1 else -1.0
			f.position = _home_pos_swayed(ci, idx)\
			+ Vector2(side * _lay.gap * 0.95, _lay.gap * 2.2)
			f.rotation = side * 1.15
			if waiting:
				f.visible = false
				(_legacy_replenish_pending[token] as Array).append(f)
			list.append(f)
		_fruit_nodes[ci] = list
	_reindex_all()


func _reindex_all() -> void :
	for ci in _fruit_nodes:
		_reindex(ci)


func _finish_beat(beat: Dictionary) -> void :
	var bird_visual: JuiceBirdCollection = beat.get("bird_visual") as JuiceBirdCollection
	if is_instance_valid(bird_visual) and _bird_collections.has(bird_visual):
		_bird_collections.erase(bird_visual)
		_bird_handoffs.erase(int(beat["nth"]))
		bird_visual.queue_free()


	for r in (beat.get("trail_ribbons", []) as Array):
		if r != null:
			_finish_coin_trail(beat, r as FireworkTrails.Ribbon)


	for tw in (beat.get("burst_tweens", []) as Array):
		if tw != null and (tw as Tween).is_valid():
			(tw as Tween).kill()


	for f in (beat["nodes"] as Array):
		if is_instance_valid(f):
			_fruit_pool.release(f)
	(beat["nodes"] as Array).clear()
	var blender: Variant = beat.get("blender")
	if blender != null and is_instance_valid(blender) and blender != _bonus_handoff_source:
		_blender_pool.release(blender as JuiceBlender)
	beat["blender"] = null
	var visual_token: int = int(beat.get("visual_token", -1))
	if visual_token >= 0:
		_visual_x.erase(visual_token)
		_planned_x.erase(visual_token)




func _process(delta: float) -> void :
	if tutorial_demo_only:
		delta *= motion_preview_speed
	_tick_sunlight_collection(delta)
	_poll_closed_check()
	_poll_death_attribution()
	_poll_safe_return()
	if _endless_session == null and is_visible_in_tree() and not is_busy() and _drag.is_empty():
		_start_safe_return_search()
	_poll_challenge_check()
	_poll_lucky_reveal_check()
	if _level == null:
		return
	_t += delta
	if not _capacity_error_hint.is_empty():
		_place_drop_hover()
	if not _capacity_error_hint.is_empty() and _t - float(_capacity_error_hint["start"]) >= float(_capacity_error_hint["duration"]):
		clear_capacity_error_hint()

	if not _complete_column_flight.is_empty():
		_advance_complete_column_flight()
		queue_redraw()
		if not _complete_column_flight.is_empty():
			return
	_advance_entrance_wind(delta)
	_advance_shake(delta)
	_advance_shifts()
	_update_wood_unlock_positions()
	_advance_beats()
	_sync_hint_demo()
	_advance_drag_match_highlight()
	_update_fruits(delta)
	_advance_return()
	_advance_connection_feedback()
	_refresh_capacity_labels()

	if not _drag.is_empty():
		_update_hover()
	if not _col_mark_live.is_empty():
		_refresh_col_mark_positions()
	var animating: bool = not _beats.is_empty() or not _shift_queue.is_empty()\
	or not _drag.is_empty() or not _shake.is_empty() or not _capacity_error_hint.is_empty()

	if animating:
		_refresh_blenders()


	if animating or _ambient_sway_on() or _wind_active:
		queue_redraw()
	if animating:
		_refresh_lock_overlays()
	elif _ambient_sway_on() or _wind_active:
		_update_lock_overlay_lean()



	if _drag_rope_layer != null:
		if not _drag.is_empty():
			_drag_rope_layer.global_transform = get_global_transform()
		_drag_rope_layer.queue_redraw()



func _hit_wood_locked_column(pos: Vector2) -> int:
	if resolved_lock_visual_version() != 3:
		return -1
	var global_pos: Vector2 = get_global_transform() * pos
	for overlay: JuiceLockOverlay in _lock_overlay_live:
		if not is_instance_valid(overlay) or not overlay.visible or not R.is_locked(_state, overlay.col):
			continue
		var door: WoodDoorLock = overlay.wood_door_view()
		if not is_instance_valid(door):
			continue
		var local_pos: Vector2 = door.get_global_transform().affine_inverse() * global_pos
		if Rect2(Vector2.ZERO, door.size).has_point(local_pos):
			return overlay.col
	return -1


func _start_column_reject_shake(ci: int) -> void :
	_shake[ci] = 0.0
	if resolved_lock_visual_version() != 3 or not R.is_locked(_state, ci):
		return

	if not _wood_reject_hidden.has(ci):
		var hidden: Array[Dictionary] = []
		var flowers: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
		for flower: JuiceFruit in flowers:
			if is_instance_valid(flower):
				hidden.append({"node": flower, "visible": flower.visible})
				flower.hide()
		_wood_reject_hidden[ci] = hidden
	for overlay: JuiceLockOverlay in _lock_overlay_live:
		if is_instance_valid(overlay) and overlay.col == ci:
			var door: WoodDoorLock = overlay.wood_door_view()
			if is_instance_valid(door):
				door.set_reject_time(0.0)


func _stop_wood_reject_feedback(ci: int) -> void :

	for overlay: JuiceLockOverlay in _lock_overlay_live:
		if is_instance_valid(overlay) and overlay.col == ci:
			var door: WoodDoorLock = overlay.wood_door_view()
			if is_instance_valid(door):
				door.set_reject_time(0.0)
	for entry: Dictionary in (_wood_reject_hidden.get(ci, []) as Array):
		var flower: Variant = entry["node"]
		if is_instance_valid(flower) and flower.col == ci:
			flower.visible = bool(entry["visible"])
	_wood_reject_hidden.erase(ci)


func _clear_wood_reject_feedback() -> void :
	for ci: int in _wood_reject_hidden.keys():
		_stop_wood_reject_feedback(ci)
		_shake.erase(ci)


func _advance_shake(delta: float) -> void :
	if _shake.is_empty():
		return
	var done: Array = []
	for ci in _shake:
		var t: float = float(_shake[ci]) + delta
		_shake[ci] = t
		if t >= 0.32:
			done.append(ci)
	for ci in done:
		if _wood_reject_hidden.has(ci):
			_stop_wood_reject_feedback(int(ci))
		_shake.erase(ci)



func set_same_color_highlight_enabled(enabled: bool) -> void :
	_same_color_highlight_enabled = enabled
	if not enabled:
		_stop_drag_match_highlight()


func _stop_drag_match_highlight(immediate: bool = false) -> void :
	for flower: JuiceFruit in _drag_match_highlight_fruits:
		if is_instance_valid(flower):
			flower.stop_breathing_group_highlight(immediate)
	if immediate:
		_drag_match_highlight_fruits.clear()





func _advance_drag_match_highlight() -> void :
	if not _same_color_highlight_enabled or _drag.is_empty():
		return
	var nodes: Array = _drag.get("nodes", [])
	if nodes.is_empty():
		return
	var color: int = (nodes[0] as JuiceFruit).fruit_type
	if color < 0 or R.is_connection_blocked(_state, color):
		return
	color = JuiceLevel.connection_type(color)

	var active: Array[JuiceFruit] = []
	for flower: JuiceFruit in _drag_match_highlight_fruits:
		if is_instance_valid(flower) and flower.is_breathing_group_highlight_active():
			active.append(flower)
	_drag_match_highlight_fruits = active
	for ci: int in _fruit_nodes:
		if R.is_locked(_state, ci) or bool((_state["gone"] as Array)[ci]):
			continue
		for flower: JuiceFruit in _fruit_nodes[ci]:
			if not is_instance_valid(flower) or not flower.visible\
			or R.is_connection_blocked(_state, flower.fruit_type)\
			or JuiceLevel.connection_type(flower.fruit_type) != color\
			or nodes.has(flower) or _return.has(flower):
				continue
			if flower.play_breathing_group_highlight(DRAG_MATCH_HIGHLIGHT_PERIOD)\
			and not _drag_match_highlight_fruits.has(flower):
				_drag_match_highlight_fruits.append(flower)







func _update_fruits(delta: float) -> void :
	_advance_color_reject_hold()
	var k: float = 1.0 - exp( - EASE_RATE * delta)
	var drag_nodes: Array = _drag.get("nodes", [])
	var drag_pos: Vector2 = _drag.get("pos", Vector2.ZERO)
	var grab: Vector2 = _drag.get("grab", Vector2.ZERO)
	var drag_gap: float = _lay.gap
	if not _drag.is_empty():
		var grip: float = lerpf(float(_drag["grip"]), 1.0, k)
		_drag["grip"] = grip
		drag_gap = _lay.gap * lerpf(1.0, DRAG_GAP_RATIO, grip)

		_advance_drag_chain(delta, drag_gap)

	var wind_rigid: bool = _wind_is_rigid()
	for ci in _fruit_nodes:
		var fruit_x: float = _col_x(int(ci)) + _shake_dx(int(ci))
		var col_dx: float = fruit_x - float(_last_col_x.get(ci, fruit_x))

		var rigid_line: bool = _col_wind_is_rigid_line(int(ci))
		var rigid_wind_slope: float = _col_entrance_wind_slope(int(ci)) if rigid_line else 0.0
		var list: Array[JuiceFruit] = _fruit_nodes[ci]
		for i in list.size():
			var f: JuiceFruit = list[i]
			if not is_instance_valid(f):
				continue
			if _apply_color_reject_hold(f):
				continue
			if not drag_nodes.is_empty():
				var di: int = drag_nodes.find(f)
				if di >= 0:



					var shown: PackedFloat32Array = _drag["shown"]
					var drag_local_pos: = Vector2(shown[di], 
						drag_pos.y - grab.y + float(di) * drag_gap)

					if f.top_level:
						f.global_position = get_global_transform() * drag_local_pos
					else:
						f.position = drag_local_pos
					var target_scale: float = DRAG_LEADING_FLOWER_SCALE if di == 0 else DRAG_SCALE

					f.scale = f.scale.lerp(Vector2.ONE * target_scale, k)


					var rot: PackedFloat32Array = _drag["rot"]
					f.rotation = lerpf(f.rotation, rot[di], 
						1.0 - exp( - DRAG_TILT_RATE * delta))
					continue
			var local_pos: Vector2 = _fruit_layer_pos(f)


			local_pos.x += col_dx



			var home_y: float = _lay.fruit_y(i) + _row_y(int(ci))

			var wind_slope: float = rigid_wind_slope if rigid_line else _wind_curve_slope(home_y - _row_y(int(ci)))
			var wind_dx: float = rigid_wind_slope * (home_y - _lay.hang_top - _row_y(int(ci))) if rigid_line\
			else _wind_curve_dx(home_y - _row_y(int(ci)))
			if wind_rigid:







				_set_fruit_layer_pos(f, Vector2(
					fruit_x + _sway_dx(int(ci), home_y) + wind_dx, home_y))




				f.rotation = clampf( - atan(wind_slope) * DRAG_TILT_RATIO, 
					- DRAG_TILT_MAX, DRAG_TILT_MAX)
				continue

			_set_fruit_layer_pos(f, local_pos.lerp(
				Vector2(fruit_x + _sway_dx(int(ci), home_y) + wind_dx, home_y), k))
			if not is_zero_approx(f.rotation):
				f.rotation = lerpf(f.rotation, 0.0, k)
			if not f.scale.is_equal_approx(Vector2.ONE):
				f.scale = f.scale.lerp(Vector2.ONE, k)
		_last_col_x[ci] = fruit_x




func _advance_return() -> void :
	if not _color_reject_hold.is_empty():
		return
	if _return.is_empty():
		return
	for f: JuiceFruit in _return:
		if not is_instance_valid(f) or f.col < 0:
			continue
		var list: Array[JuiceFruit] = _fruit_nodes.get(f.col, [] as Array[JuiceFruit])
		var i: int = list.find(f)
		if i < 0:
			continue
		var home_y: float = _lay.fruit_y(i) + _row_y(f.col)
		var home: Vector2 = Vector2(
			_col_x(f.col) + _shake_dx(f.col) + _sway_dx(f.col, home_y), home_y)
		if _fruit_layer_pos(f).distance_to(home) > RETURN_SETTLE_EPS:
			return
	_flush_return()
	if _endless_session != null:
		_check_over()


func _flush_return() -> void :
	_cancel_color_reject_hold()
	for f: JuiceFruit in _return:
		if is_instance_valid(f):
			_set_drag_top_level(f, false)
			f.z_index = 0
	_return.clear()















func _advance_drag_chain(delta: float, gap: float) -> void :
	var xs: PackedFloat32Array = _drag["xs"]
	var vx: PackedFloat32Array = _drag["vx"]
	var n: int = xs.size()
	if n == 0:
		return

	xs[0] = (_drag["pos"] as Vector2).x - (_drag["grab"] as Vector2).x
	vx[0] = 0.0
	var stiff: float = DRAG_CHAIN_OMEGA * DRAG_CHAIN_OMEGA
	var damp: float = 2.0 * DRAG_CHAIN_ZETA * DRAG_CHAIN_OMEGA
	var max_dx: float = DRAG_CHAIN_MAX_SLOPE * maxf(gap, 1.0)
	var steps: int = clampi(ceili(delta / 0.01), 1, 4)
	var h: float = delta / float(steps)
	for _s in steps:
		for i in range(1, n):
			var acc: float = stiff * (xs[i - 1] - xs[i]) - damp * vx[i]
			vx[i] += acc * h
			xs[i] += vx[i] * h

			var over: float = xs[i] - xs[i - 1]
			if absf(over) > max_dx:
				xs[i] = xs[i - 1] + signf(over) * max_dx
				vx[i] = vx[i - 1]

	_drag["xs"] = xs
	_drag["vx"] = vx

	var shown: PackedFloat32Array = xs.duplicate()


	if _sway_enabled:
		var span: float = float(maxi(1, n - 1))
		for i in n:
			shown[i] += _lay.fruit_d * DRAG_SWAY_AMP_RATIO * (float(i) / span)\
			* sin(_t * DRAG_SWAY_OMEGA + float(i) * DRAG_SWAY_PHASE_PER_IDX)
	var rot: = PackedFloat32Array()
	rot.resize(n)
	for i in n:

		var dx: float = 0.0
		if i > 0:
			dx = shown[i] - shown[i - 1]
		elif n > 1:
			dx = (shown[1] - shown[0]) * DRAG_HEAD_TILT_RATIO

		rot[i] = clampf( - atan2(dx, maxf(gap, 1.0)) * DRAG_TILT_RATIO, 
			- DRAG_TILT_MAX, DRAG_TILT_MAX)
	_drag["shown"] = shown
	_drag["rot"] = rot


































func _check_over() -> void :
	if tutorial_demo_only:
		return
	if _level == null or _state.is_empty():
		return
	if bool(_state.get("allow_root_swapping", false))\
	and (_root_adjudication_suspended or _root_ready_settling):
		return
	if can_play_after_dead() and _endless_session == null and R.is_win(_state, _level):

		_over = "win"
		_over_signal_pending = is_busy()
		if not _over_signal_pending:
			won.emit()
		return
	if _over != "":
		if _over_signal_pending and not is_busy():
			_over_signal_pending = false
			if _over == "win":
				won.emit()
			else:
				_report_dead(_pending_dead_reason)
		return
	if (_state["cols"] as Array).is_empty():
		return
	if _endless_session == null and R.is_win(_state, _level):
		_over = "win"
		_over_signal_pending = is_busy()
		if not _over_signal_pending:
			won.emit()
		return
	if not R.has_any_move(_state):
		if bool(_state.get("allow_root_swapping", false)) and R.any_ready(_state):

			if _endless_session == null and not is_busy() and _drag.is_empty():
				_settle_root_ready_without_move()
			return
		_mark_dead("stuck")
		return
	_start_closed_check()
	if _endless_session == null:
		_start_challenge_check()



func _settle_root_ready_without_move() -> void :
	if _endless_session != null or _root_ready_settling:
		return
	var before: Dictionary = R.clone_state(_state)
	var deposits: Array = []
	if R.run_deposit(_state, _level, deposits) <= 0:
		return
	_root_ready_settling = true
	var unlocked: Array = R._unlock_pass(_state)
	var revealed: Array = R._reveal_tails(_state)
	if not _history.is_empty():
		var rec: Dictionary = (_history.back() as Dictionary)["rec"]

		if (rec.get("auto_unlock_before", {}) as Dictionary).is_empty():
			rec["auto_unlock_before"] = before
		var automatic: Array = rec.get("auto_unlock_deposits", []) as Array
		automatic.append_array(deposits)
		rec["auto_unlock_deposits"] = automatic
	_cancel_closed_check()
	_invalidate_death_attribution()
	_clear_hint()
	_clear_run_highlight()
	_enqueue_beats(deposits)
	_apply_reveals(revealed)
	_refresh_blenders()
	_play_lock_unlock_effects(unlocked)
	_refresh_lock_overlays()
	_root_ready_deposits = deposits
	automatic_settlement_requested.emit()
	_root_ready_deposits = []
	_root_ready_settling = false
	queue_redraw()
	_check_over()



func _mark_dead(reason: String) -> void :
	_over = "dead"
	_pending_dead_reason = reason
	_over_signal_pending = is_busy()
	if not _over_signal_pending:
		_report_dead(reason)




func mark_hint_unwinnable() -> void :
	if _over != "" or _level == null or _state.is_empty():
		return
	if bool(_state.get("allow_root_swapping", false)):

		return
	_invalidate_death_attribution()
	_clear_hint()
	_mark_dead(HINT_UNWINNABLE_REASON)


func _report_dead(reason: String) -> void :
	_reconcile_render_before_dead(reason)

	_play_skin_sound(&"juice_dead")
	dead.emit(reason)
	if _endless_session != null:
		return
	_start_death_attribution(reason)
	_start_safe_return_search()







func _reconcile_render_before_dead(reason: String) -> Array[String]:
	var issues: Array[String] = render_mismatches()
	if issues.is_empty():
		return issues
	SortLogger.error("JuiceBoardView: 判死(%s)时渲染与状态不一致,已按状态重画: %s"
		%[reason, "; ".join(issues)])

	if sync_error() != "":
		_rebuild_nodes()

	_snap_all_home()
	_refresh_lock_overlays()
	var left: Array[String] = render_mismatches()
	if not left.is_empty():
		SortLogger.error("JuiceBoardView: 判死重画后仍不一致: %s" % "; ".join(left))
	return issues





func render_mismatches() -> Array[String]:
	var issues: Array[String] = []

	if _level == null or _state.is_empty() or _fruit_pool == null or not is_inside_tree():
		return issues
	var sync: String = sync_error()
	if sync != "":
		issues.append(sync)
	for ci: int in _order:
		var b: Variant = _blender_nodes.get(ci)
		if b == null or not is_instance_valid(b):
			issues.append("c%d 缺花盆节点" % ci)
		elif absf((b as JuiceBlender).position.x - _col_x(ci)) > 1.0:
			issues.append("c%d 花盆 x=%.1f,应为 %.1f" % [ci, (b as JuiceBlender).position.x, _col_x(ci)])
	var want: Dictionary = {}
	var s: float = _lay.fruit_d / JuiceLockOverlay.DESIGN_FRUIT_D
	for ci: int in _order:
		if R.is_locked(_state, ci):
			want[ci] = _col_x(ci) - JuiceLockOverlay.FRAME_W * 0.5 * s
	var seen: Dictionary = {}
	for o: JuiceLockOverlay in _lock_overlay_live:
		if not is_instance_valid(o) or not o.visible:
			continue
		if not want.has(o.col):
			issues.append("c%d 未上锁却盖着遮罩" % o.col)
			continue
		seen[o.col] = true
		if absf(o.position.x - float(want[o.col])) > 1.0:
			issues.append("c%d 遮罩 x=%.1f,应为 %.1f" % [o.col, o.position.x, float(want[o.col])])
	for ci: int in want:
		if not seen.has(ci):
			issues.append("c%d 已上锁却没有遮罩" % ci)
	return issues



func _start_death_attribution(reason: String) -> void :
	_invalidate_death_attribution()
	if _history.is_empty():
		dead_attributed.emit(S.DeathAttribution.UNKNOWN, reason, _steps)
		return
	var previous: Dictionary = R.clone_state(_state)
	R.undo_move(previous, (_history[-1] as Dictionary)["rec"] as Dictionary, _keep_revealed_on_undo, _rank_collectible_type)

	var request: Dictionary = {
		"previous": previous, "level": _level, "generation": _death_generation, 
		"reason": reason, "steps": _steps, 
	}
	if _death_task_id != DEATH_TASK_NONE:
		_death_pending = request
	else:
		_dispatch_death_attribution(request)


func _dispatch_death_attribution(request: Dictionary) -> void :
	var opt: Dictionary = DEATH_ATTRIBUTION_OPT.duplicate()
	opt["now"] = Time.get_ticks_msec
	_death_task_request = request
	_death_task_result = {"completed": false, "attribution": S.DeathAttribution.UNKNOWN}
	var job: Callable = S.run_death_attribution_task.bind(request["previous"], request["level"], 
		opt, _death_task_result)
	_death_task_id = WorkerThreadPool.add_task(job, false, "juice death attribution")


func _poll_death_attribution() -> void :
	if _death_task_id == DEATH_TASK_NONE\
	or not WorkerThreadPool.is_task_completed(_death_task_id):
		return
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_death_task_id)
	var completed: bool = bool(_death_task_result.get("completed", false))
	var attribution: int = int(_death_task_result.get("attribution", S.DeathAttribution.UNKNOWN))
	var request: Dictionary = _death_task_request

	var diagnostic: Dictionary = _death_task_result.get("diagnostic", {})
	_death_task_id = DEATH_TASK_NONE
	_death_task_result = {}
	_death_task_request = {}
	if task_error != OK or not completed:
		SortLogger.error("JuiceBoardView: 死亡归因任务失败,error=%d" % task_error)
		attribution = S.DeathAttribution.UNKNOWN
	if int(request["generation"]) == _death_generation and _over == "dead"\
	and is_visible_in_tree():
		_death_attribution = attribution
		dead_attributed.emit(attribution, String(request["reason"]), int(request["steps"]))
		if task_error == OK and completed:
			_emit_calculation_timeout(diagnostic)
	if not _death_pending.is_empty():
		var pending: Dictionary = _death_pending
		_death_pending = {}
		if int(pending["generation"]) == _death_generation and _over == "dead":
			_dispatch_death_attribution(pending)


func _invalidate_death_attribution() -> void :
	_invalidate_safe_return()
	_death_generation += 1
	_death_attribution = S.DeathAttribution.UNKNOWN
	_death_pending = {}


func _invalidate_safe_return() -> void :
	_safe_return_generation += 1
	_safe_return_steps = -1


func death_attribution() -> int:
	return _death_attribution



func safe_return_steps() -> int:
	return _safe_return_steps




func _start_safe_return_search() -> void :
	if tutorial_demo_only or _level == null or _history.is_empty()\
	or _safe_task_id != DEATH_TASK_NONE or _safe_return_steps >= 0:
		return
	if _over != "dead":
		return
	var first: int = maxi(0, _history.size() - SAFE_RETURN_MAX_STEPS)
	var recs: Array = []
	for i: int in range(first, _history.size()):
		recs.append(((_history[i] as Dictionary)["rec"] as Dictionary).duplicate(true))
	var opt: Dictionary = SAFE_RETURN_OPT.duplicate()
	opt["now"] = Time.get_ticks_msec
	_safe_task_generation = _safe_return_generation
	_safe_task_result = {"completed": false, "steps": 0}
	var job: Callable = S.run_safe_return_task.bind(R.clone_state(_state), recs, _level, 
		_keep_revealed_on_undo, opt, _safe_task_result)
	_safe_task_id = WorkerThreadPool.add_task(job, false, "juice safe return search")


func _poll_safe_return() -> void :
	if _safe_task_id == DEATH_TASK_NONE or not WorkerThreadPool.is_task_completed(_safe_task_id):
		return
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_safe_task_id)
	var completed: bool = bool(_safe_task_result.get("completed", false))
	var found: int = int(_safe_task_result.get("steps", 0))
	var generation: int = _safe_task_generation
	var diagnostic: Dictionary = _safe_task_result.get("diagnostic", {})
	_safe_task_id = DEATH_TASK_NONE
	_safe_task_result = {}
	if task_error != OK or not completed:
		SortLogger.error("JuiceBoardView: 安全回退搜索任务失败,error=%d" % task_error)
		return

	if generation == _safe_return_generation and _over == "dead":
		_safe_return_steps = found
		_emit_calculation_timeout(diagnostic)



func _emit_calculation_timeout(diagnostic: Dictionary) -> void :
	if diagnostic.is_empty() or not is_visible_in_tree() or _level == null:
		return
	var payload: Dictionary = diagnostic.duplicate()
	payload["level_id"] = _level.id
	calculation_timed_out.emit(payload)






func _start_closed_check() -> void :
	if bool(_state.get("allow_root_swapping", false)):
		_start_root_closed_check()
		return
	if _closed_task_id != CLOSED_TASK_NONE:
		return
	var snapshot: Dictionary = R.clone_state(_state)
	_closed_task_key = R.state_key(_state)
	_closed_task_result = {"completed": false, "closed": false}
	var job: Callable = S.run_closed_cycle_task.bind(snapshot, _level, _closed_task_result)
	_closed_task_id = WorkerThreadPool.add_task(job, false, "juice closed-cycle check")



func _poll_closed_check() -> void :
	if _root_closed_job != null:
		_poll_root_closed_check()
		return
	if _closed_task_id == CLOSED_TASK_NONE and bool(_state.get("allow_root_swapping", false)):
		_start_root_closed_check()
		return
	if _closed_task_id == CLOSED_TASK_NONE\
	or not WorkerThreadPool.is_task_completed(_closed_task_id):
		return

	if not _drag.is_empty():
		return
	var checked_key: String = _closed_task_key
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_closed_task_id)
	var completed: bool = bool(_closed_task_result.get("completed", false))
	var closed: bool = bool(_closed_task_result.get("closed", false))
	_closed_task_id = CLOSED_TASK_NONE
	_closed_task_key = ""
	_closed_task_result = {}
	if _level == null or _state.is_empty():
		return
	if checked_key != R.state_key(_state):
		_check_over()
		return
	if _over != "" or not is_visible_in_tree():
		return

	if task_error != OK or not completed:
		push_error("juice_sort: 封闭循环判定任务失败,error=%d" % task_error)
		return
	if closed:
		_mark_dead("loop")



func _cancel_closed_check() -> void :
	_invalidate_root_closed_check()
	if _root_closed_job != null:

		return
	if _closed_task_id == CLOSED_TASK_NONE:
		return
	WorkerThreadPool.wait_for_task_completion(_closed_task_id)
	_closed_task_id = CLOSED_TASK_NONE
	_closed_task_key = ""
	_closed_task_result = {}


func _invalidate_root_closed_check() -> void :
	_root_closed_generation += 1
	for key: String in _root_closed_cache.keys():
		_discard_root_closed_cache(key)
	if _root_closed_job != null:
		_root_closed_job.cancelled.post()



func _discard_root_closed_cache(key: String) -> void :
	var cached: Dictionary = _root_closed_cache[key]
	var ctx: Dictionary = cached.get("ctx", {})
	if not ctx.is_empty():
		var job: = RootClosedJob.new()
		job.ctx = ctx
		job.task_id = WorkerThreadPool.add_task(job.discard, false, "juice root search cleanup")
		job.retire(get_tree())
	_root_closed_cache.erase(key)



func root_closed_result() -> Dictionary:
	if _root_adjudication_suspended or _level == null or _state.is_empty()\
	or not bool(_state.get("allow_root_swapping", false)):
		return {}
	var key: String = S.root_closed_state_key(_state)
	if not _root_closed_cache.has(key):
		return {}
	var cached: Dictionary = _root_closed_cache[key]
	if int(cached.get("level_identity", 0)) != _level.get_instance_id():
		return {}
	return (cached["result"] as Dictionary).duplicate(true)



func ensure_root_closed_check() -> bool:
	if _root_adjudication_suspended or _level == null or _state.is_empty()\
	or not bool(_state.get("allow_root_swapping", false)):
		return false
	_start_root_closed_check()
	return _root_closed_job != null


func _start_root_closed_check() -> void :
	if _root_adjudication_suspended or _root_ready_settling\
	or _closed_task_id != CLOSED_TASK_NONE or _root_closed_job != null or _level == null\
	or _state.is_empty() or _over != "" or not is_visible_in_tree() or tutorial_demo_only\
	or (_state.get("cols", []) as Array).is_empty():
		return
	var key: String = S.root_closed_state_key(_state)
	var ctx: Dictionary = {}
	if _root_closed_cache.has(key)\
	and int(_root_closed_cache[key].get("level_identity", 0)) != _level.get_instance_id():
		_discard_root_closed_cache(key)
	if _root_closed_cache.has(key):
		var cached: Dictionary = _root_closed_cache[key]
		var result: Dictionary = cached["result"]
		if not bool(result.get("continuable", false)):
			if bool(result.get("closed", false)) and _drag.is_empty():
				_mark_dead("loop")
			return
		ctx = cached["ctx"]

		_root_closed_cache.erase(key)
	else:

		ctx = S.begin_root_closed_search(_state, _level, _root_closed_max_states, true)
	var job: = RootClosedJob.new()
	job.ctx = ctx
	job.key = key
	job.generation = _root_closed_generation
	job.level_identity = _level.get_instance_id()
	job.budget_ms = _root_closed_budget_ms
	job.now = _root_closed_now
	job.opts = _root_closed_opts.duplicate()
	_root_closed_job = job
	_closed_task_key = key
	_closed_task_result = job.result
	job.task_id = WorkerThreadPool.add_task(job.run, false, "juice root closed-cycle slice")
	_closed_task_id = job.task_id


func _poll_root_closed_check() -> void :
	var job: RootClosedJob = _root_closed_job
	if not WorkerThreadPool.is_task_completed(job.task_id):
		return
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(job.task_id)
	job.task_id = CLOSED_TASK_NONE
	_root_closed_job = null
	_closed_task_id = CLOSED_TASK_NONE
	_closed_task_key = ""
	_closed_task_result = {}
	if job.generation != _root_closed_generation or _level == null\
	or job.level_identity != _level.get_instance_id() or _state.is_empty():
		if not job.ctx.is_empty():
			job.task_id = WorkerThreadPool.add_task(job.discard, false, "juice root search cleanup")
			job.retire(get_tree())
		if _drag.is_empty():
			_check_over()
		return
	var result: Dictionary = job.result
	if task_error != OK or not bool(result.get("completed", false)):

		result = {"completed": true, "closed": false, "continuable": false, 
			"status": "UNKNOWN", "reason": "task_error"}
		SortLogger.error("JuiceBoardView: 根部交换封闭检查任务失败,error=%d" % task_error)
	_root_closed_cache[job.key] = {"ctx": job.ctx, "result": result, "level_identity": job.level_identity}
	while _root_closed_cache.size() > ROOT_CLOSED_CACHE_MAX:
		_discard_root_closed_cache(String(_root_closed_cache.keys()[0]))
	if not bool(_state.get("allow_root_swapping", false)):
		if _drag.is_empty():
			_check_over()
		return

	if job.key != S.root_closed_state_key(_state):
		if _drag.is_empty():
			_check_over()
		return
	_start_root_closed_check()




func _start_challenge_check() -> void :
	if _challenge_suppressed_by_undo or _over != "" or _level == null or _state.is_empty()\
	or (bool(_state.get("allow_root_swapping", false)) and _root_adjudication_suspended):
		return
	var key: String = R.state_key(_state)
	if key == _challenge_last_key:
		return
	var gate: String = CH.gate_reason(_state, _level, _steps, _resumed_round)
	if gate != "":
		_challenge_last_key = key
		var detail: String = ""
		if gate == "opening":
			detail = "(当前第 %d 步)" % _steps
		elif gate == "endgame":
			detail = "(剩 %d 盆)" % R.cups_left(_state, _level)
		SortLogger.info("[Challenge] 第%d步 不判:%s%s" % [_steps, CH.reason_text(gate), detail])
		return
	if _challenge_cache.has(key):
		_challenge_last_key = key
		_emit_challenge(key, _challenge_cache[key] as Dictionary)
		return

	if _challenge_task_id != CHALLENGE_TASK_NONE:
		return
	_challenge_last_key = key
	_challenge_task_key = key
	_challenge_task_gen = _challenge_generation
	_challenge_task_result = {"completed": false, "info": {}}

	var opt: Dictionary = {"ms_cap": CHALLENGE_MS_CAP, "now": Time.get_ticks_msec, 
		"slot_of": _slot_of.duplicate()}

	var job: Callable = CH.run_task.bind(R.clone_state(_state), _level, opt, _challenge_task_result)
	_challenge_task_id = WorkerThreadPool.add_task(job, false, "juice challenge check")



func _poll_challenge_check() -> void :
	if _challenge_task_id == CHALLENGE_TASK_NONE\
	or not WorkerThreadPool.is_task_completed(_challenge_task_id):
		return
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_challenge_task_id)
	var completed: bool = bool(_challenge_task_result.get("completed", false))
	var info: Dictionary = _challenge_task_result.get("info", {})
	var diagnostic: Dictionary = _challenge_task_result.get("diagnostic", {})
	var key: String = _challenge_task_key
	var gen: int = _challenge_task_gen
	_challenge_task_id = CHALLENGE_TASK_NONE
	_challenge_task_key = ""
	_challenge_task_result = {}
	if task_error != OK or not completed:
		SortLogger.error("JuiceBoardView: 关键点判定任务失败,error=%d" % task_error)
	elif gen == _challenge_generation:
		_challenge_cache[key] = info
		if _challenge_cache.size() > CHALLENGE_CACHE_MAX:
			_challenge_cache.erase(_challenge_cache.keys()[0])
		if _level != null and not _state.is_empty() and key == R.state_key(_state)\
		and _over == "" and is_visible_in_tree():
			_emit_challenge(key, info)

			if not _challenge_suppressed_by_undo:
				_emit_calculation_timeout(diagnostic)
		else:
			var stale_kind: int = int(info.get("kind", CH.Kind.NONE))
			if stale_kind != CH.Kind.NONE:
				SortLogger.info("[Challenge] 判出%s但作废:判定期间盘面已变(走得太快)或局已结束"
					%CH.kind_name(stale_kind))

	_start_challenge_check()


func _emit_challenge(key: String, info: Dictionary) -> void :

	if _challenge_suppressed_by_undo:
		return
	var kind: int = int(info.get("kind", CH.Kind.NONE))
	if kind == CH.Kind.NONE:
		SortLogger.info("[Challenge] 第%d步 不是关键点:%s(推进走法 %d 种,已算出能活 %d、会死 %d)" % [
			_steps, CH.reason_text(String(info.get("reason", ""))), int(info.get("n", 0)), 
			int(info.get("alive", 0)), int(info.get("fatal", 0))])
		return


	var last: Dictionary = {}
	if not _history.is_empty():
		var rec: Dictionary = (_history[-1] as Dictionary)["rec"]
		last = {"src": int(rec["src"]), "dst": int(rec["dst"])}
	if CH.answer_follows(info, last):
		var ans: Dictionary = info["answer"]
		SortLogger.info("[Challenge] 第%d步 判出陷阱点但不报:正解(%s)碰到上一步动过的列,顺着走不算抉择" % [
			_steps, describe_move(int(ans["src"]), int(ans["j"]), int(ans["dst"]))])
		return
	var payload: Dictionary = info.duplicate()
	payload["key"] = key
	payload["steps"] = _steps
	challenge_detected.emit(kind, payload)



func _reset_challenge_check() -> void :
	_challenge_generation += 1
	_challenge_cache.clear()
	_challenge_last_key = ""

	_challenge_suppressed_by_undo = false
	_lucky_seen.clear()




func _start_lucky_reveal_check(rec: Dictionary) -> void :
	if _over != "" or _level == null or _state.is_empty():
		return
	var fresh: Array = []
	for r: Dictionary in (rec.get("revealed", []) as Array):
		if not _lucky_seen.has("%d:%d" % [int(r["col"]), int(r["index"])]):
			fresh.append(r.duplicate())
	if fresh.is_empty():
		return

	if not (rec.get("deposits", []) as Array).is_empty():
		SortLogger.info("[LuckyReveal] 第%d步 不判:这一步收了盆" % _steps)
		return
	if _lucky_task_id != LUCKY_TASK_NONE:
		SortLogger.info("[LuckyReveal] 第%d步 不判:上一次判定还在算" % _steps)
		return
	var post: Dictionary = R.clone_state(_state)
	var pre: Dictionary = R.clone_state(_state)
	R.undo_move(pre, rec, false, _rank_collectible_type)
	_lucky_task_key = R.state_key(_state)
	_lucky_task_gen = _challenge_generation
	_lucky_task_result = {"completed": false, "info": {}}
	var opt: Dictionary = {"ms_cap": CHALLENGE_MS_CAP, "now": Time.get_ticks_msec}
	var job: Callable = CH.run_lucky_task.bind(pre, post, fresh, _level, opt, _lucky_task_result)
	_lucky_task_id = WorkerThreadPool.add_task(job, false, "juice lucky reveal check")



func _poll_lucky_reveal_check() -> void :
	if _lucky_task_id == LUCKY_TASK_NONE or not WorkerThreadPool.is_task_completed(_lucky_task_id):
		return
	var task_error: Error = WorkerThreadPool.wait_for_task_completion(_lucky_task_id)
	var completed: bool = bool(_lucky_task_result.get("completed", false))
	var info: Dictionary = _lucky_task_result.get("info", {})
	var diagnostic: Dictionary = _lucky_task_result.get("diagnostic", {})
	var key: String = _lucky_task_key
	var gen: int = _lucky_task_gen
	_lucky_task_id = LUCKY_TASK_NONE
	_lucky_task_key = ""
	_lucky_task_result = {}
	if task_error != OK or not completed:
		SortLogger.error("JuiceBoardView: 好运问号判定任务失败,error=%d" % task_error)
		return
	if gen != _challenge_generation:
		return

	if _level != null and not _state.is_empty() and key == R.state_key(_state) and _over == "":
		_emit_calculation_timeout(diagnostic)
	if not bool(info.get("lucky", false)):
		SortLogger.info("[LuckyReveal] 第%d步 不触发:%s(不翻问号的可达局面 %d 个)" % [
			_steps, CH.reason_text(String(info.get("reason", ""))), int(info.get("states", 0))])
		return
	if _level == null or _state.is_empty() or key != R.state_key(_state) or _over != ""\
	or not is_visible_in_tree():
		SortLogger.info("[LuckyReveal] 判中但作废:判定期间盘面已变(走得太快)或局已结束")
		return
	var cells: Array = []
	for r: Dictionary in (info.get("cells", []) as Array):
		var ci: int = int(r["col"])
		var idx: int = int(r["index"])
		_lucky_seen["%d:%d" % [ci, idx]] = true
		var cell: Dictionary = r.duplicate()
		var list: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
		cell["global_pos"] = list[idx].global_position\
		if idx >= 0 and idx < list.size() and is_instance_valid(list[idx]) else global_position
		cells.append(cell)
	SortLogger.info("[LuckyReveal] 第%d步 触发:翻开 %s(不翻问号的可达局面 %d 个,全都种不出盆)" % [
		_steps, str(cells.map( func(c: Dictionary) -> String: return "列%d" % int(c["col"]))), 
		int(info.get("states", 0))])
	lucky_reveal_detected.emit(cells)









func _refresh_lock_overlays() -> void :
	for ci: int in _wood_reject_hidden.keys():
		if resolved_lock_visual_version() != 3 or not R.is_locked(_state, ci):
			_stop_wood_reject_feedback(ci)
			_shake.erase(ci)
	for o: JuiceLockOverlay in _lock_overlay_live:
		if is_instance_valid(o):
			o.visible = false
			_lock_overlay_pool.append(o)
	_lock_overlay_live.clear()
	if _lock_layer == null or _state.is_empty() or _order.is_empty():
		return
	var locks: Array = _state.get("locks", []) as Array
	for ci: int in _order:
		if ci < 0 or ci >= locks.size():
			continue
		var lock: Dictionary = locks[ci] as Dictionary
		if lock.is_empty():
			continue
		var slot: int = int(_slot_of.get(ci, -1))
		if slot < 0:
			continue
		var o: JuiceLockOverlay = _lock_overlay_pool.pop_back()\
		if not _lock_overlay_pool.is_empty() else null
		if o == null:
			o = LOCK_OVERLAY_SCENE.instantiate() as JuiceLockOverlay
			_lock_layer.add_child(o)
		var rect: Rect2 = _lock_column_rect(slot)
		o.col = ci
		o.set_geometry(_col_x(ci), rect.position.y, rect.size.y, _lay.fruit_d, rect.size.x)
		o.set_lean(_rigid_lean_slope(ci), _lay.hang_top + _row_y(ci) - rect.position.y)
		o.set_lock_visual_version(resolved_lock_visual_version())
		if String(lock.get("condition", "")) == JuiceLevel.LOCK_COLLECT_TYPE:

			o.show_flower(lock_icon(int(lock.get("typeId", -1))), lock_visual(int(lock.get("typeId", -1))))
		else:
			o.show_count(int(lock.get("count", 0)) - int(_state.get("done", 0)))
		o.set_skin_resources(_skin_resources)
		o.visible = true
		_lock_overlay_live.append(o)
		if _wood_reject_hidden.has(ci):
			o.wood_door_view().set_reject_time(float(_shake.get(ci, 0.0)))







func _col_wind_is_rigid_line(ci: int) -> bool:
	return _wind_active and not _state.is_empty() and R.is_locked(_state, ci)



func _col_entrance_wind_slope(ci: int) -> float:
	if resolved_lock_visual_version() == 3 and not _state.is_empty() and R.is_locked(_state, ci):
		return _wind_amp * WOOD_LOCK_ENTRANCE_SWAY_RATIO
	return _wind_amp








func _rigid_lean_slope(ci: int) -> float:
	if _lay == null:
		return 0.0
	var slope: float = _sway_slope(ci)
	if _wind_active:
		slope += _col_entrance_wind_slope(ci)
	return slope




func _update_lock_overlay_lean() -> void :
	if _lay == null:
		return
	for o: JuiceLockOverlay in _lock_overlay_live:
		if is_instance_valid(o):
			o.set_lean(_rigid_lean_slope(o.col), _lay.hang_top + _row_y(o.col) - o.position.y)


func _draw() -> void :
	if _level == null or _order.is_empty():
		return
	_draw_collect_glows()
	_draw_capacity_error_hint()
	for ci in _order:
		if _endless_session != null and not _visual_token_by_col.has(ci):
			continue

		var rigid_line: bool = _col_wind_is_rigid_line(ci)
		_draw_rope(float(_col_x(ci)) + _content_dx, 
			_rope_type(ci), TUTORIAL_MUTED_ROPE_ALPHA if _four_goal_tutorial_visuals and (_col_mark_spec.get("errors", []) as Array).has(ci) else 1.0, _row_y(ci), 
			_rigid_lean_slope(ci) if rigid_line else _sway_slope(ci), rigid_line, 
			_col_cap(ci))





	for beat: Dictionary in _beats:
		var age: float = _t - float(beat["t0"])
		if bool(beat.get("preview", false)) and age < 0.0:
			continue
		var ghost_x: float = float(beat["ghost_x"])



		var u: float = clampf(age / GHOST_FADE_DUR, 0.0, 1.0) if age >= 0.0 else 0.0


		var a: float = maxf(0.0, 1.0 - maxf(0.0, u - 0.3) / 0.7)
		if a <= 0.0:
			continue
		_draw_rope(ghost_x + _content_dx, int(beat["fruit"]), a, float(beat.get("row_y", 0.0)), 
			_idle_sway_slope(int(beat["col"]), int(beat["q"])), false, int(beat["q"]))




func _draw_collect_glows() -> void :
	if _collect_glow_texture == null:
		return
	for beat: Dictionary in _beats:
		var age: float = _t - float(beat["t0"])
		if age < 0.0 or age >= GHOST_FADE_DUR:
			continue
		var fade_in: float = clampf(age / 0.08, 0.0, 1.0)
		var fade_out: float = clampf((GHOST_FADE_DUR - age) / 0.12, 0.0, 1.0)
		var alpha: float = PULSE_GLOW_ALPHA * minf(fade_in, fade_out)
		var nodes: Array = beat["nodes"]
		if nodes.is_empty():
			continue
		var first: JuiceFruit = nodes.front() as JuiceFruit
		var last: JuiceFruit = nodes.back() as JuiceFruit
		if first == null or last == null or not is_instance_valid(first) or not is_instance_valid(last):
			continue
		var pad_y: float = _lay.fruit_d * 0.72
		var top_y: float = minf(first.position.y, last.position.y) - pad_y
		var bottom_y: float = maxf(first.position.y, last.position.y) + pad_y
		var glow_w: float = _lay.fruit_d * PULSE_GLOW_WIDTH
		var glow_rect: = Rect2(
			Vector2(float(beat["ghost_x"]) - glow_w * 0.5, top_y), 
			Vector2(glow_w, maxf(_lay.fruit_d * 1.45, bottom_y - top_y)))
		draw_texture_rect(_collect_glow_texture, glow_rect, false, 
			Color(1.0, 0.92, 0.62, alpha))

















































func _draw_rope(x: float, type_id: int, alpha: float, dy: float, slope: float = 0.0, 
		rigid_line: bool = false, bottom_cap: int = -1) -> void :
	var top_tex: Texture2D = _rope_top_tex(type_id)
	var mid_tex: Texture2D = _rope_mid_tex(type_id)
	var bot_tex: Texture2D = _rope_bottom_tex(type_id)
	if top_tex == null or mid_tex == null or bot_tex == null:
		return
	var ribbon: JuiceSkinDefinition = _rank_rope_skin(type_id)
	var top_rows: float = ribbon.rank_collectible_rope_body_rows.x if ribbon != null else ROPE_TOP_BODY_ROWS
	var mid_rows: float = ribbon.rank_collectible_rope_body_rows.y if ribbon != null else ROPE_MID_BODY_ROWS
	var body_cols: float = mid_tex.get_width() if ribbon != null else ROPE_MID_BODY_COLS
	var separate_shadow: bool = ribbon == null
	var tex_w: float = maxf(1.0, top_tex.get_width())
	var raw_w: float = maxf(4.0, _lay.rope_scale_d * _skin.rope_tex_w_ratio)

	var step: float = maxf(roundf(mid_rows * raw_w / tex_w), 1.0)
	var k: float = step / mid_rows
	var box_w: float = tex_w * k
	var left: float = x - box_w * 0.5
	var tint: = Color(1.0, 1.0, 1.0, alpha)

	var bot_h: float = bot_tex.get_height() * k



	var dy_i: float = roundf(dy)
	var top_y: float = roundf(_lay.hang_top) + dy_i
	var pivot_y: float = top_y


	var bottom: float = _lay.rope_bottom if bottom_cap < 0 else _lay.rope_bottom_for(bottom_cap)
	var bot_y: float = roundf(bottom - ROPE_TIP_ROWS * k) + dy_i
	var seam: float = top_y + roundf(top_rows * k)
	if ribbon != null:
		var visible_span: Vector2 = _rope_reference_visible_span(type_id, dy, bottom_cap)
		var joins: Vector3 = _ribbon_join_y(visible_span, ribbon, k)
		top_y = joins.x
		seam = joins.y
		bot_y = joins.z


	if _wind_active and not is_zero_approx(_wind_amp) and not rigid_line:
		_draw_rope_curved(top_tex, mid_tex, bot_tex, left, box_w, tex_w, k, step, 
			top_y, seam, bot_y, bot_h, slope, tint, pivot_y, top_rows, mid_rows, body_cols, separate_shadow)
		return



	if not is_zero_approx(slope):
		draw_set_transform_matrix(Transform2D(
			Vector2(1.0, 0.0), Vector2(slope, 1.0), Vector2( - slope * pivot_y, 0.0)))






	_draw_rope_top(top_tex, 
		Rect2(left, top_y, box_w, seam - top_y), 
		top_rows, tint)
	_draw_rope_mid(self, mid_tex, left, seam, bot_y - seam, box_w, k, tint, mid_rows, body_cols, separate_shadow)

	draw_texture_rect(bot_tex, Rect2(left, bot_y, box_w, bot_h), false, tint)

	draw_set_transform_matrix(Transform2D.IDENTITY)


func _rank_rope_skin(type_id: int) -> JuiceSkinDefinition:
	return _skin_resources.rank_collectible_rope_skin() if _skin_resources != null\
	and type_id >= 0 and type_id == _rank_collectible_type else null


func _ribbon_join_y(visible_span: Vector2, ribbon: JuiceSkinDefinition, k: float) -> Vector3:
	var top_rows: float = ribbon.rank_collectible_rope_body_rows.x
	var visible_top_row: float = ribbon.rank_collectible_rope_top.source_bounds.position.y
	var seam: float = roundf(visible_span.x + (top_rows - visible_top_row) * k)
	var top_y: float = visible_span.x - (seam - visible_span.x) * visible_top_row / (top_rows - visible_top_row)
	var bot_y: float = visible_span.y - ribbon.rank_collectible_rope_bottom.source_bounds.end.y * k
	return Vector3(top_y, seam, bot_y)


func _rope_reference_visible_span(type_id: int, dy: float, bottom_cap: int) -> Vector2:
	var key: StringName = JuiceTheme.COLOR_KEYS[_slots[type_id]]
	var original: JuiceSkinVisual = _skin_resources.original_color_visual(key, &"rope_top")
	var tex_w: float = maxf(1.0, original.texture.get_width())
	var raw_w: float = maxf(4.0, _lay.rope_scale_d * _skin.rope_tex_w_ratio)
	var k: float = maxf(roundf(ROPE_MID_BODY_ROWS * raw_w / tex_w), 1.0) / ROPE_MID_BODY_ROWS
	var top_y: float = roundf(_lay.hang_top) + roundf(dy)
	var bottom: float = _lay.rope_bottom if bottom_cap < 0 else _lay.rope_bottom_for(bottom_cap)
	return Vector2(top_y + ROPE_TOP_VISIBLE_ROW * roundf(ROPE_TOP_BODY_ROWS * k) / ROPE_TOP_BODY_ROWS, 
		roundf(bottom - ROPE_TIP_ROWS * k) + roundf(dy) + ROPE_BOTTOM_VISIBLE_ROWS * k)






















func _draw_rope_curved(top_tex: Texture2D, mid_tex: Texture2D, bot_tex: Texture2D, 
		left: float, box_w: float, tex_w: float, k: float, step: float, 
		top_y: float, seam: float, bot_y: float, bot_h: float, 
		slope: float, tint: Color, pivot_y: float, top_rows: float, mid_rows: float, 
		body_cols: float, separate_shadow: bool) -> void :

	_set_rope_band_xform(top_y, seam, slope, pivot_y)
	_draw_rope_top(top_tex, 
		Rect2(left, top_y, box_w, seam - top_y), 
		top_rows, tint)

	var body_w: float = box_w * body_cols / tex_w
	var mid_span: float = bot_y - seam
	var full: int = int(floor(mid_span / step)) if mid_span > 0.0 else 0
	for i in full:
		var by: float = seam + float(i) * step
		_set_rope_band_xform(by, by + step, slope, pivot_y)
		if separate_shadow:
			draw_texture_rect_region(mid_tex, Rect2(left, by, box_w, step), 
				Rect2(0.0, ROPE_MID_SHADOW_ROW, tex_w, 1.0), tint)
		draw_texture_rect_region(mid_tex, Rect2(left, by, body_w, step), 
			Rect2(0.0, 0.0, body_cols, mid_rows), tint)
	var rest: float = mid_span - float(full) * step
	if rest > (0.5 if separate_shadow else 0.0):
		var by: float = seam + float(full) * step
		_set_rope_band_xform(by, by + rest, slope, pivot_y)
		if separate_shadow:
			draw_texture_rect_region(mid_tex, Rect2(left, by, box_w, rest), 
				Rect2(0.0, ROPE_MID_SHADOW_ROW, tex_w, 1.0), tint)
		draw_texture_rect_region(mid_tex, Rect2(left, by, body_w, rest), 
			Rect2(0.0, 0.0, body_cols, rest / k), tint)

	_set_rope_band_xform(bot_y, bot_y + bot_h, slope, pivot_y)
	draw_texture_rect(bot_tex, Rect2(left, bot_y, box_w, bot_h), false, tint)

	draw_set_transform_matrix(Transform2D.IDENTITY)





func _set_rope_band_xform(y0: float, y1: float, slope: float, pivot_y: float) -> void :
	var h: float = maxf(y1 - y0, 0.001)
	var off0: float = slope * (y0 - pivot_y) + _wind_curve_dx(y0 - (pivot_y - roundf(_lay.hang_top)))
	var off1: float = slope * (y1 - pivot_y) + _wind_curve_dx(y1 - (pivot_y - roundf(_lay.hang_top)))
	var s: float = (off1 - off0) / h
	draw_set_transform_matrix(Transform2D(
		Vector2(1.0, 0.0), Vector2(s, 1.0), Vector2(off0 - s * y0, 0.0)))







func _draw_rope_mid(item: CanvasItem, mid_tex: Texture2D, left: float, top: float, 
		span: float, box_w: float, k: float, tint: Color, body_rows: float = ROPE_MID_BODY_ROWS, 
		body_cols: float = ROPE_MID_BODY_COLS, separate_shadow: bool = true) -> void :
	if span <= (0.5 if separate_shadow else 0.0):
		return
	var tex_w: float = maxf(1.0, mid_tex.get_width())
	var step: float = body_rows * k

	if separate_shadow:
		item.draw_texture_rect_region(mid_tex, 
			Rect2(left, top, box_w, span + ROPE_BOT_SHADOW_ROWS * k), 
			Rect2(0.0, ROPE_MID_SHADOW_ROW, tex_w, 1.0), tint)

	var body_w: float = box_w * body_cols / tex_w
	var full: int = int(floor(span / step))
	for i in full:
		item.draw_texture_rect_region(mid_tex, 
			Rect2(left, top + i * step, body_w, step), 
			Rect2(0.0, 0.0, body_cols, body_rows), tint)
	var rest: float = span - float(full) * step
	if rest > (0.5 if separate_shadow else 0.0):
		item.draw_texture_rect_region(mid_tex, 
			Rect2(left, top + float(full) * step, body_w, rest), 
			Rect2(0.0, 0.0, body_cols, rest / k), tint)

























func _draw_drag_rope() -> void :
	if _drag_rope_layer == null or _drag.is_empty() or _level == null:
		return
	var mid_tex: Texture2D = _rope_mid_tex(-1)
	if mid_tex == null:
		return
	var inv: Transform2D = get_global_transform().affine_inverse()
	var pts: Array[Vector2] = []
	for f: JuiceFruit in (_drag["nodes"] as Array):
		if is_instance_valid(f):
			pts.append(inv * f.global_position)
	if pts.size() < 2:
		return
	var tex_w: float = maxf(1.0, mid_tex.get_width())
	var raw_w: float = maxf(4.0, _lay.rope_scale_d * _skin.rope_tex_w_ratio)

	var step: float = maxf(roundf(ROPE_MID_BODY_ROWS * raw_w / tex_w), 1.0)
	var k: float = step / ROPE_MID_BODY_ROWS
	var box_w: float = tex_w * k
	var tint: = Color.WHITE
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var y0: float = roundf(a.y)
		var dy: float = b.y - a.y
		var slope: float = (b.x - a.x) / dy if dy > 0.5 else 0.0

		if not is_zero_approx(slope):
			_drag_rope_layer.draw_set_transform_matrix(Transform2D(
				Vector2(1.0, 0.0), Vector2(slope, 1.0), Vector2( - slope * y0, 0.0)))
		_draw_rope_mid(_drag_rope_layer, mid_tex, a.x - box_w * 0.5, y0, 
			roundf(b.y) - y0, box_w, k, tint)

		_drag_rope_layer.draw_set_transform_matrix(Transform2D.IDENTITY)



func _draw_rope_top(top_tex: Texture2D, rect: Rect2, source_rows: float, tint: Color) -> void :
	draw_texture_rect_region(top_tex, rect, Rect2(0.0, 0.0, float(top_tex.get_width()), source_rows), tint)



func _col_cap(ci: int) -> int:
	var caps: Variant = _state.get("caps")
	if caps is Array and ci >= 0 and ci < (caps as Array).size():
		return int((caps as Array)[ci])
	return _level.capacity if _level != null else 0



func _col_rope_bottom(ci: int) -> float:
	if _lay == null:
		return 0.0
	return _lay.rope_bottom_for(_col_cap(ci))


func _rope_type(ci: int) -> int:
	return int((_state["jars"] as Array[int])[ci])


func _rope_top_tex(type_id: int) -> Texture2D:
	if _skin_resources != null:
		var slot: int = JuiceBonusLevel.YELLOW_SLOT if _is_bonus_type(type_id) else (_slots[type_id] if type_id >= 0 and type_id < _slots.size() else -1)
		return _skin_resources.single_visual(&"parking_rope_top").texture if slot < 0 else _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[slot], &"rope_top").texture
	return _rope_tex(type_id, rope_top_textures, rope_park_top_texture)


func _rope_mid_tex(type_id: int) -> Texture2D:
	if _skin_resources != null:
		var slot: int = JuiceBonusLevel.YELLOW_SLOT if _is_bonus_type(type_id) else (_slots[type_id] if type_id >= 0 and type_id < _slots.size() else -1)
		return _skin_resources.single_visual(&"parking_rope_mid").texture if slot < 0 else _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[slot], &"rope_mid").texture
	return _rope_tex(type_id, rope_mid_textures, rope_park_mid_texture)


func _rope_bottom_tex(type_id: int) -> Texture2D:
	if _skin_resources != null:
		var slot: int = JuiceBonusLevel.YELLOW_SLOT if _is_bonus_type(type_id) else (_slots[type_id] if type_id >= 0 and type_id < _slots.size() else -1)
		return _skin_resources.single_visual(&"parking_rope_bottom").texture if slot < 0 else _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[slot], &"rope_bottom").texture
	return _rope_tex(type_id, rope_bottom_textures, rope_park_bottom_texture)





func _rope_tex(type_id: int, texs: Array[Texture2D], park: Texture2D) -> Texture2D:
	if type_id < 0 or type_id >= _slots.size():
		return park
	var slot: int = JuiceBonusLevel.YELLOW_SLOT if _is_bonus_type(type_id) else _slots[type_id]
	return texs[slot] if slot >= 0 and slot < texs.size() else park





func _track_rect_centered(slot: int, cap: int = -1) -> Rect2:
	if _lay == null:
		return Rect2()
	var r: Rect2 = _lay.track_rect(slot, cap)
	return Rect2(r.position + Vector2(_center_offset_x() + _row_center_offset_x(slot), 0.0), r.size)



func _cap_for_slot(slot: int) -> int:
	for ci: Variant in _slot_of:
		if int(_slot_of[ci]) == slot:
			return _col_cap(int(ci))
	return -1



func _capsule_rect(slot: int) -> Rect2:
	var r: Rect2 = _track_rect_centered(slot, _cap_for_slot(slot))
	var widen: float = _capsule_widen()
	return Rect2(r.position - Vector2(widen, 0.0), r.size + Vector2(widen * 2.0, 0.0))



func _lock_column_rect(slot: int) -> Rect2:
	var rect: Rect2 = _capsule_rect(slot)
	if resolved_lock_visual_version() != 3:
		return rect
	var rope_bottom: float = _lay.rope_bottom_for(_cap_for_slot(slot)) + _lay.slot_offset_y(slot)
	var bottom: float = minf(rect.end.y, rope_bottom + WOOD_LOCK_BOTTOM_PADDING)
	bottom = minf(bottom, _wood_lock_bottom_limit)
	rect.size.y = maxf(bottom - rect.position.y, 1.0)
	return rect



func _col_capsule_rect(col: int) -> Rect2:
	var r: Rect2 = _capsule_rect(int(_slot_of[col]))
	r.position.x += _col_x(col) - _base_x(col)
	return r









func _capsule_widen() -> float:
	if _two_rows():
		return 0.0
	var first: Rect2 = _track_rect_centered(0)
	var last: Rect2 = _track_rect_centered(maxi(0, _lay.slots_total - 1))
	var room: float = minf(first.position.x - _lay.view_position.x, 
		_lay.view_position.x + _lay.view_size.x - last.end.x)
	if _lay.slots_total == 4 or (_lay.slots_total > 1 and _has_col_mark_guide()):
		var adjacent_room: float = (_lay.col_w - first.size.x - CAPSULE_GAP) * 0.5
		room = minf(room, maxf(adjacent_room, 0.0))
	return minf(first.size.x * (CAPSULE_WIDEN - 1.0) * 0.5, maxf(room, 0.0))







func set_background_highlights(use_new: bool) -> void :
	_ensure_refs()
	_normal_drop_hover_fill_texture = new_background_hover_fill_texture if use_new else _default_hover_fill_texture
	_normal_drop_hover_glow_texture = new_background_hover_glow_texture if use_new else _default_hover_glow_texture
	_apply_drop_hover_style()



func set_drop_hover_tint(tint: Color) -> void :
	if _drop_hover != null:
		_normal_drop_hover_tint = tint
		_apply_drop_hover_style()



func _apply_drop_hover_style() -> void :
	if _drop_hover_fill == null or _drop_hover_glow == null:
		return
	var red: bool = not _capacity_error_hint.is_empty()
	var fill_texture: Texture2D = invalid_drop_hover_fill_texture if red else _normal_drop_hover_fill_texture
	var glow_texture: Texture2D = invalid_drop_hover_glow_texture if red else _normal_drop_hover_glow_texture
	var tint: Color = Color.WHITE if red else _normal_drop_hover_tint

	if _drop_hover_fill.texture != fill_texture:
		_drop_hover_fill.texture = fill_texture
	if _drop_hover_glow.texture != glow_texture:
		_drop_hover_glow.texture = glow_texture
	if _drop_hover_glow.self_modulate != tint:
		_drop_hover_glow.self_modulate = tint


func _place_drop_hover() -> void :
	_refresh_col_mark_selection()
	if _drop_hover == null:
		return
	_drop_hover.modulate.a = 1.0
	if not _capacity_error_hint.is_empty() and _drag.is_empty():
		var error_col: int = int(_capacity_error_hint["col"])
		if _slot_of.has(error_col):
			_apply_drop_hover_style()
			var error_rect: Rect2 = _col_capsule_rect(error_col)
			_drop_hover.position = error_rect.position
			_drop_hover.size = error_rect.size
			_drop_hover.modulate.a = _capacity_error_hint_alpha()
			_drop_hover.visible = true
			return
	var guide: bool = _has_col_mark_guide()
	var slot: int = int(_slot_of.get(_hover_col, -1)) if _hover_col >= 0 else -1
	var selected_mark: bool = guide and (_col_mark_spec.get("guides", []) as Array).has(_hover_col)
	if _drag.is_empty() or slot < 0 or selected_mark:
		_apply_drop_hover_style()
		_drop_hover.visible = false
		return
	var src: int = int(_drag["col"])
	var invalid: bool = _level != null and _level.id >= 4 and _hover_col != src\
	and R.move_info(_state, src, int(_drag["j"]), _hover_col) <= 0
	_apply_drop_hover_style()
	if invalid:
		_drop_hover.visible = false
		return
	var r: Rect2 = _col_capsule_rect(_hover_col)
	_drop_hover.position = r.position
	_drop_hover.size = r.size
	_drop_hover.visible = true




func level() -> JuiceLevel:
	return _level


func state() -> Dictionary:
	return _state


func steps() -> int:
	return _steps


func move_attempt_count() -> int:
	return _move_attempt_count




func describe_move(src: int, j: int, dst: int) -> String:
	var cols: Array = _state.get("cols", [])
	var count: int = (cols[src] as Array).size() - j if src < cols.size() else 0
	return "第 %d 列下端 %d 朵 → 第 %d 列" % [int(_slot_of.get(src, src)) + 1, count, 
		int(_slot_of.get(dst, dst)) + 1]





func skip_challenge_opening_gate() -> void :
	_resumed_round = true


func successful_link_count() -> int:
	return _successful_link_count


func over() -> String:
	return _over




func cheat_preview_trail(slot: int) -> void :
	if _level == null or _lay == null or _skin == null:
		return
	_cancel_trail_previews()
	var count: int = _skin.colors.size()
	var q: int = maxi(1, _level.capacity)
	var ghost_x: float = size.x * 0.5
	var gap: float = _slam_len(q)
	if slot < 0:
		for i in count:
			_append_trail_preview(i, q, ghost_x, _t + gap * float(i), i == 0)
	elif slot < count:
		_append_trail_preview(slot, q, ghost_x, _t, true)


func _cancel_trail_previews() -> void :
	var left: Array = []
	for beat: Dictionary in _beats:
		if bool(beat.get("preview", false)):
			_finish_beat(beat)
		else:
			left.append(beat)
	_beats = left
	if _trail_preview_settle_pending and _beats.is_empty() and _shift_queue.is_empty():
		_trail_preview_settle_pending = false
		_snap_all_home()
		_check_over()
		settled.emit()


func _append_trail_preview(slot: int, q: int, ghost_x: float, t0: float, show_now: bool) -> void :
	var textures: Array[Texture2D] = _fruit_textures()
	var tex: Texture2D = textures[slot] if slot >= 0 and slot < textures.size() else null
	var tex_size: Vector2 = _skin.fruit_tex_size
	var nodes: Array[JuiceFruit] = []
	var spin_deg: = PackedFloat32Array()
	for i in q:
		var fruit: JuiceFruit = _fruit_pool.acquire(_fruit_layer) as JuiceFruit
		if fruit == null:
			continue
		fruit.col = -1
		fruit.idx = i
		fruit.setup(tex, -1, _lay.fruit_d, tex_size, false)
		fruit.position = Vector2(ghost_x, _lay.fruit_y(i))
		fruit.rotation = 0.0
		fruit.scale = Vector2.ONE
		fruit.visible = show_now
		nodes.append(fruit)
		spin_deg.append(randf_range(90.0, 180.0))
	var ribbons: Array = []
	ribbons.resize(nodes.size())
	var blender: JuiceBlender = _make_preview_blender(slot, ghost_x)
	if blender != null:
		blender.visible = show_now
	_beats.append({
		"preview": true, 
		"preview_color": JuiceTheme.color_of_slot(slot, _skin), 
		"preview_slot": slot, 
		"col": 0, 
		"fruit": _type_id_for_slot(slot), 
		"q": nodes.size(), 
		"nth": 0, 
		"spawns": [], 
		"t0": t0, 
		"ghost_x": ghost_x, 
		"ghost_top": _lay.blender_top + _lay.blender_h - _lay.blender_display_h, 
		"ghost_h": _lay.blender_display_h, 
		"ghost_w": _lay.blender_display_w, 
		"visual_token": -1, 
		"lead": 0.0, 
		"lead_from": PackedVector2Array(), 
		"lead_scale": PackedFloat32Array(), 
		"lead_rot": PackedFloat32Array(), 
		"lead_done": true, 
		"started": false, 
		"cup_sent": false, 
		"blender_released": false, 
		"burst_started": false, 
		"burst_tweens": [], 
		"nodes": nodes, 
		"blender": blender, 
		"spin_deg": spin_deg, 
		"trail_ribbons": ribbons, 
	})


func _make_preview_blender(slot: int, ghost_x: float) -> JuiceBlender:
	var blender: JuiceBlender = _blender_pool.acquire(_blender_layer) as JuiceBlender
	if blender == null:
		return null
	var empty_textures: Array[Texture2D] = _blender_textures()
	var empty_tex: Texture2D = empty_textures[slot] if slot >= 0 and slot < empty_textures.size() else null
	var full_tex: Texture2D = full_blender_texture_for_slot(slot)
	blender.col = -1
	blender.set_target(empty_tex, full_tex, slot, _empty_pot_content_rect(empty_tex), 
		_empty_pot_source_bottom(empty_tex))
	blender.place(_lay.blender_rect(0), _skin, _empty_pot_bottom_y(empty_tex, 0), _empty_pot_max_ratio())
	blender.position.x = ghost_x
	blender.modulate.a = 1.0
	return blender


func _type_id_for_slot(slot: int) -> int:
	for i in _slots.size():
		if _slots[i] == slot:
			return i
	return -1







func cheat_force_win() -> void :
	if _over != "" or _level == null or _state.is_empty():
		return
	var cups: Array[int] = _state["cups"] as Array[int]
	var remaining: Array[int] = _level.jar_seq.duplicate()
	for type_id: int in cups:
		remaining.erase(type_id)
	cups.append_array(remaining)
	_state["done"] = _level.groups_total
	_over = "win"
	_over_signal_pending = false
	cups_changed.emit()
	won.emit()







func complete_column_prop() -> bool:
	_complete_column_fail_reason = ""
	if _endless_session != null:

		if _over != "" or (_endless_move_guard.is_valid() and not bool(_endless_move_guard.call())):
			_complete_column_fail_reason = "board_over"
			return false
		var endless_blocked: String = _fill_pot_block_reason()
		if not endless_blocked.is_empty():
			_complete_column_fail_reason = endless_blocked
			return false
		var endless_result: Dictionary = _endless_session.complete_column(_order)
		if endless_result.is_empty():
			_complete_column_fail_reason = "no_column"
			return false
		_apply_complete_column_result(endless_result)
		return true
	var was_over: String = _over
	if was_over == "dead":
		_over = ""
	var blocked: String = _fill_pot_block_reason()
	var result: Dictionary = {}
	if blocked.is_empty():
		result = S.complete_column_checked(_state, _level, _order, {
			"now": Time.get_ticks_msec, "now_us": Time.get_ticks_usec, 
		})
	if result.is_empty():
		_complete_column_fail_reason = blocked if not blocked.is_empty() else "no_column"
		_over = was_over
		return false
	_log_fill_pot_check(result)
	_apply_complete_column_result(result)
	return true




func complete_column_fail_reason() -> String:
	return _complete_column_fail_reason



func _fill_pot_block_reason() -> String:
	var reason: String = _can_play_block_reason()
	if not reason.is_empty():
		return reason
	if is_busy():
		return "busy"
	if not _drag.is_empty():
		return "drag"
	if not _return.is_empty():
		return "returning"
	if is_entrance_motion_active():
		return "entrance_motion"
	if not _run_demo.is_empty():
		return "demo"
	return ""



func _log_fill_pot_check(result: Dictionary) -> void :
	var timing: Dictionary = result.get("timing", {}) as Dictionary
	var message: String = ("[完成一列] 关卡=%d 目标列=%d 回退=%s 候选列=%d "
			+ "落位=%d 封闭=%d 触顶=%s 构造耗时=%.2fms 结算耗时=%.2fms "
			+ "判定耗时=%.2fms 总耗时=%.2fms") % [
		_level.id if _level != null else -1, 
		int(result.get("target", -1)), 
		str(bool(result.get("fallback", false))), 
		int(timing.get("tried_cols", 0)), 
		int(timing.get("placements", 0)), 
		int(timing.get("closed_checks", 0)), 
		str(bool(timing.get("budget_hit", false))), 
		float(int(timing.get("build_us", 0))) / 1000.0, 
		float(int(timing.get("finalize_us", 0))) / 1000.0, 
		float(int(timing.get("check_us", 0))) / 1000.0, 
		float(int(timing.get("total_us", 0))) / 1000.0, 
	]
	if bool(result.get("fallback", false)):
		SortLogger.warn(message + " 死因=" + String(result.get("dead_reason", "")))
	else:
		SortLogger.info(message)





func _apply_complete_column_result(result: Dictionary) -> void :
	_cancel_closed_check()
	_reset_challenge_check()
	_invalidate_death_attribution()
	_clear_hint()
	_clear_run_highlight()
	_clear_tutorial_pot_highlight()
	clear_col_marks()
	_empty_rope_feedback.clear()
	_history.clear()

	var original: Dictionary = _fruit_nodes.duplicate()
	var original_blenders: Array = _blender_nodes.values()
	var from: Dictionary = {}
	for list: Array[JuiceFruit] in original.values():
		for fruit: JuiceFruit in list:
			from[fruit] = _fruit_layer_pos(fruit)
	var mapping: Dictionary = result["mapping"]
	var destinations: Dictionary = {}
	for ci: int in mapping:
		var list: Array[JuiceFruit] = []
		for origin: Dictionary in mapping[ci]:
			var fruit: JuiceFruit = (original[int(origin["col"])] as Array[JuiceFruit])[int(origin["index"])]
			destinations[fruit] = {"src_col": int(origin["col"]), "src_index": int(origin["index"]), 
				"dst_col": ci, "dst_index": list.size()}
			list.append(fruit)
		_fruit_nodes[ci] = list
	_reindex_all()
	_state = result["state"]
	var rec: Dictionary = result["rec"]
	var revealed_all: Array = rec.get("revealed", []) as Array
	var revealed_target: Array = rec.get("revealed_target", []) as Array

	var reveal_delay: float = JuiceFruit.REVEAL_DURATION\
	if not revealed_target.is_empty() else 0.0
	_complete_column_flight = {"start": _t, "entries": [], "hidden": [], "rec": rec, 
		"delay": reveal_delay, "target": int(result["target"]), 
		"phase": "reveal" if reveal_delay > 0.0 else "center"}



	_apply_reveals(revealed_target)

	var delayed_reveals: Array = _resolve_reveals(revealed_all.slice(revealed_target.size()))
	_enqueue_beats(rec["deposits"] as Array, true)
	if not delayed_reveals.is_empty():
		var attached: bool = false
		for beat: Dictionary in _beats:
			if not bool(beat.get("preview", false)):
				beat["pending_reveals"] = delayed_reveals
				attached = true
				break

		if not attached:
			_apply_node_reveals(delayed_reveals)



	var entries: Array = _complete_column_flight["entries"]
	var hidden: Array = _complete_column_flight["hidden"]
	for ci: int in _fruit_nodes:
		var list: Array[JuiceFruit] = _fruit_nodes[ci]
		var origins: Array = mapping.get(ci, []) as Array
		for i: int in list.size():
			var fruit: JuiceFruit = list[i]
			if not from.has(fruit):
				hidden.append({"node": fruit, "visible": fruit.visible})
				fruit.visible = false
				continue
			if _complete_column_origin_is(origins, i, ci):
				continue
			_prepare_complete_column_flower(entries, fruit, from[fruit], 
				_home_pos_swayed(ci, i), destinations[fruit])
	for beat: Dictionary in _beats:
		for i: int in (beat["nodes"] as Array).size():
			var fruit: JuiceFruit = (beat["nodes"] as Array)[i]
			if from.has(fruit):
				var dst_pos: Vector2 = Vector2(float(beat["ghost_x"]), 
					_lay.fruit_y(i) + float(beat["row_y"]))
				_prepare_complete_column_flower(entries, fruit, from[fruit], dst_pos, destinations[fruit])
			else:
				hidden.append({"node": fruit, "visible": fruit.visible})
				fruit.visible = false
	_prepare_complete_column_flight_schedule(entries)
	var fly_wait: float = float(_complete_column_flight["duration"]) + reveal_delay
	for beat: Dictionary in _beats:
		beat["t0"] = float(beat["t0"]) + fly_wait

	var blenders: Array = _blender_nodes.values()
	for beat: Dictionary in _beats:
		if is_instance_valid(beat["blender"]):
			blenders.append(beat["blender"])
	for blender: JuiceBlender in blenders:
		if not original_blenders.has(blender):
			hidden.append({"node": blender, "visible": blender.visible})
			blender.visible = false
	for shift: Dictionary in _shift_queue:
		shift["start_at"] = float(shift["start_at"]) + fly_wait
	_refresh_blenders()
	_steps += 1
	_complete_column_deposits = rec["deposits"]

	moved.emit(_steps)
	_complete_column_deposits = []
	_check_over()
	queue_redraw()



func _complete_column_origin_is(origins: Array, i: int, ci: int) -> bool:
	if i < 0 or i >= origins.size():
		return false
	var origin: Dictionary = origins[i] as Dictionary
	return int(origin.get("col", -1)) == ci and int(origin.get("index", -1)) == i



func _prepare_complete_column_flower(entries: Array, fruit: JuiceFruit, 
		from: Vector2, dst_pos: Vector2, destination: Dictionary) -> void :
	var stays: bool = int(destination["src_col"]) == int(destination["dst_col"])\
	and int(destination["src_index"]) == int(destination["dst_index"])
	var kind: String = "stay" if stays else ("gather"\
	if int(destination["dst_col"]) == int(_complete_column_flight["target"]) else "exchange")
	var entry: Dictionary = destination.duplicate()
	entry.merge({"node": fruit, "from": from, "dst_pos": dst_pos, "kind": kind, 
		"arrival_pos": dst_pos + COMPLETE_COLUMN_ARRIVAL_OFFSET if kind == "gather" else dst_pos, 
		"trail_ribbons": [], "trail_phase": "", "feedback_fx": null, 
		"trail_color": color_for_type(JuiceLevel.true_type(fruit.fruit_type))})
	if kind == "gather":
		var travel_x: float = dst_pos.x - from.x
		var direction: float = signf(travel_x)
		if int(destination["src_col"]) == int(destination["dst_col"]) or is_zero_approx(direction):
			direction = -1.0 if int(destination["dst_index"]) % 2 == 0 else 1.0
		var pullback: float = maxf(_lay.fruit_d, absf(travel_x) * COMPLETE_COLUMN_PULLBACK_RATIO)
		var arc_height: float = maxf(_lay.fruit_d * COMPLETE_COLUMN_ARC_HEIGHT_RATIO, absf(travel_x) * 0.15)
		entry["curve_from_control"] = from + Vector2( - direction * pullback, - _lay.fruit_d * 0.25)
		entry["curve_dst_control"] = (entry["arrival_pos"] as Vector2)\
		+ Vector2( - direction * _lay.fruit_d * 0.65, - arc_height)
	entries.append(entry)
	_set_drag_top_level(fruit, true)
	fruit.z_index = RETURN_Z + 1 if kind == "gather" else (RETURN_Z if kind == "exchange" else 0)
	_set_fruit_layer_pos(fruit, from)


func _prepare_complete_column_flight_schedule(entries: Array) -> void :
	var exchange_end: float = 0.0
	var gather_end: float = 0.0
	for entry: Dictionary in entries:
		if String(entry["kind"]) == "gather":
			entry["gather_duration"] = COMPLETE_COLUMN_GATHER_DUR\
			* randf_range(1.0 - COMPLETE_COLUMN_DEPARTURE_RANDOM_RATIO, 1.0 + COMPLETE_COLUMN_DEPARTURE_RANDOM_RATIO)
			entry["gather_duration"] = float(entry["gather_duration"]) + COMPLETE_COLUMN_MOTION_EXTRA_DUR
			gather_end = maxf(gather_end, COMPLETE_COLUMN_FEEDBACK_DUR + float(entry["gather_duration"]))
		elif String(entry["kind"]) == "exchange":
			entry["exchange_duration"] = COMPLETE_COLUMN_EXCHANGE_DUR\
			* randf_range(1.0 - COMPLETE_COLUMN_TIMING_RANDOM_RATIO, 1.0 + COMPLETE_COLUMN_TIMING_RANDOM_RATIO)
			entry["exchange_duration"] = float(entry["exchange_duration"]) + COMPLETE_COLUMN_MOTION_EXTRA_DUR
			exchange_end = maxf(exchange_end, float(entry["exchange_duration"]))
	_complete_column_flight.merge({"exchange_end": exchange_end, 
		"duration": maxf(exchange_end, gather_end)})




func _advance_complete_column_flight() -> void :
	var elapsed: float = _t - float(_complete_column_flight["start"])
	var delay: float = float(_complete_column_flight.get("delay", 0.0))
	var fly_elapsed: float = elapsed - delay
	if fly_elapsed < 0.0:
		return
	var phase: String = "feedback" if fly_elapsed < COMPLETE_COLUMN_FEEDBACK_DUR else "gather"
	_complete_column_flight["phase"] = phase
	for entry: Dictionary in _complete_column_flight["entries"]:
		if not is_instance_valid(entry["node"]):
			continue
		var fruit: JuiceFruit = entry["node"]
		var from: Vector2 = entry["from"]
		var dst_pos: Vector2 = entry["dst_pos"]
		var pos: Vector2 = from
		var scale: Vector2 = Vector2.ONE
		var rotation: float = 0.0
		var kind: String = entry["kind"]
		if kind == "gather":
			var arrival_pos: Vector2 = entry["arrival_pos"]
			var motion_elapsed: float = fly_elapsed - COMPLETE_COLUMN_FEEDBACK_DUR
			if phase == "feedback":
				scale = Vector2.ONE * _complete_column_feedback_scale(fly_elapsed)
			else:
				var gather_progress: float = clampf(motion_elapsed / float(entry["gather_duration"]), 0.0, 1.0)
				var gather_eased: float = _complete_column_motion_progress(motion_elapsed, 
					float(entry["gather_duration"]), COMPLETE_COLUMN_FLIGHT_BRAKE_RATIO)
				pos = from.bezier_interpolate(entry["curve_from_control"], entry["curve_dst_control"], arrival_pos, gather_eased)
				scale = Vector2.ONE * _complete_column_flight_scale(gather_progress)
				if gather_progress > 0.0 and gather_progress < 1.0:
					_start_complete_column_trails(entry, "gather")
		elif kind == "exchange":
			pos = from.lerp(dst_pos, _complete_column_motion_progress(fly_elapsed, 
				float(entry["exchange_duration"]), COMPLETE_COLUMN_BRAKE_RATIO))
		else:
			pos = from if phase == "feedback" or phase == "gather" else dst_pos
		_set_fruit_layer_pos(fruit, pos)
		fruit.scale = scale
		fruit.rotation = rotation
		if kind == "gather":
			if entry["feedback_fx"] == null:
				entry["feedback_fx"] = _acquire_complete_column_fx(fruit)
			var feedback_fx: CompleteColumnFlowerFx = entry["feedback_fx"]
			feedback_fx.global_position = fruit.tutorial_visual_center_global()
			var flying: bool = phase == "gather" and fly_elapsed > COMPLETE_COLUMN_FEEDBACK_DUR\
			and fly_elapsed - COMPLETE_COLUMN_FEEDBACK_DUR < float(entry["gather_duration"])
			var fade_start: float = COMPLETE_COLUMN_FEEDBACK_DUR + float(entry["gather_duration"])\
			- CompleteColumnFlowerFx.LANDING_FADE_DUR
			var dropping: bool = fly_elapsed >= fade_start
			var fade_progress: float = clampf((fly_elapsed - fade_start) / CompleteColumnFlowerFx.LANDING_FADE_DUR, 0.0, 1.0)
			feedback_fx.advance(fly_elapsed, scale.x, flying, dropping, fade_progress)
		if kind == "gather" and phase == "gather" and (entry["trail_ribbons"] as Array).size() == 1:
			var trail_width: float = _lay.fruit_d * scale.x * COMPLETE_COLUMN_TRAIL_WIDTH_RATIO
			(entry["trail_ribbons"][0] as FireworkTrails.Ribbon).head_width = trail_width * SpiralLightFx.TRAIL_GLOW_RATIO
		if kind == "gather" and fly_elapsed - COMPLETE_COLUMN_FEEDBACK_DUR >= float(entry["gather_duration"]):
			for ribbon: FireworkTrails.Ribbon in entry["trail_ribbons"]:
				ribbon.detach()
	if fly_elapsed + 1e-06 < float(_complete_column_flight["duration"]):
		return
	var rec: Dictionary = _complete_column_flight["rec"]

	var overrun: float = maxf(0.0, fly_elapsed - float(_complete_column_flight["duration"]))
	for beat: Dictionary in _beats:
		beat["t0"] = float(beat["t0"]) + overrun
		var arrival_positions: = PackedVector2Array()
		for fruit: JuiceFruit in (beat["nodes"] as Array):
			arrival_positions.append(_fruit_layer_pos(fruit))
		beat["complete_column_arrival"] = arrival_positions
	for shift: Dictionary in _shift_queue:
		shift["start_at"] = float(shift["start_at"]) + overrun
	_clear_complete_column_flight(false)
	_play_lock_unlock_effects(rec["unlocked"] as Array)
	_refresh_lock_overlays()


func _complete_column_feedback_scale(elapsed: float) -> float:
	var start: float = 1.0
	var finish: float = 1.2
	var duration: float = COMPLETE_COLUMN_FEEDBACK_UP_DUR
	if elapsed >= COMPLETE_COLUMN_FEEDBACK_UP_DUR + COMPLETE_COLUMN_FEEDBACK_DOWN_DUR:
		elapsed -= COMPLETE_COLUMN_FEEDBACK_UP_DUR + COMPLETE_COLUMN_FEEDBACK_DOWN_DUR
		start = 0.95
		finish = 1.0
		duration = COMPLETE_COLUMN_FEEDBACK_RESTORE_DUR
	elif elapsed >= COMPLETE_COLUMN_FEEDBACK_UP_DUR:
		elapsed -= COMPLETE_COLUMN_FEEDBACK_UP_DUR
		start = 1.2
		finish = 0.95
		duration = COMPLETE_COLUMN_FEEDBACK_DOWN_DUR
	var progress: float = clampf(elapsed / duration, 0.0, 1.0)
	return lerpf(start, finish, progress * progress * (3.0 - 2.0 * progress))


func _complete_column_flight_scale(progress: float) -> float:
	var restore_start: float = 1.0 - COMPLETE_COLUMN_RESTORE_RATIO
	if progress >= restore_start:
		return lerpf(COMPLETE_COLUMN_FLOAT_SCALE, 1.0, smoothstep(restore_start, 1.0, progress))
	return lerpf(1.0, COMPLETE_COLUMN_FLOAT_SCALE, smoothstep(0.0, restore_start, progress))


func _acquire_complete_column_fx(fruit: JuiceFruit) -> CompleteColumnFlowerFx:
	var effect: CompleteColumnFlowerFx = _complete_column_fx_pool.pop_back()\
	if not _complete_column_fx_pool.is_empty() else CompleteColumnFlowerFx.new()
	var feather: Texture2D = feather_for_type(JuiceLevel.true_type(fruit.fruit_type))
	var petals: Texture2D = feather if feather != null else effect_texture(&"rope_petal", rope_petal_texture)
	effect.z_index = RETURN_Z - 1
	effect.configure(_lay.fruit_d, petals, feather != null, effect_texture(&"quota_ring", null), 
		color_for_type(JuiceLevel.true_type(fruit.fruit_type)), fruit.visual_diameter(), 
		effect_texture(&"complete_column_glow", null), fruit.z_index + 1 - effect.z_index)
	if effect.get_parent() == null:
		_fruit_layer.add_child(effect)
	return effect


func _ensure_complete_column_trails() -> FireworkTrails:
	if is_instance_valid(_complete_column_trails):
		return _complete_column_trails
	var layer: Node2D = _resolve_fruit_layer()
	if layer == null:
		return null
	_complete_column_trails = FireworkTrails.new()
	_complete_column_trails.name = "CompleteColumnTrails"
	_complete_column_trails.z_index = RETURN_Z - 1
	layer.add_child(_complete_column_trails)
	layer.move_child(_complete_column_trails, 0)
	return _complete_column_trails


func _start_complete_column_trails(entry: Dictionary, phase: String) -> void :
	if String(entry["trail_phase"]) == phase:
		return
	for previous: FireworkTrails.Ribbon in entry["trail_ribbons"]:
		previous.detach()
	(entry["trail_ribbons"] as Array).clear()
	var trails: FireworkTrails = _ensure_complete_column_trails()
	if trails == null:
		return
	entry["trail_phase"] = phase
	var fruit: JuiceFruit = entry["node"]
	var width: float = _lay.fruit_d * fruit.scale.x * COMPLETE_COLUMN_TRAIL_WIDTH_RATIO
	var rgb: Color = entry["trail_color"]
	var ribbons: Array = entry["trail_ribbons"]
	ribbons.append(trails.add_ribbon(fruit, width * SpiralLightFx.TRAIL_GLOW_RATIO, rgb, 
		COMPLETE_COLUMN_TRAIL_ALPHA, COMPLETE_COLUMN_TRAIL_LIFETIME))


func _complete_column_motion_progress(elapsed: float, duration: float, brake_ratio: float) -> float:
	if elapsed <= 0.0:
		return 0.0
	if elapsed >= duration:
		return 1.0
	var base_duration: float = duration - COMPLETE_COLUMN_MOTION_EXTRA_DUR
	var speed: float = (1.0 + brake_ratio) / base_duration
	var brake_duration: float = base_duration * 2.0 * brake_ratio / (1.0 + brake_ratio)\
	+ COMPLETE_COLUMN_BRAKE_EXTRA_DUR
	var cruise_duration: float = 1.0 / speed - (COMPLETE_COLUMN_LAUNCH_DUR + brake_duration) * 0.5
	if elapsed < COMPLETE_COLUMN_LAUNCH_DUR:
		return speed * elapsed * elapsed / (2.0 * COMPLETE_COLUMN_LAUNCH_DUR)
	var launch_distance: float = speed * COMPLETE_COLUMN_LAUNCH_DUR * 0.5
	if elapsed < COMPLETE_COLUMN_LAUNCH_DUR + cruise_duration:
		return launch_distance + speed * (elapsed - COMPLETE_COLUMN_LAUNCH_DUR)
	var brake_elapsed: float = elapsed - COMPLETE_COLUMN_LAUNCH_DUR - cruise_duration
	return clampf(launch_distance + speed * cruise_duration\
	+ speed * (brake_elapsed - brake_elapsed * brake_elapsed / (2.0 * brake_duration)), 0.0, 1.0)



func _clear_complete_column_flight(cancelled: bool = true) -> void :
	if _complete_column_flight.is_empty():
		return
	for entry: Dictionary in _complete_column_flight["entries"]:
		var feedback_fx: CompleteColumnFlowerFx = entry["feedback_fx"]
		if is_instance_valid(feedback_fx):
			feedback_fx.reset_for_pool()
			_complete_column_fx_pool.append(feedback_fx)
			entry["feedback_fx"] = null
		for ribbon: FireworkTrails.Ribbon in entry["trail_ribbons"]:
			if cancelled:
				ribbon.reset()
			else:
				ribbon.detach()
		(entry["trail_ribbons"] as Array).clear()
		var fruit: Variant = entry["node"]
		if is_instance_valid(fruit):
			fruit.scale = Vector2.ONE
			fruit.rotation = 0.0
			_set_drag_top_level(fruit as JuiceFruit, false)
			fruit.z_index = 0
	for entry: Dictionary in _complete_column_flight["hidden"]:
		var node: Variant = entry["node"]
		if is_instance_valid(node):
			node.visible = bool(entry["visible"])
	_complete_column_flight.clear()



func cheat_prepare_last_cup() -> bool:
	if _over != "" or _level == null or _state.is_empty() or is_busy()\
	or not _drag.is_empty() or not _return.is_empty():
		return false
	var next_state: Dictionary = R.cheat_last_cup_state(_state, _level)
	if next_state.is_empty():
		return false
	_cancel_closed_check()
	_reset_challenge_check()
	_invalidate_death_attribution()
	_clear_hint()
	_clear_run_highlight()
	_clear_tutorial_pot_highlight()
	clear_col_marks()
	_run_demo = {}
	_history.clear()
	_state = next_state
	_rebuild_nodes()
	cups_changed.emit()
	_check_over()
	return _over == ""




func cheat_force_dead(reason: String = "stuck", attribution: int = -1) -> void :
	if _over != "" or _level == null:
		return
	_invalidate_death_attribution()
	_over = "dead"
	_pending_dead_reason = reason
	_over_signal_pending = false
	_play_skin_sound(&"juice_dead")
	dead.emit(reason)
	if attribution == -1:

		_start_death_attribution(reason)
		return
	_death_attribution = attribution
	dead_attributed.emit(attribution, reason, _steps)


func now() -> float:
	return _t


func order() -> Array[int]:
	return _order


func layout() -> JuiceLayout:
	return _lay







func sync_error() -> String:
	if _level == null:
		return ""
	var cols: Array = _state["cols"]
	for ci in cols.size():
		if bool((_state["gone"] as Array[bool])[ci]):
			continue
		var want: Array[int] = cols[ci]
		var got: Array[JuiceFruit] = _fruit_nodes.get(ci, [] as Array[JuiceFruit])
		if want.size() != got.size():
			return "第 %d 列:状态 %d 颗、节点 %d 个" % [ci, want.size(), got.size()]
		for i in want.size():
			if not is_instance_valid(got[i]):
				return "第 %d 列第 %d 个节点已失效" % [ci, i]
			if got[i].fruit_type != want[i]:
				return "第 %d 列第 %d 颗:状态 %d、节点 %d" % [ci, i, want[i], got[i].fruit_type]
	return ""



func note_player_operation() -> void :
	player_operated.emit()


func _rope_base_dx(y: float, ci: int, cap: int = -1) -> float:

	var rigid: bool = cap < 0 and _col_wind_is_rigid_line(ci)
	var slope: float = _idle_sway_slope(ci, cap) if cap >= 0\
	else (_rigid_lean_slope(ci) if rigid else _sway_slope(ci))
	var dx: float = slope * (y - roundf(_lay.hang_top))
	if _wind_active and not is_zero_approx(_wind_amp) and not rigid:
		dx += _wind_curve_dx(y)
	return dx



func bonus_collection_preview_geometry(ci: int) -> Dictionary:
	var rect: Rect2 = blender_rect_global(ci)
	if not rect.has_area():
		return {}
	var origins: Array[Vector2] = []
	var diameter: float = _lay.fruit_d
	var list: Array = _fruit_nodes.get(ci, [])
	for fruit: JuiceFruit in list:
		if is_instance_valid(fruit) and fruit.visible:
			origins.append(fruit.tutorial_visual_center_global())
			diameter = fruit.diameter() * fruit.global_transform.get_scale().abs().x
	if origins.is_empty() or origins.size() > 6:
		return {}
	return {"pot_rect": rect, "coin_origins": origins, "coin_diameter": diameter, "preview_col": ci}


func begin_bonus_collection_preview(pig: Control, ci: int) -> bool:
	end_bonus_collection_preview()
	if is_busy() or has_active_drag() or bonus_collection_preview_geometry(ci).is_empty():
		return false
	var hidden: Array[Dictionary] = []
	var blender: JuiceBlender = _blender_nodes[ci]
	hidden.append({"node": blender, "visible": blender.visible})
	for fruit: JuiceFruit in _fruit_nodes.get(ci, []):
		hidden.append({"node": fruit, "visible": fruit.visible})
	_bonus_preview_state = {"pig": pig, "parent": pig.get_parent(), "index": pig.get_index(), 
		"hidden": hidden}
	for entry: Dictionary in hidden:
		(entry["node"] as CanvasItem).hide()
	pig.reparent(_blender_layer, true)
	pig.z_index = 0
	return true

func end_bonus_collection_preview() -> void :
	if _bonus_preview_state.is_empty():
		return
	var saved: Dictionary = _bonus_preview_state
	_bonus_preview_state = {}
	var pig: Control = saved["pig"]
	var parent: Node = saved["parent"]
	if is_instance_valid(pig):
		pig.hide()
		if is_instance_valid(parent) and parent.is_inside_tree():
			pig.reparent(parent, true)
			parent.move_child(pig, mini(int(saved["index"]), parent.get_child_count() - 1))
	for entry: Dictionary in saved["hidden"]:
		if is_instance_valid(entry["node"]):
			(entry["node"] as CanvasItem).visible = bool(entry["visible"])



static func sample_collection_motion(home: Vector2, mouth: Vector2, index: int, age: float) -> Dictionary:
	if age < GHOST_FADE_DUR:
		var t: float = clampf(age / GHOST_FADE_DUR, 0.0, 1.0)
		var e: float = t * t * (3.0 - 2.0 * t)
		return {"center": home + Vector2(0.0, - SLAM_FLOAT_RISE * e), 
			"scale": lerpf(1.0, SLAM_FLOAT_SCALE, e), "done": false, "flight": false, "eased": 0.0}
	var u: float = clampf((age - GHOST_FADE_DUR) / SLAM_FLY_DUR, 0.0, 1.0)
	var eased: float = 1.0 - cos(u * PI * 0.5)
	var direction: float = -1.0 if index % 2 == 0 else 1.0
	var amp: float = SLAM_FLY_WAVE_AMP * pow(SLAM_FLY_WAVE_AMP_GROWTH, float(index / 2))
	var decay: float = pow(SLAM_FLY_WAVE_DECAY, floor(eased * SLAM_FLY_WAVE_CYCLES))
	var dx: float = direction * amp * decay * sin(eased * SLAM_FLY_WAVE_CYCLES * PI)
	var shrink: float = 1.0 - cos(clampf(u / SLAM_FLY_SHRINK_RATIO, 0.0, 1.0) * PI * 0.5)
	return {"center": (home + Vector2(0.0, - SLAM_FLOAT_RISE)).lerp(mouth, eased) + Vector2(dx, 0.0), 
		"scale": lerpf(1.0, SLAM_FLY_K, shrink), "done": u >= 1.0, "flight": true, "eased": eased}


func _start_bonus_entry_feedback(beat: Dictionary) -> void :
	_ensure_bonus_entry_feedback()
	var blender: JuiceBlender = beat.get("blender") as JuiceBlender
	if not is_instance_valid(blender):
		return
	var body: Sprite2D = blender.get_node("Body") as Sprite2D
	var rect: Rect2 = body.global_transform * body.get_rect()
	_bonus_entry_fx.start(rect.position + Vector2(0.5, SLAM_MOUTH_RATIO) * rect.size, int(beat["q"]), blender)

func is_bonus_entry_feedback_running() -> bool:
	return is_instance_valid(_bonus_entry_fx) and _bonus_entry_fx.is_running()

func stop_bonus_entry_feedback() -> void :
	_stop_skin_sound(&"bonus_coin_impact")
	if is_instance_valid(_bonus_entry_fx):
		_bonus_entry_fx.reset()
	if is_instance_valid(_bonus_handoff_source):
		for beat: Dictionary in _beats:
			if beat.get("blender") == _bonus_handoff_source:
				beat["blender"] = null
				beat["blender_released"] = true
		_blender_pool.release(_bonus_handoff_source)
	_bonus_handoff_source = null


func _ensure_bonus_gold_trails() -> BonusGoldTrails:
	if not is_instance_valid(_bonus_gold_trails):
		_bonus_gold_trails = BonusGoldTrails.new()
		_bonus_gold_trails.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_bonus_gold_trails.z_index = SLAM_FLY_Z
		_fruit_layer.add_child(_bonus_gold_trails)
		_fruit_layer.move_child(_bonus_gold_trails, 0)
		_bonus_gold_trails.prepare_pool(6)
	return _bonus_gold_trails

func _ensure_bonus_entry_feedback() -> BonusCoinEntryFx:
	if not is_instance_valid(_bonus_entry_fx):
		_bonus_entry_fx = bonus_entry_scene.instantiate() as BonusCoinEntryFx
		_bonus_entry_fx.z_index = SLAM_FLY_Z + 2
		get_parent().add_child(_bonus_entry_fx)
	return _bonus_entry_fx


func _start_bonus_coin_burst(beat: Dictionary) -> void :
	_spawn_rope_petals(float(beat["ghost_x"]), Color.WHITE, float(beat.get("row_y", 0.0)), 
		true, _beat_rope_range(beat))
	beat["bonus_coin_debris"] = true


func _bind_bonus_idle(target: JuiceBlender) -> void :

	_ensure_bonus_entry_feedback()
	_ensure_bonus_gold_trails()
	if not is_instance_valid(_bonus_idle_fx):
		_bonus_idle_fx = bonus_idle_scene.instantiate() as BonusPigIdleFx
		_bonus_idle_fx.z_index = 2
		get_parent().add_child(_bonus_idle_fx)
	_bonus_idle_fx.bind_target(self, target)



func take_bonus_pig_handoff() -> Dictionary:
	if not is_instance_valid(_bonus_handoff_source):
		return {}
	var source: JuiceBlender = _bonus_handoff_source
	var body: Sprite2D = source.get_node("Body") as Sprite2D
	var row_y: float = _row_y(source.col) if source.col >= 0 else 0.0
	var plank_top: float = (get_global_transform() * Vector2(0.0, _lay.plank_top + row_y)).y
	var result: Dictionary = {"node": source, "pool": _blender_pool, 
		"rect": body.global_transform * body.get_rect(), "plank_top": plank_top, 
		"lift_layer": garden_pot_layer}

	_blender_pool._live.erase(source)
	for beat: Dictionary in _beats:
		if beat.get("blender") == source:
			beat["blender"] = null
			beat["blender_released"] = true
	_bonus_handoff_source = null
	return result



func _request_major_sound(id: StringName, preview: bool) -> void :
	if major_sound_requested.has_connections():
		major_sound_requested.emit(id, preview)
	else:
		_play_skin_sound(id)



func _start_color_reject_hold(src: int, j: int, tail: JuiceFruit) -> void :
	_cancel_color_reject_hold()
	var source: Array[JuiceFruit] = _fruit_nodes.get(src, [] as Array[JuiceFruit])
	if j < 0 or j >= source.size():
		return
	var nodes: Array[JuiceFruit] = source.slice(j)
	var starts: Array[Vector2] = []
	for flower: JuiceFruit in nodes:
		starts.append(_fruit_layer_pos(flower))
	_color_reject_hold = {"nodes": nodes, "starts": starts, "tail": tail, 
		"start": _t, "feedback_started": false}


func _advance_color_reject_hold() -> void :
	if _color_reject_hold.is_empty():
		return
	var nodes: Array = _color_reject_hold["nodes"]
	var tail: JuiceFruit = _color_reject_hold["tail"]
	if nodes.is_empty() or not is_instance_valid(tail) or not is_instance_valid(nodes[0]):
		_cancel_color_reject_hold()
		return
	var age: float = _t - float(_color_reject_hold["start"])
	if age >= 0.5:
		_cancel_color_reject_hold()
		return
	if age >= 0.1 and not bool(_color_reject_hold["feedback_started"]):
		_color_reject_hold["feedback_started"] = true
		tail.play_color_reject()
		(nodes[0] as JuiceFruit).play_color_reject()


func _apply_color_reject_hold(flower: JuiceFruit) -> bool:
	if _color_reject_hold.is_empty():
		return false
	var nodes: Array = _color_reject_hold["nodes"]
	var index: int = nodes.find(flower)
	if index < 0:
		return false
	var age: float = _t - float(_color_reject_hold["start"])
	var tail: JuiceFruit = _color_reject_hold["tail"]
	var join: Vector2 = _fruit_layer_pos(tail) + Vector2(0.0, _lay.gap * 0.85)
	var starts: Array = _color_reject_hold["starts"]
	var end: Vector2 = join + Vector2(0.0, float(index) * _lay.gap * DRAG_GAP_RATIO)
	_set_fruit_layer_pos(flower, (starts[index] as Vector2).lerp(end, smoothstep(0.0, 0.1, age)))
	flower.scale = Vector2.ONE
	flower.rotation = 0.0
	return true


func _cancel_color_reject_hold() -> void :
	if _color_reject_hold.is_empty():
		return
	var tail: JuiceFruit = _color_reject_hold.get("tail") as JuiceFruit
	if is_instance_valid(tail):
		tail.cancel_color_reject()
	var nodes: Array = _color_reject_hold.get("nodes", [])
	if not nodes.is_empty() and is_instance_valid(nodes[0]):
		(nodes[0] as JuiceFruit).cancel_color_reject()
	_color_reject_hold.clear()



func rejected_target_space() -> int:
	var caps: Array = _state.get("caps", [])
	if _last_rejected_target < 0 or _last_rejected_target >= caps.size():
		return 0
	var cols: Array = _state.get("cols", [])
	if _last_rejected_target >= cols.size():
		return 0
	return maxi(0, int(caps[_last_rejected_target]) - (cols[_last_rejected_target] as Array).size())


func show_capacity_error_hint(duration: float) -> void :
	if _last_rejected_target < 0 or not _fruit_nodes.has(_last_rejected_target):
		return
	_capacity_error_hint = {"col": _last_rejected_target, "start": _t, "duration": duration}
	_place_drop_hover()
	queue_redraw()


func clear_capacity_error_hint() -> void :
	_capacity_error_hint.clear()
	_place_drop_hover()
	queue_redraw()


func _draw_capacity_error_hint() -> void :
	if _capacity_error_hint.is_empty():
		return
	var ci: int = int(_capacity_error_hint["col"])
	var cols: Array = _state.get("cols", [])
	var caps: Array = _state.get("caps", [])
	if ci < 0 or ci >= cols.size() or ci >= caps.size() or not _order.has(ci):
		return
	var count: int = (cols[ci] as Array).size()
	var alpha: float = _capacity_error_hint_alpha()
	var color: = Color(0.91, 0.43, 0.4, alpha * 0.8)
	for slot: int in range(count, int(caps[ci])):
		var y: float = _lay.fruit_y(slot) + _row_y(ci)
		var center: = Vector2(_col_x(ci) + _sway_dx(ci, y) + _content_dx, y)
		var radius: float = _lay.fruit_d * 0.264
		var width: float = maxf(2.0, _lay.fruit_d * 0.022)
		draw_circle(center, radius, Color(1.0, 0.76, 0.69, alpha * 0.13))

		for dash: int in 8:
			var start: float = float(dash) * TAU / 8.0 + 0.1
			var end: float = start + TAU / 8.0 * 0.57
			draw_arc(center, radius, start, end, 10, color, width, true)
			draw_circle(center + Vector2(cos(start), sin(start)) * radius, width * 0.5, color)
			draw_circle(center + Vector2(cos(end), sin(end)) * radius, width * 0.5, color)


func _capacity_error_hint_alpha() -> float:
	if _capacity_error_hint.is_empty():
		return 0.0
	var age: float = _t - float(_capacity_error_hint["start"])
	var duration: float = float(_capacity_error_hint["duration"])

	var fade_u: float = clampf((age - (duration - 0.25)) / 0.25, 0.0, 1.0)
	var fade: float = 1.0 - fade_u * fade_u * fade_u * (fade_u * (fade_u * 6.0 - 15.0) + 10.0)
	return smoothstep(0.0, 0.1, age) * fade



func set_new_error_animation_enabled(enabled: bool) -> void :
	_new_error_animation_enabled = enabled
	if not enabled:
		clear_capacity_error_hint()
		_cancel_color_reject_hold()


func has_skin_demo() -> bool:
	return not _run_demo.is_empty() or not _run_hl.is_empty()


func skin_color_slots() -> PackedInt32Array:
	return _slots.duplicate()

func has_skin_effects() -> bool:
	for effects: JuiceMysteryRevealEffects in _mystery_effect_sets.values():
		if effects.has_effects():
			return true
	for emitter: GPUParticles2D in _common_skin_emitters:
		if is_instance_valid(emitter) and emitter.visible:
			return true
	return false


func completed_visual(type_id: int) -> JuiceSkinVisual:
	if (_skin_resources == null or type_id < 0 or type_id >= _slots.size()
			or _is_bonus_type(type_id) or (_level != null and _level.is_sunlight_type(type_id))):
		return null
	return _skin_resources.color_visual(JuiceTheme.COLOR_KEYS[_slots[type_id]], &"completed_container")

func reset_skin_effects() -> void :
	for effects: JuiceMysteryRevealEffects in _mystery_effect_sets.values():
		effects.reset_immediate()
	_mystery_reveal_generation += 1
	if _connection_particles_preparing or _connection_particles_warming or _connection_instances_ready:
		_cancel_connection_preparation()
	for emitter: GPUParticles2D in _common_skin_emitters:
		if is_instance_valid(emitter):
			(emitter.get_meta(&"skin_lifecycle") as GpuParticleLifecycle).reset_immediate()


func warm_effects_render_optimized(active: Callable = Callable(), ice: bool = true, mystery: bool = true, full_warmup: bool = true, checkpoint: Callable = Callable()) -> bool:
	if active.is_valid() and not active.call():
		return false
	if mystery:
		var guard: Callable = active if active.is_valid() else func() -> bool: return is_inside_tree()
		if not await mystery_effects_for_skin(_skin_resources).prepare_render(self, guard, full_warmup):
			return false
		if not ice:
			return true
		mystery = false
	var viewport: = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer:
		SortLogger.error("JuiceBoardView warmup requires a detached SubViewport")
		return false
	_ensure_refs()
	_warming_effects = true

	var saved_fruit_d: float = _lay.fruit_d
	if _lay.fruit_d <= 0.0:
		_lay.fruit_d = JuiceLockOverlay.DESIGN_FRUIT_D

	var global_center: Vector2 = Vector2(viewport.size) * 0.5
	var center: Vector2 = get_global_transform().affine_inverse() * global_center
	var area: = Vector2(_lay.fruit_d * 1.2, _lay.fruit_d * 4.0)
	var tint: Color = Color.WHITE

	var spawns: Array[Callable] = [
		_spawn_unlock_spine.bind(center, area), 
		_spawn_unlock_leaves.bind(center, area), 
		_spawn_unlock_glows.bind(center, area, tint), 
		_spawn_mystery_reveal_petals.bind(global_center, tint, false, mystery_particle_texture(0)), 
		_spawn_mystery_reveal_glow.bind(global_center, tint), 
		_spawn_mystery_reveal_flash.bind(global_center, tint), 
		_spawn_mystery_reveal_star.bind(global_center, tint), 
	]

	var spawn_names: PackedStringArray = [
		"unlock_spine", "unlock_leaves", "unlock_glows", "mystery_petals", 
		"mystery_glow", "mystery_flash", "mystery_star", 
	]
	var completed: bool = true
	var guard: Callable = func() -> bool:
		return is_inside_tree() and get_viewport() == viewport and ( not active.is_valid() or active.call())
	for i in spawns.size():
		if (i < 3 and not ice) or (i >= 3 and not mystery):
			continue
		if active.is_valid() and not active.call():
			completed = false
			break
		if checkpoint.is_valid() and not await checkpoint.call(spawn_names[i]):
			completed = false
			break
		NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:%s" % spawn_names[i])
		var previous_nodes: Array = _warm_effect_releases.keys()
		spawns[i].call()

		for node: CanvasItem in _warm_effect_releases:
			if node is GPUParticles2D and not previous_nodes.has(node):
				var lifecycle: GpuParticleLifecycle = node.get_meta(&"skin_lifecycle")
				if not await lifecycle.pre_render(guard, 0.12 if full_warmup else 0.0):
					completed = false
					break
		await RenderingServer.frame_post_draw
		if not completed:
			break

		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:%s" % spawn_names[i])

		_clear_warm_effects()


	NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:flush")
	_clear_warm_effects()
	_warming_effects = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 2:
		await RenderingServer.frame_post_draw
	NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:flush")
	_lay.fruit_d = saved_fruit_d
	return completed and ( not active.is_valid() or active.call())


func warm_connection_particles_render_optimized(active: Callable = Callable(), full_warmup: bool = true, checkpoint: Callable = Callable()) -> bool:
	if _connection_particles_warmed:
		return true
	if DisplayServer.get_name() == "headless" or _connection_particles_warming or (active.is_valid() and not active.call()):
		return false
	var viewport: SubViewport = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer:
		SortLogger.error("JuiceBoardView connection warmup requires a detached SubViewport")
		return false
	if not _connection_instances_ready:
		if not await prepare_connection_particles_spread(active):
			return false
	var generation: int = _connection_preparation_generation
	var guard: Callable = func() -> bool:
		return is_inside_tree() and get_viewport() == viewport and generation == _connection_preparation_generation\
		and ( not active.is_valid() or active.call())
	_connection_particles_warming = true
	var completed: bool = true
	var emitters: Array[GPUParticles2D] = []
	emitters.assign(_connection_prepared_petals)
	emitters.append(_connection_prepared_stars)
	for i: int in emitters.size():
		var stage: String = "connection_petals_%d" % i if i < 2 else "connection_stars"
		if not guard.call() or (checkpoint.is_valid() and not await checkpoint.call(stage)) or not guard.call():
			completed = false
			break

		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var emitter: GPUParticles2D = emitters[i]
		NativeUtilManager.set_crashlytics_key("boot_step", "WarmGameEffects:%s" % stage)
		var started: int = Time.get_ticks_usec()
		var rendered: bool = await _rope_particle_lifecycles[emitter].pre_render(guard, 
			(0.12 if i < 2 else 0.05) if full_warmup else 0.0)
		SortLogger.info("[ConnectionRender] stage=%s elapsed_ms=%.2f success=%s" % [
			stage, (Time.get_ticks_usec() - started) / 1000.0, rendered])
		if not rendered:
			completed = false
			break
		NativeUtilManager.set_crashlytics_key("boot_step_done", "WarmGameEffects:%s" % stage)
	if generation != _connection_preparation_generation:
		return false
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_release_prepared_connection_particles()
	_connection_particles_warming = false
	_connection_particles_warmed = completed and guard.call()
	return _connection_particles_warmed


func _ensure_rope_petal_ramp_optimized() -> GradientTexture1D:
	if _rope_petal_ramp == null:
		_rope_petal_ramp = preload("res://assets/effect/texture/particle_preparation/connection_petal_fade.tres")
	return _rope_petal_ramp


func _ensure_rope_star_scale_curve_optimized() -> CurveTexture:
	if _rope_star_scale_curve == null:
		_rope_star_scale_curve = preload("res://assets/effect/texture/particle_preparation/connection_star_scale.tres")
	return _rope_star_scale_curve


func prepare_connection_particles_spread(active: Callable = Callable(), checkpoint: Callable = Callable(), progress: Callable = Callable()) -> bool:
	if _connection_instances_ready or _connection_particles_warmed:
		if active.is_valid() and not active.call():
			if _connection_instances_ready and not _connection_particles_warming:
				_cancel_connection_preparation()
			return false
		return true
	if _connection_particles_preparing or _connection_particles_warming:
		return false
	var viewport: SubViewport = get_viewport() as SubViewport
	if viewport == null or viewport.get_parent() is SubViewportContainer or rope_petal_texture == null:
		return false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_connection_preparation_generation += 1
	var generation: int = _connection_preparation_generation
	_connection_particles_preparing = true
	var guard: Callable = func() -> bool:
		return is_inside_tree() and get_viewport() == viewport and generation == _connection_preparation_generation\
		and ( not active.is_valid() or active.call())
	_ensure_refs()
	var resource_steps: Array[Callable] = [_ensure_rope_petal_shader_mat, _ensure_rope_petal_ramp, 
		_ensure_rope_star_add_mat, _ensure_rope_star_scale_curve]
	for i: int in resource_steps.size():
		if not await _connection_prepare_checkpoint(checkpoint, "connection/resources_%d" % i, false, guard):
			_cancel_connection_preparation_if_current(generation)
			return false
		var started: int = Time.get_ticks_usec()
		resource_steps[i].call()
		_log_connection_preparation("resources_%d" % i, started)
		if progress.is_valid():
			progress.call(float(i + 1) / 10.0)
	var fruit_d: float = _lay.fruit_d if _lay.fruit_d > 0.0 else JuiceLockOverlay.DESIGN_FRUIT_D
	var layer: Node2D = _resolve_fruit_layer()
	var center: Vector2 = layer.get_global_transform_with_canvas().affine_inverse() * (Vector2(viewport.size) * 0.5)
	var top_y: float = center.y - fruit_d
	var bot_y: float = center.y + fruit_d
	var amount: int = maxi(1, int(round((bot_y - top_y) / 10.0 * ROPE_PETAL_DENSITY_PER_10PX)) / 2)
	for i: int in 3:
		var label: String = "petals_%d" % i if i < 2 else "stars"
		if not await _connection_prepare_checkpoint(checkpoint, "connection/%s/create" % label, true, guard):
			_cancel_connection_preparation_if_current(generation)
			return false
		var started: int = Time.get_ticks_usec()
		var emitter: GPUParticles2D = _acquire_rope_petal_emitter() if i < 2 else _acquire_rope_star_emitter()
		if emitter == null:
			_cancel_connection_preparation_if_current(generation)
			return false
		emitter.set_meta(&"connection_warming", true)
		if i < 2:
			_connection_prepared_petals.append(emitter)
		else:
			_connection_prepared_stars = emitter
		_log_connection_preparation(label + "/create_attach", started)
		if progress.is_valid():
			progress.call(float(5 + i * 2) / 10.0)
		if not await _connection_prepare_checkpoint(checkpoint, "connection/%s/configure" % label, true, guard):
			_cancel_connection_preparation_if_current(generation)
			return false
		started = Time.get_ticks_usec()

		var saved_fruit_d: float = _lay.fruit_d
		_lay.fruit_d = fruit_d
		if i < 2:
			var spin_min: float = ROPE_PETAL_SPIN_MIN if i == 0 else - ROPE_PETAL_SPIN_MAX
			var spin_max: float = ROPE_PETAL_SPIN_MAX if i == 0 else - ROPE_PETAL_SPIN_MIN
			_rope_particle_lifecycles[emitter].reconfigure(_configure_rope_petals.bind(emitter, 
				center.x, top_y, bot_y, amount, spin_min, spin_max, Color.WHITE))
		else:
			_rope_particle_lifecycles[emitter].reconfigure(_configure_rope_stars.bind(emitter, 
				center.x, 1.0, 1.0, 0.0, Vector2(top_y, bot_y)))
		_lay.fruit_d = saved_fruit_d
		_log_connection_preparation(label + "/configure", started)
		if progress.is_valid():
			progress.call(float(6 + i * 2) / 10.0)
	if not guard.call():
		_cancel_connection_preparation_if_current(generation)
		return false
	_connection_particles_preparing = false
	_connection_instances_ready = true
	return true


func _connection_prepare_checkpoint(checkpoint: Callable, stage: String, force_frame: bool, guard: Callable) -> bool:
	if not guard.call():
		return false
	if checkpoint.is_valid():
		var permitted: bool = await checkpoint.call(stage, force_frame)
		return permitted and guard.call()
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	return guard.call()


func _log_connection_preparation(stage: String, started: int) -> void :
	SortLogger.info("[ConnectionPrepare] stage=%s cpu_ms=%.2f" % [
		stage, (Time.get_ticks_usec() - started) / 1000.0])


func _cancel_connection_preparation_if_current(generation: int) -> void :
	if generation == _connection_preparation_generation:
		_cancel_connection_preparation()


func _release_prepared_connection_particles() -> void :
	for emitter: GPUParticles2D in _connection_prepared_petals:
		if is_instance_valid(emitter):
			emitter.remove_meta(&"connection_warming")
			_release_rope_petal_emitter(emitter)
	_connection_prepared_petals.clear()
	if is_instance_valid(_connection_prepared_stars):
		_connection_prepared_stars.remove_meta(&"connection_warming")
		_release_rope_star_emitter(_connection_prepared_stars)
	_connection_prepared_stars = null
	_connection_instances_ready = false


func _cancel_connection_preparation() -> void :
	_connection_preparation_generation += 1
	_connection_particles_preparing = false
	_connection_particles_warming = false
	_connection_particles_warmed = false
	_release_prepared_connection_particles()
