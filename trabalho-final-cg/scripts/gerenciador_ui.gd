extends CanvasLayer

# --- Cenas das construções ---
@export var cena_canhao: PackedScene
@export var cena_balista: PackedScene
@export var cena_catapulta: PackedScene
@export var cena_mina: PackedScene

# --- Preload da Nova Torre de Gelo ---
var cena_gelo: PackedScene = preload("res://Scenes/cena_gelo.tscn")

# --- Sistema de economia e validação ---
@export var ouro_inicial: int = 300
@export var custo_canhao: int = 100
@export var custo_balista: int = 75
@export var custo_catapulta: int = 150
@export var custo_mina: int = 125
var custo_gelo: int = 125

@onready var mapa_3d: Node3D = get_parent()
var camera: Camera3D = null

@onready var botao_canhao: Button = $HBoxContainer/BotaoCanhao
@onready var botao_balista: Button = $HBoxContainer/BotaoBalista
@onready var botao_catapulta: Button = $HBoxContainer/BotaoCatapulta
@onready var botao_mina: Button = $HBoxContainer/BotaoMina
var botao_gelo: Button = null
var botao_pausa: Button = null
var hbox_loja: HBoxContainer = null

var ouro: int
var arrastando: bool = false
var torre_fantasma: Node3D = null
var custo_construcao_atual: int = 0
var nome_construcao_atual: String = ""

# --- Controle de local válido ---
var local_valido: bool = false

var label_ouro: Label
var label_mensagem: Label
var label_vidas: Label

# --- Interface de Onda, Melhoria e Derrota ---
var construcao_selecionada: Node3D = null
var painel_melhoria: PanelContainer = null
var label_titulo_melhoria: Label = null
var label_status_melhoria: Label = null
var botao_melhorar: Button = null
var botao_vender: Button = null
var botao_upgrade_gelo: Button = null

var painel_onda: PanelContainer = null
var label_onda_status: Label = null
var botao_onda_skip: Button = null

var painel_derrota: PanelContainer = null

var cooldowns_maximos = {
	"Canhão": 3.0,
	"Balista": 2.0,
	"Catapulta": 5.0,
	"Mina": 4.0
}
var cooldowns_restantes = {
	"Canhão": 0.0,
	"Balista": 0.0,
	"Catapulta": 0.0,
	"Mina": 0.0
}
var barras_cooldown = {} # Key: Button name, Value: TextureProgressBar

var mouse_pressed_on_button: bool = false
var mouse_start_pos: Vector2
var drag_mode: bool = false

var tempo_limite_posicionamento: float = 12.0
var tempo_limite_restante: float = 0.0

var tempo_guia_spawn: float = 0.0
var lista_guias: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ouro = ouro_inicial
	hbox_loja = $HBoxContainer
	
	# Encontrar a câmera do mapa ativo
	var cam = get_node_or_null("../GridMapPrimavera/Camera3D2")
	if not cam:
		cam = get_node_or_null("../GridMapInverno/Camera3D2")
	if cam:
		camera = cam
		# Ajustar a posição da câmera ligeiramente para mover o mapa para cima na tela
		camera.position.z += 1.5
		camera.position.y += 0.5
		
	# Ajustar cor de fundo (Clear Color) dependendo do mapa
	if is_instance_valid(mapa_3d):
		var map_name = mapa_3d.name.to_lower()
		var map_path = mapa_3d.scene_file_path.to_lower()
		if "inverno" in map_name or "inverno" in map_path or "gelo" in map_name or "gelo" in map_path:
			RenderingServer.set_default_clear_color(Color(0.88, 0.92, 0.95)) # Branco/neve azulado
		else:
			RenderingServer.set_default_clear_color(Color(0.35, 0.62, 0.42)) # Verde suave
			
	_criar_fundo_loja()
	_criar_labels()
	_adicionar_botao_gelo()
	_adicionar_labels_custo()
	_atualizar_label_ouro()
	_mostrar_mensagem("Escolha uma construção.")
	
	# Conexões de botões para click-to-place e drag-and-drop
	botao_canhao.button_down.connect(_on_botao_down.bind(cena_canhao, custo_canhao, "Canhão"))
	botao_balista.button_down.connect(_on_botao_down.bind(cena_balista, custo_balista, "Balista"))
	botao_catapulta.button_down.connect(_on_botao_down.bind(cena_catapulta, custo_catapulta, "Catapulta"))
	botao_mina.button_down.connect(_on_botao_down.bind(cena_mina, custo_mina, "Mina"))


