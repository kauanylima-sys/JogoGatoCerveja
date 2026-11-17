extends CharacterBody2D

const VELOCIDADE_ANDAR = 80.0
const VELOCIDADE_CORRER = 160.0

# Quantos segundos parado até cada ação
const TEMPO_PARA_PISCAR = 4.0
const TEMPO_PARA_LAMBER = 7.0

# Escala de cada animação (ajuste até todas ficarem do mesmo tamanho)
const ESCALAS = {
	"idle": 0.3,
	"walk": 0.08,
	"run": 0.05,
	"blink": 0.3,
	"lick": 0.3,
	"hurt": 0.3,
}

@onready var anim = $AnimatedSprite2D

# Ordem importa: começa no Leste e gira no sentido horário
const ROSA_DOS_VENTOS = ["L", "SE", "S", "SO", "O", "NO", "N", "NE"]

var direcao_atual = "S"
var tempo_parado = 0.0
var fazendo_ocioso = false  # true enquanto pisca ou lambe


func _ready():
	_criar_acao("norte", [KEY_W, KEY_UP])
	_criar_acao("sul", [KEY_S, KEY_DOWN])
	_criar_acao("oeste", [KEY_A, KEY_LEFT])
	_criar_acao("leste", [KEY_D, KEY_RIGHT])
	_criar_acao("correr", [KEY_SHIFT])
	anim.animation_finished.connect(_ao_terminar_animacao)
	_tocar("idle")


func _physics_process(delta):
	var direcao = Input.get_vector("oeste", "leste", "norte", "sul")

	if direcao != Vector2.ZERO:
		# Está se movendo: zera o cronômetro e cancela piscar/lamber
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


# Controla idle -> piscar -> lamber quando o gato está parado
func _atualizar_parado(delta):
	# Se já está piscando ou lambendo, deixa terminar
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


# Quando blink ou lick terminam, volta para idle
func _ao_terminar_animacao():
	if anim.animation == "blink" or anim.animation == "lick":
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


# Troca a animação e ajusta a escala dela
func _tocar(nome: String, reiniciar: bool = true):
	anim.scale = Vector2.ONE * ESCALAS.get(nome, 0.3)
	if reiniciar or anim.animation != nome:
		anim.play(nome)
