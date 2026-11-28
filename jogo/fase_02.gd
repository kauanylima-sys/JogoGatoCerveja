extends Node2D

@onready var camera = $cerveja/Camera2D

func _ready() -> void:
	camera.limit_left = 2
	camera.limit_top = 0
	camera.limit_right = 1010
	camera.limit_bottom = 560
