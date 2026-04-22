class_name GameOverPanel
extends Control

@onready var _final_score_label: Label = %FinalScoreLabel
@onready var _high_score_label: Label = %HighScoreLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	assert(_final_score_label != null, "GameOverPanel: FinalScoreLabel not found")
	assert(_high_score_label != null, "GameOverPanel: HighScoreLabel not found")
	assert(_restart_button != null, "GameOverPanel: RestartButton not found")
	set_process(false)
	set_physics_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_high_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_button.pressed.connect(_on_restart_pressed)
	Events.game_over.connect(_on_game_over)
	hide()


func _on_game_over(_final_height: float) -> void:
	_final_score_label.text = "Height: " + str(GameState.current_score)
	_high_score_label.text = "Best: " + str(GameState.high_score)
	show()


func _on_restart_pressed() -> void:
	Events.ui_restart_pressed.emit()
	hide()
