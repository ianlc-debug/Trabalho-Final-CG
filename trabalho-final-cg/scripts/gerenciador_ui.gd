extends CanvasLayer

# --- Cenas das construções ---
@export var cena_canhao: PackedScene
@export var cena_balista: PackedScene
@export var cena_catapulta: PackedScene
@export var cena_mina: PackedScene

# --- Sistema de economia e validação ---
@export var ouro_inicial: int = 300
@export var custo_canhao: int = 100
@export var custo_balista: int = 75
@export var custo_catapulta: int = 150
@export var custo_mina: int = 125

@onready var mapa_3d: Node3D = get_parent()
@onready var camera: Camera3D = $"../GridMapPrimavera/Camera3D2"

@onready var botao_canhao: Button = $HBoxContainer/BotaoCanhao
@onready var botao_balista: Button = $HBoxContainer/BotaoBalista
@onready var botao_catapulta: Button = $HBoxContainer/BotaoCatapulta
@onready var botao_mina: Button = $HBoxContainer/BotaoMina

var ouro: int
var arrastando: bool = false
var torre_fantasma: Node3D = null
var custo_construcao_atual: int = 0
var nome_construcao_atual: String = ""

# --- Controle de local válido ---
var local_valido: bool = false

var label_ouro: Label
var label_mensagem: Label

# --- Interface de Onda e Melhoria ---
var construcao_selecionada: Node3D = null
var painel_melhoria: PanelContainer = null
var label_titulo_melhoria: Label = null
var label_status_melhoria: Label = null
var botao_melhorar: Button = null
var botao_vender: Button = null

var painel_onda: PanelContainer = null
var label_onda_status: Label = null
var botao_onda_skip: Button = null

# --- NOVAS VARIÁVEIS: Cooldown e Limite de Tempo ---
var cooldown_tempo: float = 3.0  # Tempo de espera após colocar uma torre
var cooldown_restante: float = 0.0

var tempo_limite_posicionamento: float = 12.0  # Tempo limite para posicionar a torre fantasma
var tempo_limite_restante: float = 0.0


func _ready() -> void:
	ouro = ouro_inicial
	_criar_labels()
	_adicionar_labels_custo()
	_atualizar_label_ouro()
	_mostrar_mensagem("Escolha uma construção.")
	
	# Usando o sinal pressed (clique único) em vez de arrastar com mouse pressionado
	botao_canhao.pressed.connect(_iniciar_colocacao.bind(cena_canhao, custo_canhao, "Canhão"))
	botao_balista.pressed.connect(_iniciar_colocacao.bind(cena_balista, custo_balista, "Balista"))
	botao_catapulta.pressed.connect(_iniciar_colocacao.bind(cena_catapulta, custo_catapulta, "Catapulta"))
	botao_mina.pressed.connect(_iniciar_colocacao.bind(cena_mina, custo_mina, "Mina"))


func _criar_labels() -> void:
	label_ouro = Label.new()
	add_child(label_ouro)
	label_ouro.position = Vector2(20, 20)
	label_ouro.add_theme_font_size_override("font_size", 20)
	label_ouro.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	
	label_mensagem = Label.new()
	add_child(label_mensagem)
	label_mensagem.position = Vector2(20, 50)
	label_mensagem.add_theme_font_size_override("font_size", 14)
	
	_criar_ui_onda()
	_criar_ui_melhorias()


# --- ADICIONADO: Exibe o custo de cada torre acima de seu ícone ---
func _adicionar_labels_custo() -> void:
	var botoes_e_custos = [
		{"botao": botao_canhao, "custo": custo_canhao},
		{"botao": botao_balista, "custo": custo_balista},
		{"botao": botao_catapulta, "custo": custo_catapulta},
		{"botao": botao_mina, "custo": custo_mina}
	]
	
	var hbox = $HBoxContainer
	if not hbox: return
	
	for item in botoes_e_custos:
		var btn = item["botao"]
		var cost = item["custo"]
		if not btn: continue
		
		# Salvar posição na hierarquia do HBox
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
		lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Dourado
		
		vbox.add_child(btn)


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
	
	painel_onda.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	painel_onda.position = Vector2(get_viewport().size.x - 320, 20)
	
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
	
	painel_melhoria.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	painel_melhoria.position = Vector2(get_viewport().size.x - 300, get_viewport().size.y - 280)
	
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


func _iniciar_colocacao(cena_escolhida: PackedScene, custo: int, nome_construcao: String) -> void:
	if cooldown_restante > 0:
		_mostrar_mensagem("Aguarde a recarga de construção! Tempo restante: " + str(snapped(cooldown_restante, 0.1)) + "s")
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
	
	# Iniciar o cooldown de posicionamento
	cooldown_restante = cooldown_tempo


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
	if cooldown_restante > 0:
		cooldown_restante -= delta
		_atualizar_botoes_cooldown()
		if cooldown_restante <= 0:
			_mostrar_mensagem("Recarga de construção finalizada.")
			_atualizar_botoes_cooldown()
	
	if arrastando and torre_fantasma:
		mover_torre_com_mouse()
		
		# Contagem de limite de tempo para posicionar
		tempo_limite_restante -= delta
		label_mensagem.text = "Clique para comprar " + nome_construcao_atual + ". Tempo restante: " + str(int(tempo_limite_restante)) + "s"
		if tempo_limite_restante <= 0:
			_cancelar_colocacao()
			_mostrar_mensagem("Tempo esgotado para posicionar a torre!")
	
	_atualizar_ui_onda()


func _atualizar_botoes_cooldown() -> void:
	var em_cooldown = cooldown_restante > 0
	
	botao_canhao.disabled = em_cooldown
	botao_balista.disabled = em_cooldown
	botao_catapulta.disabled = em_cooldown
	botao_mina.disabled = em_cooldown
	
	if em_cooldown:
		label_mensagem.text = "Recarga de construção: " + str(snapped(cooldown_restante, 0.1)) + "s"


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


func _on_botao_melhorar_pressed() -> void:
	if not is_instance_valid(construcao_selecionada): return
	
	var custo_up = construcao_selecionada.obter_custo_upgrade()
	if ouro < custo_up:
		_mostrar_mensagem("Ouro insuficiente para melhorar! Custo: " + str(custo_up))
		return
		
	_gastar_ouro(custo_up)
	construcao_selecionada.melhorar()
	_mostrar_mensagem("Melhorado com sucesso!")
	_atualizar_painel_melhoria()


func _on_botao_vender_pressed() -> void:
	if not is_instance_valid(construcao_selecionada): return
	
	var valor_venda = construcao_selecionada.obter_valor_venda()
	adicionar_ouro(valor_venda)
	
	var construcao_a_deletar = construcao_selecionada
	_deselecionar_construcao()
	construcao_a_deletar.queue_free()


func _on_botao_skip_wave_pressed() -> void:
	if mapa_3d and mapa_3d.has_method("iniciar_proxima_onda"):
		var em_esp = mapa_3d.get("em_espera")
		if em_esp:
			mapa_3d.iniciar_proxima_onda()


func _atualizar_ui_onda() -> void:
	if not painel_onda or not is_instance_valid(mapa_3d): return
	
	painel_onda.position = Vector2(get_viewport().size.x - 300, 20)
	if painel_melhoria:
		painel_melhoria.position = Vector2(get_viewport().size.x - 300, get_viewport().size.y - 280)
		
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
