class_name LevelDownloader
extends Node


















const BUCKET_SIZE: = 5


const CHAPTER_CHANNEL_DEFAULT: = "default"
const CHAPTER_CHANNEL_BASELINE: = "baseline"

const CACHE_DIR: = "user://level_cache"
const MANIFEST_PATH: = "user://level_cache/_manifest.json"
const EXPERIMENT_SELECTION_PATH: = "user://level_cache/_experiment_selection.json"
const FLOW_DOMAIN_CONFIRM_PATH: = "user://level_cache/_flow_domain.json"
const COVER_DIR: = "user://level_cache/covers"


var _chapter_channel: String = CHAPTER_CHANNEL_DEFAULT
var _chapter_channel_bound: bool = false

var _last_saved_flow_domain: String = ""

const DEFAULT_TIMEOUT: = 20.0




const STRATEGY_CONFIG_TYPE_PREFIX: = "sortparade_abtest_level_"


const CHAPTER_API_DEV_HOST: = "https://jigsaw-api-dev.dailyinnovation.biz"
const CHAPTER_API_PROD_HOST: = "https://jigsaw-api.dailyinnovation.biz"




const HOP_API: = "第一跳接口"
const HOP_CDN: = "第二跳 CDN"



static func bucket_of(chapter_index: int) -> Vector2i:
	var start: int = (chapter_index - 1) / BUCKET_SIZE * BUCKET_SIZE + 1
	return Vector2i(start, start + BUCKET_SIZE - 1)



func bind_chapter_channel(channel: String) -> void :
	if _chapter_channel_bound:
		return
	if channel == CHAPTER_CHANNEL_BASELINE:
		_chapter_channel = CHAPTER_CHANNEL_BASELINE
	else:
		_chapter_channel = CHAPTER_CHANNEL_DEFAULT
	_chapter_channel_bound = true


func is_chapter_channel_bound() -> bool:
	return _chapter_channel_bound


func chapter_channel() -> String:
	return _chapter_channel


func is_baseline_chapter_channel() -> bool:
	return _chapter_channel == CHAPTER_CHANNEL_BASELINE




func chapter_bucket_url(chapter_index: int) -> String:
	return _config_url(_chapter_config_type(bucket_of(chapter_index)))


func _chapter_config_type(bucket: Vector2i) -> String:
	if _chapter_channel == CHAPTER_CHANNEL_BASELINE:
		return "sortparade_v1_chapter_baseline_%d_%d" % [bucket.x, bucket.y]
	return "sortparade_v1_chapter_%d_%d" % [bucket.x, bucket.y]


func _chapter_cache_key(bucket: Vector2i) -> String:
	var bare: String = "%d_%d" % [bucket.x, bucket.y]
	if _chapter_channel == CHAPTER_CHANNEL_BASELINE:
		return "baseline:%s" % bare
	return bare



func read_confirmed_flow_domain() -> String:
	if not FileAccess.file_exists(FLOW_DOMAIN_CONFIRM_PATH):
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLOW_DOMAIN_CONFIRM_PATH))
	if not (parsed is Dictionary):
		return ""
	return String((parsed as Dictionary).get("domain", "")).strip_edges()



func save_confirmed_flow_domain(domain: String) -> bool:
	var value: String = domain.strip_edges()
	if value.is_empty():
		return false
	if value == _last_saved_flow_domain:
		return true
	var ok: bool = _write_cache_atomic(FLOW_DOMAIN_CONFIRM_PATH, 
		JSON.stringify({"version": 1, "domain": value}))
	if ok:
		_last_saved_flow_domain = value
	return ok













func fetch_chapter_bucket(chapter_index: int, total_timeout_sec: float = -1.0) -> Dictionary:
	var deadline_msec: int = -1
	if total_timeout_sec > 0.0:
		deadline_msec = Time.get_ticks_msec() + int(total_timeout_sec * 1000.0)
	var bucket: Vector2i = bucket_of(chapter_index)
	var config_type: String = _chapter_config_type(bucket)
	var cache_key: String = _chapter_cache_key(bucket)
	var started_msec: int = Time.get_ticks_msec()
	var result: Dictionary = await _fetch_config(config_type, cache_key, true, deadline_msec)
	if _requested_chapter_missing(result, chapter_index):
		result["requested_chapter_missing"] = true
	_report_api_req(bucket, result, started_msec)
	return result







