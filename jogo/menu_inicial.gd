extends Control

func _ready():
	print("menu carregado")
	$Jogar.mouse_entered.connect(func(): print("mouse entrou no Jogar"))
	$Jogar.button_down.connect(func(): print("botao apertado"))

func _on_jogar_pressed():
	print("1. clicou em jogar")
	var resultado = get_tree().change_scene_to_file("res://fase_01.tscn")
	print("3. resultado da troca: ", resultado)