func _on_botao_down(cena: PackedScene, custo: int, nome: String) -> void:
	if get_tree().paused:
		_mostrar_mensagem("Não é possível construir com o jogo pausado!")
		return
		
	# Verificar cooldown individual
	if cooldowns_restantes.get(nome, 0.0) > 0.0:
		_mostrar_mensagem("Aguarde a recarga de " + nome + "!")
		return
		
	_iniciar_colocacao(cena, custo, nome)
	if arrastando:
		mouse_pressed_on_button = true
		mouse_start_pos = get_viewport().get_mouse_position()
		drag_mode = false


func _criar_labels() -> void:
	# Label de Ouro
	label_ouro = Label.new()
	add_child(label_ouro)
	label_ouro.position = Vector2(20, 20)
	label_ouro.add_theme_font_size_override("font_size", 20)
	label_ouro.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	
	# Label de Mensagem
	label_mensagem = Label.new()
	add_child(label_mensagem)
	label_mensagem.position = Vector2(20, 50)
	label_mensagem.add_theme_font_size_override("font_size", 14)
	
	# Label de Vidas (Base Health)
	label_vidas = Label.new()
	add_child(label_vidas)
	label_vidas.position = Vector2(20, 80)
	label_vidas.add_theme_font_size_override("font_size", 18)
	label_vidas.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	_criar_ui_onda()
	_criar_ui_melhorias()
	_criar_ui_derrota()


# --- ADICIONADO: Envelopa a loja num painel com fundo colorido ---
func _criar_fundo_loja() -> void:
	var hbox = hbox_loja
	if not hbox: return
	
	# Criar PanelContainer para envelopar a loja
	var painel_loja = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85) # Cinza escuro com ciano sutil, translúcido
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	painel_loja.add_theme_stylebox_override("panel", style)
	
	# Ajustar o espaçamento interno do HBoxContainer
	hbox.add_theme_constant_override("separation", 10)
	
	# Mover HBoxContainer para dentro do painel
	add_child(painel_loja)
	remove_child(hbox)
	painel_loja.add_child(hbox)
	
	# Configurar âncoras e posição no centro inferior da tela
	painel_loja.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 12)
	painel_loja.position.y -= 10


# --- ADICIONADO: Adiciona o botão de Gelo dinamicamente ao menu ---
func _adicionar_botao_gelo() -> void:
	return # A torre de gelo agora é uma melhoria (upgrade), não se compra na loja.


# --- MODIFICADO: Exibe o custo de cada torre acima de seu ícone ---
func _adicionar_labels_custo() -> void:
	var botoes_e_custos = [
		{"botao": botao_canhao, "custo": custo_canhao},
		{"botao": botao_balista, "custo": custo_balista},
		{"botao": botao_catapulta, "custo": custo_catapulta},
		{"botao": botao_mina, "custo": custo_mina},
		{"botao": botao_gelo, "custo": custo_gelo}
	]
	
	var hbox = hbox_loja
	if not hbox: return
	
	for item in botoes_e_custos:
		var btn = item["botao"]
		var cost = item["custo"]
		if not btn: continue
		
		var index = btn.get_index()
		hbox.remove_child(btn)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)
		hbox.move_child(vbox, index)
		
		var lbl = Label.new()
		vbox.add_child(lbl)
		lbl.text = str(cost) + " G"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		
		# Padronizar o tamanho dos botões e ajustar o ícone
		btn.custom_minimum_size = Vector2(64, 64)
		btn.expand_icon = true
		vbox.add_child(btn)
		
		# Criar overlay de cooldown estilo PVZ (sweep radial horário / clockwise)
		var progress_overlay = TextureProgressBar.new()
		progress_overlay.name = "CooldownOverlay"
		progress_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		progress_overlay.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		progress_overlay.nine_patch_stretch = true
		progress_overlay.custom_minimum_size = Vector2(64, 64)
		progress_overlay.size = Vector2(64, 64)
		
		# Criar textura branca 64x64 em tempo de execução
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var tex = ImageTexture.create_from_image(img)
		progress_overlay.texture_progress = tex
		
		# Estilo escuro transparente
		progress_overlay.tint_progress = Color(0.0, 0.0, 0.0, 0.6)
		progress_overlay.min_value = 0.0
		progress_overlay.max_value = 100.0
		progress_overlay.value = 0.0 # Começa invisível
		
		btn.add_child(progress_overlay)
		barras_cooldown[btn.name] = progress_overlay