func _report_api_req(bucket: Vector2i, result: Dictionary, started_msec: int) -> void :
	var ok: bool = bool(result.get("ok", false))
	Tracker.send_event(TrackingEvents.EV_API_REQ_MONITOR, {
		TrackingEvents.K_TYPE: TrackingEvents.API_TYPE_CHAPTER, 
		TrackingEvents.K_START_CONTENT_ID: str(bucket.x), 
		TrackingEvents.K_END_CONTENT_ID: str(bucket.y), 
		TrackingEvents.K_STATE: TrackingEvents.REQ_STATE_SUCCESS if ok else TrackingEvents.REQ_STATE_FAIL, 
		TrackingEvents.K_NET_TYPE: Tracker.net_type(), 
		TrackingEvents.K_COST_TIME: Time.get_ticks_msec() - started_msec, 
		TrackingEvents.K_ERR_CODE: String(result.get("err_code", "")), 
		TrackingEvents.K_ERR_MSG: String(result.get("err_msg", "")), 
	})



static func _requested_chapter_missing(result: Dictionary, chapter_index: int) -> bool:
	if not bool(result.get("ok", false)) or bool(result.get("exhausted", false)):
		return false
	for raw_chapter: Variant in result.get("chapters", []) as Array:
		if raw_chapter is Dictionary and int((raw_chapter as Dictionary).get("chapterIndex", 0)) == chapter_index:
			return false
	return true












func fetch_strategy_pool(strategy: String) -> Dictionary:
	var value: String = strategy.strip_edges()
	if value.is_empty():
		return {"ok": false}
	var config_type: String = STRATEGY_CONFIG_TYPE_PREFIX + value
	return await _fetch_config(config_type, "strategy:%s" % config_type, false, -1)




func read_cached_strategy_pool(strategy: String) -> Dictionary:
	var value: String = strategy.strip_edges()
	if value.is_empty():
		return {"ok": false}
	var cache_key: String = "strategy:%s%s" % [STRATEGY_CONFIG_TYPE_PREFIX, value]
	var filename: String = String(_load_manifest().get(cache_key, ""))
	if filename.is_empty():
		return {"ok": false}
	var cache_path: String = "%s/%s" % [CACHE_DIR, filename]
	var worker: = Thread.new()
	var error: Error = worker.start( func() -> Dictionary:
		var text_data: String = LevelDownloader._read_cache_if_valid(cache_path)
		return LevelDownloader._parse_strategy_pool(text_data) if not text_data.is_empty() else {"ok": false})
	if error != OK:
		return {"ok": false}
	while worker.is_alive():
		await get_tree().process_frame
	return worker.wait_to_finish() as Dictionary


func _parse_envelope_threaded(body_text: String) -> Dictionary:
	var worker: = Thread.new()
	var error: Error = worker.start( func() -> Dictionary:
		return LevelDownloader._parse_envelope(body_text))
	if error != OK:
		return {"ok": false}
	while worker.is_alive():
		await get_tree().process_frame
	return worker.wait_to_finish() as Dictionary


func _parse_strategy_pool_threaded(body_text: String) -> Dictionary:
	var worker: = Thread.new()
	var error: Error = worker.start( func() -> Dictionary:
		return LevelDownloader._parse_strategy_pool(body_text))
	if error != OK:
		return {"ok": false}
	while worker.is_alive():
		await get_tree().process_frame
	return worker.wait_to_finish() as Dictionary




func read_cached_experiment_selection(current_group_id: String) -> Dictionary:
	if not FileAccess.file_exists(EXPERIMENT_SELECTION_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXPERIMENT_SELECTION_PATH))
	if not (parsed is Dictionary):
		return {}
	var saved: Dictionary = parsed
	if int(saved.get("version", 0)) != 1 or not (saved.get("values") is Dictionary):
		return {}
	var saved_group_id: String = String(saved.get("group_id", ""))
	if not saved_group_id.is_empty() and not current_group_id.is_empty()\
	and saved_group_id != current_group_id:
		return {}
	return (saved["values"] as Dictionary).duplicate()


