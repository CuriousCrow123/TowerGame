class_name HUD
extends CanvasLayer

signal rotate_cw_pressed
signal rotate_cw_released
signal rotate_ccw_pressed
signal rotate_ccw_released
signal fast_drop_pressed

@onready var _score_label: Label = %ScoreLabel
@onready var _high_score_label: Label = %HighScoreLabel
@onready var _rotate_ccw: Button = %RotateCCWButton
@onready var _rotate_cw: Button = %RotateCWButton
@onready var _fast_drop: Button = %FastDropButton


func _ready() -> void:
	assert(_score_label != null, "HUD: ScoreLabel not found")
	assert(_high_score_label != null, "HUD: HighScoreLabel not found")
	assert(_rotate_ccw != null, "HUD: RotateCCWButton not found")
	assert(_rotate_cw != null, "HUD: RotateCWButton not found")
	assert(_fast_drop != null, "HUD: FastDropButton not found")
	set_process(false)
	set_physics_process(false)
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_high_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_rotate_ccw.button_down.connect(func() -> void: rotate_ccw_pressed.emit())
	_rotate_ccw.button_up.connect(func() -> void: rotate_ccw_released.emit())
	_rotate_cw.button_down.connect(func() -> void: rotate_cw_pressed.emit())
	_rotate_cw.button_up.connect(func() -> void: rotate_cw_released.emit())
	_fast_drop.pressed.connect(func() -> void: fast_drop_pressed.emit())

	var is_mobile: bool = _detect_mobile()
	_rotate_ccw.visible = is_mobile
	_rotate_cw.visible = is_mobile
	_fast_drop.visible = is_mobile

	Events.score_changed.connect(_on_score_changed)
	Events.high_score_beaten.connect(_on_high_score_beaten)
	Events.game_started.connect(_on_game_started)


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Height: " + str(new_score)


func _on_high_score_beaten(new_high: int) -> void:
	_high_score_label.text = "BEST: " + str(new_high)


func _on_game_started() -> void:
	_score_label.text = "Height: 0"
	_high_score_label.text = "Best: " + str(GameState.high_score)


func _detect_mobile() -> bool:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		return true
	if OS.get_name() == "Web":
		return DisplayServer.is_touchscreen_available()
	return false


func show_hud() -> void:
	visible = true


func hide_hud() -> void:
	visible = false
