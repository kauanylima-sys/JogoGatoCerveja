extends Node2D

@export var peixe_cena: PackedScene
@export var quantidade: int = 3
@export var deslocamento: Vector2 = Vector2(0, -6)
@export var area: Rect2 = Rect2(0, 0, 1152, 648)
@export var debug: bool = true


func _ready() -> void:
	print("SPAWN RODANDO")
	print("peixe_cena = ", peixe_cena)

	if peixe_cena == null:
		print("ERRO: peixe_cena está vazio! Arraste o peixe.tscn no Inspetor.")
		return

	var esconderijos: Array[Node2D] = _achar_esconderijos()
	if esconderijos.is_empty():
		push_warning("SpawnPeixes: nenhum esconderijo encontrado. Os peixes vão aparecer em lugares aleatórios da área.")
	esconderijos.shuffle()

	if debug:
		print("[SpawnPeixes] Esconderijos achados: ", esconderijos.size())

	for i in quantidade:
		var posicao: Vector2
		if esconderijos.is_empty():
			posicao = Vector2(
				randf_range(area.position.x, area.end.x),
				randf_range(area.position.y, area.end.y)
			)
		else:
			var item: Node2D = esconderijos[i % esconderijos.size()]
			posicao = _centro_do_item(item) + deslocamento

		var peixe = peixe_cena.instantiate()
		peixe.add_to_group("peixe")
		add_child(peixe)
		peixe.global_position = posicao
		peixe.hide()

		if "monitoring" in peixe:
			peixe.set_deferred("monitoring", false)

		if debug:
			print("[SpawnPeixes] Peixe ", i + 1, " criado em: ", posicao)

	if debug:
		print("[SpawnPeixes] Peixes no grupo 'peixe': ", get_tree().get_nodes_in_group("peixe").size())


func _achar_esconderijos() -> Array[Node2D]:
	var lista: Array[Node2D] = []

	for no in get_tree().get_nodes_in_group("esconderijo"):
		if no is Node2D:
			lista.append(no)

	if lista.is_empty():
		for no in get_tree().root.find_children("*", "StaticBody2D", true, false):
			if no is Node2D:
				lista.append(no)

	if lista.is_empty():
		for no in get_tree().root.find_children("*", "Area2D", true, false):
			if no is Node2D and not no.is_in_group("peixe"):
				lista.append(no)

	return lista


func _centro_do_item(item: Node2D) -> Vector2:
	for filho in item.get_children():
		if filho is CollisionShape2D or filho is CollisionPolygon2D:
			return filho.global_position
	return item.global_position
