extends Node3D

@export var cena_inimigo: PackedScene 

# 1. Pegamos a referência dos DOIS caminhos (ajuste o nome do Path3D2 se você mudou no editor!)
@onready var caminho_1 = $Path3D
@onready var caminho_2 = $Path3D2 

@onready var timer = $SpawnTimer

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)
	timer.wait_time = 3.0 
	timer.start()

func _on_spawn_timer_timeout():
	if not cena_inimigo:
		printerr("Erro: A cena do inimigo não foi definida no Inspetor!")
		return
		
	# 2. Colocamos os caminhos em uma lista
	var todos_os_caminhos = [caminho_1, caminho_2]
	
	# 3. O código vai repetir o bloco abaixo para CADA caminho da lista
	for rota_atual in todos_os_caminhos:
		
		# Cria o carrinho e configura
		var seguidor = PathFollow3D.new()
		seguidor.rotation_mode = PathFollow3D.ROTATION_Y
		seguidor.loop = false
		
		# Instancia o inimigo
		var inimigo_instancia = cena_inimigo.instantiate()
		
		# Coloca o inimigo no carrinho
		seguidor.add_child(inimigo_instancia)
		
		# Coloca o carrinho NA ROTA ATUAL do loop
		rota_atual.add_child(seguidor)