func _criar_ui_onda() -> void:
	painel_onda = PanelContainer.new()
	add_child(painel_onda)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	painel_onda.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	painel_onda.add_child(hbox)
	hbox.add_theme_constant_override("separation", 10)
	
	label_onda_status = Label.new()
	hbox.add_child(label_onda_status)
	label_onda_status.text = "Onda: --"
	label_onda_status.add_theme_font_size_override("font_size", 14)
	
	botao_onda_skip = Button.new()
	hbox.add_child(botao_onda_skip)
	botao_onda_skip.text = "Iniciar Onda"
	botao_onda_skip.add_theme_font_size_override("font_size", 12)
	botao_onda_skip.button_down.connect(_on_botao_skip_wave_pressed)
	
	# Botão de Pausa
	botao_pausa = Button.new()
	hbox.add_child(botao_pausa)
	botao_pausa.text = "Pausar"
	botao_pausa.add_theme_font_size_override("font_size", 12)
	botao_pausa.button_down.connect(_on_botao_pausa_pressed)
	
	# Recalcular tamanho e manter ancorado corretamente
	painel_onda.reset_size()
	painel_onda.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


func _criar_ui_melhorias() -> void:
	painel_melhoria = PanelContainer.new()
	add_child(painel_melhoria)
	painel_melhoria.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 5
	painel_melhoria.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	painel_melhoria.add_child(vbox)
	vbox.add_theme_constant_override("separation", 8)
	
	label_titulo_melhoria = Label.new()
	vbox.add_child(label_titulo_melhoria)
	label_titulo_melhoria.text = "Torre"
	label_titulo_melhoria.add_theme_font_size_override("font_size", 15)
	label_titulo_melhoria.add_theme_color_override("font_color", Color(0.3, 0.75, 1.0))
	
	label_status_melhoria = Label.new()
	vbox.add_child(label_status_melhoria)
	label_status_melhoria.text = "Stats"
	label_status_melhoria.add_theme_font_size_override("font_size", 12)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	hbox.add_theme_constant_override("separation", 10)
	
	botao_melhorar = Button.new()
	hbox.add_child(botao_melhorar)
	botao_melhorar.text = "Upgrade"
	botao_melhorar.add_theme_font_size_override("font_size", 12)
	botao_melhorar.button_down.connect(_on_botao_melhorar_pressed)
	
	botao_vender = Button.new()
	hbox.add_child(botao_vender)
	botao_vender.text = "Vender"
	botao_vender.add_theme_font_size_override("font_size", 12)
	botao_vender.button_down.connect(_on_botao_vender_pressed)
	
	# Botão de Upgrade para Torre de Gelo
	botao_upgrade_gelo = Button.new()
	vbox.add_child(botao_upgrade_gelo)
	botao_upgrade_gelo.text = "Evoluir para Gelo (125 Ouro)"
	botao_upgrade_gelo.add_theme_font_size_override("font_size", 12)
	botao_upgrade_gelo.modulate = Color(0.4, 0.8, 1.0)
	botao_upgrade_gelo.visible = false
	botao_upgrade_gelo.button_down.connect(_on_botao_upgrade_gelo_pressed)
	
	# Recalcular tamanho e manter ancorado no canto inferior direito
	painel_melhoria.reset_size()
	painel_melhoria.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


# --- ADICIONADO: UI de Derrota (Game Over) ---
func _criar_ui_derrota() -> void:
	painel_derrota = PanelContainer.new()
	add_child(painel_derrota)
	painel_derrota.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.05, 0.05, 0.95) # Vermelho escuro
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 10
	painel_derrota.add_theme_stylebox_override("panel", style)
	
	painel_derrota.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var vbox = VBoxContainer.new()
	painel_derrota.add_child(vbox)
	vbox.add_theme_constant_override("separation", 15)
	
	var lbl_title = Label.new()
	vbox.add_child(lbl_title)
	lbl_title.text = "FIM DE JOGO"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	
	var lbl_sub = Label.new()
	vbox.add_child(lbl_sub)
	lbl_sub.text = "Sua base foi destruída!"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 14)
	
	var btn_restart = Button.new()
	vbox.add_child(btn_restart)
	btn_restart.text = "Jogar Novamente"
	btn_restart.add_theme_font_size_override("font_size", 14)
	btn_restart.button_down.connect(_on_botao_recomecar_pressed)