func save_confirmed_experiment_selection(group_id: String, values: Dictionary) -> bool:
	return _write_cache_atomic(EXPERIMENT_SELECTION_PATH, JSON.stringify({
		"version": 1, "group_id": group_id, "values": values}))



func forget_cached_strategy_pool(strategy: String) -> void :
	var cache_key: String = "strategy:%s%s" % [STRATEGY_CONFIG_TYPE_PREFIX, strategy.strip_edges()]
	var manifest: Dictionary = _load_manifest()
	if manifest.erase(cache_key):
		_save_manifest(manifest)










func _fetch_config(config_type: String, cache_key: String, is_default_bucket: bool, 
		deadline_msec: int) -> Dictionary:
	var url: String = _config_url(config_type)
	var started_msec: int = Time.get_ticks_msec()

	if _deadline_reached(deadline_msec):
		return _fail(url, started_msec, TrackingEvents.ERR_DEADLINE_PREFIX, 1, 
			_with_hop(HOP_API, "发起前已过总时限"))
	var first: Dictionary = await _request(url, _get_default_headers(), 
		_request_timeout(deadline_msec), HOP_API)
	if not bool(first.get("ok", false)):

		return first
	var code: int = int(first.get("code", 0))
	var body_text: String = String(first.get("body_text", ""))

	if code == 404:
		if _is_config_type_not_found(body_text):
			if is_default_bucket:

				return {"ok": true, "exhausted": true, "url": url, 
					"cost_time": Time.get_ticks_msec() - started_msec}

			return {
				"ok": false, 
				"not_found": true, 
				"url": url, 
				"cost_time": Time.get_ticks_msec() - started_msec, 
				"err_code": Tracker.build_err_code(TrackingEvents.ERR_HTTP_PREFIX, code), 
				"err_msg": "config_type 不存在（策略池 404）", 
			}
		return _fail(url, started_msec, TrackingEvents.ERR_HTTP_PREFIX, code, 
			_with_hop(HOP_API, "HTTP 404，且响应不是 config_type not found"))

	var location: String = String(first.get("location", ""))
	if location.is_empty():
		return _fail(url, started_msec, TrackingEvents.ERR_PARSE_FAIL_PREFIX, 1, 
			_with_hop(HOP_API, "响应缺少 Location 头"))
	var filename: String = _filename_of(location)
	if filename.is_empty():
		return _fail(url, started_msec, TrackingEvents.ERR_PARSE_FAIL_PREFIX, 2, 
			_with_hop(HOP_API, "Location 里取不到文件名"))

	var cache_path: String = "%s/%s" % [CACHE_DIR, filename]

	var cached_text: String = _read_cache_if_valid(cache_path)
	var json_text: String = cached_text
	if json_text.is_empty():
		if _deadline_reached(deadline_msec):
			return _fail(url, started_msec, TrackingEvents.ERR_DEADLINE_PREFIX, 2, 
				_with_hop(HOP_CDN, "发起前已过总时限"))
		var second: Dictionary = await _request(
			location, PackedStringArray(), _request_timeout(deadline_msec), HOP_CDN)
		if not bool(second.get("ok", false)):



			var cdn_fail: Dictionary = second.duplicate()
			cdn_fail["url"] = url
			cdn_fail["cost_time"] = Time.get_ticks_msec() - started_msec
			return cdn_fail
		if int(second.get("code", 0)) != 200:

			return _fail(url, started_msec, TrackingEvents.ERR_HTTP_PREFIX, 
				int(second.get("code", 0)), _with_hop(HOP_CDN, "HTTP 状态码非 200"))
		json_text = String(second.get("body_text", ""))
		if not _write_cache_atomic(cache_path, json_text):
			return _fail(url, started_msec, TrackingEvents.ERR_IO_FAIL, -1, 
				_with_hop(HOP_CDN, "写磁盘缓存失败"))

	var parsed: Dictionary = await _parse_envelope_threaded(json_text) if is_default_bucket\
	else await _parse_strategy_pool_threaded(json_text)
	if not bool(parsed.get("ok", false)):

		if cached_text == json_text and not cached_text.is_empty():
			DirAccess.remove_absolute(cache_path)
			return await _fetch_config(
				config_type, cache_key, is_default_bucket, deadline_msec)
		if cached_text.is_empty():
			DirAccess.remove_absolute(cache_path)

		return _fail(url, started_msec, TrackingEvents.ERR_PARSE_FAIL_PREFIX, 3, 
			_with_hop(HOP_CDN, "响应解析失败"))

	if String(_load_manifest().get(cache_key, "")) != filename:
		_replace_config_cache(cache_key, filename)
	elif not cached_text.is_empty():

		parsed["unchanged"] = true
	parsed["url"] = url
	parsed["cost_time"] = Time.get_ticks_msec() - started_msec
	return parsed


