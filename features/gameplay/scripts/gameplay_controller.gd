class_name GameplayController
extends Node2D

const GROUND_Y: float = 1200.0
const SPAWN_X: float = 360.0
const SPAWN_DELAY: float = 0.2
const SPAWN_MARGIN: float = 350.0

const _BLOCK_SCENE_PATH: String = "res://features/blocks/scenes/block.tscn"
var _block_scene: PackedScene

@onready var _camera: TowerCamera = $TowerCamera
@onready var _input_handler: BlockInputHandler = $BlockInputHandler
@onready var _block_container: Node2D = $BlockContainer
@onready var _ground: Ground = $Ground
@onready var _kill_zone_bottom: Area2D = $KillZoneBottom
@onready var _kill_zone_left: Area2D = $KillZoneLeft
@onready var _kill_zone_right: Area2D = $KillZoneRight

var _spawner: BlockSpawner
var _active_block: Block = null
var _first_block: Block = null
var _highest_y: float = GROUND_Y
var _spawn_timer: Timer


func _ready() -> void:
	assert(_camera != null, "GameplayController requires TowerCamera child")
	assert(_block_container != null, "GameplayController requires BlockContainer child")
	assert(_ground != null, "GameplayController requires Ground child")
	assert(_kill_zone_bottom != null, "GameplayController requires KillZoneBottom child")
	assert(_kill_zone_left != null, "GameplayController requires KillZoneLeft child")
	assert(_kill_zone_right != null, "GameplayController requires KillZoneRight child")
	assert(_input_handler != null, "GameplayController requires BlockInputHandler child")

	set_process(false)
	set_physics_process(false)

	_spawner = BlockSpawner.new()
	_block_scene = load(_BLOCK_SCENE_PATH) as PackedScene
	assert(_block_scene != null, "Failed to load block scene")

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.wait_time = SPAWN_DELAY
	_spawn_timer.timeout.connect(_spawn_next_block)
	add_child(_spawn_timer)

	_kill_zone_bottom.body_entered.connect(_on_kill_zone_body_entered)
	_kill_zone_left.body_entered.connect(_on_kill_zone_body_entered)
	_kill_zone_right.body_entered.connect(_on_kill_zone_body_entered)

	Events.game_started.connect(_on_game_started)
	Events.game_restarted.connect(_on_game_restarted)


func _spawn_next_block() -> void:
	if not GameState.is_playing:
		return
	var data: BlockData = _spawner.get_random_block_data()
	var block: Block = _block_scene.instantiate() as Block
	block.block_data = data
	_block_container.add_child(block)
	var spawn_y: float = _highest_y - SPAWN_MARGIN
	block.global_position = Vector2(SPAWN_X, spawn_y)

	if _first_block == null:
		_first_block = block

	_active_block = block
	_input_handler.set_active_block(block)

	block.landed.connect(_on_block_landed)
	block.contacted.connect(_on_block_contacted)
	block.body_entered.connect(_on_block_hit_something.bind(block))


func _on_block_contacted(_block: Block) -> void:
	_input_handler.clear_active_block()


func _on_block_landed(block: Block) -> void:
	_input_handler.clear_active_block()
	_active_block = null

	var block_top_y: float = block.global_position.y - _get_block_half_height(block)
	if block_top_y < _highest_y:
		_highest_y = block_top_y

	_update_score()
	_camera.set_tower_top(_highest_y, GameState.current_height)
	Events.block_placed.emit(block, GameState.current_height)

	_spawn_timer.start()


func _on_block_hit_something(body: Node, block: Block) -> void:
	if not GameState.is_playing:
		return
	if body != _ground:
		return
	if block == _first_block:
		return
	_trigger_game_over()


func _trigger_game_over() -> void:
	_input_handler.clear_active_block()
	_active_block = null
	Events.game_over.emit(GameState.current_height)


func _update_score() -> void:
	var height: float = GROUND_Y - _highest_y
	GameState.current_height = height
	var score: int = int(height / float(Block.BASE_CELL_SIZE))
	GameState.current_score = score
	Events.score_changed.emit(score)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if not GameState.is_playing:
		return
	if not body is Block:
		return
	var block: Block = body as Block
	if block == _active_block:
		return
	_trigger_game_over()


func _on_game_started() -> void:
	_spawn_next_block()


func _on_game_restarted() -> void:
	_input_handler.clear_active_block()
	_active_block = null
	_first_block = null
	_clear_all_blocks()
	_highest_y = GROUND_Y


func _clear_all_blocks() -> void:
	for child: Node in _block_container.get_children():
		child.queue_free()


func _get_block_half_height(block: Block) -> float:
	if block.block_data == null:
		return 24.0
	var max_y: int = 0
	var min_y: int = 0
	for cell: Vector2i in block.block_data.cells:
		max_y = maxi(max_y, cell.y)
		min_y = mini(min_y, cell.y)
	return float(max_y - min_y + 1) * block.cell_size * 0.5
