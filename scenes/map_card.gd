extends Button
class_name BoardCard

const NAME_FONT_SIZE := 10
const MIN_NAME_FONT_SIZE := 7

var board_data: BoardData
var is_selected := false

var glow: Panel
var original_scale: Vector2

func setup(data: BoardData) -> void:
	board_data = data
	
	original_scale = scale
	
	var name_label: Label = $Panel/VBoxContainer/Name
	var meta_label: Label = $Panel/VBoxContainer/Meta
	var preview: MapPreview = $Panel/VBoxContainer/Preview
	glow = $SelectionGlow
	
	name_label.text = board_data.board_name
	_fit_name_font(name_label)
	preview.board_data = data

func _fit_name_font(name_label: Label) -> void:
	var font := name_label.get_theme_font("font")
	if font == null:
		return

	var available_width := name_label.custom_minimum_size.x
	var font_size := NAME_FONT_SIZE
	while font_size > MIN_NAME_FONT_SIZE:
		var text_width := font.get_string_size(board_data.board_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if text_width <= available_width:
			break
		font_size -= 1
	name_label.add_theme_font_size_override("font_size", font_size)

func set_selected(value: bool):
	is_selected = value

	if value:
		glow.show()
		create_tween().tween_property(self, "scale", original_scale * 1.05, 0.1)
	else:
		glow.hide()
		create_tween().tween_property(self, "scale", original_scale, 0.1)

		# anim
