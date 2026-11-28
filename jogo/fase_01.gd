extends Node2D

@onready var dialogo = $dialogo
@onready var camera = $cerveja/Camera2D
@onready var cerveja = $cerveja
@onready var tico = $tico
@onready var area_estacionamento: Area2D = $areaEstacionamento
@onready var peixe = $Peixe

# 0: encontrar Tico; 1: procurar no estacionamento;
# 2: retornar ao Tico; 3: procurar a comida no novo local.
var etapa_missao: int = 0
var etapa_apos_dialogo: int = -1

func testar_dialogo() -> void:
	var conversa: Array[Dictionary] = [
		{
			"nome": "Cerveja",
			"texto": "É isso? Me largaram aqui sem nenhuma despedida?",
			"retrato": preload("res://assets/retratos/cerveja/03_triste.png")
		},
		{
			"nome": "Cerveja",
			"texto": "Hump. Como se eu precisasse deles. Eu consigo ser um gato livre!",
			"retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")
		},
		{
			"nome": "Cerveja",
			"texto": "Sinto que vou morrer caso não coma alguma coisa. Preciso achar comida!",
			"retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")
		}
	]
	iniciar_conversa(conversa)

func _ready() -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 962
	camera.limit_bottom = 415

	# A comida so pode ser encontrada depois da segunda conversa.
	cerveja.set_meta("busca_liberada", false)
	peixe.remove_from_group("peixe")
	cerveja.busca_sem_resultado.connect(_on_busca_sem_resultado)
	tico.interacao_solicitada.connect(_on_tico_interacao_solicitada)
	dialogo.dialogo_finalizado.connect(_on_dialogo_finalizado)
	testar_dialogo()


func iniciar_conversa(conversa: Array[Dictionary], proxima_etapa: int = -1) -> void:
	if dialogo.dialogo_ativo or conversa.is_empty():
		return
	etapa_apos_dialogo = proxima_etapa

	# Bloqueia o jogador antes de mostrar a primeira fala.
	cerveja.set_meta("em_dialogo", true)
	cerveja.velocity = Vector2.ZERO
	cerveja.set_physics_process(false)
	cerveja.fazendo_ocioso = false
	cerveja.tempo_parado = 0.0
	cerveja._tocar("idle")

	dialogo.iniciar_dialogo(conversa)


func _on_tico_interacao_solicitada() -> void:
	if dialogo.dialogo_ativo or cerveja.buscando or cerveja.comendo or cerveja.morto or cerveja.venceu:
		return
	var conversa: Array[Dictionary] = []
	match etapa_missao:
		0:
			conversa = [
				{"nome": "Gato desconhecido", "texto": "Eai! nunca te vi aqui, você parece meio abatido!", "retrato": preload("res://assets/retratos/tico/normal.png")},
				{"nome": "Cerveja", "texto": "Pareço abatido? você está muito enganado!", "retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")},
				{"nome": "Tico", "texto": "Não quis te ofender! Eu sou o tico, moro por aqui faz tempo,", "retrato": preload("res://assets/retratos/tico/normal.png")},
				{"nome": "Tico", "texto": "Se precisar de alguma coisa pode contar comigo!", "retrato": preload("res://assets/retratos/tico/calmo.png")},
				{"nome": "Cerveja", "texto": "Pra falar a verdade eu to com um pouco de fome...", "retrato": preload("res://assets/retratos/cerveja/01_neutro.png")},
				{"nome": "Tico", "texto": "Tem um estacionamento ao Leste, talvez você encontre comida lá", "retrato": preload("res://assets/retratos/tico/normal.png")},
			]
			iniciar_conversa(conversa, 1)
		1:
			conversa = [
				{"nome": "Tico", "texto": "Já procurou no estacionamento, ao leste? Vai logo, antes que os outros gatos cheguem!", "retrato": preload("res://assets/retratos/tico/normal.png")}
			]
			iniciar_conversa(conversa)
		2:
			conversa = [
				{"nome": "Cerveja", "texto": "Não tinha nada no estacionamento. Acho que outro gato já procurou lá...", "retrato": preload("res://assets/retratos/cerveja/03_triste.png")},
				{"nome": "Tico", "texto": "hmm, não é fácil conseguir comida por aqui...", "retrato": preload("res://assets/retratos/tico/normal.png")},
				{"nome": "Tico", "texto": "Tenta procurar nas caixas perto do beco ao oeste. Às vezes os humanos deixam restos de comida por ali.", "retrato": null},
				{"nome": "Cerveja", "texto": "Obrigado, vou tentar de novo!", "retrato": preload("res://assets/retratos/cerveja/06_pensativo.png")}
			]
			iniciar_conversa(conversa, 3)
		3:
			conversa = [
				{"nome": "Tico", "texto": "O beco fica ao oeste!. Dá uma boa olhada por ali!", "retrato": preload("res://assets/retratos/tico/normal.png")}
			]
			iniciar_conversa(conversa)


func _on_busca_sem_resultado() -> void:
	if etapa_missao == 0:
		cerveja._mostrar_mensagem("Melhor conversar com o Tico primeiro.")
	elif etapa_missao == 1 and area_estacionamento.overlaps_body(cerveja):
		etapa_missao = 2
		cerveja._mostrar_mensagem("Nada no estacionamento. Melhor voltar e falar com o Tico.", 4.0)
	elif etapa_missao == 1:
		cerveja._mostrar_mensagem("Preciso procurar no estacionamento, ao leste")
	elif etapa_missao == 2:
		cerveja._mostrar_mensagem("Preciso voltar e conversar com o Tico.")


func _on_dialogo_finalizado() -> void:
	if etapa_apos_dialogo != -1:
		etapa_missao = etapa_apos_dialogo
		etapa_apos_dialogo = -1

	if etapa_missao == 3:
		cerveja.set_meta("busca_liberada", true)
		if is_instance_valid(peixe) and not peixe.is_in_group("peixe"):
			peixe.add_to_group("peixe")

	# Libera o movimento apenas quando a ultima fala terminar.
	cerveja.velocity = Vector2.ZERO
	cerveja.set_meta("em_dialogo", false)
	cerveja.set_physics_process(true)
