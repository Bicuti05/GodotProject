extends Node














const DB_PATH: = "user://pocket_sort.db"
const TABLE_LEVEL: = "level_progress"

const ZTIME_COLUMNS: Array[String] = [
	"play_time_ms", "hint_used", "undo_used", "rope_used", "fill_pot_used", "dead_times", 
]


const START_TIMES_COLUMN: = "start_times"

var _db: SQLite
var _initialized: bool = false
var _initializing: bool = false


func init() -> void :
	if _initialized:
		SortLogger.warn("DbManager 已初始化")
		return
	SortLogger.mark("DbManager init")
	var db_path: = _resolve_db_path()
	_db = SQLite.new()
	_db.path = db_path
	if not _db.open_db():
		SortLogger.error("DB open 失败: %s" % db_path)
		return
	if not _create_tables():
		SortLogger.error("DB 挑战表初始化失败")
		_db.close_db()
		return
	_initialized = true
	SortLogger.info("DB ready: %s" % ProjectSettings.globalize_path(db_path))





func _resolve_db_path() -> String:
	if not OS.has_feature("editor"):
		return DB_PATH
	var project_hash: = ProjectSettings.globalize_path("res://").md5_text()
	return "user://pocket_sort_%s.db" % project_hash


func _create_tables() -> bool:






















	_db.query("""
		CREATE TABLE IF NOT EXISTS %s (
			level_id INTEGER PRIMARY KEY,
			completed INTEGER NOT NULL DEFAULT 0,
			score INTEGER NOT NULL DEFAULT 0,
			cost_time_ms INTEGER NOT NULL DEFAULT 0,
			completed_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0,
			raw_level_info TEXT,
			initial_state TEXT,
			current_state TEXT,
			game_id TEXT,
			play_time_ms INTEGER NOT NULL DEFAULT 0,
			hint_used INTEGER NOT NULL DEFAULT 0,
			undo_used INTEGER NOT NULL DEFAULT 0,
			rope_used INTEGER NOT NULL DEFAULT 0,
			fill_pot_used INTEGER NOT NULL DEFAULT 0,
			dead_times INTEGER NOT NULL DEFAULT 0,
			start_times INTEGER NOT NULL DEFAULT 0
		)
	""" %TABLE_LEVEL)
	_db.query("CREATE INDEX IF NOT EXISTS idx_level_completed ON %s(completed)" % TABLE_LEVEL)
	var special_ready: bool = _db.query("""
		CREATE TABLE IF NOT EXISTS special_challenge_progress (
			instance_id TEXT PRIMARY KEY, completed INTEGER NOT NULL DEFAULT 0,
			raw_level_info TEXT NOT NULL, initial_state TEXT NOT NULL,
			current_state TEXT NOT NULL, game_id TEXT NOT NULL,
			cost_time_ms INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")
	_ensure_game_id_column()
	_ensure_ztime_columns()
	_ensure_start_times_column()
	_drop_legacy_progress_table()
	return special_ready





func _drop_legacy_progress_table() -> void :
	_db.query("PRAGMA table_info(progress)")
	if _db.query_result.is_empty():
		return
	_db.query("DROP TABLE IF EXISTS progress")
	SortLogger.info("DbManager: 已删除废弃的 progress 表（职责由 %s 接管）" % TABLE_LEVEL)







func _ensure_game_id_column() -> void :
	_db.query("PRAGMA table_info(%s)" % TABLE_LEVEL)
	for col in _db.query_result:
		if String((col as Dictionary).get("name", "")) == "game_id":
			return
	_db.query("ALTER TABLE %s ADD COLUMN game_id TEXT" % TABLE_LEVEL)
	SortLogger.info("DbManager: %s 已补 game_id 列（老库迁移）" % TABLE_LEVEL)




func _ensure_ztime_columns() -> void :
	_db.query("PRAGMA table_info(%s)" % TABLE_LEVEL)
	var existing: Dictionary = {}
	for col in _db.query_result:
		existing[String((col as Dictionary).get("name", ""))] = true
	for name: String in ZTIME_COLUMNS:
		if existing.has(name):
			continue
		_db.query("ALTER TABLE %s ADD COLUMN %s INTEGER NOT NULL DEFAULT 0" % [TABLE_LEVEL, name])
		SortLogger.info("DbManager: %s 已补 %s 列（老库迁移）" % [TABLE_LEVEL, name])




func _ensure_start_times_column() -> void :
	_db.query("PRAGMA table_info(%s)" % TABLE_LEVEL)
	for col in _db.query_result:
		if String((col as Dictionary).get("name", "")) == START_TIMES_COLUMN:
			return
	_db.query("ALTER TABLE %s ADD COLUMN %s INTEGER NOT NULL DEFAULT 0"
		%[TABLE_LEVEL, START_TIMES_COLUMN])
	SortLogger.info("DbManager: %s 已补 %s 列（老库迁移）" % [TABLE_LEVEL, START_TIMES_COLUMN])





func load_level_entity(level_id: int) -> Dictionary:
	if not _initialized or level_id <= 0:
		return {}
	if not _db.query_with_bindings(
			"SELECT * FROM %s WHERE level_id=?" % TABLE_LEVEL, [level_id]):
		return {}
	if _db.query_result.is_empty():
		return {}
	return _db.query_result[0] as Dictionary




func save_level_entity(row: Dictionary) -> bool:
	if not _initialized:
		return false
	var level_id: int = int(row.get("level_id", 0))
	if level_id <= 0:
		return false
	return _db.query_with_bindings("""
		INSERT INTO %s (level_id, completed, score, cost_time_ms, completed_at, updated_at,
			raw_level_info, initial_state, current_state, game_id)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(level_id) DO UPDATE SET
			completed=excluded.completed,
			score=excluded.score,
			cost_time_ms=excluded.cost_time_ms,
			completed_at=excluded.completed_at,
			updated_at=excluded.updated_at,
			raw_level_info=excluded.raw_level_info,
			initial_state=excluded.initial_state,
			current_state=excluded.current_state,
			game_id=excluded.game_id
	""" %TABLE_LEVEL, [
		level_id, 
		int(row.get("completed", 0)), 
		int(row.get("score", 0)), 
		int(row.get("cost_time_ms", 0)), 
		int(row.get("completed_at", 0)), 
		int(row.get("updated_at", 0)), 
		str(row.get("raw_level_info", "{}")), 
		str(row.get("initial_state", "{}")), 
		str(row.get("current_state", "{}")), 
		str(row.get("game_id", "")), 
	])








func update_level_state(level_id: int, current_state_json: String, updated_at: int, 
		play_time_delta_ms: int = 0, round_ms: int = -1) -> bool:
	if not _initialized or level_id <= 0:
		return false
	return _db.query_with_bindings((
			"UPDATE %s SET current_state=?, updated_at=?, play_time_ms=play_time_ms+?, "
			+ "cost_time_ms=CASE WHEN ? >= 0 THEN ? ELSE cost_time_ms END "
			+ "WHERE level_id=?") % TABLE_LEVEL, 
		[current_state_json, updated_at, maxi(play_time_delta_ms, 0), 
			round_ms, round_ms, level_id])





func add_level_play_time(level_id: int, delta_ms: int, round_ms: int = -1) -> bool:
	if not _initialized or level_id <= 0:
		return false
	if delta_ms <= 0 and round_ms < 0:
		return false
	return _db.query_with_bindings((
			"UPDATE %s SET play_time_ms=play_time_ms+?, "
			+ "cost_time_ms=CASE WHEN ? >= 0 THEN ? ELSE cost_time_ms END "
			+ "WHERE level_id=?") % TABLE_LEVEL, 
		[maxi(delta_ms, 0), round_ms, round_ms, level_id])




func load_round_play_time_ms(level_id: int) -> int:
	if not _initialized or level_id <= 0:
		return 0
	if not _db.query_with_bindings(
			"SELECT cost_time_ms FROM %s WHERE level_id=?" % TABLE_LEVEL, [level_id]):
		return 0
	if _db.query_result.is_empty():
		return 0
	return int((_db.query_result[0] as Dictionary).get("cost_time_ms", 0))




func inc_level_counter(level_id: int, column: String) -> bool:
	if not _initialized or level_id <= 0:
		return false
	if column == "play_time_ms" or not (ZTIME_COLUMNS.has(column) or column == START_TIMES_COLUMN):
		SortLogger.error("DbManager: 非法计数列 %s" % column)
		return false
	return _db.query_with_bindings(
		"UPDATE %s SET %s=%s+1 WHERE level_id=?" % [TABLE_LEVEL, column, column], [level_id])



func clear_level_state(level_id: int) -> bool:
	if not _initialized or level_id <= 0:
		return false
	return _db.query_with_bindings(
		"UPDATE %s SET current_state=NULL WHERE level_id=?" % TABLE_LEVEL, [level_id])










func mark_level_completed(level_id: int, score: int, cost_time_ms: int, now_ms: int, 
		also_clear_raw: bool = false) -> bool:
	if not _initialized or level_id <= 0:
		return false
	var raw_clause: = "raw_level_info=NULL," if also_clear_raw else ""
	return _db.query_with_bindings("""
		INSERT INTO %s (level_id, completed, score, cost_time_ms, completed_at, updated_at,
			raw_level_info, initial_state, current_state)
		VALUES (?, 1, ?, ?, ?, ?, NULL, NULL, NULL)
		ON CONFLICT(level_id) DO UPDATE SET
			completed=1,
			score=CASE WHEN %s.completed=1 AND excluded.score=0
				THEN %s.score ELSE excluded.score END,
			cost_time_ms=CASE WHEN %s.completed=1 AND excluded.cost_time_ms=0
				THEN %s.cost_time_ms ELSE excluded.cost_time_ms END,
			completed_at=CASE WHEN %s.completed=1
				THEN %s.completed_at ELSE excluded.completed_at END,
			updated_at=excluded.updated_at,
			%s
			current_state=NULL
	""" %[TABLE_LEVEL, TABLE_LEVEL, TABLE_LEVEL, TABLE_LEVEL, TABLE_LEVEL, 
			TABLE_LEVEL, TABLE_LEVEL, raw_clause], [
		level_id, maxi(score, 0), maxi(cost_time_ms, 0), now_ms, now_ms
	])



func reset_all_levels() -> void :
	reset_special_challenges()
	if not _initialized:
		return
	_db.query("DELETE FROM %s" % TABLE_LEVEL)
	SortLogger.info("所有关卡存档已清空")



func load_special_challenge(instance_id: String) -> Dictionary:
	if not _initialized or instance_id.is_empty():
		return {}
	if not _db.query_with_bindings("SELECT * FROM special_challenge_progress WHERE instance_id=?", [instance_id]):
		return {}
	return {} if _db.query_result.is_empty() else _db.query_result[0] as Dictionary

func save_special_challenge(row: Dictionary) -> bool:
	if not _initialized:
		return false
	return _db.query_with_bindings("""
		INSERT INTO special_challenge_progress
		(instance_id,raw_level_info,initial_state,current_state,game_id,updated_at)
		VALUES (?,?,?,?,?,?) ON CONFLICT(instance_id) DO UPDATE SET
		raw_level_info=excluded.raw_level_info,initial_state=excluded.initial_state,
		current_state=excluded.current_state,game_id=excluded.game_id,
		cost_time_ms=0,updated_at=excluded.updated_at
		WHERE special_challenge_progress.completed=0
	""", [row["instance_id"], row["raw_level_info"], row["initial_state"], row["current_state"], 
		row["game_id"], int(row["updated_at"])])

func update_special_challenge(instance_id: String, state: String, round_ms: int) -> bool:
	if not _initialized:
		return false
	return _db.query_with_bindings("""
		UPDATE special_challenge_progress SET current_state=?,updated_at=?,
		cost_time_ms=CASE WHEN ? >= 0 THEN ? ELSE cost_time_ms END
		WHERE instance_id=? AND completed=0
	""", [state, int(Time.get_unix_time_from_system() * 1000.0), round_ms, round_ms, instance_id])

func update_special_challenge_time(instance_id: String, round_ms: int) -> bool:
	if not _initialized:
		return false
	return _db.query_with_bindings("UPDATE special_challenge_progress SET cost_time_ms=? WHERE instance_id=? AND completed=0", [round_ms, instance_id])

func complete_special_challenge(instance_id: String) -> bool:
	if not _initialized or load_special_challenge(instance_id).is_empty():
		return false
	return _db.query_with_bindings("UPDATE special_challenge_progress SET completed=1,current_state='{}' WHERE instance_id=?", [instance_id])

func reset_special_challenges() -> void :
	if _initialized:
		_db.query("DELETE FROM special_challenge_progress")


func init_async(active: Callable = Callable()) -> bool:
	while _initializing:
		await get_tree().process_frame
	if _initialized:
		return true
	_initializing = true
	var worker: = Thread.new()
	var path: String = ProjectSettings.globalize_path(_resolve_db_path())
	if worker.start(_open_initialized_db.bind(path)) != OK:
		_initializing = false
		SortLogger.error("DbManager: 初始化线程启动失败")
		return false
	while worker.is_alive():
		await get_tree().process_frame

	var connection: SQLite = worker.wait_to_finish()
	_initializing = false
	if connection == null:
		SortLogger.error("DbManager: 开库或迁移失败")
		return false
	if active.is_valid() and not active.call():
		connection.close_db()
		return false
	_db = connection
	_initialized = true
	SortLogger.info("DB ready: %s" % path)
	return true


static func _open_initialized_db(path: String) -> SQLite:
	var db: = SQLite.new()
	db.path = path
	if not db.open_db():
		return null
	if not db.query("BEGIN TRANSACTION"):
		db.close_db()
		return null
	if not _create_tables_worker(db) or not db.query("COMMIT"):
		db.query("ROLLBACK")
		db.close_db()
		return null
	return db


static func _migrate_columns(db: SQLite) -> bool:
	if not db.query("PRAGMA table_info(%s)" % TABLE_LEVEL):
		return false
	var existing: Dictionary = {}
	for col: Dictionary in db.query_result:
		existing[String(col.get("name", ""))] = true
	var additions: Dictionary = {"game_id": "TEXT", "start_times": "INTEGER NOT NULL DEFAULT 0"}
	for column: String in ZTIME_COLUMNS:
		additions[column] = "INTEGER NOT NULL DEFAULT 0"
	for column: String in additions:
		if not existing.has(column) and not db.query("ALTER TABLE %s ADD COLUMN %s %s" % [TABLE_LEVEL, column, additions[column]]):
			return false
	return true


static func _create_tables_worker(db: SQLite) -> bool:






















	var level_ready: bool = db.query("""
		CREATE TABLE IF NOT EXISTS %s (
			level_id INTEGER PRIMARY KEY,
			completed INTEGER NOT NULL DEFAULT 0,
			score INTEGER NOT NULL DEFAULT 0,
			cost_time_ms INTEGER NOT NULL DEFAULT 0,
			completed_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0,
			raw_level_info TEXT,
			initial_state TEXT,
			current_state TEXT,
			game_id TEXT,
			play_time_ms INTEGER NOT NULL DEFAULT 0,
			hint_used INTEGER NOT NULL DEFAULT 0,
			undo_used INTEGER NOT NULL DEFAULT 0,
			rope_used INTEGER NOT NULL DEFAULT 0,
			dead_times INTEGER NOT NULL DEFAULT 0,
			start_times INTEGER NOT NULL DEFAULT 0
		)
	""" %TABLE_LEVEL)
	var index_ready: bool = db.query("CREATE INDEX IF NOT EXISTS idx_level_completed ON %s(completed)" % TABLE_LEVEL)
	var special_ready: bool = db.query("""
		CREATE TABLE IF NOT EXISTS special_challenge_progress (
			instance_id TEXT PRIMARY KEY, completed INTEGER NOT NULL DEFAULT 0,
			raw_level_info TEXT NOT NULL, initial_state TEXT NOT NULL,
			current_state TEXT NOT NULL, game_id TEXT NOT NULL,
			cost_time_ms INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")
	return level_ready and index_ready and special_ready and _migrate_columns(db)\
	and db.query("DROP TABLE IF EXISTS progress")
