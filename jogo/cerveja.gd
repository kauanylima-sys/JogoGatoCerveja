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
const AJUSTE_VERTICAL = 0.52

const PASTA_COMER = "res://cat_eating/frames/eat_once_%02d.png"
const DURACOES_COMER = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 4]
const VELOCIDADE_COMER = 6.0
const AJUSTE_COMER = 1.0
const OFFSETS = {
	"eat": Vector2.ZERO,
}

const ESCALAS = {
	"idle": 0.3,
	"walk": 0.08,
	"run": 0.05,
	"blink": 0.3,
	"lick": 0.3,
	"walk_up": 0.3,
	"walk_down": 0.3,
	"eat": 0.3,
}

@onready var anim = $AnimatedSprite2D

const ROSA_DOS_VENTOS = ["L", "SE", "S", "SO", "O", "NO", "N", "NE"]
const NOMES_DIRECOES = {
	"N": "Norte",
	"NE": "Nordeste",
	"L": "Leste",
	"SE": "Sudeste",
	"S": "Sul",
	"SO": "Sudoeste",
	"O": "Oeste",
	"NO": "Noroeste",
}

var direcao_atual = "S"
var tempo_parado = 0.0
var fazendo_ocioso = false
var morto = false
var venceu = false
var buscando = false
var comendo = false
var vida = VIDA_MAXIMA
var tempo_restante = TEMPO_PARA_ACHAR_PEIXE
var posicao_inicial = Vector2.ZERO
var avisando = false
var tween_aviso: Tween
var escalas_auto = {}
var rotulo_mensagem: Label
var tween_mensagem: Tween


func _ready():
	add_to_group("jogador")
	posicao_inicial = global_position
	_criar_acao("norte", [KEY_W, KEY_UP])
	_criar_acao("sul", [KEY_S, KEY_DOWN])
	_criar_acao("oeste", [KEY_A, KEY_LEFT])
	_criar_acao("leste", [KEY_D, KEY_RIGHT])
	_criar_acao("correr", [KEY_SHIFT])
	_criar_acao("procurar", [KEY_E])
	_adicionar_animacao_comer()
	for nome in ["blink", "lick", "eat"]:
		if anim.sprite_frames.has_animation(nome):
			anim.sprite_frames.set_animation_loop(nome, false)
	anim.animation_finished.connect(_ao_terminar_animacao)
	_ajustar_escalas_verticais()
	_ajustar_escala_comer()
	_configurar_camera()
	_criar_mensagem()
	_tocar("idle")


func _criar_mensagem():
	var camada = CanvasLayer.new()
	add_child(camada)
	rotulo_mensagem = Label.new()
	rotulo_mensagem.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rotulo_mensagem.offset_top = 16
	rotulo_mensagem.offset_bottom = 48
	rotulo_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_mensagem.add_theme_font_size_override("font_size", 20)
	rotulo_mensagem.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo_mensagem.add_theme_constant_override("outline_size", 6)
	rotulo_mensagem.modulate.a = 0.0
	camada.add_child(rotulo_mensagem)


func _mostrar_mensagem(texto: String, duracao: float = 3.0):
	print(texto)
	if rotulo_mensagem == null:
		return
	rotulo_mensagem.text = texto
	if tween_mensagem:
		tween_mensagem.kill()
	rotulo_mensagem.modulate.a = 1.0
	tween_mensagem = create_tween()
	tween_mensagem.tween_interval(duracao)
	tween_mensagem.tween_property(rotulo_mensagem, "modulate:a", 0.0, 0.5)


func mostrar_dica_peixe():
	var total = get_tree().get_nodes_in_group("peixe").size()
	var peixe = _peixe_escondido_mais_proximo()
	print("DICA -> peixes no grupo: ", total, " | escondido mais próximo: ", peixe)
	if peixe == null:
		_mostrar_mensagem("Não sinto nenhum peixe escondido por perto...")
		return
	var rumo = _nome_da_direcao(peixe.global_position - global_position)
	_mostrar_mensagem("Dica: o peixe mais próximo está ao " + NOMES_DIRECOES[rumo], 5.0)


func _configurar_camera():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = Camera2D.new()
		add_child(camera)
		camera.make_current()
	camera.zoom = ZOOM_CAMERA


func _physics_process(delta):

	if morto or venceu:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	tempo_restante -= delta
	if tempo_restante <= 0.0:
		_perder_vida_por_tempo()
		return

	if tempo_restante <= TEMPO_AVISO and not avisando:
		_iniciar_aviso()

	if buscando or comendo:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Input.is_action_just_pressed("procurar"):
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

		if abs(direcao.y) > 0.5:
			anim.flip_h = false
			_tocar("walk_up" if direcao.y < 0 else "walk_down")
			anim.speed_scale = 1.6 if correndo else 1.0
		else:
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
	if tipo == "peixe":
		tempo_restante = TEMPO_PARA_ACHAR_PEIXE
		_parar_aviso()
		vida = min(vida + 1, VIDA_MAXIMA)
		var restantes = get_tree().get_nodes_in_group("peixe").size()
		print("Nhac! Vida: ", vida, " | Peixes restantes: ", restantes)
		_comecar_a_comer()
		if restantes == 0:
			venceu = true
			if comendo:
				await anim.animation_finished
			_passar_de_fase()


