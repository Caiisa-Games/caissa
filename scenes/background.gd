extends OptionButton


@onready var background: TextureRect = $"../../../../../../../Background"

func back():
	background.texture = GameState.background[GameState.back]

func dis():
	if 5 in GameState.back_disable:
		set_item_disabled(1, false)
		set_item_disabled(2, false)
		print(3)
	if 10 in GameState.back_disable:
		set_item_disabled(3, false)
		#$"../ModeSelect".set_item_disabled(1, false)
		print(4)
	if 15 in GameState.back_disable:
		#$"../ModeSelect".set_item_disabled(2, false)
		set_item_disabled(4, false)
		print(5)
	else:
		print(9999999)

func _ready() -> void:
	dis()

func _on_item_selected(index: int) -> void:
	if index == 0:
		GameState.back = 1
		back()
	elif index == 1:
		GameState.back = 2
		back()
	elif index == 2:
		GameState.back = 3
		back()
	elif index == 3:
		GameState.back = 4
		back()
	elif index == 4:
		GameState.back = 5
		back()
	else:
		print(99999)
