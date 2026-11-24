
extends Node
class StartRoundHost extends RefCounted:
	var finished: bool = false
	var fallback_shown: bool = false
	var succeeds: bool = true
	func should_run_tutorial_now(_restore: Dictionary) -> bool:
		return false
	func start_round(_restore: Dictionary) -> bool:
		await (Engine.get_main_loop() as SceneTree).process_frame
		finished = true
		return succeeds
	func show_fallback_toast_if_needed() -> void :
		fallback_shown = true

class ClaimHost extends Node:
	var generation: int = 1
	var collects: int = 0
	var fades: int = 0
	var presentation_steps: Array[String] = []
	func is_claim_current(g: int) -> bool:
		return g == generation
	func fade_presentation(_grant: Dictionary) -> void :
		fades += 1
		presentation_steps.append("fade")
	func play_collection(_grant: Dictionary) -> void :
		collects += 1
		presentation_steps.append("collect")
var checks: int = 0
var failures: int = 0
func check(value: bool, label: String) -> void :
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _ready() -> void :
	for path: String in ["res://scripts/main/pages/game/juice_game_page.tscn", "res://scripts/main/pages/home/home_page.tscn", "res://scripts/main/dialogs/finish/finish_dialog.tscn", "res://scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn"]:
		var scene: PackedScene = load(path)
		check(scene != null, path)
		if scene != null:
			var node: Node = scene.instantiate()
			check(node != null, "instantiate " + path)
			node.free()
	check( not SpecialChallengeRules.is_anchor(26), "26")
	check(SpecialChallengeRules.is_anchor(27), "27")
	check( not SpecialChallengeRules.is_anchor(28), "28")
	check(SpecialChallengeRules.is_anchor(37), "37")
	check( not SpecialChallengeRules.is_anchor(17), "no early injection")
	check(SpecialChallengeRules.case_number(199) == 200 and SpecialChallengeRules.case_number(200) == 1, "bank wrap")
	var reward_packages: Array[Dictionary] = [
		{"coins": 300, "undo": 1, "hint": 1, "rope": 0}, 
		{"coins": 0, "undo": 0, "hint": 0, "rope": 1}, 
		{"coins": 0, "undo": 2, "hint": 1, "rope": 0}, 
	]
	var buckets: Array[int] = [0, 0, 0]
	for roll: int in 100:
		var reward: Dictionary = SpecialChallengeRules.reward_for_roll(roll)
		buckets[0 if reward.coins > 0 else (1 if reward.rope > 0 else 2)] += 1
		var doubled: Dictionary = SpecialChallengeRules.multiplied_reward(reward, 2)
		for kind: String in reward:
			check(doubled[kind] == reward[kind] * 2, "full package doubled")
	check(buckets == [40, 20, 40], "probability boundaries")
	for roll: int in [0, 39, 40, 59, 60, 99]:
		check(SpecialChallengeRules.reward_for_roll(roll) == reward_packages[0 if roll < 40 else (1 if roll < 60 else 2)], "boundary roll %d" % roll)
	var changed_reward: Dictionary = SpecialChallengeRules.reward_for_roll(0)
	changed_reward.coins = 900
	check(SpecialChallengeRules.reward_for_roll(0).coins == 300, "reward dictionaries are independent")
	var reward_scene: PackedScene = load("res://scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn")
	var reward_dialog: SpecialChallengeRewardDialog = reward_scene.instantiate()
	add_child(reward_dialog)
	await get_tree().process_frame
	for package: Dictionary in reward_packages:
		for multiplier: int in [1, 2]:
			var shown: Dictionary = SpecialChallengeRules.multiplied_reward(package, multiplier)
			reward_dialog.set("_reward", shown)
			reward_dialog.call("_refresh_reward")
			reward_dialog.call("_filter_reward_slots", reward_dialog.get("_spine"))
			for kind: String in ["coins", "hint", "undo", "rope"]:
				var item: Node2D = reward_dialog.get_node("Presentation/Rewards/" + kind)
				check(item.visible == (int(shown[kind]) > 0), "only awarded item visible: " + kind)
				check(item.get_node("Count").text == str(shown[kind]), "reward quantity: " + kind)
			var rope_icon: Sprite2D = reward_dialog.get_node("Presentation/Rewards/rope/Icon")
			check(rope_icon.texture != null and rope_icon.visible, "rope icon is bound for cached dialog reuse")
			var slots: Dictionary = reward_dialog.get("_slots")
			for kind: String in ["coins", "hint", "undo"]:
				if int(shown[kind]) == 0:
					check((slots[SpecialChallengeRewardDialog.REWARD_SLOTS[kind]] as SpineSlot).get_attachment() == null, "absent original Spine icon hidden: " + kind)
	reward_dialog.queue_free()
	await get_tree().process_frame
	var bank: = SpecialChallengeBank.new()
	var colors: Array[int] = [0, 0]
	for i: int in SpecialChallengeRules.BANK_SIZE:
		var data: Dictionary = bank.read_case(i + 1)
		data["round_kind"] = "special_challenge"
		data["level_id"] = 28
		var model: = JuiceLevelModel.new()
		model.from_dict(data)
		check(model.juice.validate().is_empty(), "valid puzzle %d" % (i + 1))
		colors[model.juice.groups_total - 4] += 1
		check(model.juice.id == 28 and model.juice.capacity == 8, "special model id/capacity")
		for incoming: Dictionary in model.juice.incoming:
			check(incoming.slot == JuiceLevel.SLOT_RETIRE, "never replenish")
		await get_tree().process_frame
	check(colors == [3, 197], "four/five color bank counts")


	for width: float in [1080.0, 1755.0]:
		for height: float in [1492.0, 1612.0, 1872.0]:
			for pots: int in [4, 5]:
				for extra: int in [0, 1]:
					var layout: = JuiceLayout.new()
					layout.solve(Rect2(0, 0, width, height), pots + 1 + extra, 8, JuiceSkin.bead(), pots + 1)
					check(layout.gap > 0 and layout.fruit_d > 0, "long rope positive geometry")
					for col: int in pots + 1 + extra:
						check(layout.fruit_pos(col, 7).y <= height, "long rope bottom fits")
						check(layout.slot_center_x(col) >= 0 and layout.slot_center_x(col) <= width, "long rope horizontal fits")

	var raw: Dictionary = bank.read_case(1).raw
	var lv: = JuiceLevel.from_dict(raw)
	var st: Dictionary = JuiceRules.make_state(lv)
	var target_col: int = 1
	while st.jars[target_col] < 0:
		target_col += 1
	st.cols[target_col] = [] as Array[int]
	for bead: int in lv.capacity:
		st.cols[target_col].append(st.jars[target_col])
	var logs: Array = []
	check(JuiceRules.run_deposit(st, lv, logs) >= 1, "matching target deposits")
	check(st.gone[target_col] and st.caps[target_col] == 0 and st.cols[target_col].is_empty(), "deposit retires without refill")
	DbManager.init()
	DbManager.reset_all_levels()
	UserState.reset_all()
	await _test_special_schedule()
	UserState.reset_all()
	DbManager.reset_all_levels()
	UserState.set_current_level(28)
	check( not UserState.has_special_challenge() and UserState.get_special_challenge_offer_after() == 0, "old player no catchup")
	UserState.begin_level_completion(27)
	UserState.finalize_level_completion(27)
	check(UserState.resolve_special_challenge_offer(true), "offer after normal27")
	var active: Dictionary = UserState.get_special_challenge()
	var id: String = active.instance_id
	LevelManager.register_parser(JuiceLevelParser.new())
	var loaded: Dictionary = LevelManager.load_special_challenge()
	check( not loaded.is_empty(), "shared parser load")
	var model: LevelModel = loaded.model
	var saver: = SpecialChallengeSaver.new()
	check(saver.save_initial(id, model, {"test": 1}), "save challenge")
	var first: String = saver.load_session(id).game_id
	check(saver.save_state(id, {"test": 2}, 1234), "move persisted")
	check(saver.load_session(id).current_state.test == 2, "move restore")
	check(saver.load_session(id).game_id == first, "resume keeps id")
	check(saver.save_initial(id, model, {"test": 1}), "restart snapshot")
	check(saver.load_session(id).game_id != first, "restart changes id")
	check(DbManager.load_level_entity(28).is_empty(), "special does not create ordinary28")
	var ordinary: = LevelEntity.for_level(28)
	ordinary.game_id = "ordinary-preserved"
	ordinary.current_state = {"normal": true}
	check(DbManager.save_level_entity(ordinary.to_row()), "existing normal28 fixture")
	check(saver.save_state(id, {"test": 3}, 1234), "special update with normal row present")
	check(DbManager.load_level_entity(28).game_id == "ordinary-preserved", "ordinary id preserved")
	check(JSON.parse_string(DbManager.load_level_entity(28).current_state).normal, "ordinary snapshot preserved")
	_test_challenge_tracking(id, model, saver)
	UserState.on_win_streak_won(12, 1000, 5)
	UserState.cheat_set_win_streak(4)
	var best_results: Dictionary = UserState.get("_finish_best_results").duplicate(true)
	var tmp_path: String = UserState.call("_resolve_save_path") + ".tmp"
	check( not UserState.begin_special_challenge_completion("wrong-instance"), "wrong challenge cannot complete")
	check(UserState.get_win_streak_count() == 4, "wrong challenge preserves streak")
	DirAccess.make_dir_absolute(tmp_path)
	check( not UserState.begin_special_challenge_completion(id), "save failure blocks challenge win")
	check(UserState.get_special_challenge().status == "playing", "failed win rolls back challenge journal")
	check(UserState.get_win_streak_count() == 4 and UserState.get("_finish_best_streak") == 1
		and UserState.get("_last_streak_record_count") == 0, "failed win rolls back streak and record")
	DirAccess.remove_absolute(tmp_path)
	check(UserState.begin_special_challenge_completion(id), "freeze reward")
	check(UserState.get_win_streak_count() == 5, "challenge win adds exactly one streak")
	check(UserState.get("_finish_best_streak") == 5 and UserState.is_current_streak_record(5), "challenge win updates personal streak record")
	check(UserState.get("_finish_best_results") == best_results, "challenge leaves ordinary time and step records unchanged")
	var reward: Dictionary = UserState.get_special_challenge().reward
	check(reward in reward_packages, "completion freezes one of the authorized random packages")
	check(UserState.begin_special_challenge_completion(id), "repeat pending idempotent")
	check(UserState.get_win_streak_count() == 5, "duplicate pending win never adds streak")
	check(reward == UserState.get_special_challenge().reward, "never reroll")
	UserState.call("_load_data")
	check(reward == UserState.get_special_challenge().reward, "journal survives reload")
	check(UserState.get_win_streak_count() == 5 and UserState.is_current_streak_record(5), "challenge streak and record survive reload")
	check(LevelManager.recover_special_challenge_completion(), "recover interrupted commit")
	check(LevelManager.recover_special_challenge_completion(), "recovery idempotent")
	check(LevelManager.complete_special_challenge(id), "duplicate completed win succeeds")
	check(UserState.get_win_streak_count() == 5, "journal recovery and duplicate completed win never add streak")
	var before: int = UserState.get_coins()
	DirAccess.make_dir_absolute(tmp_path)
	check(UserState.claim_special_challenge(id, 2).is_empty(), "save failure blocks claim")
	check(UserState.get_coins() == before and UserState.has_special_challenge(), "failed claim rolls back all state")
	DirAccess.remove_absolute(tmp_path)
	var granted: Dictionary = UserState.claim_special_challenge(id, 2)
	check( not granted.is_empty(), "claim atomically")
	check(UserState.get_coins() == before + int(reward.coins) * 2, "grant balance")
	check(UserState.claim_special_challenge(id, 2).is_empty(), "duplicate claim blocked")
	UserState.call("_load_data")
	check( not UserState.has_special_challenge() and UserState.get_current_level() == 28, "claimed reload and normal cursor")
	check(UserState.get_win_streak_count() == 5, "claim and reload preserve counted challenge win")
	var pending_coins: int = UserState.get_coins()
	var pending_props: Dictionary = {}
	for kind: String in ["hint", "undo", "rope"]:
		pending_props[kind] = UserState.get_prop_count(kind)
	var completed: int = UserState.get("_special_challenge_completed")
	for status: String in ["win_pending", "reward_pending"]:
		for package: Dictionary in reward_packages:
			UserState.set("_special_challenge", {"instance_id": id, "case_number": 1, "after_level": 27, "status": status, "reward": package})
			UserState.call("_save_data")
			UserState.call("_load_data")
			check(UserState.get_special_challenge().reward == package, "pending reward survives reload without replacement")
			check(UserState.get_special_challenge().status == status, "reload preserves pending lifecycle")
			check(UserState.get_coins() == pending_coins and UserState.get("_special_challenge_completed") == completed, "reload never grants or advances")
			for kind: String in pending_props:
				check(UserState.get_prop_count(kind) == pending_props[kind], "reload preserves " + kind)
	UserState.set("_special_challenge", {"instance_id": id, "case_number": 1, "after_level": 27, "status": "reward_pending", "reward": reward_packages[1]})
	UserState.call("_save_data")
	DirAccess.make_dir_absolute(tmp_path)
	UserState.call("_load_data")
	check(UserState.get_special_challenge().reward == reward_packages[1], "pending rope remains exactly the stored package")
	check(UserState.claim_special_challenge(id, 1).is_empty() and UserState.get_coins() == pending_coins, "failed rope claim rolls back economy")
	check(UserState.get_special_challenge().reward == reward_packages[1], "failed claim never redraws reward")
	DirAccess.remove_absolute(tmp_path)
	var pending_grant: Dictionary = UserState.claim_special_challenge(id, 1)
	check(pending_grant.get("reward", {}) == reward_packages[1], "retry grants exactly the displayed rope")
	check(UserState.get_coins() == pending_coins, "rope claim gives no coins")
	check(UserState.get_prop_count("hint") == pending_props.hint and UserState.get_prop_count("undo") == pending_props.undo, "rope claim gives no other props")
	check(UserState.get_prop_count("rope") == pending_props.rope + 1, "rope claim grants one rope")
	UserState.call("_load_data")
	check( not UserState.has_special_challenge() and UserState.get_prop_count("rope") == pending_props.rope + 1, "claimed package is never granted twice")


	UserState.begin_level_completion(37)
	UserState.finalize_level_completion(37)
	UserState.resolve_special_challenge_offer(true)
	active = UserState.get_special_challenge()
	id = active.instance_id
	loaded = LevelManager.load_special_challenge()
	saver.save_initial(id, loaded.model, {"test": 1})
	LevelManager.complete_special_challenge(id)
	var host: = ClaimHost.new()
	add_child(host)
	MockUnikitConfig.set_mock_enabled(true)
	MockUnikitConfig.set_mock_reward_ad_ready(MockUnikitConfig.MockState.FALSE)
	check( not await AdManager.check_reward_ads_available("special_challenge"), "no fill")
	check(( await SpecialChallengeClaimFlow.run(host, 1, id, 2)).is_empty(), "no fill grants nothing")
	MockUnikitConfig.set_mock_reward_ad_ready(MockUnikitConfig.MockState.TRUE)
	MockUnikitConfig.set_mock_reward_ad_result(MockUnikitConfig.MockState.FALSE)
	check(( await SpecialChallengeClaimFlow.run(host, 1, id, 2)).is_empty(), "ad failed grants nothing")
	MockUnikitConfig.set_mock_reward_ad_result(MockUnikitConfig.MockState.TRUE)
	check(( await SpecialChallengeClaimFlow.run(host, 0, id, 2)).is_empty(), "stale callback grants nothing")
	check( not ( await SpecialChallengeClaimFlow.run(host, 1, id, 2)).is_empty(), "rewarded ad grants package")
	check(host.collects == 1, "collection runs after successful grant only")
	check(host.fades == 1 and host.presentation_steps == ["fade", "collect"], "successful grant fades presentation before collection")
	check(( await SpecialChallengeClaimFlow.run(host, 1, id, 1)).is_empty(), "duplicate flow callback blocked")
	check(host.collects == 1, "no duplicate collection")
	check(host.fades == 1, "no duplicate presentation fade")
	host.queue_free()
	await _test_claim_hud_reveal()
	UserState.reset_all()
	DbManager.reset_all_levels()
	var ab_was_init_done: bool = ABManager.is_ab_init_done()
	ABManager.set("_is_init_done", false)
	UserState.begin_level_completion(27)
	check(UserState.finalize_level_completion(27), "default offer after normal27")
	var default_descriptor: Dictionary = LevelManager.get_next_round_descriptor()
	check(bool(default_descriptor["is_special"]), "default challenge inserts without AB readiness")
	check(UserState.get_special_challenge_offer_after() == 0, "default offer consumed once")
	ABManager.set("_is_init_done", true)
	check(LevelManager.get_next_round_descriptor() == default_descriptor, "started challenge stays frozen after AB readiness changes")
	ABManager.set("_is_init_done", ab_was_init_done)
	UserState.reset_all()
	DbManager.reset_all_levels()
	UserState.begin_level_completion(27)
	UserState.finalize_level_completion(27)
	UserState.resolve_special_challenge_offer(false)
	check( not bool(LevelManager.get_next_round_descriptor()["is_special"]), "previously consumed offer is not caught up")
	UserState.begin_level_completion(37)
	UserState.finalize_level_completion(37)
	var next_descriptor: Dictionary = LevelManager.get_next_round_descriptor()
	check(bool(next_descriptor["is_special"]), "default descriptor inserts after next anchor")
	check(LevelManager.get_next_round_descriptor() == next_descriptor, "started challenge remains the same instance")
	UserState.reset_all()
	DbManager.reset_all_levels()
	UserState.begin_level_completion(27)
	UserState.finalize_level_completion(27)
	ordinary = LevelEntity.for_level(28)
	ordinary.game_id = "normal-already-started"
	ordinary.current_state = {"normal": true}
	DbManager.save_level_entity(ordinary.to_row())
	check( not bool(LevelManager.get_next_round_descriptor()["is_special"]), "existing normal28 cannot be replaced")
	_test_replayed_anchor_offer()
	UserState.reset_all()
	DbManager.reset_all_levels()
	print("SPECIAL TEST %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _test_special_schedule() -> void :
	var defaults: Dictionary = SpecialChallengeRules.default_schedule()
	var android: Dictionary = SpecialChallengeRules.schedule_for_platform("Android")
	var ios: Dictionary = SpecialChallengeRules.schedule_for_platform("iOS")
	check(android == {"first_anchor": 17, "interval": 5}, "Android applies group2 globally")
	check(ios == {"first_anchor": 17, "interval": 10}, "iOS applies group1 globally")
	for level: int in range(1, 49):
		check(SpecialChallengeRules.is_anchor(level, int(android.first_anchor), int(android.interval))
			== (level in [17, 22, 27, 32, 37, 42, 47]), "Android cadence boundary %d" % level)
		check(SpecialChallengeRules.is_anchor(level, int(ios.first_anchor), int(ios.interval))
			== (level in [17, 27, 37, 47]), "iOS cadence boundary %d" % level)
	check(SpecialChallengeRules.schedule_for_platform("macOS") == android, "editor uses Android schedule")
	var current: Dictionary = SpecialChallengeRules.current_schedule()
	check(current == SpecialChallengeRules.schedule_for_platform(OS.get_name()), "runtime uses actual platform")
	check(ABManager.find_config("special_timing") == null, "frequency experiment is unregistered")
	var first_round: = LevelModel.new()
	first_round.level_id = 17
	LevelManager.configure_special_challenge_schedule(first_round, false)
	check(first_round.special_challenge_schedule == current, "new mainline freezes platform schedule")
	check(UserState.begin_level_completion(17, {}, true, first_round.special_challenge_schedule), 
		"first platform anchor journal")
	check(UserState.get_pending_special_challenge_offer(17), "both platforms offer after17")
	UserState.finalize_level_completion(17)
	UserState.reset_all()
	var start_host: = StartRoundHost.new()
	var start_ctx: = GameStartContext.new(start_host)
	await StartRoundStep.new().run(start_ctx)
	check(start_host.finished and start_host.fallback_shown and not start_ctx.aborted, 
		"StartRoundStep awaits preparation before continuing")
	var cancelled_host: = StartRoundHost.new()
	cancelled_host.succeeds = false
	var cancelled_ctx: = GameStartContext.new(cancelled_host)
	await StartRoundStep.new().run(cancelled_ctx)
	check(cancelled_host.finished and cancelled_ctx.aborted and not cancelled_host.fallback_shown, 
		"StartRoundStep aborts after cancelled preparation")

	var schedule: Dictionary = {"first_anchor": 27, "interval": 5}
	var model: = LevelModel.new()
	model.level_id = 32
	model.special_challenge_schedule = schedule.duplicate()
	LevelManager.configure_special_challenge_schedule(model, false)
	check(model.special_challenge_schedule == schedule, "existing round keeps historical schedule")
	var saved: Dictionary = model.to_dict()
	var resumed: = LevelModel.new()
	resumed.from_dict(saved)
	check(resumed.special_challenge_schedule == schedule, "metadata snapshot roundtrip")
	var copied: LevelModel = model.duplicate_model()
	copied.special_challenge_schedule.interval = 7
	check(model.special_challenge_schedule.interval == 5, "model copy owns schedule")
	LevelManager.configure_special_challenge_schedule(resumed, true)
	check(resumed.special_challenge_schedule == schedule, "global application cannot change resumed round")
	LevelManager.configure_special_challenge_schedule(model, false)
	check(model.special_challenge_schedule == schedule, "same round/restart keeps frozen schedule")
	var old_resume: = LevelModel.new()
	old_resume.level_id = 32
	LevelManager.configure_special_challenge_schedule(old_resume, true)
	check(old_resume.special_challenge_schedule == defaults, "old resume without metadata keeps27_10")
	var bonus: = LevelModel.new()
	bonus.level_id = 28
	LevelManager.configure_special_challenge_schedule(bonus, false)
	check(bonus.special_challenge_schedule == current, "Bonus uses global platform schedule")
	var special: = LevelModel.new()
	special.round_kind = "special_challenge"
	special.level_id = 28
	LevelManager.configure_special_challenge_schedule(special, false)
	check(special.special_challenge_schedule.is_empty(), "Special does not schedule another challenge")
	var next: = LevelModel.new()
	next.level_id = 33
	LevelManager.configure_special_challenge_schedule(next, false)
	check(next.special_challenge_schedule == current, "next fresh round uses platform schedule")

	UserState.set_current_level(32)
	check(UserState.begin_level_completion(32, {}, true, schedule), "freeze experimental anchor journal")
	check(UserState.get_pending_special_challenge_offer(32), "32 is experimental anchor")
	UserState.call("_load_data")
	check(UserState.get_pending_special_challenge_offer(32), "offer decision survives forced-quit reload")
	check(UserState.begin_level_completion(32, {}, true, defaults), "pending retry ignores new config")
	var tmp_path: String = UserState.call("_resolve_save_path") + ".tmp"
	DirAccess.make_dir_absolute(tmp_path)
	check( not UserState.finalize_level_completion(32), "failed finalize blocked")
	check(UserState.get_current_level() == 32 and UserState.get_pending_special_challenge_offer(32), "failed finalize restores cursor and offer decision")
	DirAccess.remove_absolute(tmp_path)
	check(UserState.recover_pending_level_completion(), "pending recovery commits frozen anchor")
	check(UserState.resolve_special_challenge_offer(true), "candidate becomes exactly one challenge")
	var active: Dictionary = UserState.get_special_challenge()
	check(active.after_level == 32 and active.case_number == 1, "cadence does not derive case from anchor")
	UserState.call("_load_data")
	check(UserState.get_special_challenge() == active, "global application/reload preserves active challenge")
	UserState.begin_special_challenge_completion(active.instance_id)
	UserState.finalize_special_challenge_completion()
	var pending: Dictionary = UserState.get_special_challenge()
	UserState.call("_load_data")
	check(UserState.get_special_challenge() == pending, "pending reward survives cadence changes")
	check( not UserState.claim_special_challenge(active.instance_id, 1).is_empty(), "existing instance still claimable")
	UserState.begin_level_completion(37, {}, true, defaults)
	UserState.finalize_level_completion(37)
	UserState.resolve_special_challenge_offer(true)
	check(UserState.get_special_challenge().case_number == 2, "cadence changes continue next puzzle rather than replaying first")
	UserState.reset_all()
	UserState.begin_level_completion(32, {}, true, defaults)
	UserState.call("_load_data")
	UserState.begin_level_completion(32, {}, true, schedule)
	UserState.finalize_level_completion(32)
	check(UserState.get_special_challenge_offer_after() == 0, "frozen false never becomes offer after config switch")
	UserState.set_current_level(28)
	check( not UserState.has_special_challenge() and not UserState.resolve_special_challenge_offer(true), "old cursor does not catch up missed anchors")
	for level: int in [27, 32]:
		UserState.reset_all()
		UserState.begin_level_completion(level)
		var legacy: = ConfigFile.new()
		var save_path: String = UserState.call("_resolve_save_path")
		check(legacy.load_encrypted_pass(save_path, UserState.SAVE_PASSWORD) == OK, "legacy journal fixture")
		legacy.erase_section_key("progress", "pending_special_challenge_offer")
		check(legacy.save_encrypted_pass(save_path, UserState.SAVE_PASSWORD) == OK, "legacy journal without new field")
		UserState.call("_load_data")
		check(UserState.get_pending_special_challenge_offer(level) == (level == 27), "legacy journal preserves old cadence")


func _test_challenge_tracking(instance_id: String, model: LevelModel, saver: SpecialChallengeSaver) -> void :
	var page: JuiceGamePage = JuiceGamePage.new()
	page.set("_level_model", model)
	page.setup_tracking_context(model, {})
	var common: TrackingCommonParams = page.get("_tracking_common")
	check(common.level_type == TrackingEvents.LEVEL_TYPE_SPECIAL_CHALLENGE, "challenge has independent tracking type")
	check(common.game_id == saver.load_session(instance_id).game_id, "tracking uses saved challenge game id")
	check(common.level_unique_id == model.level_unique_id and common.level_data_source == model.level_data_source, 
		"tracking preserves frozen challenge metadata")

	var ordinary_level: int = UserState.get_current_level()
	var normal_starts: int = LevelManager.get_level_start_times(ordinary_level)
	page.call("_record_special_challenge_start")
	page.call("_record_special_challenge_death")
	check(UserState.get_special_challenge_tracking(instance_id).new_start_times == 1, "first challenge attempt counted once")
	check(UserState.get_special_challenge_tracking(instance_id).dead_times == 1, "challenge death counted independently")
	check(LevelManager.get_level_start_times(ordinary_level) == normal_starts, "challenge never changes ordinary start counter")
	UserState.call("_load_data")
	page.setup_tracking_context(model, {"resume": true})
	page.call("_record_special_challenge_start")
	check(UserState.get_special_challenge_tracking(instance_id).new_start_times == 1, "resume keeps attempt count after reload")
	check(UserState.get_special_challenge_tracking(instance_id).dead_times == 1, "death count survives reload")
	check(saver.save_initial(instance_id, model, {"test": 1}), "tracking restart saves a new round")
	page.setup_tracking_context(model, {})
	page.call("_record_special_challenge_start")
	page.call("_record_special_challenge_death")
	var tracking: Dictionary = UserState.get_special_challenge_tracking(instance_id)
	check(tracking.new_start_times == 2 and tracking.dead_times == 2, "restart increments attempts and preserves cumulative deaths")
	check(tracking.game_id == saver.load_session(instance_id).game_id, "restart tracking follows changed game id")
	check( not UserState.update_special_challenge_tracking("expired-instance", {}), "expired instance cannot change tracking")
	var copied: Dictionary = UserState.get_special_challenge_tracking(instance_id)
	copied["dead_times"] = 999
	check(UserState.get_special_challenge_tracking(instance_id).dead_times == 2, "tracking getter returns independent data")
	var tmp_path: String = UserState.call("_resolve_save_path") + ".tmp"
	DirAccess.make_dir_absolute(tmp_path)
	check( not UserState.update_special_challenge_tracking(instance_id, copied), "failed tracking save is rejected")
	check(UserState.get_special_challenge_tracking(instance_id).dead_times == 2, "failed tracking save rolls back memory")
	DirAccess.remove_absolute(tmp_path)
	tracking["game_end_params"] = {
		TrackingEvents.K_COST_TIME: 1234, 
		TrackingEvents.K_GAME_STATE: TrackingEvents.GAME_STATE_CONTINUE_UNDO, 
		TrackingEvents.K_USED_HINT_INFO: JSON.stringify({"hint": 1, "undo": 2, "rope": 1}), 
		TrackingEvents.K_LEFT_HINT_INFO: JSON.stringify({"hint": 2, "undo": 0, "rope": 0}), 
	}
	check(UserState.update_special_challenge_tracking(instance_id, tracking), "final challenge metrics persist before claim")
	UserState.call("_load_data")
	page.setup_tracking_context(model, {"initial_board": true})
	check(page.get("_tracking_special_state").game_end_params[TrackingEvents.K_COST_TIME] == 1234, 
		"pending restore uses final metrics rather than the initial board")
	page.report_game_end()
	check(UserState.get_special_challenge_tracking(instance_id).game_end_reported, "completion marks reported after sending")
	UserState.call("_load_data")
	page.setup_tracking_context(model, {"initial_board": true})
	page.report_game_end()
	check(UserState.get_special_challenge_tracking(instance_id).game_end_reported, "reported completion remains deduplicated after reload")
	check(DbManager.load_level_entity(28).game_id == "ordinary-preserved", "tracking never changes ordinary save")

	check(UserState.update_special_challenge_tracking(instance_id, {}), "legacy challenge tracking fixture")
	page.setup_tracking_context(model, {"initial_board": true})
	page.report_game_end()
	check(UserState.get_special_challenge_tracking(instance_id).is_empty(), "legacy pending challenge does not invent completion metrics")
	page.free()


func _test_claim_hud_reveal() -> void :
	var scene: PackedScene = load("res://scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn")
	var package: Dictionary = {"coins": 0, "undo": 2, "hint": 1, "rope": 0}
	var instance_id: String = "hud-claim-test"
	var tmp_path: String = UserState.call("_resolve_save_path") + ".tmp"
	for scenario: String in ["no_fill", "interrupted", "save_failed", "double", "normal"]:
		UserState.set("_special_challenge", {"instance_id": instance_id, "case_number": 1, 
			"after_level": 37, "status": "reward_pending", "reward": package.duplicate()})
		UserState.call("_save_data")
		var before: int = UserState.get_prop_count("undo")
		MockUnikitConfig.set_mock_reward_ad_ready(MockUnikitConfig.MockState.FALSE if scenario == "no_fill" else MockUnikitConfig.MockState.TRUE)
		MockUnikitConfig.set_mock_reward_ad_result(MockUnikitConfig.MockState.FALSE if scenario == "interrupted" else MockUnikitConfig.MockState.TRUE)
		var dialog: SpecialChallengeRewardDialog = scene.instantiate()
		add_child(dialog)
		dialog.set("_instance_id", instance_id)
		dialog.set("_reward", package)
		dialog.call("_refresh_reward")
		dialog.call("_reset_hud_reveal")
		dialog.show()
		if scenario == "save_failed":
			DirAccess.make_dir_absolute(tmp_path)
		dialog.call("_claim", 1 if scenario == "normal" else 2)
		if bool(dialog.get("_busy")) and UserState.has_special_challenge():
			check(dialog.get_node("CoinHudHost").z_index == -3 and dialog.get_node("PropBarHost").z_index == -3, 
				"HUD stays under overlay while awaiting ad: " + scenario)
		while bool(dialog.get("_busy")):
			await get_tree().process_frame
		var success: bool = scenario in ["double", "normal"]
		check(dialog.was_claimed() == success, "dialog claim result: " + scenario)
		check(dialog.get_node("CoinHudHost").z_index == (90 if success else -3)
			and dialog.get_node("PropBarHost").z_index == (1 if success else -3), 
			"HUD reveals only for persisted rewards: " + scenario)
		check(UserState.get_prop_count("undo") == before + (2 if scenario == "normal" else (4 if success else 0)), 
			"HUD reveal matches actual reward: " + scenario)
		if not success:
			check(is_equal_approx(float(dialog.get("_collection_fade")), 1.0), "failed claim preserves chest presentation: " + scenario)
		if scenario == "save_failed":
			DirAccess.remove_absolute(tmp_path)
		dialog.queue_free()
		await get_tree().process_frame

func _test_replayed_anchor_offer() -> void :
	var scenarios: Array[Dictionary] = [
		{"label": "historical snapshot", "ordinary_time": 1000, "anchor_time": 2000, "completed": true, "expected": true}, 
		{"label": "started after offer", "ordinary_time": 3000, "anchor_time": 2000, "completed": true, "expected": false}, 
		{"label": "equal timestamps", "ordinary_time": 2000, "anchor_time": 2000, "completed": true, "expected": false}, 
		{"label": "unknown snapshot time", "ordinary_time": 0, "anchor_time": 2000, "completed": true, "expected": false}, 
		{"label": "unknown anchor time", "ordinary_time": 1000, "anchor_time": 0, "completed": true, "expected": false}, 
		{"label": "unfinished anchor", "ordinary_time": 1000, "anchor_time": 2000, "completed": false, "expected": false}, 
	]
	for scenario: Dictionary in scenarios:
		UserState.reset_all()
		DbManager.reset_all_levels()
		var ordinary: LevelEntity = LevelEntity.for_level(28)
		ordinary.game_id = "preserved-normal-28"
		ordinary.current_state = {"normal": true}
		ordinary.updated_at = int(scenario["ordinary_time"])
		check(DbManager.save_level_entity(ordinary.to_row()), "save ordinary fixture " + scenario["label"])
		var anchor: LevelEntity = LevelEntity.for_level(27)
		anchor.completed = bool(scenario["completed"])
		anchor.statistics["completed_at"] = 500
		anchor.updated_at = int(scenario["anchor_time"])
		check(DbManager.save_level_entity(anchor.to_row()), "save replay anchor " + scenario["label"])
		UserState.begin_level_completion(27)
		check(UserState.finalize_level_completion(27), "fresh candidate " + scenario["label"])
		var before: Dictionary = DbManager.load_level_entity(28).duplicate(true)
		check( not bool(LevelManager.get_next_round_descriptor(false)["is_special"]), "read-only descriptor does not resolve candidate")
		check(UserState.get_special_challenge_offer_after() == 27, "read-only descriptor preserves candidate")
		var descriptor: Dictionary = LevelManager.get_next_round_descriptor()
		check(bool(descriptor["is_special"]) == bool(scenario["expected"]), "entry chronology " + scenario["label"])
		check(DbManager.load_level_entity(28) == before, "entry never changes ordinary snapshot " + scenario["label"])
		check(UserState.get_special_challenge_offer_after() == 0, "candidate consumed exactly once " + scenario["label"])
		check(LevelManager.get_next_round_descriptor() == descriptor, "repeated descriptors keep frozen result " + scenario["label"])
		if bool(scenario["expected"]):
			var instance_id: String = descriptor["instance_id"]
			check(int(descriptor["case_number"]) == 1, "replay uses next challenge case, not normal cursor")
			var loaded: Dictionary = LevelManager.load_special_challenge()
			check( not loaded.is_empty(), "inserted replay challenge loads actual bank model")
			LevelManager.save_initial(28, loaded.get("model") as LevelModel, {"test": true})
			check(LevelManager.complete_special_challenge(instance_id), "complete inserted replay challenge")
			var coins: int = UserState.get_coins()
			var grant: Dictionary = UserState.claim_special_challenge(instance_id, 1)
			check( not grant.is_empty(), "claim inserted replay challenge")
			check(UserState.get_coins() == coins + int(grant.get("reward", {}).get("coins", 0)) and UserState.get_current_level() == 28, "replay grants original reward without advancing normal cursor")
			check( not bool(LevelManager.get_next_round_descriptor()["is_special"]), "claim returns to normal round")
			check(DbManager.load_level_entity(28) == before, "historical ordinary snapshot survives challenge and claim")
	UserState.reset_all()
	DbManager.reset_all_levels()
	var consumed_anchor: LevelEntity = LevelEntity.for_level(27)
	consumed_anchor.completed = true
	consumed_anchor.updated_at = 2000
	check(DbManager.save_level_entity(consumed_anchor.to_row()), "previously consumed replay anchor")
	var old_ordinary: LevelEntity = LevelEntity.for_level(28)
	old_ordinary.current_state = {"normal": true}
	old_ordinary.updated_at = 1000
	check(DbManager.save_level_entity(old_ordinary.to_row()), "historical snapshot after consumed offer")
	UserState.begin_level_completion(27)
	check(UserState.finalize_level_completion(27), "candidate before historical consumption")
	UserState.resolve_special_challenge_offer(false)
	check(UserState.get_special_challenge_offer_after() == 0, "historical offer already consumed")
	check( not bool(LevelManager.get_next_round_descriptor()["is_special"]), "consumed offer does not insert despite historical snapshot")
	check( not bool(LevelManager.get_next_round_descriptor()["is_special"]), "repeated query never backfills a consumed offer")
