extends InteractableDisplay


signal correct_code
signal incorrect_code

@export var code: String = "0000"

var input: String = ""

@onready var keypad_display: TextureRect = $KeypadDisplay


func _input_char(character: String) -> void:
	input += character
	print(input)


func _on_button_one_pressed() -> void:
	_input_char("1")


func _on_button_two_pressed() -> void:
	_input_char("2")


func _on_button_three_pressed() -> void:
	_input_char("3")


func _on_button_four_pressed() -> void:
	_input_char("4")


func _on_button_five_pressed() -> void:
	_input_char("5")


func _on_button_six_pressed() -> void:
	_input_char("6")


func _on_button_seven_pressed() -> void:
	_input_char("7")


func _on_button_eight_pressed() -> void:
	_input_char("8")


func _on_button_nine_pressed() -> void:
	_input_char("9")


func _on_button_enter_pressed() -> void:
	if input == code:
		correct_code.emit()
		print("The code is correct!")
	else:
		incorrect_code.emit()
		print("The code is incorrect...")
	input = ""


func _on_button_zero_pressed() -> void:
	_input_char("0")


func _on_button_clear_pressed() -> void:
	input = ""
