extends Node2D

@onready var dialogo = $dialogo
@onready var camera = $Cerveja/Camera2D

func testar_dialogo() -> void:
	var conversa: Array[Dictionary] = [
		{
			"nome": "Cerveja",
			"texto": "É isso? Me largaram aqui sem nenhuma despedida?",
			"retrato": preload("res://assets/sprite_pack_cat/blink/blink_00.png")
		},
		{
			"nome": "Cerveja",
			"texto": "Humanos... Nunca foram muito inteligentes mesmo.",
			"retrato": preload("res://assets/sprite_pack_cat/lick/lick_06.png")
		},
		{
			"nome": "Cerveja",
			"texto": "Bom, primeiro preciso encontrar alguma coisa para comer.",
			"retrato": preload("res://assets/sprite_pack_cat/blink/blink_00.png")
		}
	]
	dialogo.testar_dialogo(conversa)
	
func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1024
	camera.limit_bottom = 768
