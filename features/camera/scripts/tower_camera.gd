class_name TowerCamera
extends Camera2D

@export var follow_speed_up: float = 6.0
@export var follow_speed_down: float = 3.0
@export var look_ahead_pixels: float = 150.0
@export var max_fall_speed: float = 400.0
@export var collapse_delay: float = 0.3
@export var min_zoom_level: float = 0.5
@export var max_zoom_level: float = 1.0
@export var zoom_height_range: float = 2000.0
@export var zoom_speed: float = 1.5

var _target_y: float = 640.0
var _tower_height: float = 0.0
var _is_collapsing: bool = false
var _collapse_timer: float = 0.0


func _ready() -> void:
	set_process(false)
	set_physics_process(true)
	position_smoothing_enabled = false
	process_callback = CAMERA2D_PROCESS_PHYSICS
	limit_smoothed = true


func _physics_process(delta: float) -> void:
	_update_zoom(delta)

	if _is_collapsing:
		_collapse_timer -= delta
		if _collapse_timer <= 0.0:
			var speed: float = minf(max_fall_speed, follow_speed_down / delta)
			position.y = move_toward(position.y, _target_y, speed * delta)
			if absf(position.y - _target_y) < 1.0:
				_is_collapsing = false
		return

	var desired_y: float = _target_y
	if _tower_height > 0.0:
		desired_y = _target_y - look_ahead_pixels
	var clamped_y: float = minf(desired_y, 640.0)
	var speed: float = follow_speed_up if clamped_y < position.y else follow_speed_down
	position.y = lerpf(position.y, clamped_y, speed * delta)


func _update_zoom(delta: float) -> void:
	var height_ratio: float = clampf(_tower_height / zoom_height_range, 0.0, 1.0)
	var target_zoom: float = lerpf(max_zoom_level, min_zoom_level, height_ratio)
	var current_zoom: float = zoom.x
	var new_zoom: float = lerpf(current_zoom, target_zoom, zoom_speed * delta)
	zoom = Vector2(new_zoom, new_zoom)


func set_tower_top(world_y: float, tower_height: float) -> void:
	_target_y = world_y
	_tower_height = tower_height


func notify_collapse(new_top_y: float, new_height: float) -> void:
	_is_collapsing = true
	_collapse_timer = collapse_delay
	_target_y = new_top_y
	_tower_height = new_height


func reset() -> void:
	_target_y = 640.0
	_tower_height = 0.0
	_is_collapsing = false
	_collapse_timer = 0.0
	position.y = 640.0
	zoom = Vector2(max_zoom_level, max_zoom_level)
