class_name MapPreview
extends Control

## A compact, data-driven terrain diagram for a BoardData resource.
@export var board_data: BoardData:
	set(value):
		board_data = value
		queue_redraw()

const HEIGHT_COLORS := [
	Color("28445f"),
	Color("39749a"),
	Color("63a9b8"),
	Color("d7c36a"),
]

const LIGHT_TILE_TINT := Color(1.14, 1.14, 1.14, 1.0)
const GRID_LINE_COLOR := Color(0.04, 0.09, 0.14, 0.72)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if board_data == null or board_data.grid_size.x <= 0 or board_data.grid_size.y <= 0:
		return

	var columns := board_data.grid_size.x
	var rows := board_data.grid_size.y
	var inset := maxf(3.0, minf(size.x, size.y) * 0.06)
	var cell_size := minf((size.x - inset * 2.0) / columns, (size.y - inset * 2.0) / rows)
	if cell_size <= 0.0:
		return

	var preview_size := Vector2(columns * cell_size, rows * cell_size)
	var origin := (size - preview_size) * 0.5

	for y in rows:
		for x in columns:
			var index := y * columns + x
			var height := board_data.cell_heights[index] if index < board_data.cell_heights.size() else 0
			height = clampi(height, 0, HEIGHT_COLORS.size() - 1)
			var color: Color = HEIGHT_COLORS[height]
			if (x + y) % 2 == 0:
				color *= LIGHT_TILE_TINT

			var rect := Rect2(origin + Vector2(x * cell_size, y * cell_size), Vector2.ONE * cell_size)
			draw_rect(rect, color)
			draw_rect(rect, GRID_LINE_COLOR, false, maxf(1.0, cell_size * 0.045))

	draw_rect(Rect2(origin, preview_size), Color("b8eaff"), false, maxf(1.0, cell_size * 0.11))
