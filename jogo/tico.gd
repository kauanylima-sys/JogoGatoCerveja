extends CharacterBody2D

signal interacao_solicitada

@onready var area_interacao: Area2D = $areaInteracao
@onready var aviso_interacao: Label = $AvisoInteracao

var jogador_perto: bool = false
var jogador: CharacterBody2D

func _ready() -> void:
	aviso_interacao.hide()
	area_interacao.body_entered.connect(_ao_entrar_na_area)
	area_interacao.body_exited.connect(_ao_sair_da_area)

func _unhandled_input(event: InputEvent) -> void:
	if jogador_perto and event.is_action_pressed("interagir") and not event.is_echo():
		if jogador != null and not jogador.get_meta("em_dialogo", false):
			interacao_solicitada.emit()
			get_viewport().set_input_as_handled()

func _ao_entrar_na_area(body: Node2D) -> void:
	if body.is_in_group("jogador"):
		jogador = body as CharacterBody2D
		jogador_perto = true
		jogador.set_meta("npc_proximo", true)
		aviso_interacao.show()

func _ao_sair_da_area(body: Node2D) -> void:
	if body == jogador:
		jogador_perto = false
		jogador.set_meta("npc_proximo", false)
		jogador = null
		aviso_interacao.hide()
