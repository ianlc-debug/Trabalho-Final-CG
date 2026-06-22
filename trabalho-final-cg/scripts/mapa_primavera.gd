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
		"inimigos": [{"tipo": "basico", "quantidade": 10}],
		"intervalo": 1.5,
		"recompensa": 300
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 15},
			{"tipo": "rapido", "quantidade": 10}
		],
		"intervalo": 0.9,
		"recompensa": 300
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 20},
			{"tipo": "rapido", "quantidade": 15},
			{"tipo": "forte", "quantidade": 5}
		],
		"intervalo": 0.8,
		"recompensa": 300
	},
	{
		"inimigos": [
			{"tipo": "basico", "quantidade": 25},
			{"tipo": "rapido", "quantidade": 20},
			{"tipo": "forte", "quantidade": 10}
		],
		"intervalo": 0.7,
		"recompensa": 300
	},
	{
		"inimigos": [
			{"tipo": "boss", "quantidade": 1},
			{"tipo": "forte", "quantidade": 15},
			{"tipo": "rapido", "quantidade": 25}
		],
		"intervalo": 0.5,
		"recompensa": 300
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
var jogo_vencido: bool = false:
	set(valor):
		jogo_vencido = valor
		if jogo_vencido:
			_verificar_salvamento_inverno()
var base_health: int = 10
var jogo_perdido: bool = false

@onready var ui_gerenciador = $UI

func _ready() -> void:
	timer.timeout.connect(_on_spawn_timer_timeout)
	tempo_espera_restante = tempo_espera_total
	
	# Correção da barra inferior (que já deu certo)
	call_deferred("_corrigir_barra_botoes_dinamicamente")
	
	# --- LINHA ADICIONADA: Organiza o HUD superior e configura o sistema de pausa ---
	call_deferred("_reorganizar_hud_superior_e_pausa")


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
			gerenciador_ui.adicionar_ouro(300) # <- Mude 100 para o valor de bônus que você preferir!

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


func registrar_dano_base(eh_chefe: bool = false) -> void:
	if jogo_perdido or jogo_vencido:
		return
		
	# Se a função for avisada que é o chefe, a vida vai a zero na hora
	if eh_chefe == true:
		base_health = 0
		if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
			ui_gerenciador._mostrar_mensagem("O CHEFE DESTRUIU O CASTELO!")
	else:
		# Se não for o chefe, tira só 1 de vida (funcionamento normal)
		base_health -= 1
		if ui_gerenciador and ui_gerenciador.has_method("_mostrar_mensagem"):
			ui_gerenciador._mostrar_mensagem("Base invadida! Vidas restantes: " + str(base_health))
		
	# Se a vida zerou (seja por dano normal ou pelo chefe), dispara a derrota
	if base_health <= 0:
		_disparar_derrota()


func _disparar_derrota() -> void:
	jogo_perdido = true
	timer.stop()
	
	# Parar todos os inimigos ativos no mapa
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(inimigo):
			inimigo.set("velocidade", 0.0)
	_exibir_tela_game_over()


func _verificar_salvamento_inverno() -> void:
	var map_name = name.to_lower()
	var map_path = scene_file_path.to_lower()
	if "inverno" in map_name or "inverno" in map_path or "gelo" in map_name or "gelo" in map_path:
		Salvamento.salvar_inverno_concluido(true)
		
func _corrigir_barra_botoes_dinamicamente() -> void:
	if not is_instance_valid(ui_gerenciador):
		return
		
	for filho in ui_gerenciador.get_children():
		if filho is Control:
			var nome = filho.name.to_lower()
			
			# Identifica o painel de compras
			if "painel" in nome or "barra" in nome or "botoes" in nome or "container" in nome or filho is PanelContainer or filho is Panel:
				
				# 1. Encontra o container horizontal interno (onde os botões realmente estão)
				var container_interno: Control = null
				for sub_filho in filho.get_children():
					if sub_filho is HBoxContainer or sub_filho is GridContainer:
						container_interno = sub_filho
						break
				
				if container_interno:
					# Força o container de botões a se espremer ao mínimo possível
					container_interno.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					
					# 2. Faz o painel de fundo copiar o tamanho exato mínimo dos botões (mais uma bordinha de respiro)
					var tamanho_botoes = container_interno.get_combined_minimum_size()
					filho.custom_minimum_size = Vector2(tamanho_botoes.x + 30, tamanho_botoes.y + 20)
				
				# Reseta e força a atualização do tamanho do painel
				filho.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				filho.reset_size()
				
				# Pega o tamanho atual da janela do jogo
				var tamanho_tela = get_viewport().get_visible_rect().size
				
				# Posição X 
				var centro_x = (tamanho_tela.x / 2.0) - (filho.size.x / 2.0)
				
				# Posição Y
				var chao_y = tamanho_tela.y - filho.size.y - 20.0
				
				# Aplica a posição calculada diretamente no objeto
				filho.global_position = Vector2(centro_x, chao_y)
				
# Variável para controlar a existência do menu de pausa na tela
var _menu_pausa_instancia: PanelContainer = null
var _botao_pausa_ref: Button = null 

func _reorganizar_hud_superior_e_pausa() -> void:
	var ui_alvo = null
	if "ui_gerenciador" in self and is_instance_valid(get("ui_gerenciador")):
		ui_alvo = get("ui_gerenciador")
	elif has_node("UI"):
		ui_alvo = get_node("UI")
	elif has_node("GerenciadorUI"):
		ui_alvo = get_node("GerenciadorUI")
		
	if not is_instance_valid(ui_alvo):
		return
		
	await get_tree().create_timer(0.05).timeout
	
	var botao_pausa: Button = null
	var botao_iniciar: Button = null
	var labels_onda: Array[Label] = []
	var painel_original: Control = null
	
	var nos_para_checar = [ui_alvo]
	while nos_para_checar.size() > 0:
		var atual = nos_para_checar.pop_front()
		if atual is Button:
			var txt = atual.text.to_lower()
			var nom = atual.name.to_lower()
			if "paus" in txt or "paus" in nom or "cont" in txt or "cont" in nom:
				botao_pausa = atual
			elif "onda" in txt or "onda" in nom or "ini" in txt or "ini" in nom:
				botao_iniciar = atual
		elif atual is Label:
			var txt = atual.text.to_lower()
			var nom = atual.name.to_lower()
			if "onda" in txt or "onda" in nom or "próx" in txt or "prox" in txt or "tempo" in nom or "resta" in txt:
				labels_onda.append(atual)
		nos_para_checar.append_array(atual.get_children())
		
	if not botao_pausa:
		return

	# SALVA O BOTÃO NA NOSSA VARIÁVEL GLOBAL
	_botao_pausa_ref = botao_pausa

	var pai = botao_pausa.get_parent()
	while pai and pai != ui_alvo:
		if pai is PanelContainer or pai is Panel or "onda" in pai.name.to_lower():
			painel_original = pai
			break
		pai = pai.get_parent()

	if painel_original:
		for filho in painel_original.get_children():
			if filho is Label and not filho in labels_onda:
				labels_onda.append(filho)

	if botao_pausa and botao_pausa.get_parent():
		botao_pausa.get_parent().remove_child(botao_pausa)
	if botao_iniciar and botao_iniciar.get_parent():
		botao_iniciar.get_parent().remove_child(botao_iniciar)
	for lbl in labels_onda:
		if lbl.get_parent():
			lbl.get_parent().remove_child(lbl)
			
	if painel_original:
		painel_original.visible = false
		painel_original.process_mode = Node.PROCESS_MODE_DISABLED

	var tamanho_tela = get_viewport().get_visible_rect().size

	var novo_painel_centro = PanelContainer.new()
	novo_painel_centro.name = "NovoPainelOndasCentro"
	
	var estilo_centro = StyleBoxFlat.new()
	estilo_centro.bg_color = Color(0.12, 0.12, 0.14, 0.85)
	estilo_centro.set_corner_radius_all(8)
	estilo_centro.set_content_margin_all(10)
	novo_painel_centro.add_theme_stylebox_override("panel", estilo_centro)
	
	var hbox_centro = HBoxContainer.new()
	hbox_centro.add_theme_constant_override("separation", 20)
	novo_painel_centro.add_child(hbox_centro)
	
	var vbox_labels = VBoxContainer.new()
	vbox_labels.add_theme_constant_override("separation", 2)
	hbox_centro.add_child(vbox_labels)
	
	for lbl in labels_onda:
		vbox_labels.add_child(lbl)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
	if botao_iniciar:
		hbox_centro.add_child(botao_iniciar)
		botao_iniciar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		botao_iniciar.custom_minimum_size = Vector2(105, 35)

	ui_alvo.add_child(novo_painel_centro)
	novo_painel_centro.reset_size()
	
	var centro_x = (tamanho_tela.x / 2.0) - (novo_painel_centro.size.x / 2.0)
	novo_painel_centro.global_position = Vector2(centro_x, 15)

	var novo_painel_pausa = PanelContainer.new()
	novo_painel_pausa.name = "NovoPainelPausaDireito"
	novo_painel_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var estilo_pausa = StyleBoxFlat.new()
	estilo_pausa.bg_color = Color(0.12, 0.12, 0.14, 0.85)
	estilo_pausa.set_corner_radius_all(8)
	estilo_pausa.set_content_margin_all(8)
	novo_painel_pausa.add_theme_stylebox_override("panel", estilo_pausa)
	
	botao_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	botao_pausa.custom_minimum_size = Vector2(80, 35)
	novo_painel_pausa.add_child(botao_pausa)
	
	ui_alvo.add_child(novo_painel_pausa)
	novo_painel_pausa.reset_size()
	
	var direita_x = tamanho_tela.x - novo_painel_pausa.size.x - 20
	novo_painel_pausa.global_position = Vector2(direita_x, 15)

	for conexao in botao_pausa.pressed.get_connections():
		botao_pausa.pressed.disconnect(conexao.callable)
	botao_pausa.pressed.connect(_on_botao_pausa_clicado)

# --- SISTEMA DO MENU DE PAUSA CENTRALIZADO ---

func _on_botao_pausa_clicado() -> void:
	if is_instance_valid(_menu_pausa_instancia):
		_alternar_pausa(false)
	else:
		_alternar_pausa(true)

func _alternar_pausa(pausar: bool) -> void:
	get_tree().paused = pausar
	
	# Sincroniza o texto E as cores do botão superior
	if is_instance_valid(_botao_pausa_ref):
		if pausar:
			_botao_pausa_ref.text = "Continuar"
			# Aplica a cor avermelhada no texto (ajuste o RGB se quiser outro tom)
			_botao_pausa_ref.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) 
		else:
			_botao_pausa_ref.text = "Pausar"
			# Remove a alteração de cor para voltar ao branco padrão do tema
			_botao_pausa_ref.remove_theme_color_override("font_color")
			
	if pausar:
		_criar_menu_pausa()
	else:
		if is_instance_valid(_menu_pausa_instancia):
			_menu_pausa_instancia.queue_free()

