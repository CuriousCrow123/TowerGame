class_name BlockSpawner
extends RefCounted

const _BLOCK_DATA_PATHS: Array[String] = [
	"res://features/blocks/resources/block_small.tres",
	"res://features/blocks/resources/block_square.tres",
	"res://features/blocks/resources/block_rect_h.tres",
	"res://features/blocks/resources/block_rect_v.tres",
	"res://features/blocks/resources/block_l.tres",
	"res://features/blocks/resources/block_t.tres",
	"res://features/blocks/resources/block_long.tres",
	"res://features/blocks/resources/block_big_square.tres",
]

var _block_data_array: Array[BlockData] = []


func _init() -> void:
	for path: String in _BLOCK_DATA_PATHS:
		var data: BlockData = load(path) as BlockData
		assert(data != null, "Failed to load BlockData at: " + path)
		_block_data_array.append(data)


func get_random_block_data() -> BlockData:
	var index: int = randi() % _block_data_array.size()
	return _block_data_array[index]