func _on_botao_recomecar_pressed() -> void:
	get_tree().reload_current_scene()


func _iniciar_colocacao(cena_escolhida: PackedScene, custo: int, nome_construcao: String) -> void:
	if get_tree().paused:
		_mostrar_mensagem("Não é possível construir com o jogo pausado!")
		return
		
	if arrastando:
		_cancelar_colocacao()
		
	if not cena_escolhida:
		_mostrar_mensagem("ERRO: a cena de " + nome_construcao + " não foi definida no Inspector.")
		return
	if ouro < custo:
		_mostrar_mensagem("Ouro insuficiente para comprar " + nome_construcao + ". Custo: " + str(custo))
		return
	
	_deselecionar_construcao()
	
	arrastando = true
	custo_construcao_atual = custo
	nome_construcao_atual = nome_construcao
	local_valido = false
	tempo_limite_restante = tempo_limite_posicionamento
	
	torre_fantasma = cena_escolhida.instantiate()
	mapa_3d.add_child(torre_fantasma)
	
	if torre_fantasma.has_node("Alcance"):
		torre_fantasma.get_node("Alcance").visible = true


func _confirmar_colocacao() -> void:
	if not arrastando or not torre_fantasma: return
	
	if not local_valido:
		_mostrar_mensagem("Não é possível construir neste local.")
		return
		
	if ouro < custo_construcao_atual:
		_mostrar_mensagem("Ouro insuficiente!")
		_cancelar_colocacao()
		return
		
	_gastar_ouro(custo_construcao_atual)
	
	var pos_construcao = torre_fantasma.global_position
	
	if torre_fantasma.has_node("Alcance"):
		torre_fantasma.get_node("Alcance").visible = false
		
	if torre_fantasma.has_method("configurar_gerenciador_ouro"):
		torre_fantasma.configurar_gerenciador_ouro(self)
		
	if torre_fantasma.has_method("ativar_torre"):
		torre_fantasma.ativar_torre()
		
	_remover_material_recursivo(torre_fantasma)
	
	_mostrar_mensagem(nome_construcao_atual + " colocado! Ouro restante: " + str(ouro))
	torre_fantasma = null
	arrastando = false
	_limpar_arraste()
	
	# Iniciar cooldown individual
	var tempo_cooldown = cooldowns_maximos.get(nome_construcao_atual, 2.0)
	cooldowns_restantes[nome_construcao_atual] = tempo_cooldown
	
	# Efeito visual de poeira/faíscas douradas ao construir
	_spawnar_particulas_construcao(pos_construcao, Color(1.0, 0.85, 0.3))


func _cancelar_colocacao() -> void:
	if not arrastando: return
	arrastando = false
	if is_instance_valid(torre_fantasma):
		torre_fantasma.queue_free()
	torre_fantasma = null
	_limpar_arraste()
	_mostrar_mensagem("Construção cancelada.")


func _limpar_arraste() -> void:
	custo_construcao_atual = 0
	nome_construcao_atual = ""


func _process(delta: float) -> void:
	# Atualizar HUD de Vidas
	if is_instance_valid(mapa_3d):
		var vidas = mapa_3d.get("base_health")
		label_vidas.text = "Vidas: " + str(vidas)
		if vidas <= 5:
			label_vidas.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1)) # Vermelho forte
			
		var perdeu = mapa_3d.get("jogo_perdido")
		if perdeu and painel_derrota:
			painel_derrota.visible = true
	
	_atualizar_ui_onda()
	
	# Gerenciamento de arrasto (drag and drop)
	if mouse_pressed_on_button:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var dist = get_viewport().get_mouse_position().distance_to(mouse_start_pos)
			if dist > 15.0:
				drag_mode = true
		else:
			# Se o botão foi solto
			mouse_pressed_on_button = false
			if drag_mode:
				drag_mode = false
				if arrastando:
					if local_valido:
						_confirmar_colocacao()
					else:
						_cancelar_colocacao()
						_mostrar_mensagem("Construção cancelada (local inválido).")
	
	if get_tree().paused:
		return
		
	# Atualizar cooldowns individuais e overlays estilo PVZ
	for nome in cooldowns_restantes.keys():
		var rest = cooldowns_restantes[nome]
		if rest > 0.0:
			rest -= delta
			cooldowns_restantes[nome] = max(rest, 0.0)
			
			var btn = _obter_botao_por_nome(nome)
			if btn:
				var overlay = barras_cooldown.get(btn.name)
				if overlay:
					var max_cd = cooldowns_maximos.get(nome, 2.0)
					overlay.value = (rest / max_cd) * 100.0
		else:
			var btn = _obter_botao_por_nome(nome)
			if btn:
				var overlay = barras_cooldown.get(btn.name)
				if overlay:
					overlay.value = 0.0
	
	# Ghost Tower movimento
	if arrastando and torre_fantasma:
		mover_torre_com_mouse()
		
		# Limite de tempo para posicionar
		tempo_limite_restante -= delta
		label_mensagem.text = "Clique para comprar " + nome_construcao_atual + ". Tempo restante: " + str(int(tempo_limite_restante)) + "s"
		if tempo_limite_restante <= 0:
			_cancelar_colocacao()
			_mostrar_mensagem("Tempo esgotado para posicionar a torre!")
	
	# Efeito de Partículas Guia ao longo dos caminhos na fase de preparação
	_atualizar_guias_caminho(delta)