func _criar_menu_pausa() -> void:
	_menu_pausa_instancia = PanelContainer.new()
	_menu_pausa_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_pausa_instancia.name = "MenuPausaCentralizado"
	
	var estilo_painel = StyleBoxFlat.new()
	estilo_painel.bg_color = Color(0.12, 0.12, 0.14, 0.95)
	estilo_painel.set_corner_radius_all(12)
	estilo_painel.set_content_margin_all(25)
	estilo_painel.border_width_left = 2
	estilo_painel.border_width_top = 2
	estilo_painel.border_width_right = 2
	estilo_painel.border_width_bottom = 2
	estilo_painel.border_color = Color(0.3, 0.3, 0.35)
	_menu_pausa_instancia.add_theme_stylebox_override("panel", estilo_painel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_menu_pausa_instancia.add_child(vbox)
	
	var texto_titulo = Label.new()
	texto_titulo.text = "JOGO PAUSADO"
	texto_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_titulo.add_theme_font_size_override("font_size", 22)
	texto_titulo.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(texto_titulo)
	
	var separador = HSeparator.new()
	vbox.add_child(separador)
	
	var btn_continuar = Button.new()
	btn_continuar.text = "Continuar Jogo"
	btn_continuar.custom_minimum_size = Vector2(200, 38)
	btn_continuar.pressed.connect(func(): _alternar_pausa(false))
	vbox.add_child(btn_continuar)
	
	var btn_reiniciar = Button.new()
	btn_reiniciar.text = "Reiniciar Fase"
	btn_reiniciar.custom_minimum_size = Vector2(200, 38)
	btn_reiniciar.pressed.connect(_on_reiniciar_fase_pressionado)
	vbox.add_child(btn_reiniciar)
	
	var btn_menu_principal = Button.new()
	btn_menu_principal.text = "Menu Principal"
	btn_menu_principal.custom_minimum_size = Vector2(200, 38)
	btn_menu_principal.pressed.connect(_on_voltar_menu_pressionado)
	vbox.add_child(btn_menu_principal)
	
	var ui_alvo = null
	if "ui_gerenciador" in self and is_instance_valid(get("ui_gerenciador")):
		ui_alvo = get("ui_gerenciador")
	elif has_node("UI"):
		ui_alvo = get_node("UI")
		
	if ui_alvo:
		ui_alvo.add_child(_menu_pausa_instancia)
		_menu_pausa_instancia.reset_size()
		var tamanho_tela = get_viewport().get_visible_rect().size
		_menu_pausa_instancia.global_position = Vector2(
			(tamanho_tela.x / 2.0) - (_menu_pausa_instancia.size.x / 2.0),
			(tamanho_tela.y / 2.0) - (_menu_pausa_instancia.size.y / 2.0)
		)

func _on_reiniciar_fase_pressionado() -> void:
	_alternar_pausa(false)
	get_tree().reload_current_scene()

func _on_voltar_menu_pressionado() -> void:
	_alternar_pausa(false)
	get_tree().change_scene_to_file("res://Scenes/menu_principal.tscn")

# Variável para guardar o nosso novo painel de derrota
var _menu_game_over_instancia: PanelContainer = null

func _exibir_tela_game_over() -> void:
	# Pausa o jogo instantaneamente
	get_tree().paused = true
	
	var ui_alvo = null
	if "ui_gerenciador" in self and is_instance_valid(get("ui_gerenciador")):
		ui_alvo = get("ui_gerenciador")
	elif has_node("UI"):
		ui_alvo = get_node("UI")
	elif has_node("GerenciadorUI"):
		ui_alvo = get_node("GerenciadorUI")
	else:
		ui_alvo = self
		
	# 1. VARREDURA PARA ESCONDER O MENU VELHO
	# Isso garante que a janelinha feia lá de baixo desapareça da tela
	if is_instance_valid(ui_alvo):
		var nos = [ui_alvo]
		while nos.size() > 0:
			var atual = nos.pop_front()
			if atual is Control and atual.visible:
				for filho in atual.get_children():
					if filho is Label and ("fim de jogo" in filho.text.to_lower() or "destruída" in filho.text.to_lower()):
						# Encontramos o texto do menu velho, vamos esconder o painel inteiro
						var pai = filho.get_parent()
						while pai and pai != ui_alvo:
							if pai is PanelContainer or pai is Panel or pai is ColorRect:
								pai.visible = false
								break
							pai = pai.get_parent()
			nos.append_array(atual.get_children())

	# 2. CRIAÇÃO DO NOVO MENU DE GAME OVER CENTRALIZADO
	_menu_game_over_instancia = PanelContainer.new()
	_menu_game_over_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_game_over_instancia.name = "MenuGameOverCentralizado"
	
	# Estilo visual de derrota (Fundo escuro com bordas vermelhas)
	var estilo_painel = StyleBoxFlat.new()
	estilo_painel.bg_color = Color(0.15, 0.05, 0.05, 0.95)
	estilo_painel.set_corner_radius_all(12)
	estilo_painel.set_content_margin_all(30)
	estilo_painel.border_width_left = 3
	estilo_painel.border_width_top = 3
	estilo_painel.border_width_right = 3
	estilo_painel.border_width_bottom = 3
	estilo_painel.border_color = Color(0.8, 0.2, 0.2) # Vermelho alerta
	_menu_game_over_instancia.add_theme_stylebox_override("panel", estilo_painel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_menu_game_over_instancia.add_child(vbox)
	
	# Título principal
	var texto_titulo = Label.new()
	texto_titulo.text = "FIM DE JOGO"
	texto_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_titulo.add_theme_font_size_override("font_size", 28)
	texto_titulo.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(texto_titulo)
	
	# Subtítulo
	var texto_sub = Label.new()
	texto_sub.text = "Sua base foi destruída!"
	texto_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(texto_sub)
	
	var separador = HSeparator.new()
	vbox.add_child(separador)
	
	# Botão 1: Jogar Novamente (Reaproveita a função do Pause!)
	var btn_jogar_novamente = Button.new()
	btn_jogar_novamente.text = "Jogar Novamente"
	btn_jogar_novamente.custom_minimum_size = Vector2(220, 42)
	btn_jogar_novamente.pressed.connect(_on_reiniciar_fase_pressionado)
	vbox.add_child(btn_jogar_novamente)
	
	# Botão 2: Menu Principal (Reaproveita a função do Pause!)
	var btn_menu_principal = Button.new()
	btn_menu_principal.text = "Menu Principal"
	btn_menu_principal.custom_minimum_size = Vector2(220, 42)
	btn_menu_principal.pressed.connect(_on_voltar_menu_pressionado)
	vbox.add_child(btn_menu_principal)
	
	# Adiciona à tela e calcula o centro exato
	if ui_alvo:
		ui_alvo.add_child(_menu_game_over_instancia)
		_menu_game_over_instancia.reset_size()
		var tamanho_tela = get_viewport().get_visible_rect().size
		_menu_game_over_instancia.global_position = Vector2(
			(tamanho_tela.x / 2.0) - (_menu_game_over_instancia.size.x / 2.0),
			(tamanho_tela.y / 2.0) - (_menu_game_over_instancia.size.y / 2.0)
		)

# Variável para guardar o nosso novo painel de vitória 
var _camada_vitoria_instancia: CanvasLayer = null

func _exibir_tela_vitoria() -> void:
	if is_instance_valid(_camada_vitoria_instancia):
		return 

	# Pausa o jogo instantaneamente
	get_tree().paused = true

	var ui_alvo = null
	if has_node("UI"): ui_alvo = get_node("UI")
	elif has_node("GerenciadorUI"): ui_alvo = get_node("GerenciadorUI")
	
	if is_instance_valid(ui_alvo):
		var nos = [ui_alvo]
		while nos.size() > 0:
			var atual = nos.pop_front()
			if atual is Control and atual.visible:
				for filho in atual.get_children():
					if filho is Label and ("vitória" in filho.text.to_lower() or "vitoria" in filho.text.to_lower()):
						var pai = filho.get_parent()
						while pai and pai != ui_alvo:
							if pai is PanelContainer or pai is Panel or pai is ColorRect:
								pai.visible = false
								pai.mouse_filter = Control.MOUSE_FILTER_IGNORE 
								break
							pai = pai.get_parent()
			nos.append_array(atual.get_children())

	_camada_vitoria_instancia = CanvasLayer.new()
	_camada_vitoria_instancia.layer = 120 
	_camada_vitoria_instancia.process_mode = Node.PROCESS_MODE_ALWAYS 
	get_tree().current_scene.add_child(_camada_vitoria_instancia)

	# Fundo escuro
	var fundo_escuro = ColorRect.new()
	fundo_escuro.name = "VitoriaFundoOverlay"
	fundo_escuro.anchor_right = 1.0
	fundo_escuro.anchor_bottom = 1.0
	fundo_escuro.color = Color(0, 0, 0, 0.6) 
	fundo_escuro.mouse_filter = Control.MOUSE_FILTER_STOP 
	_camada_vitoria_instancia.add_child(fundo_escuro)

	var centro = CenterContainer.new()
	centro.anchor_right = 1.0
	centro.anchor_bottom = 1.0
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_escuro.add_child(centro)

	# 4. CRIAÇÃO DO PAINEL VERDE CENTRALIZADO
	var panel_vitoria = PanelContainer.new()
	panel_vitoria.mouse_filter = Control.MOUSE_FILTER_STOP 
	centro.add_child(panel_vitoria) # Adicionamos no centro, e não no fundo!
	
	# Estilo visual de vitória 
	var estilo_painel = StyleBoxFlat.new()
	estilo_painel.bg_color = Color(0.05, 0.15, 0.05, 0.98)
	estilo_painel.set_corner_radius_all(12)
	estilo_painel.set_content_margin_all(35) 
	estilo_painel.border_width_left = 3
	estilo_painel.border_width_top = 3
	estilo_painel.border_width_right = 3
	estilo_painel.border_width_bottom = 3
	estilo_painel.border_color = Color(0.2, 0.8, 0.2)
	estilo_painel.shadow_color = Color(0, 0, 0, 0.6)
	estilo_painel.shadow_size = 10
	
	panel_vitoria.add_theme_stylebox_override("panel", estilo_painel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_vitoria.add_child(vbox)
	
	# Título principal
	var texto_titulo = Label.new()
	texto_titulo.text = "VITÓRIA!"
	texto_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_titulo.add_theme_font_size_override("font_size", 30)
	texto_titulo.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	texto_titulo.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(texto_titulo)
	
	# Subtítulo
	var texto_sub = Label.new()
	texto_sub.text = "O castelo está a salvo!"
	texto_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_sub.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(texto_sub)
	
	var separador = HSeparator.new()
	vbox.add_child(separador)
	
	var btn_jogar_novamente = Button.new()
	btn_jogar_novamente.text = "Jogar Novamente"
	btn_jogar_novamente.custom_minimum_size = Vector2(240, 45)
	btn_jogar_novamente.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	btn_jogar_novamente.pressed.connect(func():
		get_tree().paused = false
		if is_instance_valid(_camada_vitoria_instancia):
			_camada_vitoria_instancia.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn_jogar_novamente)
	
	var btn_menu_principal = Button.new()
	btn_menu_principal.text = "Menu Principal"
	btn_menu_principal.custom_minimum_size = Vector2(240, 45)
	btn_menu_principal.mouse_filter = Control.MOUSE_FILTER_STOP
	
	btn_menu_principal.pressed.connect(func():
		get_tree().paused = false
		if is_instance_valid(_camada_vitoria_instancia):
			_camada_vitoria_instancia.queue_free()
		
		if self.has_method("_on_voltar_menu_pressionado"):
			self.call("_on_voltar_menu_pressionado")
		elif self.has_method("_on_botao_menu_principal_pressed"):
			self.call("_on_botao_menu_principal_pressed")
		else:
			if ResourceLoader.exists("res://menu.tscn"):
				get_tree().change_scene_to_file("res://menu.tscn")
			elif ResourceLoader.exists("res://MenuPrincipal.tscn"):
				get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
	)
	vbox.add_child(btn_menu_principal)
