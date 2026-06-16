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

# --- NOVO: Controle de local válido ---
var local_valido: bool = false

var label_ouro: Label
var label_mensagem: Label


func _ready() -> void:
	ouro = ouro_inicial
	_criar_labels()
	_atualizar_label_ouro()
	_mostrar_mensagem("Escolha uma construção.")
	
	botao_canhao.button_down.connect(_iniciar_arraste.bind(cena_canhao, custo_canhao, "Canhão"))
	botao_balista.button_down.connect(_iniciar_arraste.bind(cena_balista, custo_balista, "Balista"))
	botao_catapulta.button_down.connect(_iniciar_arraste.bind(cena_catapulta, custo_catapulta, "Catapulta"))
	botao_mina.button_down.connect(_iniciar_arraste.bind(cena_mina, custo_mina, "Mina"))
	
	botao_canhao.button_up.connect(_soltar_torre)
	botao_balista.button_up.connect(_soltar_torre)
	botao_catapulta.button_up.connect(_soltar_torre)
	botao_mina.button_up.connect(_soltar_torre)


func _criar_labels() -> void:
	label_ouro = Label.new()
	add_child(label_ouro)
	label_ouro.position = Vector2(20, 20)
	label_mensagem = Label.new()
	add_child(label_mensagem)
	label_mensagem.position = Vector2(20, 50)


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


func _iniciar_arraste(cena_escolhida: PackedScene, custo: int, nome_construcao: String) -> void:
	if arrastando: return
	if not cena_escolhida:
		_mostrar_mensagem("ERRO: a cena de " + nome_construcao + " não foi definida no Inspector.")
		return
	if ouro < custo:
		_mostrar_mensagem("Ouro insuficiente para comprar " + nome_construcao + ". Custo: " + str(custo))
		return
	
	arrastando = true
	custo_construcao_atual = custo
	nome_construcao_atual = nome_construcao
	local_valido = false # Começa como falso até o mouse validar
	
	torre_fantasma = cena_escolhida.instantiate()
	mapa_3d.add_child(torre_fantasma)
	
	if torre_fantasma.has_node("Alcance"):
		torre_fantasma.get_node("Alcance").visible = true
	
	_mostrar_mensagem("Posicione " + nome_construcao + ". Custo: " + str(custo))


func _soltar_torre() -> void:
	if not arrastando: return
	arrastando = false
	if not torre_fantasma: return
	
	# --- NOVO: Impede a construção se o local for inválido ---
	if not local_valido:
		_mostrar_mensagem("Construção cancelada: Local proibido.")
		torre_fantasma.queue_free()
		_limpar_arraste()
		return
	# ---------------------------------------------------------
	
	if ouro < custo_construcao_atual:
		_mostrar_mensagem("Construção cancelada: ouro insuficiente.")
		torre_fantasma.queue_free()
		_limpar_arraste()
		return
	
	_gastar_ouro(custo_construcao_atual)
	
	if torre_fantasma.has_node("Alcance"):
		torre_fantasma.get_node("Alcance").visible = false
	
	if torre_fantasma.has_method("configurar_gerenciador_ouro"):
		torre_fantasma.configurar_gerenciador_ouro(self)
	
	if torre_fantasma.has_method("ativar_torre"):
		torre_fantasma.ativar_torre()
		
	# --- NOVO: Devolve as cores originais da torre ao construir ---
	_remover_material_recursivo(torre_fantasma)
	
	_mostrar_mensagem(nome_construcao_atual + " colocado. Ouro restante: " + str(ouro))
	torre_fantasma = null
	_limpar_arraste()


func _limpar_arraste() -> void:
	custo_construcao_atual = 0
	nome_construcao_atual = ""


func _process(_delta: float) -> void:
	if arrastando and torre_fantasma:
		mover_torre_com_mouse()


func mover_torre_com_mouse() -> void:
	if not camera: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = mapa_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true
	query.collide_with_areas = true # Mudado para true para detectar áreas proibidas
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty(): return
	
	torre_fantasma.global_position = result["position"]
	
	# --- NOVO: Verifica se o objeto embaixo do mouse é proibido ---
	var collider = result["collider"]
	if collider.is_in_group("area_proibida"):
		local_valido = false
		label_mensagem.text = "Local inválido para construir!"
	else:
		local_valido = true
		label_mensagem.text = "Solte para comprar " + nome_construcao_atual + "."
	
	_atualizar_cor_fantasma()


# --- NOVAS FUNÇÕES: Sistema de Holograma Colorido ---
func _atualizar_cor_fantasma() -> void:
	if not is_instance_valid(torre_fantasma): return
	
	var material_fantasma = StandardMaterial3D.new()
	material_fantasma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if local_valido:
		material_fantasma.albedo_color = Color(1.0, 1.0, 1.0, 0.4) # Branco Translúcido (Permitido)
	else:
		material_fantasma.albedo_color = Color(1.0, 0.0, 0.0, 0.6) # Vermelho Translúcido (Proibido)
		
	_aplicar_material_recursivo(torre_fantasma, material_fantasma)


func _aplicar_material_recursivo(no: Node, mat: Material) -> void:
	if no is MeshInstance3D:
		no.material_override = mat
	for filho in no.get_children():
		_aplicar_material_recursivo(filho, mat)


func _remover_material_recursivo(no: Node) -> void:
	if no is MeshInstance3D:
		no.material_override = null # Retira a tinta e devolve a textura original
	for filho in no.get_children():
		_remover_material_recursivo(filho)
