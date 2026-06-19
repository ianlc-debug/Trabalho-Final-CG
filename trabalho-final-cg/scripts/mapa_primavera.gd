extends Node3D

@export var cena_inimigo: PackedScene = preload("res://Scenes/inimigo_basico.tscn") # Básico
@export var cena_inimigo_rapido: PackedScene = preload("res://Scenes/inimigo_rapido.tscn")
@export var cena_inimigo_forte: PackedScene = preload("res://Scenes/inimigo_forte.tscn")
@export var cena_inimigo_boss: PackedScene = preload("res://Scenes/inimigo_boss.tscn")

@onready var caminho_1 = $Path3D
@onready var caminho_2 = $Path3D2 
@onready var timer = $SpawnTimer

# Configurações de ondas
var configuracao_ondas = [
	{
		"inimigos": [{"tipo": "basico", "quantidade": 5}],
		"intervalo": 3.0,
		"recompensa": 100
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 6},
			{"tipo": "rapido", "quantidade": 3}
		],
		"intervalo": 2.5,
		"recompensa": 120
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 6},
			{"tipo": "rapido", "quantidade": 5},
			{"tipo": "forte", "quantidade": 2}
		],
		"intervalo": 2.0,
		"recompensa": 150
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 8},
			{"tipo": "rapido", "quantidade": 8},
			{"tipo": "forte", "quantidade": 4}
		],
		"intervalo": 1.6,
		"recompensa": 200
	},
	{
		"inimigos": [
			{"tipo": "boss", "quantidade": 1},
			{"tipo": "forte", "quantidade": 5},
			{"tipo": "rapido", "quantidade": 6}
		],
		"intervalo": 1.4,
		"recompensa": 350
	}
]

var onda_atual: int = 0
var em_espera: bool = true
var em_spawn: bool = false
var tempo_espera_total: float = 12.0
var tempo_espera_restante: float = 12.0
var fila_spawn: Array[PackedScene] = []
var inimigos_vivos: int = 0
var proximo_caminho_index: int = 0
var jogo_vencido: bool = false
var base_health: int = 20
var jogo_perdido: bool = false

@onready var ui_gerenciador = $UI

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)
	# Começar no estado de espera
	tempo_espera_restante = tempo_espera_total


func _process(delta: float) -> void:
	if jogo_vencido or jogo_perdido:
		return
		
	if em_espera:
		tempo_espera_restante -= delta
		if tempo_espera_restante <= 0:
			iniciar_proxima_onda()


func iniciar_proxima_onda() -> void:
	if jogo_perdido:
		return
		
	if onda_atual >= configuracao_ondas.size():
		jogo_vencido = true
		if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
			ui_gerenciador._mostrar_mensagem("Você venceu o jogo! Parabéns!")
		return
		
	em_espera = false
	em_spawn = true
	tempo_espera_restante = 0.0
	
	# Construir a fila de spawn para a onda atual
	var onda_info = configuracao_ondas[onda_atual]
	fila_spawn.clear()
	
	for grupo in onda_info["inimigos"]:
		var tipo = grupo["tipo"]
		var quant = grupo["quantidade"]
		var cena: PackedScene = cena_inimigo
		
		if tipo == "rapido":
			cena = cena_inimigo_rapido
		elif tipo == "forte":
			cena = cena_inimigo_forte
		elif tipo == "boss":
			cena = cena_inimigo_boss
			
		for i in range(quant):
			fila_spawn.append(cena)
			
	# Misturar um pouco os inimigos (exceto boss que deve vir no final)
	_misturar_fila_spawn()
	
	# Configurar timer de spawn
	timer.wait_time = onda_info["intervalo"]
	timer.start()
	
	# Spawnar o primeiro imediatamente
	_on_spawn_timer_timeout()
	if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
		ui_gerenciador._mostrar_mensagem("Onda " + str(onda_atual + 1) + " iniciada!")


func _misturar_fila_spawn() -> void:
	var n = fila_spawn.size()
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		if fila_spawn[i] == cena_inimigo_boss or fila_spawn[j] == cena_inimigo_boss:
			continue
		var temp = fila_spawn[i]
		fila_spawn[i] = fila_spawn[j]
		fila_spawn[j] = temp


