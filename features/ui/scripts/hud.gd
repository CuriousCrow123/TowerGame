class_name HUD
extends CanvasLayer

@onready var _score_label: Label = %ScoreLabel
@onready var _high_score_label: Label = %HighScoreLabel


func _ready() -> void:
	assert(_score_label != null, "HUD: ScoreLabel not found")
	assert(_high_score_label != null, "HUD: HighScoreLabel not found")
	set_process(false)
	set_physics_process(false)
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_high_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func show_hud() -> void:
	visible = true


func hide_hud() -> void:
	visible = false
