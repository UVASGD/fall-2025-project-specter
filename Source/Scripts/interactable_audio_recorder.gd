class_name InteractableAudioRecorder
extends Interactable


@export var stream: AudioStream


var _audio_stream_player: AudioStreamPlayer3D


func _ready() -> void:
	_audio_stream_player = AudioStreamPlayer3D.new()
	_audio_stream_player.stream = stream
	add_child(_audio_stream_player)


func interact(_player: Player) -> void:
	if _audio_stream_player.playing:
		_audio_stream_player.stop()
		return
	
	_audio_stream_player.play()
	# Emit sound w new system
	SoundManager.emit_sound(global_position, 30.0, self)
