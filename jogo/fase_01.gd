extends Node2D

@onready var dialogo = $dialogo
@onready var camera = $cerveja/Camera2D
@onready var cerveja = $cerveja
@onready var tico = $tico

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

	tico.interacao_solicitada.connect(_on_tico_interacao_solicitada)
	dialogo.dialogo_finalizado.connect(_on_dialogo_finalizado)
	testar_dialogo()


func _on_tico_interacao_solicitada() -> void:
	if dialogo.dialogo_ativo:
		return
	cerveja.set_meta("em_dialogo", true)
	var conversa_tico: Array[Dictionary] = [
		{"nome": "Tico", "texto": "Ei! Você é novo por aqui?", "retrato": null},
		{"nome": "Cerveja", "texto": "Sou. Estou tentando encontrar alguma coisa para comer.", "retrato": preload("res://assets/retratos/cerveja/01_neutro.png")},
		{"nome": "Tico", "texto": "Então fica de olho nas ruas. Às vezes aparece comida por aí!", "retrato": null}
	]
	dialogo.iniciar_dialogo(conversa_tico)

func _on_dialogo_finalizado() -> void:
	cerveja.set_meta("em_dialogo", false)
