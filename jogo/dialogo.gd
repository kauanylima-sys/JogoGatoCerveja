
extends CanvasLayer

signal dialogo_finalizado

@onready var painel = $Control/PanelContainer

@onready var retrato = $Control/PanelContainer/MarginContainer/HBoxContainer/retratoPersonagem

@onready var nome = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/nomePersonagem

@onready var texto = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/textoDialogo

var falas: Array[Dictionary] = []
var indice: int = 0
var dialogo_ativo: bool = false


func _ready() -> void:
	painel.hide()


func iniciar_dialogo(novas_falas: Array[Dictionary]) -> void:
	if dialogo_ativo or novas_falas.is_empty():
		return

	falas = novas_falas
	indice = 0
	dialogo_ativo = true

	painel.show()
	mostrar_fala()


func mostrar_fala() -> void:
	var fala = falas[indice]

	nome.text = fala["nome"]
	texto.text = fala["texto"]
	retrato.texture = fala.get("retrato", null)


func _unhandled_input(event: InputEvent) -> void:
	if not dialogo_ativo:
		return

	if event.is_action_pressed("ui_accept") and not event.is_echo():
		avancar_dialogo()
		get_viewport().set_input_as_handled()


func avancar_dialogo() -> void:
	indice += 1

	if indice < falas.size():
		mostrar_fala()
	else:
		finalizar_dialogo()


func finalizar_dialogo() -> void:
	dialogo_ativo = false
	painel.hide()
	dialogo_finalizado.emit()