static func _deadline_reached(deadline_msec: int) -> bool:
	return deadline_msec >= 0 and Time.get_ticks_msec() >= deadline_msec


static func _request_timeout(deadline_msec: int) -> float:
	if deadline_msec < 0:
		return DEFAULT_TIMEOUT
	var remaining_sec: float = float(deadline_msec - Time.get_ticks_msec()) / 1000.0
	return minf(DEFAULT_TIMEOUT, maxf(remaining_sec, 0.001))





func read_cached_bucket(chapter_index: int) -> Dictionary:
	var bucket: Vector2i = bucket_of(chapter_index)
	var bucket_key: String = _chapter_cache_key(bucket)
	var filename: String = String(_load_manifest().get(bucket_key, ""))
	if filename.is_empty():
		return {"ok": false}
	var cache_path: String = "%s/%s" % [CACHE_DIR, filename]
	var worker: = Thread.new()
	var error: Error = worker.start( func() -> Dictionary:
		var text_data: String = LevelDownloader._read_cache_if_valid(cache_path)
		return LevelDownloader._parse_envelope(text_data) if not text_data.is_empty() else {"ok": false})
	if error != OK:
		return {"ok": false}
	while worker.is_alive():
		await get_tree().process_frame
	return worker.wait_to_finish() as Dictionary




func forget_cached_bucket(chapter_index: int) -> bool:
	var bucket: Vector2i = bucket_of(chapter_index)
	var bucket_key: String = _chapter_cache_key(bucket)
	var manifest: Dictionary = _load_manifest()
	if not manifest.erase(bucket_key):
		return true
	return _write_cache_atomic(MANIFEST_PATH, JSON.stringify(manifest))




func fetch_chapter_cover(url: String, size: int = 512, active: Callable = Callable(), download_started: Callable = Callable()) -> String:
	if url.is_empty() or (active.is_valid() and not active.call()):
		return ""
	var sized_url: String = _image_url_with_size(url, size, size)
	var key: String = sized_url.md5_text()
	var reader: = Thread.new()
	if reader.start( func() -> String:
		DirAccess.make_dir_recursive_absolute(COVER_DIR)
		return LevelDownloader._find_cover_by_key(key)) != OK:
		return ""
	while reader.is_alive():
		await get_tree().process_frame
	var existing: String = String(reader.wait_to_finish())
	if active.is_valid() and not active.call():
		return ""
	if not existing.is_empty():
		return existing

	if download_started.is_valid():
		download_started.call()

	var resp: Dictionary = await _request(sized_url, PackedStringArray(["Accept: image/webp"]), DEFAULT_TIMEOUT, "", false, active)
	if not bool(resp.get("ok", false)) or int(resp.get("code", 0)) != 200:
		return ""
	var bytes: PackedByteArray = resp.get("body_bytes", PackedByteArray())
	var writer: = Thread.new()
	if writer.start( func() -> String:
		var ext: String = LevelDownloader._sniff_image_ext(bytes)
		if ext.is_empty():
			return ""
		var image: = Image.new()
		var error: Error = image.load_webp_from_buffer(bytes) if ext == "webp" else (
			image.load_png_from_buffer(bytes) if ext == "png" else image.load_jpg_from_buffer(bytes))
		if error != OK or image.is_empty():
			return ""
		var path: String = "%s/%s.%s" % [COVER_DIR, key, ext]
		return path if LevelDownloader._write_cache_atomic_bytes(path, bytes) else "") != OK:
		return ""
	while writer.is_alive():
		await get_tree().process_frame
	var saved_path: String = String(writer.wait_to_finish())
	return saved_path if not active.is_valid() or active.call() else ""





