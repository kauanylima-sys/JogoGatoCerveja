extends Node2D

@onready var dialogo = $dialogo
@onready var camera = $cerveja/Camera2D

func testar_dialogo() -> void:
	var conversa: Array[Dictionary] = [
		{
			"nome": "Cerveja",
			"texto": "É isso? Me largaram aqui sem nenhuma despedida?",
			"retrato": preload("res://assets/retratos/cerveja/03_triste.png")
		},
		{
			"nome": "Cerveja",
			"texto": "hump. Como se eu precisa-se deles. Eu consigo ser um gato livre!",
			"retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")
		},
		{
			"nome": "Cerveja",
			"texto": "Sinto que vou morrer caso não coma alguma coisa. Preciso achar comida!",
			"retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")
		}
	]
	dialogo.iniciar_dialogo(conversa)
	

func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 962
	camera.limit_bottom = 415

	testar_dialogo()
