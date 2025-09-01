extends Control

@onready var stamina_bar = $ProgressBar
@onready var stamina_text = $ProgressBar/RichTextLabel
@onready var vars = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var stamina = vars[0]
	var _noise = vars[1]
	
	stamina_bar.value = stamina
	stamina_text.text = "Oxygen: %.0f" % stamina
