class_name ApplySystemLocaleStep
extends FlowStep








func get_step_name() -> String:
	return "ApplySystemLocale"


func run(ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", get_step_name())
	ctx.system_locale = OS.get_locale()
	if OS.has_feature("editor"):
		var test_locale: String = str(ProjectSettings.get_setting("internationalization/locale/test", "en"))
		TranslationServer.set_locale("en" if test_locale.is_empty() else test_locale)
		return
	var sys_lang: String = OS.get_locale_language()
	if sys_lang == "zh":
		var full: String = ctx.system_locale
		var trad: bool = "TW" in full or "HK" in full or "MO" in full or "Hant" in full
		TranslationServer.set_locale("zh_TW" if trad else "zh_CN")
		return
	var loc_map: Dictionary = {
		"en": "en", "pt": "pt_BR", "id": "id", "in": "id", "tl": "fil", "fil": "fil", 
		"es": "es", "ru": "ru", "de": "de", "ja": "ja", "fr": "fr", "ko": "ko", 
		"it": "it", "pl": "pl", "tr": "tr", "uk": "uk", "th": "th", "ms": "ms", 
		"vi": "vi", "ro": "ro", "nl": "nl", "nb": "nb", "no": "nb", "fi": "fi", 
		"el": "el", "sv": "sv", "hu": "hu", "bn": "bn", "ta": "ta", "ur": "ur", 
	}
	TranslationServer.set_locale(loc_map.get(sys_lang, "en"))