# --- ADICIONADO: Atualização e movimentação das partículas guias ---
func _atualizar_guias_caminho(delta: float) -> void:
	if not is_instance_valid(mapa_3d): return
	
	var em_esp = mapa_3d.get("em_espera")
	var perdeu = mapa_3d.get("jogo_perdido")
	var venceu = mapa_3d.get("jogo_vencido")
	
	if em_esp and not perdeu and not venceu:
		tempo_guia_spawn += delta
		if tempo_guia_spawn >= 1.5: # Spawn de uma partícula guia a cada 1.5s
			tempo_guia_spawn = 0.0
			_spawnar_guia_caminho()
			
		# Mover os guias
		var i = lista_guias.size() - 1
		while i >= 0:
			var guia = lista_guias[i]
			if is_instance_valid(guia):
				guia.progress += 8.0 * delta # velocidade do guia
				if guia.progress_ratio >= 0.99:
					guia.queue_free()
					lista_guias.remove_at(i)
			else:
				lista_guias.remove_at(i)
			i -= 1
	else:
		# Se a onda começou ou acabou, limpa todos os guias
		if lista_guias.size() > 0:
			for g in lista_guias:
				if is_instance_valid(g):
					g.queue_free()
			lista_guias.clear()


func _spawnar_guia_caminho() -> void:
	if not is_instance_valid(mapa_3d): return
	var caminhos = [mapa_3d.get("caminho_1"), mapa_3d.get("caminho_2")]
	
	for caminho in caminhos:
		if not is_instance_valid(caminho): continue
		
		var seguidor = PathFollow3D.new()
		seguidor.loop = false
		
		# Criação de um pequeno cristal flutuante brilhante
		var mesh_inst = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.1
		sm.height = 0.2
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.1, 0.8, 1.0, 0.7) # Ciano brilhante
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.material = mat
		mesh_inst.mesh = sm
		
		# Eleva um pouco acima do chão
		mesh_inst.position = Vector3(0, 0.4, 0)
		
		seguidor.add_child(mesh_inst)
		caminho.add_child(seguidor)
		lista_guias.append(seguidor)


# --- ADICIONADO: Helper para criar explosões de partículas CPUParticles3D ---
func _spawnar_particulas_construcao(pos: Vector3, cor: Color) -> void:
	var part = CPUParticles3D.new()
	part.emitting = true
	part.one_shot = true
	part.explosiveness = 0.8
	part.amount = 25
	part.lifetime = 0.6
	
	var sm = SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.16
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = cor
	sm.material = mat
	part.mesh = sm
	
	part.direction = Vector3.UP
	part.spread = 180.0
	part.initial_velocity_min = 2.5
	part.initial_velocity_max = 5.0
	
	mapa_3d.add_child(part)
	part.global_position = pos + Vector3(0, 0.5, 0)
	
	get_tree().create_timer(1.0).timeout.connect(part.queue_free)


func _obter_botao_por_nome(nome: String) -> Button:
	match nome:
		"Canhão": return botao_canhao
		"Balista": return botao_balista
		"Catapulta": return botao_catapulta
		"Mina": return botao_mina
	return null


func _obter_rids_colisores(no: Node) -> Array:
	var rids = []
	if no is CollisionObject3D:
		rids.append(no.get_rid())
	for filho in no.get_children():
		rids.append_array(_obter_rids_colisores(filho))
	return rids