static func _is_dev() -> bool:
	return not (OS.has_feature("rel") or OS.has_feature("pre"))


static func _config_url(config_type: String) -> String:
	var host: String = CHAPTER_API_DEV_HOST if _is_dev() else CHAPTER_API_PROD_HOST
	return "%s/s3_config_url?config_type=%s" % [host, config_type.uri_encode()]





static func _image_url_with_size(url: String, w: int = 512, h: int = 512) -> String:
	if url.is_empty() or url.contains("/imageView/"):
		return url
	var scheme_end: = url.find("://")
	if scheme_end < 0:
		return url
	var path_slash: = url.find("/", scheme_end + 3)
	if path_slash < 0:
		return url
	return "%simageView/%d/%d/%s" % [url.substr(0, path_slash + 1), w, h, url.substr(path_slash + 1)]





static func _sniff_image_ext(head: PackedByteArray) -> String:
	if head.size() >= 3 and head[0] == 255 and head[1] == 216 and head[2] == 255:
		return "jpg"
	if head.size() >= 8 and head[0] == 137 and head[1] == 80 and head[2] == 78 and head[3] == 71\
	and head[4] == 13 and head[5] == 10 and head[6] == 26 and head[7] == 10:
		return "png"
	if head.size() >= 12 and head[0] == 82 and head[1] == 73 and head[2] == 70 and head[3] == 70\
	and head[8] == 87 and head[9] == 69 and head[10] == 66 and head[11] == 80:
		return "webp"
	return ""









static func _get_default_headers() -> PackedStringArray:
	var headers: = PackedStringArray()
	headers.append("platform: %s" % _platform_header())
	headers.append("install-day: %d" % UserState.get_install_days())
	headers.append("app-version: %s" % (ProjectSettings.get_setting("application/config/version", "") as String))
	headers.append("language: %s" % _api_language())
	headers.append("timezone: %s" % _timezone_id())


	var learnings_id: String = Tracker.get_learnings_id()
	headers.append("learnings_id: %s" % learnings_id)


	var luid: String = UniKitManager.get_luid()
	headers.append("luid: %s" % luid)


	var inner_tags: Dictionary = UniKitManager.get_inner_tags()
	headers.append("country: %s" % str(inner_tags.get("country", "")))
	return headers



static func _platform_header() -> String:
	if OS.has_feature("ios"):
		return "ios"
	if OS.has_feature("android"):
		return "android"
	return OS.get_name().to_lower()






static func _api_language() -> String:
	var loc: String = TranslationServer.get_locale()
	match loc:
		"zh_CN", "zh_Hans", "zh-CN":
			return "ZH_HANS"
		"zh_TW", "zh_HK", "zh_MO", "zh_Hant", "zh-TW":
			return "ZH_HANT"
		"id", "in":
			return "ID"
		"he", "iw":
			return "IW"
		"fil", "tl":
			return "TL"

	return loc.split("_")[0].split("-")[0].to_lower()




static func _timezone_id() -> String:
	var tz: Dictionary = Time.get_time_zone_from_system()
	return str(tz.get("name", ""))




static func _apply_debug_proxy(req: HTTPRequest) -> void :
	if OS.has_feature("rel"):
		return
	if not UserState.has_debug_proxy():
		return
	var host: = UserState.get_debug_proxy_host()
	var port: = UserState.get_debug_proxy_port()
	req.set_http_proxy(host, port)
	req.set_https_proxy(host, port)






static func _parse_api_response(body_text: String) -> Dictionary:
	var json: = JSON.new()
	var err: = json.parse(body_text)
	if err != OK:
		return {"ok": false, "code": -1, "message": "JSON 解析失败: %s" % json.get_error_message()}
	var root: Variant = json.data
	if not (root is Dictionary):
		return {"ok": false, "code": -2, "message": "响应根不是 Dictionary"}
	var root_dict: Dictionary = root
	var status: Dictionary = root_dict.get("status", {})
	var code: int = int(status.get("code", -1))
	if code != 0:
		return {"ok": false, "code": code, "message": str(status.get("message", ""))}
	return {
		"ok": true, 
		"data": root_dict.get("data"), 
	}










