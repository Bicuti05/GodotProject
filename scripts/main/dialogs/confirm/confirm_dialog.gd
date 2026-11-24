class_name ConfirmDialog
extends Control








@onready var _title_label: Label = $Root / Content / DialogRoot / Title
@onready var _title_back_label: Label = $Root / Content / DialogRoot / TitleBack
@onready var _content_label: Label = $Root / Content / DialogRoot / ContentLabel
@onready var _action_btn: CommonBtn = $Root / Content / DialogRoot / ActionButton
@onready var _stay_btn: CommonBtn = $Root / Content / DialogRoot / StayButton
@onready var _anim: AnimationPlayer = $Root / AnimationPlayer






signal closed(confirmed: bool)

var _on_confirm: Callable
var _on_close: Callable
var _closing: bool = false

func _ready() -> void :
	SceneManager.bind_press_release_scale($Root / Content / DialogRoot / CloseButton)

func _on_show(params: Dictionary = {}) -> void :
	open(
		params.get("title", _title_label.text), 
		params.get("content", _content_label.text), 
		params.get("btn_text", _action_btn.btn_text), 
		params.get("on_confirm", Callable()), 
		params.get("on_close", Callable()), 
		params.get("stay_text", _stay_btn.btn_text)
	)



func open(title: String, content: String, btn_text: String, on_confirm: Callable, on_close: Callable = Callable(), stay_text: String = "EXIT_LEVEL_DIALOG_STAY") -> void :


	var t: String = tr(title)
	_title_label.text = t
	_title_back_label.text = t
	_content_label.text = tr(content)



	_action_btn.btn_text = btn_text
	_stay_btn.btn_text = stay_text
	_on_confirm = on_confirm
	_on_close = on_close
	_closing = false
	visible = true
	_anim.play_section_with_markers("GenericPopup", &"", &"Mark")

func close() -> void :
	if _closing:
		return
	_closing = true
	_anim.play_section_with_markers("GenericPopup", &"Mark", &"")
	await _anim.animation_finished

	visible = false

func _on_action_btn_pressed() -> void :
	close()
	if _on_confirm.is_valid():
		_on_confirm.call()
	closed.emit(true)

func _on_close_btn_pressed() -> void :
	close()
	if _on_close.is_valid():
		_on_close.call()
	closed.emit(false)
