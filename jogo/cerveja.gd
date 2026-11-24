extends CharacterBody2D

const VELOCIDADE_ANDAR = 80.0
const VELOCIDADE_CORRER = 160.0
const VIDA_MAXIMA = 3

const TEMPO_PARA_PISCAR = 4.0
const TEMPO_PARA_ACHAR_PEIXE = 60.0
const TEMPO_AVISO = 10.0

const RAIO_BUSCA = 40.0

const FATOR_TAMANHO = 0.5

const ZOOM_CAMERA = Vector2(3.5, 3.5)

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
var buscando = false
var vida = VIDA_MAXIMA
var tempo_restante = TEMPO_PARA_ACHAR_PEIXE
var posicao_inicial = Vector2.ZERO
var avisando = false
var tween_aviso: Tween


func _ready():
	posicao_inicial = global_position
	_criar_acao("norte", [KEY_W, KEY_UP])
	_criar_acao("sul", [KEY_S, KEY_DOWN])
	_criar_acao("oeste", [KEY_A, KEY_LEFT])
	_criar_acao("leste", [KEY_D, KEY_RIGHT])
	_criar_acao("correr", [KEY_SHIFT])
	_criar_acao("procurar", [KEY_E])
	for nome in ["blink", "lick", "hurt"]:
		if anim.sprite_frames.has_animation(nome):
			anim.sprite_frames.set_animation_loop(nome, false)
	anim.animation_finished.connect(_ao_terminar_animacao)
	_configurar_camera()
	_tocar("idle")


func _configurar_camera():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = Camera2D.new()
		add_child(camera)
		camera.make_current()
	camera.zoom = ZOOM_CAMERA


func _physics_process(delta):

	if get_meta("em_dialogo", false):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if machucado or morto or venceu:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	tempo_restante -= delta
	if tempo_restante <= 0.0:
		_perder_vida_por_tempo()
		return

	if tempo_restante <= TEMPO_AVISO and not avisando:
		_iniciar_aviso()

	if buscando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Input.is_action_just_pressed("procurar") and not get_meta("npc_proximo", false):
		_procurar()
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
		tempo_restante = TEMPO_PARA_ACHAR_PEIXE
		_parar_aviso()
		vida = min(vida + 1, VIDA_MAXIMA)
		var restantes = get_tree().get_nodes_in_group("peixe").size()
		print("Nhac! Vida: ", vida, " | Peixes restantes: ", restantes)
		if restantes == 0:
			_passar_de_fase()


func _procurar():
	buscando = true
	fazendo_ocioso = false
	tempo_parado = 0.0
	velocity = Vector2.ZERO
	_tocar("idle")

	var tween = create_tween()
	tween.tween_property(anim, "rotation_degrees", -8.0, 0.2)
	tween.tween_property(anim, "rotation_degrees", 8.0, 0.4)
	tween.tween_property(anim, "rotation_degrees", 0.0, 0.2)
	tween.set_loops(2)
	await tween.finished

	anim.rotation_degrees = 0.0
	buscando = false

	if morto or venceu:
		return

	if _revelar_peixe_proximo():
		print("Achou um peixe!")
	else:
		print("Nada por aqui...")


func _revelar_peixe_proximo() -> bool:
	for no in get_tree().get_nodes_in_group("peixe"):
		var peixe = no as Node2D
		if peixe == null or peixe.visible:
			continue
		if global_position.distance_to(peixe.global_position) <= RAIO_BUSCA:
			peixe.modulate.a = 0.0
			peixe.show()
			if "monitoring" in peixe:
				peixe.set_deferred("monitoring", true)
			create_tween().tween_property(peixe, "modulate:a", 1.0, 0.3)
			return true
	return false


func _passar_de_fase():
	venceu = true
	fazendo_ocioso = false
	_parar_aviso()
	print("Todos os peixes! Próxima fase...")
	_tocar("lick")
	await get_tree().create_timer(1.5).timeout

	var caminho = _caminho_da_proxima_fase()
	if caminho == "":
		print("Vitoria!!")
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


func _iniciar_aviso():
	avisando = true
	tween_aviso = create_tween().set_loops()
	tween_aviso.tween_property(anim, "modulate", Color(1, 0.4, 0.4), 0.3)
	tween_aviso.tween_property(anim, "modulate", Color.WHITE, 0.3)


func _parar_aviso():
	avisando = false
	if tween_aviso:
		tween_aviso.kill()
	anim.modulate = Color.WHITE


func _machucar():
	if machucado:
		return
	_parar_aviso()
	machucado = true
	buscando = false
	fazendo_ocioso = false
	tempo_parado = 0.0
	_tocar("hurt")

	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(1, 0.4, 0.4), 0.15)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)
	tween.set_loops(2)


func _perder_vida_por_tempo():
	vida -= 1
	_parar_aviso()
	print("Tempo esgotado! Vida: ", vida)

	if vida <= 0:
		morto = true
		print("Game over! Recomeçando...")
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()
		return

	global_position = posicao_inicial
	tempo_restante = TEMPO_PARA_ACHAR_PEIXE
	tempo_parado = 0.0
	fazendo_ocioso = false
	_tocar("idle")


func _atualizar_parado(delta):
	if fazendo_ocioso:
		return

	tempo_parado += delta

	if tempo_parado >= TEMPO_PARA_PISCAR and anim.animation == "idle":
		fazendo_ocioso = true
		_tocar("blink")
	elif anim.animation != "idle":
		_tocar("idle")


func _ao_terminar_animacao():
	if venceu or morto:
		return
	if anim.animation == "hurt":
		machucado = false
		_tocar("idle")
	elif anim.animation == "blink":
		_tocar("lick")
	elif anim.animation == "lick":
		fazendo_ocioso = false
		tempo_parado = 0.0
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


func _tocar(nome: String):
	anim.scale = Vector2.ONE * ESCALAS.get(nome, 0.3) * FATOR_TAMANHO
	if anim.animation != nome or not anim.is_playing():
		anim.play(nome)