func _request(url: String, headers: PackedStringArray, 
		timeout_sec: float = DEFAULT_TIMEOUT, hop_label: String = "", decode_text: bool = true, active: Callable = Callable()) -> Dictionary:
	var started_msec: int = Time.get_ticks_msec()
	var req: = HTTPRequest.new()
	req.timeout = timeout_sec

	req.max_redirects = 0
	add_child(req)
	_apply_debug_proxy(req)


	SortLogger.info("请求 url = %s" % url)
	var response: Dictionary = {"done": false, "args": []}
	req.request_completed.connect( func(result: int, code: int, response_headers: PackedStringArray, body: PackedByteArray) -> void :
		response.args = [result, code, response_headers, body]
		response.done = true)
	var err: int = req.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		req.queue_free()
		SortLogger.warn("请求失败(发起失败, err=%d), url = %s" % [err, url])
		return _fail(url, started_msec, TrackingEvents.ERR_START_FAIL, -1, 
			_with_hop(hop_label, "请求发起失败(engine err=%d)" % err))

	while not response.done:
		if active.is_valid() and not active.call():
			req.cancel_request()
			req.queue_free()
			return {"ok": false, "cancelled": true}
		await get_tree().process_frame
	var args: Array = response.args
	var result: int = args[0]
	var code: int = args[1]
	var resp_headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]
	req.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS and result != HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
		SortLogger.warn("请求失败(result=%d), url = %s" % [result, url])


		if result == HTTPRequest.RESULT_TIMEOUT:
			return _fail(url, started_msec, TrackingEvents.ERR_HTTPREQUEST_TIMEOUT, -1, 
				_with_hop(hop_label, "请求超时"))

		return _fail(url, started_msec, _err_code_of_result(result), -1, 
			_with_hop(hop_label, "HTTPRequest 层失败(result=%d)" % result))


	SortLogger.info("请求成功(code=%d), url = %s" % [code, url])
	return {
		"ok": true, 
		"code": code, 
		"url": url, 
		"cost_time": Time.get_ticks_msec() - started_msec, 
		"body_text": body.get_string_from_utf8() if decode_text else "", 
		"body_bytes": body, 
		"location": _location_header(resp_headers), 
	}




static func _with_hop(hop_label: String, msg: String) -> String:
	return msg if hop_label.is_empty() else "%s %s" % [hop_label, msg]








