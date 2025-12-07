extends InteractableDisplay


signal correct_code
signal incorrect_code

@export var code: String = "0000"

var input: String = ""

@onready var keypad_display: TextureRect = $KeypadDisplay
@onready var main_player = %Player


func _input_char(character: String) -> void:
	input += character
	print(input)


func _on_button_enter_pressed() -> void:
	if input == code:
		correct_code.emit()
		main_player.stop_looking_at_display()
		print("The code is correct!")
	else:
		incorrect_code.emit()
		print("The code is incorrect...")
	input = ""


func _on_button_pressed(num):
	_input_char(num)


func _on_button_clear_pressed() -> void:
	input = ""
