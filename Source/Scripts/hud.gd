class_name Hud
extends Control


signal start_dialogue(text_array: Array[String])
signal stop_dialogue

@onready var stamina_bar = $Oxygen
@onready var stamina_text = $Oxygen/RichTextLabel
@onready var noise_bar = $Noise
@onready var vars = []
@onready var dialogue_box: TextureRect = $CanvasLayer/DialogueBox
@onready var dialogue_text: RichTextLabel = $CanvasLayer/DialogueBox/DialogueText

var interactable_display: TextureRect
var dialogue_array: Array[String]


#TODO make dynamic
func _process(_delta: float) -> void:
	var stamina = abs(vars[0])
	var noise = vars[1]
	
	stamina_bar.value = stamina
	stamina_text.text = "Oxygen: %.0f" % stamina
	noise_bar.value = noise #TODO add tween


func display_dialogue_box(text_array: Array[String]) -> void:
	print("Signal Recieved")
	dialogue_array = text_array
	dialogue_box.visible = true
	dialogue_text.text = dialogue_array.pop_front()


func get_next_dialogue_text() -> void:
	if dialogue_array:
		dialogue_text.text = dialogue_array.pop_front()
	else:
		dialogue_box.visible = false
		stop_dialogue.emit()