func mover_torre_com_mouse() -> void:
	if not camera: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = mapa_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	query.exclude = _obter_rids_colisores(torre_fantasma)
	
	var result = space_state.intersect_ray(query)
	if result.is_empty(): return
	
	torre_fantasma.global_position = result["position"]
	
	var collider = result["collider"]
	var pai_collider = collider.get_parent()
	var e_construcao = false
	
	if pai_collider and (pai_collider.is_in_group("construcoes") or pai_collider.has_method("obter_custo_upgrade")):
		e_construcao = true
		
	if collider.is_in_group("area_proibida") or e_construcao:
		local_valido = false
		if e_construcao:
			label_mensagem.text = "Espaço ocupado por outra construção!"
		else:
			label_mensagem.text = "Local inválido para construir!"
	else:
		local_valido = true
	
	_atualizar_cor_fantasma()


func _atualizar_cor_fantasma() -> void:
	if not is_instance_valid(torre_fantasma): return
	
	var material_fantasma = StandardMaterial3D.new()
	material_fantasma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if local_valido:
		material_fantasma.albedo_color = Color(1.0, 1.0, 1.0, 0.4)
	else:
		material_fantasma.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
		
	_aplicar_material_recursivo(torre_fantasma, material_fantasma)


func _aplicar_material_recursivo(no: Node, mat: Material) -> void:
	if no is MeshInstance3D:
		no.material_override = mat
	for filho in no.get_children():
		_aplicar_material_recursivo(filho, mat)


func _remover_material_recursivo(no: Node) -> void:
	if no is MeshInstance3D:
		no.material_override = null
	for filho in no.get_children():
		_remover_material_recursivo(filho)


func _unhandled_input(event: InputEvent) -> void:
	# Se perdeu o jogo, desabilita cliques
	if is_instance_valid(mapa_3d) and mapa_3d.get("jogo_perdido"): return
	
	# Se o jogo estiver pausado, bloqueia cliques de construção/seleção
	if get_tree().paused:
		if event is InputEventMouseButton:
			return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if arrastando:
				_confirmar_colocacao()
			else:
				_tentar_selecionar_construcao()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if arrastando:
				_cancelar_colocacao()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if arrastando:
				_cancelar_colocacao()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			var novo_estado = not Salvamento.is_inverno_concluido()
			Salvamento.salvar_inverno_concluido(novo_estado)
			_mostrar_mensagem("DEBUG: Conclusao do Inverno alterada para: " + str(novo_estado))
			_atualizar_painel_melhoria()
			get_viewport().set_input_as_handled()


func _tentar_selecionar_construcao() -> void:
	if not camera: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = mapa_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	if not result.is_empty():
		var collider = result["collider"]
		var pai = collider.get_parent()
		if pai and (pai.is_in_group("construcoes") or pai.has_method("obter_custo_upgrade") or pai.has_method("melhorar")):
			_selecionar_construcao(pai)
			return
			
	_deselecionar_construcao()


func _selecionar_construcao(construcao: Node3D) -> void:
	_deselecionar_construcao()
	
	construcao_selecionada = construcao
	
	if is_instance_valid(construcao_selecionada) and construcao_selecionada.has_node("Alcance"):
		construcao_selecionada.get_node("Alcance").visible = true
		
	_atualizar_painel_melhoria()
	if painel_melhoria:
		painel_melhoria.visible = true


func _deselecionar_construcao() -> void:
	if is_instance_valid(construcao_selecionada) and construcao_selecionada.has_node("Alcance"):
		construcao_selecionada.get_node("Alcance").visible = false
		
	construcao_selecionada = null
	if painel_melhoria:
		painel_melhoria.visible = false


