class_name Block
extends RigidBody2D

signal landed(block: Block)
signal contacted(block: Block)

const BASE_CELL_SIZE: int = 48
const LAND_VELOCITY: float = 30.0
const LAND_TIME: float = 0.15
const MIN_SCALE: float = 0.6
const MAX_SCALE: float = 1.3

@export var block_data: BlockData

var cell_size: float = BASE_CELL_SIZE
var _center_offset: Vector2 = Vector2.ZERO
var _is_falling: bool = false
var _has_landed: bool = false
var _has_contacted: bool = false
var _land_timer: float = 0.0


func _ready() -> void:
	assert(block_data != null, "Block requires block_data to be set")
	set_process(false)
	set_physics_process(false)

	cell_size = BASE_CELL_SIZE * randf_range(MIN_SCALE, MAX_SCALE)

	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	contact_monitor = true
	max_contacts_reported = 4

	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	mat.rough = true
	physics_material_override = mat

	_center_offset = _calculate_center_offset()
	_build_collision_shapes()

	body_entered.connect(_on_body_entered)


func _draw() -> void:
	for cell: Vector2i in block_data.cells:
		var rect_pos: Vector2 = Vector2(cell) * cell_size - _center_offset
		draw_rect(Rect2(rect_pos, Vector2(cell_size, cell_size)), block_data.color)


func _physics_process(delta: float) -> void:
	if _has_landed:
		return

	if linear_velocity.length() < LAND_VELOCITY:
		_land_timer += delta
		if _land_timer >= LAND_TIME:
			_has_landed = true
			mass = 1.0
			set_physics_process(false)
			landed.emit(self)
	else:
		_land_timer = 0.0


func activate_fall() -> void:
	_is_falling = true
	freeze = false
	mass = 0.01
	gravity_scale = 1.0
	set_physics_process(true)


func hard_drop() -> void:
	activate_fall()
	gravity_scale = 3.0


func _on_body_entered(_body: Node) -> void:
	if _is_falling and not _has_contacted:
		_has_contacted = true
		contacted.emit(self)


func _calculate_center_offset() -> Vector2:
	if block_data.cells.is_empty():
		return Vector2.ZERO
	var min_x: int = block_data.cells[0].x
	var max_x: int = block_data.cells[0].x
	var min_y: int = block_data.cells[0].y
	var max_y: int = block_data.cells[0].y

	for cell: Vector2i in block_data.cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)

	var width: float = float(max_x - min_x + 1) * cell_size
	var height: float = float(max_y - min_y + 1) * cell_size
	return Vector2(float(min_x) * cell_size + width * 0.5, float(min_y) * cell_size + height * 0.5)


func _build_collision_shapes() -> void:
	var half_cell := Vector2(cell_size * 0.5, cell_size * 0.5)
	var body_rid: RID = get_rid()
	for cell: Vector2i in block_data.cells:
		var shape_rid: RID = PhysicsServer2D.rectangle_shape_create()
		PhysicsServer2D.shape_set_data(shape_rid, half_cell)
		var center: Vector2 = Vector2(cell) * cell_size - _center_offset + half_cell
		var xform := Transform2D(0.0, center)
		PhysicsServer2D.body_add_shape(body_rid, shape_rid, xform)
