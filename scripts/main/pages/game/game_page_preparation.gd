class_name GamePagePreparation
extends RefCounted


const COMPONENT_SCENES: Dictionary = {
	"core": {
		"Board": "res://scripts/gameplay/juice_sort/view/juice_board_view.tscn", 
		"ComboFeedback": "res://scripts/main/pages/game/combo_feedback.tscn", 
		"EmptyColFeedback": "res://scripts/main/pages/game/empty_col_feedback.tscn", 
		"LongLinkFeedback": "res://scripts/main/pages/game/long_link_feedback.tscn", 
		"Quota/IqProgressBar": "res://scripts/main/pages/game/iq_progress_bar.tscn", 
		"Quota/ProgressBling": "res://scripts/gameplay/juice_sort/view/progress_bling.tscn", 
		"GameStartBanner": "res://scripts/main/pages/game/game_start_banner.tscn", 
		"GoodLuckSpine": "res://assets/spine/effect_good_luck/effect_good_luck.tscn", 
	}, 
	"bonus": {
		"BonusPigHud": "res://scripts/main/pages/game/bonus_pig_hud.tscn", 
		"BonusLevelBanner": "res://scripts/main/pages/game/bonus_level_banner.tscn", 
	}, 
	"special": {
		"SpecialChallengeBanner": "res://scripts/main/pages/game/special_challenge_banner.tscn", 
	}, 
	"rank": {
		"RankCollectBar": "res://scripts/gameplay/rank/view/rank_collect_bar.tscn", 
		"RankCollectFly": "res://scripts/gameplay/rank/view/rank_collect_fly_layer.tscn", 
	}, 
	"end_iq": {
		"IqGeniusFeedback": "res://scripts/main/pages/game/iq_genius_feedback.tscn", 
	}, 
	"end_bonus": {
		"BonusPigSmash": "res://scripts/main/pages/game/bonus_pig_smash.tscn", 
	}, 
	"preview": {
		"ChallengeBanner": "res://scripts/main/pages/game/challenge_banner.tscn", 
		"SmartMoveSpine": "res://assets/spine/effect_smart_move/effect_smart_move.tscn", 
		"LikeSpine": "res://assets/spine/effect_like/effect_like.tscn", 
	}, 
}
const WIN_COIN_PATH: String = "res://assets/spine/effect_coin_clover/effect_coin_clover.tscn"


static func first_screen_groups(special: bool, bonus: bool, rank: bool) -> Array[String]:
	var groups: Array[String] = ["core"]
	if special:
		groups.append("special")
	elif bonus:
		groups.append("bonus")
	if rank:
		groups.append("rank")
	return groups


static func end_groups(iq: bool, bonus: bool) -> Array[String]:
	var groups: Array[String] = []
	if iq:
		groups.append("end_iq")
	if bonus:
		groups.append("end_bonus")
	return groups
