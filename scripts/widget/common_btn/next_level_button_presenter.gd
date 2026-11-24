class_name NextLevelButtonPresenter
extends RefCounted


static func describe(level: int, hard: bool, super_hard: bool, bonus: bool, 
		special: bool, unavailable: bool, coming_soon: bool, double_coins: bool = false, timed_endless: bool = false) -> Dictionary:
	var variant: CommonBtn.Variant = CommonBtn.Variant.SECONDARY
	if special or bonus:
		variant = CommonBtn.Variant.TERTIARY
	elif super_hard:
		variant = CommonBtn.Variant.SUPER_HARD
	elif hard:
		variant = CommonBtn.Variant.HARD
	var text: String
	if timed_endless:
		variant = CommonBtn.Variant.TERTIARY
		text = "TIMED_CHALLENGE_TITLE"
	elif special:
		text = "SPECIAL_CHALLENGE_BUTTON"
	elif coming_soon:
		text = "COMING_SOON"
	elif bonus:
		text = "BONUS_LEVEL_TITLE"
	else:
		var level_fmt: String = TranslationServer.translate("LEVEL_NUM")
		text = level_fmt % level if "%d" in level_fmt else "Level %d" % level
	return {"variant": variant, "text": text, "special": special, "bonus": bonus, 
		"show_hard": (hard or super_hard) and not special and not unavailable and not timed_endless, 
		"super_hard": super_hard, "unavailable": unavailable, "coming_soon": coming_soon, 
		"double_coins": double_coins and not special and not bonus and not unavailable and not timed_endless}


static func apply(button: CommonBtn, state: Dictionary, 
		textures: Dictionary, locked: bool, dim_locked: bool = true, badge: TextureRect = null) -> void :
	if badge != null:
		badge.visible = bool(state.get("double_coins", false))
	var special: bool = bool(state["special"])
	var super_hard: bool = bool(state["super_hard"])
	var show_hard: bool = bool(state["show_hard"])
	button.variant = state["variant"]
	button.btn_text = state["text"]
	button.base_font_size = 90 if special else 102
	button.btn_icon = textures["special"] if special else textures["bonus"] if state["bonus"] else null
	button.btn_sub_text = ("HOME_SUPER_HARD_BADGE" if super_hard else "HOME_HARD_BADGE") if show_hard else ""
	button.btn_sub_icon = (textures["fire_yellow"] if super_hard else textures["fire_white"]) if show_hard else null
	button.sub_font_color = Color("ffe100") if super_hard else Color.WHITE

	button.set_button_disabled(bool(state["unavailable"]) or (locked and dim_locked and not special))

	button.disabled = locked or (bool(state["unavailable"]) and not bool(state["coming_soon"]))
