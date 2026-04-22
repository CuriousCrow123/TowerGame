extends Node2D
## Entry point — manages game states and scene transitions.

@onready var _hud: HUD = $HUD
@onready var _main_menu: MainMenu = $UILayer/MainMenu
@onready var _game_over: GameOverPanel = $UILayer/GameOverPanel


func _ready() -> void:
	assert(_hud != null, "Main: HUD not found")
	assert(_main_menu != null, "Main: MainMenu not found")
	assert(_game_over != null, "Main: GameOverPanel not found")
	set_process(false)
	set_physics_process(false)

	Events.ui_play_pressed.connect(_on_play_pressed)
	Events.ui_restart_pressed.connect(_on_restart_pressed)
	Events.game_over.connect(_on_game_over)

	_hud.hide_hud()
	_main_menu.show()
	_game_over.hide()


func _on_play_pressed() -> void:
	_main_menu.hide()
	_hud.show_hud()
	Events.game_started.emit()


func _on_restart_pressed() -> void:
	Events.game_restarted.emit()
	_hud.show_hud()
	_game_over.hide()
	Events.game_started.emit()


func _on_game_over(_final_height: float) -> void:
	_hud.hide_hud()