func _on_spawn_timer_timeout() -> void:
	if fila_spawn.is_empty():
		timer.stop()
		em_spawn = false
		
		# --- NOVO: Força a checagem final assim que o spawn termina ---
		_atualizar_inimigos_vivos() 
		return
		
	var cena_a_spawnar = fila_spawn.pop_front()
	_spawnar_inimigo(cena_a_spawnar)


func _spawnar_inimigo(cena: PackedScene) -> void:
	if not cena:
		return
		
	# Alternar entre caminho 1 e 2
	var todos_os_caminhos = [caminho_1, caminho_2]
	var rota_atual = todos_os_caminhos[proximo_caminho_index]
	proximo_caminho_index = (proximo_caminho_index + 1) % todos_os_caminhos.size()
	
	var seguidor = PathFollow3D.new()
	seguidor.rotation_mode = PathFollow3D.ROTATION_Y
	seguidor.loop = false
	
	var inimigo_instancia = cena.instantiate()
	seguidor.add_child(inimigo_instancia)
	rota_atual.add_child(seguidor)
	
	# Incrementar inimigos vivos e conectar sinal para decrementar
	inimigos_vivos += 1
	inimigo_instancia.tree_exited.connect(_on_inimigo_saiu_da_arvore)


func _on_inimigo_saiu_da_arvore() -> void:
	call_deferred("_atualizar_inimigos_vivos")


func _atualizar_inimigos_vivos() -> void:
	# 1. Proteção contra o crash ao reiniciar
	if not is_inside_tree():
		return
		
	# 2. Contagem real dos inimigos ativos no jogo
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	inimigos_vivos = inimigos.size()
	
	# 3. Lógica de avanço de ondas
	if fila_spawn.is_empty() and inimigos_vivos == 0 and not em_espera and not jogo_vencido:
		# --- LINHA DE OURO ADICIONADA: Dá ouro ao jogador pelo fim da onda ---
		# Procura o nó da UI e chama o método "adicionar_ouro" que está no seu gerenciador_ui.gd
		var gerenciador_ui = get_node_or_null("UI") # Ajuste o caminho se a UI não estiver direto na raiz do mapa
		if gerenciador_ui and gerenciador_ui.has_method("adicionar_ouro"):
			gerenciador_ui.adicionar_ouro(100) # <- Mude 100 para o valor de bônus que você preferir!

		# Verifica se ainda existem mais ondas configuradas
		if onda_atual + 1 < configuracao_ondas.size():
			em_espera = true
			tempo_espera_restante = 10.0 
			onda_atual += 1
			print("Onda finalizada! Preparando onda: ", onda_atual + 1)
		else:
			# Se não há mais ondas, o jogador venceu o mapa
			jogo_vencido = true
			print("Parabéns! Você venceu o jogo!")


func _finalizar_onda() -> void:
	var recompensa = configuracao_ondas[onda_atual]["recompensa"]
	if ui_gerenciador and ui_gerenciador.has_method("adicionar_ouro"):
		ui_gerenciador.adicionar_ouro(recompensa)
		
	onda_atual += 1
	
	if onda_atual >= configuracao_ondas.size():
		jogo_vencido = true
		if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
			ui_gerenciador._mostrar_mensagem("Vitória! Você defendeu a base de todas as ondas!")
	else:
		em_espera = true
		tempo_espera_restante = tempo_espera_total
		if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
			ui_gerenciador._mostrar_mensagem("Onda " + str(onda_atual) + " concluída! + " + str(recompensa) + " Ouro.")


func registrar_dano_base() -> void:
	if jogo_perdido or jogo_vencido:
		return
		
	base_health -= 1
	if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
		ui_gerenciador._mostrar_mensagem("Base invadida! Vidas restantes: " + str(base_health))
		
	if base_health <= 0:
		_disparar_derrota()


func _disparar_derrota() -> void:
	jogo_perdido = true
	timer.stop()
	
	# Parar todos os inimigos ativos no mapa
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(inimigo):
			inimigo.set("velocidade", 0.0)
			
	if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
		ui_gerenciador._mostrar_mensagem("Fim de Jogo! Você foi derrotado.")
