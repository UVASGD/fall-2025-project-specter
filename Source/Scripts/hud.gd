class_name Hud
extends Control

@onready var stamina_bar = $Oxygen
@onready var stamina_text = $Oxygen/RichTextLabel
@onready var noise_bar = $Noise
@onready var vars = []

var interactable_display: TextureRect


#TODO make dynamic
func _process(_delta: float) -> void:
	var stamina = vars[0]
	var noise = vars[1]
	
	stamina_bar.value = stamina
	stamina_text.text = "Oxygen: %.0f" % stamina
	noise_bar.value = noise #TODO add tween
