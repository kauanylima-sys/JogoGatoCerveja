extends Control

@export var raio: float = 36.0
@export var margem: float = 12.0
@export var mostrar_agulha_peixe: bool = false

const COR_FUNDO = Color(0, 0, 0, 0.45)
const COR_BORDA = Color(1, 1, 1, 0.9)
const COR_NORTE = Color(0.9, 0.2, 0.2)
const COR_PONTAS = Color(1, 1, 1, 0.95)
const COR_DIAGONAIS = Color(1, 1, 1, 0.55)
const COR_AGULHA = Color(1, 0.85, 0.2)

func _ready():
	var lado = (raio + 22.0) * 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -lado - margem
	offset_right = -margem
	offset_top = margem
	offset_bottom = lado + margem

func _process(_delta):
	if mostrar_agulha_peixe:
		queue_redraw()

func _draw():
	var centro = size / 2.0
	var fonte = ThemeDB.fallback_font

	draw_circle(centro, raio + 8.0, COR_FUNDO)
	draw_arc(centro, raio + 8.0, 0.0, TAU, 48, COR_BORDA, 2.0)

	var diagonais = [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]
	for d in diagonais:
		_desenhar_ponta(centro, d.normalized(), raio * 0.62, raio * 0.10, COR_DIAGONAIS)

	var principais = [
		{"dir": Vector2.UP, "nome": "N", "cor": COR_NORTE},
		{"dir": Vector2.RIGHT, "nome": "L", "cor": COR_PONTAS},
		{"dir": Vector2.DOWN, "nome": "S", "cor": COR_PONTAS},
		{"dir": Vector2.LEFT, "nome": "O", "cor": COR_PONTAS},
	]
	for p in principais:
		_desenhar_ponta(centro, p["dir"], raio, raio * 0.18, p["cor"])
		var pos = centro + p["dir"] * (raio + 15.0)
		draw_string(fonte, Vector2(pos.x - 10.0, pos.y + 5.0), p["nome"],
			HORIZONTAL_ALIGNMENT_CENTER, 20.0, 14, p["cor"])

	draw_circle(centro, 3.0, Color.BLACK)

	if mostrar_agulha_peixe:
		_desenhar_agulha(centro)

func _desenhar_ponta(centro: Vector2, dir: Vector2, comprimento: float, largura: float, cor: Color):
	var ponta = centro + dir * comprimento
	var lado_a = centro + dir.rotated(PI / 2.0) * largura
	var lado_b = centro + dir.rotated(-PI / 2.0) * largura
	draw_colored_polygon(PackedVector2Array([ponta, lado_a, lado_b]), cor)

func _desenhar_agulha(centro: Vector2):
	var jogador = get_tree().get_first_node_in_group("jogador") as Node2D
	if jogador == null:
		return
	var alvo: Node2D = null
	var menor = INF
	for no in get_tree().get_nodes_in_group("peixe"):
		var peixe = no as Node2D
		if peixe == null or peixe.visible:
			continue
		var distancia = jogador.global_position.distance_to(peixe.global_position)
		if distancia < menor:
			menor = distancia
			alvo = peixe
	if alvo == null:
		return
	var dir = (alvo.global_position - jogador.global_position).normalized()
	var fim = centro + dir * (raio - 4.0)
	draw_line(centro, fim, COR_AGULHA, 3.0)
	draw_circle(fim, 4.0, COR_AGULHA)
