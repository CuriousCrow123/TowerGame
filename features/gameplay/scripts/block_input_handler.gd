class_name BlockInputHandler
extends Node

const EDGE_MARGIN: float = 20.0
const LERP_WEIGHT: float = 0.15
const SWIPE_MIN_VELOCITY: float = 1200.0
const SWIPE_MIN_DISTANCE: float = 80.0
const SWIPE_DIRECTION_RATIO: float = 0.5
const VIEWPORT_WIDTH: float = 720.0
const KEY_MOVE_SPEED: float = 400.0
const KEY_ROTATE_SPEED: float = 3.0

var _active_block: Block = null
var _target_x: float = 0.0
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_time: int = 0
var _move_direction: int = 0
var _rotate_direction: int = 0


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func set_active_block(block: Block) -> void:
	_active_block = block
	_target_x = block.global_position.x
	_is_dragging = false
	set_process(true)


func clear_active_block() -> void:
	_active_block = null
	_is_dragging = false
	_rotate_direction = 0
	_move_direction = 0
	set_process(false)


func _process(delta: float) -> void:
	if _active_block == null:
		return

	if _move_direction != 0:
		_target_x += _move_direction * KEY_MOVE_SPEED * delta
	if _rotate_direction != 0:
		_active_block.rotation += _rotate_direction * KEY_ROTATE_SPEED * delta

	var half_width: float = _get_block_half_width()
	var min_x: float = EDGE_MARGIN + half_width
	var max_x: float = VIEWPORT_WIDTH - EDGE_MARGIN - half_width
	_target_x = clampf(_target_x, min_x, max_x)

	var current_x: float = _active_block.global_position.x
	var new_x: float = lerpf(current_x, _target_x, LERP_WEIGHT)
	_active_block.global_position.x = new_x


func _input(event: InputEvent) -> void:
	if _active_block == null:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	if touch.index == 0:
		if touch.pressed:
			_start_drag(touch.position)
		else:
			_end_drag()
	elif touch.index == 1:
		if touch.pressed:
			_start_touch_rotate(touch.position)
		else:
			_rotate_direction = 0


func _handle_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == 0 and _is_dragging:
		_target_x += drag.relative.x
		_check_swipe_down(drag)


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_start_drag(mb.position)
	else:
		_end_drag()


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if _is_dragging and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_target_x += mm.relative.x


func _handle_key(key: InputEventKey) -> void:
	if key.keycode == KEY_LEFT or key.keycode == KEY_A:
		_move_direction = -1 if key.pressed else 0
	elif key.keycode == KEY_RIGHT or key.keycode == KEY_D:
		_move_direction = 1 if key.pressed else 0
	elif key.keycode == KEY_Q:
		_rotate_direction = -1 if key.pressed else 0
	elif key.keycode == KEY_E:
		_rotate_direction = 1 if key.pressed else 0
	elif key.pressed:
		if key.keycode == KEY_SPACE:
			_hard_drop()
		elif key.keycode == KEY_DOWN or key.keycode == KEY_S:
			_drop_block()


func _start_drag(pos: Vector2) -> void:
	_is_dragging = true
	_drag_start_pos = pos
	_drag_start_time = Time.get_ticks_msec()


func _end_drag() -> void:
	if _is_dragging:
		_is_dragging = false
		_drop_block()


func _start_touch_rotate(pos: Vector2) -> void:
	if pos.x < VIEWPORT_WIDTH * 0.5:
		_rotate_direction = -1
	else:
		_rotate_direction = 1


func _check_swipe_down(drag: InputEventScreenDrag) -> void:
	var distance: Vector2 = drag.position - _drag_start_pos
	var abs_x: float = absf(distance.x)
	var abs_y: float = absf(distance.y)
	if drag.velocity.y > SWIPE_MIN_VELOCITY and abs_y > SWIPE_MIN_DISTANCE:
		if abs_x / abs_y < SWIPE_DIRECTION_RATIO:
			_hard_drop()


func _drop_block() -> void:
	if _active_block == null:
		return
	_active_block.activate_fall()


func _hard_drop() -> void:
	if _active_block == null:
		return
	_active_block.activate_fall()
	_active_block.hard_drop()


func _get_block_half_width() -> float:
	if _active_block == null or _active_block.block_data == null:
		return 24.0
	var max_x: int = 0
	var min_x: int = 0
	for cell: Vector2i in _active_block.block_data.cells:
		max_x = maxi(max_x, cell.x)
		min_x = mini(min_x, cell.x)
	return float(max_x - min_x + 1) * _active_block.cell_size * 0.5