func _comecar_a_comer():
	if not anim.sprite_frames.has_animation("eat"):
		# sem os quadros de "comer", toca a lambida para mostrar alguma reação
		fazendo_ocioso = true
		tempo_parado = 0.0
		velocity = Vector2.ZERO
		_tocar("lick")
		return
	comendo = true
	fazendo_ocioso = false
	tempo_parado = 0.0
	velocity = Vector2.ZERO
	anim.rotation_degrees = 0.0
	_tocar("eat")


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

	var peixe_achado = _peixe_ao_alcance()
	if peixe_achado != null:
		# achou: o peixe sai do jogo e o personagem come (toca a animação de comer)
		_mostrar_mensagem("Achou um peixe!")
		peixe_achado.remove_from_group("peixe")
		peixe_achado.queue_free()
		comer("peixe")
	else:
		var peixe = _peixe_escondido_mais_proximo()
		if peixe == null:
			_mostrar_mensagem("Nada por aqui...")
		else:
			var rumo = _nome_da_direcao(peixe.global_position - global_position)
			_mostrar_mensagem("Nada por aqui... o peixe mais próximo está ao " + NOMES_DIRECOES[rumo])


func _peixe_escondido_mais_proximo() -> Node2D:
	var mais_proximo: Node2D = null
	var menor = INF
	for no in get_tree().get_nodes_in_group("peixe"):
		var peixe = no as Node2D
		if peixe == null or peixe.visible:
			continue
		var distancia = global_position.distance_to(peixe.global_position)
		if distancia < menor:
			menor = distancia
			mais_proximo = peixe
	return mais_proximo


func _peixe_ao_alcance() -> Node2D:
	var mais_proximo: Node2D = null
	var menor = RAIO_BUSCA
	for no in get_tree().get_nodes_in_group("peixe"):
		var peixe = no as Node2D
		if peixe == null:
			continue
		var distancia = global_position.distance_to(peixe.global_position)
		if distancia <= menor:
			menor = distancia
			mais_proximo = peixe
	return mais_proximo


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
	comendo = false
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
	if anim.animation == "eat":
		comendo = false
		if venceu or morto:
			return
		fazendo_ocioso = false
		tempo_parado = 0.0
		_tocar("idle")
		return

	if venceu or morto:
		return
	if anim.animation == "blink":
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


func _largura_visivel(nome: String) -> float:
	if not anim.sprite_frames.has_animation(nome):
		return 0.0
	var textura = anim.sprite_frames.get_frame_texture(nome, 0)
	if textura == null:
		return 0.0
	var imagem = textura.get_image()
	if imagem == null:
		return 0.0
	return float(imagem.get_used_rect().size.x)


func _ajustar_escalas_verticais():
	var largura_ref = _largura_visivel("idle")
	var largura_cima = _largura_visivel("walk_up")
	if largura_ref <= 0.0 or largura_cima <= 0.0:
		return
	var escala = ESCALAS["idle"] * largura_ref / largura_cima * AJUSTE_VERTICAL
	escalas_auto["walk_up"] = escala
	escalas_auto["walk_down"] = escala


func _adicionar_animacao_comer():
	if anim.sprite_frames.has_animation("eat"):
		return
	var frames: SpriteFrames = anim.sprite_frames
	frames.add_animation("eat")
	frames.set_animation_speed("eat", VELOCIDADE_COMER)
	frames.set_animation_loop("eat", false)
	for i in DURACOES_COMER.size():
		var caminho = PASTA_COMER % i
		if not ResourceLoader.exists(caminho):
			push_warning("Quadro da animação de comer não encontrado: " + caminho)
			continue
		frames.add_frame("eat", load(caminho), DURACOES_COMER[i])
	if frames.get_frame_count("eat") == 0:
		frames.remove_animation("eat")


func _ajustar_escala_comer():
	var largura_ref = _largura_visivel("idle")
	var largura_comer = _largura_visivel("eat")
	if largura_ref <= 0.0 or largura_comer <= 0.0:
		return
	escalas_auto["eat"] = ESCALAS["idle"] * largura_ref / largura_comer * AJUSTE_COMER


func _tocar(nome: String):
	anim.speed_scale = 1.0
	anim.offset = OFFSETS.get(nome, Vector2.ZERO)
	var escala = escalas_auto.get(nome, ESCALAS.get(nome, 0.3))
	anim.scale = Vector2.ONE * escala * FATOR_TAMANHO
	if anim.animation != nome or not anim.is_playing():
		anim.play(nome)
