extends Node3D

@export var cena_inimigo: PackedScene 

@onready var caminho = $Path3D
@onready var timer = $SpawnTimer

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)
	timer.wait_time = 2.0 
	timer.start()

func _on_spawn_timer_timeout():
	if not cena_inimigo:
		printerr("Erro: A cena do inimigo não foi definida no Inspetor!")
		return
		
	var seguidor = PathFollow3D.new()
	seguidor.rotation_mode = PathFollow3D.ROTATION_Y
	seguidor.loop = false
	var inimigo_instancia = cena_inimigo.instantiate()
	seguidor.add_child(inimigo_instancia)
	caminho.add_child(seguidor)
