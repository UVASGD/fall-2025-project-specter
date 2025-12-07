extends InteractableDisplay

@export var text : String
var text_display : RichTextLabel

func _ready() -> void:
	super()
	text_display = display.get_child(0)

func interact(player: Player) -> void:
	text_display.text = text
	super(player)
	
	
