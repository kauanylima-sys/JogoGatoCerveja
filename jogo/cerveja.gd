extends CharacterBody2D

const VELOCIDADE_ANDAR = 80.0
const VELOCIDADE_CORRER = 160.0
const VIDA_MAXIMA = 3

const TEMPO_PARA_PISCAR = 4.0
const TEMPO_PARA_LAMBER = 7.0

const ESCALAS = {
	"idle": 0.3,
	"walk": 0.08,
	"run": 0.05,
	"blink": 0.3,
	"lick": 0.3,
	"hurt": 0.3,
}

@onready var anim = $AnimatedSprite2D

const ROSA_DOS_VENTOS = ["L", "SE", "S", "SO", "O", "NO", "N", "NE"]

var direcao_atual = "S"
var tempo_parado = 0.0
var fazendo_ocioso = false  
var machucado = false       
var morto = false           
var venceu = false          
var vida = VIDA_MAXIMA


func _ready():
	_criar_acao("norte", [KEY_W, KEY_UP])
	_criar_acao("sul", [KEY_S, KEY_DOWN])
	_criar_acao("oeste", [KEY_A, KEY_LEFT])
	_criar_acao("leste", [KEY_D, KEY_RIGHT])
	_criar_acao("correr", [KEY_SHIFT])
	anim.animation_finished.connect(_ao_terminar_animacao)
	_tocar("idle")


func _physics_process(delta):
	
	if machucado or morto or venceu:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direcao = Input.get_vector("oeste", "leste", "norte", "sul")

	if direcao != Vector2.ZERO:
		tempo_parado = 0.0
		fazendo_ocioso = false

		direcao = direcao.normalized()
		direcao_atual = _nome_da_direcao(direcao)

		var correndo = Input.is_action_pressed("correr")
		var velocidade = VELOCIDADE_CORRER if correndo else VELOCIDADE_ANDAR
		velocity = direcao * velocidade

		if direcao.x != 0:
			anim.flip_h = direcao.x < 0

		_tocar("run" if correndo else "walk")
	else:
		velocity = Vector2.ZERO
		_atualizar_parado(delta)

	move_and_slide()


func comer(tipo: String):
	if morto or venceu:
		return
	if tipo == "lixo":
		_machucar()
	elif tipo == "peixe":
		vida = min(vida + 1, VIDA_MAXIMA)
		var restantes = get_tree().get_nodes_in_group("peixe").size()
		print("Nhac! Vida: ", vida, " | Peixes restantes: ", restantes)
		if restantes == 0:
			_passar_de_fase()


func _passar_de_fase():
	venceu = true
	fazendo_ocioso = false
	print("Todos os peixes! Próxima fase...")
	_tocar("lick") 
	await get_tree().create_timer(1.5).timeout

	var caminho = _caminho_da_proxima_fase()
	if caminho == "":
		print("Não existe próxima fase. Fim de jogo!")
		return
	get_tree().change_scene_to_file(caminho)



func _caminho_da_proxima_fase() -> String:
	var atual = get_tree().current_scene.scene_file_path 
	var nome = atual.get_file().get_basename()           

	var partes = nome.rsplit("_", true, 1)               
	if partes.size() < 2 or not partes[1].is_valid_int():
		return ""

	var numero = partes[1].to_int() + 1
	var digitos = partes[1].length()                      
	var proximo = "%s_%0*d" % [partes[0], digitos, numero]
	var caminho = atual.get_base_dir() + "/" + proximo + ".tscn"

	if ResourceLoader.exists(caminho):
		return caminho
	return ""


func _machucar():
	if machucado:
		return
	machucado = true
	fazendo_ocioso = false
	tempo_parado = 0.0
	vida -= 1
	print("Ai! Comeu lixo. Vida: ", vida)
	_tocar("hurt")


	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(1, 0.4, 0.4), 0.15)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)
	tween.set_loops(2)


	if vida <= 0:
		morto = true
		print("Game over! Recomeçando...")
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()



func _atualizar_parado(delta):
	if fazendo_ocioso:
		return

	tempo_parado += delta

	if tempo_parado >= TEMPO_PARA_LAMBER:
		fazendo_ocioso = true
		tempo_parado = 0.0
		_tocar("lick", false)
	elif tempo_parado >= TEMPO_PARA_PISCAR and anim.animation == "idle":
		fazendo_ocioso = true
		_tocar("blink", false)
	elif anim.animation != "idle":
		_tocar("idle")


func _ao_terminar_animacao():
	if venceu or morto:
		return
	if anim.animation == "hurt":
		machucado = false
		_tocar("idle")
	elif anim.animation == "blink" or anim.animation == "lick":
		fazendo_ocioso = false
		_tocar("idle")


func _nome_da_direcao(direcao: Vector2) -> String:
	var indice = int(round(direcao.angle() / (PI / 4.0)))
	return ROSA_DOS_VENTOS[posmod(indice, 8)]


func _criar_acao(nome: String, teclas: Array):
	if not InputMap.has_action(nome):
		InputMap.add_action(nome)
	for tecla in teclas:
		var evento = InputEventKey.new()
		evento.physical_keycode = tecla
		InputMap.action_add_event(nome, evento)


func _tocar(nome: String, reiniciar: bool = true):
	anim.scale = Vector2.ONE * ESCALAS.get(nome, 0.3)
	if reiniciar or anim.animation != nome:
		anim.play(nome)
