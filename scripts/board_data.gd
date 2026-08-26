class_name BoardData
extends Resource

@export var id: String
@export var board_name: String = "Unnamed Board"
@export_multiline var description: String
@export var grid_size: Vector2i = Vector2i(BoardManager.DEFAULT_GRID_SIZE, BoardManager.DEFAULT_GRID_SIZE)

@export var cell_heights: Array[int] = []

func _ready() -> void:
	if cell_heights.is_empty():
		cell_heights.resize(grid_size.x * grid_size.y)
		cell_heights.fill(0)

func resized_to(target_size: Vector2i) -> BoardData:
	var safe_target := Vector2i(maxi(1, target_size.x), maxi(1, target_size.y))
	var safe_source := Vector2i(maxi(1, grid_size.x), maxi(1, grid_size.y))
	var resized := BoardData.new()
	resized.id = id
	resized.board_name = board_name
	resized.description = description
	resized.grid_size = safe_target
	resized.cell_heights.resize(safe_target.x * safe_target.y)

	for y in safe_target.y:
		var source_y := _resample_index(y, safe_target.y, safe_source.y)
		for x in safe_target.x:
			var source_x := _resample_index(x, safe_target.x, safe_source.x)
			var source_index := source_y * safe_source.x + source_x
			var target_index := y * safe_target.x + x
			resized.cell_heights[target_index] = cell_heights[source_index] if source_index < cell_heights.size() else 0

	return resized

func _resample_index(target_index: int, target_length: int, source_length: int) -> int:
	if target_length <= 1 or source_length <= 1:
		return 0
	return roundi(float(target_index) * float(source_length - 1) / float(target_length - 1))
