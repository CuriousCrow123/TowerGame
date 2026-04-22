class_name MainMenu
extends Control

@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	assert(_play_button != null, "MainMenu: PlayButton not found")
	set_process(false)
	set_physics_process(false)
	_play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	Events.ui_play_pressed.emit()