func _atualizar_painel_melhoria() -> void:
	if not is_instance_valid(construcao_selecionada):
		_deselecionar_construcao()
		return
		
	var nome_construcao = construcao_selecionada.name
	var nivel = construcao_selecionada.get("nivel")
	var nivel_max = construcao_selecionada.get("nivel_maximo")
	
	var nome_exibir = "Construção"
	var nome_l = nome_construcao.to_lower()
	if "canhao" in nome_l or "canhão" in nome_l:
		nome_exibir = "Canhão"
	elif "balista" in nome_l:
		nome_exibir = "Balista"
	elif "catapulta" in nome_l:
		nome_exibir = "Catapulta"
	elif "mina" in nome_l:
		nome_exibir = "Mina de Ouro"
	elif "gelo" in nome_l:
		nome_exibir = "Ice Tower"
		
	label_titulo_melhoria.text = nome_exibir + " (Nvl " + str(nivel) + ")"
	
	var stats_text = ""
	if construcao_selecionada.has_method("ativar_torre"):
		# Torre de ataque
		var dano = construcao_selecionada.get("dano")
		var alcance = construcao_selecionada.get("alcance")
		var intervalo = construcao_selecionada.get("intervalo_ataque")
		
		stats_text += "Dano: " + str(dano)
		if nivel < nivel_max:
			stats_text += " -> " + str(int(dano * 1.4)) + "\n"
		else:
			stats_text += " (Max)\n"
			
		stats_text += "Alcance: " + str(snapped(alcance, 0.1))
		if nivel < nivel_max:
			stats_text += " -> " + str(snapped(alcance * 1.15, 0.1)) + "\n"
		else:
			stats_text += " (Max)\n"
			
		stats_text += "Velocidade: " + str(snapped(intervalo, 0.1)) + "s"
		if nivel < nivel_max:
			stats_text += " -> " + str(snapped(intervalo * 0.85, 0.1)) + "s"
		else:
			stats_text += " (Max)"
	else:
		# Mina de ouro
		var ouro_ciclo = construcao_selecionada.get("ouro_por_ciclo")
		var intervalo = construcao_selecionada.get("intervalo")
		
		stats_text += "Ouro/Ciclo: " + str(ouro_ciclo)
		if nivel < nivel_max:
			stats_text += " -> " + str(int(ouro_ciclo * 1.6)) + "\n"
		else:
			stats_text += " (Max)\n"
			
		stats_text += "Intervalo: " + str(snapped(intervalo, 0.1)) + "s"
		if nivel < nivel_max:
			stats_text += " -> " + str(snapped(intervalo * 0.85, 0.1)) + "s"
		else:
			stats_text += " (Max)"
			
	label_status_melhoria.text = stats_text
	
	if nivel < nivel_max:
		var custo_up = construcao_selecionada.obter_custo_upgrade()
		botao_melhorar.text = "Melhorar (" + str(custo_up) + " Ouro)"
		botao_melhorar.disabled = false
	else:
		botao_melhorar.text = "Melhoria Máxima"
		botao_melhorar.disabled = true
		
	var valor_venda = construcao_selecionada.obter_valor_venda()
	botao_vender.text = "Vender (+" + str(valor_venda) + ")"
	
	# Lógica do Botão de Upgrade para Torre de Gelo
	if botao_upgrade_gelo:
		var pode_evoluir = false
		if not "mina" in nome_l and not "gelo" in nome_l:
			if _is_ice_phase():
				pode_evoluir = true
				
		if pode_evoluir:
			botao_upgrade_gelo.visible = true
			botao_upgrade_gelo.text = "Evoluir para Gelo (" + str(custo_gelo) + " G)"
			botao_upgrade_gelo.disabled = (ouro < custo_gelo)
		else:
			botao_upgrade_gelo.visible = false
			
	# Recalcular tamanho e manter ancorado no canto inferior direito
	painel_melhoria.reset_size()
	painel_melhoria.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


func _on_botao_melhorar_pressed() -> void:
	if not is_instance_valid(construcao_selecionada): return
	
	var custo_up = construcao_selecionada.obter_custo_upgrade()
	if ouro < custo_up:
		_mostrar_mensagem("Ouro insuficiente para melhorar! Custo: " + str(custo_up))
		return
		
	_gastar_ouro(custo_up)
	
	var pos_torre = construcao_selecionada.global_position
	
	construcao_selecionada.melhorar()
	_mostrar_mensagem("Melhorado com sucesso!")
	_atualizar_painel_melhoria()
	
	# Efeito de faíscas verdes ao melhorar
	_spawnar_particulas_construcao(pos_torre, Color(0.2, 1.0, 0.4))


func _on_botao_vender_pressed() -> void:
	if not is_instance_valid(construcao_selecionada): return
	
	var valor_venda = construcao_selecionada.obter_valor_venda()
	adicionar_ouro(valor_venda)
	
	var pos_torre = construcao_selecionada.global_position
	
	var construcao_a_deletar = construcao_selecionada
	_deselecionar_construcao()
	construcao_a_deletar.queue_free()
	
	# Efeito de cinza/poeira vermelha ao vender
	_spawnar_particulas_construcao(pos_torre, Color(1.0, 0.3, 0.3))


func _on_botao_skip_wave_pressed() -> void:
	if mapa_3d and mapa_3d.has_method("iniciar_proxima_onda"):
		var em_esp = mapa_3d.get("em_espera")
		if em_esp:
			mapa_3d.iniciar_proxima_onda()