static func _err_code_of_result(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return TrackingEvents.ERR_HTTPREQUEST_CHUNKED_BODY_SIZE_MISMATCH
		HTTPRequest.RESULT_CANT_CONNECT:
			return TrackingEvents.ERR_HTTPREQUEST_CANT_CONNECT
		HTTPRequest.RESULT_CANT_RESOLVE:
			return TrackingEvents.ERR_HTTPREQUEST_CANT_RESOLVE
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return TrackingEvents.ERR_HTTPREQUEST_CONNECTION_ERROR
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return TrackingEvents.ERR_HTTPREQUEST_TLS_HANDSHAKE_ERROR
		HTTPRequest.RESULT_NO_RESPONSE:
			return TrackingEvents.ERR_HTTPREQUEST_NO_RESPONSE
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return TrackingEvents.ERR_HTTPREQUEST_BODY_SIZE_LIMIT_EXCEEDED
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return TrackingEvents.ERR_HTTPREQUEST_BODY_DECOMPRESS_FAILED
		HTTPRequest.RESULT_REQUEST_FAILED:
			return TrackingEvents.ERR_HTTPREQUEST_REQUEST_FAILED
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return TrackingEvents.ERR_HTTPREQUEST_DOWNLOAD_FILE_CANT_OPEN
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return TrackingEvents.ERR_HTTPREQUEST_DOWNLOAD_FILE_WRITE_ERROR
	return TrackingEvents.ERR_HTTPREQUEST_UNKNOWN

















func _fail(url: String, started_msec: int, prefix: String, code: int, msg: String) -> Dictionary:
	return {
		"ok": false, 
		"url": url, 
		"cost_time": Time.get_ticks_msec() - started_msec, 
		"err_code": prefix if code < 0 else Tracker.build_err_code(prefix, code), 
		"err_msg": msg, 
	}


static func _location_header(headers: PackedStringArray) -> String:
	for h: String in headers:
		var idx: int = h.find(":")
		if idx <= 0:
			continue
		if h.substr(0, idx).strip_edges().to_lower() == "location":
			return h.substr(idx + 1).strip_edges()
	return ""


static func _filename_of(url: String) -> String:
	var no_query: String = url.get_slice("?", 0)
	var slash: int = no_query.rfind("/")
	return no_query.substr(slash + 1) if slash >= 0 else no_query


static func _is_config_type_not_found(body_text: String) -> bool:
	var parsed: Variant = JSON.parse_string(body_text)
	if not (parsed is Dictionary):
		return false
	return String((parsed as Dictionary).get("error", "")) == "config_type not found"



static func _parse_envelope(body_text: String) -> Dictionary:
	var envelope: Dictionary = _parse_api_response(body_text)
	if not bool(envelope.get("ok", false)):
		return {"ok": false}
	var chapters_variant: Variant = envelope.get("data")
	if not (chapters_variant is Array):
		return {"ok": false}

	var ab_info: Dictionary = {}
	var raw: Variant = JSON.parse_string(body_text)
	if raw is Dictionary:
		var raw_ab: Variant = (raw as Dictionary).get("ab_info")
		if raw_ab is Dictionary:
			ab_info = raw_ab
	return {"ok": true, "chapters": chapters_variant, "ab_info": ab_info}












static func _parse_strategy_pool(body_text: String) -> Dictionary:
	var root: Variant = JSON.parse_string(body_text)
	if root is Array:
		return {"ok": true, "levels": root as Array}
	if not (root is Dictionary):
		return {"ok": false}
	var root_dict: Dictionary = root

	if root_dict.has("status"):
		var status: Dictionary = root_dict.get("status", {}) as Dictionary
		if int(status.get("code", -1)) != 0:
			return {"ok": false}
	var data: Variant = root_dict.get("data")
	if not (data is Array):
		return {"ok": false}
	return {"ok": true, "levels": data as Array}


static func _read_cache_if_valid(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return ""
	return text


static func _write_cache_atomic(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var part_path: String = path + ".part"
	var f: = FileAccess.open(part_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return DirAccess.rename_absolute(part_path, path) == OK


static func _write_cache_atomic_bytes(path: String, bytes: PackedByteArray) -> bool:
	var part_path: String = path + ".part"
	var f: = FileAccess.open(part_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	return DirAccess.rename_absolute(part_path, path) == OK




static func _replace_config_cache(cache_key: String, new_filename: String) -> void :
	var manifest: Dictionary = _load_manifest()
	var old_filename: String = String(manifest.get(cache_key, ""))
	manifest[cache_key] = new_filename
	_save_manifest(manifest)
	if not old_filename.is_empty() and old_filename != new_filename:
		var old_path: String = "%s/%s" % [CACHE_DIR, old_filename]
		if FileAccess.file_exists(old_path):
			DirAccess.remove_absolute(old_path)


static func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	return (parsed as Dictionary) if parsed is Dictionary else {}


static func _save_manifest(manifest: Dictionary) -> void :
	_write_cache_atomic(MANIFEST_PATH, JSON.stringify(manifest))


static func _find_cover_by_key(key: String) -> String:
	var dir: = DirAccess.open(COVER_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var found: String = ""
	var names: Array[String] = []
	var name: String = dir.get_next()
	while name != "":
		names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	for n: String in names:
		if n.begins_with(key + "."):
			var path: String = "%s/%s" % [COVER_DIR, n]
			var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
			var ext: String = _sniff_image_ext(bytes)
			var image: Image = Image.load_from_file(path) if not ext.is_empty() else null
			if image != null and not image.is_empty():
				found = path
			else:
				DirAccess.remove_absolute(path)
			break
	return found




static func clear_disk_cache() -> int:
	var removed: int = 0
	for dir_path: String in [CACHE_DIR, COVER_DIR]:
		var dir: = DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var names: Array[String] = []
		var name: String = dir.get_next()
		while name != "":
			if not dir.current_is_dir():
				names.append(name)
			name = dir.get_next()
		dir.list_dir_end()
		for n: String in names:
			if DirAccess.remove_absolute("%s/%s" % [dir_path, n]) == OK:
				removed += 1
	return removed
