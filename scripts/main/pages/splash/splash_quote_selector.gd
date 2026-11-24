class_name SplashQuoteSelector
extends RefCounted


const QUOTE_COUNT: int = 10
const _COUNTRY_BY_LANGUAGE: Dictionary = {
	"fr": "fr", "de": "de", "ru": "ru", "ta": "in", "ur": "pk", 
	"es": "mx", "pt": "br", "ja": "jp", 
}



static func resolve_country(system_locale: String) -> String:
	var parts: PackedStringArray = system_locale.replace("-", "_").to_lower().split("_", false)
	if parts.is_empty():
		return ""
	if parts[0] == "en":
		return "gb" if "gb" in parts else "us"
	return _COUNTRY_BY_LANGUAGE.get(parts[0], "")


static func quote_key(country: String, index: int) -> String:
	if country not in ["us", "gb"] and country not in _COUNTRY_BY_LANGUAGE.values():
		return ""
	if index < 1 or index > QUOTE_COUNT:
		return ""
	return "splash_quote_%s_content_%d" % [country, index]