func _on_botao_pausa_pressed() -> void:
	var pausado = get_tree().paused
	get_tree().paused = not pausado
	if get_tree().paused:
		botao_pausa.text = "Continuar"
		botao_pausa.modulate = Color(1.0, 0.5, 0.5)
		_mostrar_mensagem("Jogo Pausado")
	else:
		botao_pausa.text = "Pausar"
		botao_pausa.modulate = Color(1.0, 1.0, 1.0)
		_mostrar_mensagem("Jogo Retomado")


func _atualizar_ui_onda() -> void:
	if not painel_onda or not is_instance_valid(mapa_3d): return
	
	var onda_at = mapa_3d.get("onda_atual")
	var total_ondas = mapa_3d.get("configuracao_ondas").size()
	var em_esp = mapa_3d.get("em_espera")
	var t_restante = mapa_3d.get("tempo_espera_restante")
	var inimigos_vivos = mapa_3d.get("inimigos_vivos")
	var fila_size = mapa_3d.get("fila_spawn").size()
	var vencido = mapa_3d.get("jogo_vencido")
	
	if vencido:
		label_onda_status.text = "Vitória Completa!"
		botao_onda_skip.visible = false
		return
		
	if em_esp:
		label_onda_status.text = "Onda: " + str(onda_at + 1) + "/" + str(total_ondas) + "\nPróxima em: " + str(int(t_restante)) + "s"
		botao_onda_skip.text = "Iniciar Onda"
		botao_onda_skip.visible = true
	else:
		label_onda_status.text = "Onda: " + str(onda_at + 1) + "/" + str(total_ondas) + "\nRestam: " + str(inimigos_vivos + fila_size)
		botao_onda_skip.visible = false
			
	# Recalcular tamanho e manter ancorado no canto superior direito
	painel_onda.reset_size()
	painel_onda.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


func _atualizar_label_ouro() -> void:
	if label_ouro:
		label_ouro.text = "Ouro: " + str(ouro)


func _mostrar_mensagem(texto: String) -> void:
	if label_mensagem:
		label_mensagem.text = texto
	print(texto)


func adicionar_ouro(valor: int) -> void:
	ouro += valor
	_atualizar_label_ouro()
	_mostrar_mensagem("+" + str(valor) + " de ouro. Total: " + str(ouro))


func _gastar_ouro(valor: int) -> void:
	ouro -= valor
	_atualizar_label_ouro()


func _is_ice_phase() -> bool:
	if not is_instance_valid(mapa_3d):
		return false
	
	var map_name = mapa_3d.name.to_lower()
	var map_path = mapa_3d.scene_file_path.to_lower()
	
	# Se for mapa de inverno (Inverno ou Gelo no nome/path)
	if "inverno" in map_name or "inverno" in map_path or "gelo" in map_name or "gelo" in map_path:
		return true
		
	# Se for outro mapa (ex: primavera), só desbloqueia se a fase de inverno já tiver sido concluída
	if Salvamento.is_inverno_concluido():
		var onda_at = mapa_3d.get("onda_atual")
		if onda_at != null and onda_at >= 2:
			return true
		
	return false


func _on_botao_upgrade_gelo_pressed() -> void:
	if not is_instance_valid(construcao_selecionada): return
	
	if ouro < custo_gelo:
		_mostrar_mensagem("Ouro insuficiente para evoluir para Torre de Gelo! Custo: " + str(custo_gelo))
		return
		
	_gastar_ouro(custo_gelo)
	
	var pos_torre = construcao_selecionada.global_position
	var rot_torre = construcao_selecionada.global_rotation
	
	# Criação da nova torre de gelo
	var nova_torre = cena_gelo.instantiate()
	nova_torre.global_position = pos_torre
	nova_torre.global_rotation = rot_torre
	
	mapa_3d.add_child(nova_torre)
	
	if nova_torre.has_method("ativar_torre"):
		nova_torre.ativar_torre()
		
	# Remove a antiga
	var construcao_a_deletar = construcao_selecionada
	_deselecionar_construcao()
	construcao_a_deletar.queue_free()
	
	_mostrar_mensagem("Torre evoluída para Torre de Gelo!")
	
	# VFX de faíscas congeladas/ciano no upgrade
	_spawnar_particulas_construcao(pos_torre, Color(0.2, 0.8, 1.0))
