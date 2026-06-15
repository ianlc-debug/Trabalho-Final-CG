extends CanvasLayer

# --- Variáveis para as Construções ---
@export var cena_canhao: PackedScene 
@export var cena_balista: PackedScene 
@export var cena_catapulta: PackedScene 
@export var cena_mina: PackedScene 

@onready var mapa_3d = get_parent() 
@onready var camera = $"../GridMapPrimavera/Camera3D2" 

# --- Referências dos Botões ---
@onready var botao_canhao = $HBoxContainer/BotaoCanhao
@onready var botao_balista = $HBoxContainer/BotaoBalista
@onready var botao_catapulta = $HBoxContainer/BotaoCatapulta
@onready var botao_mina = $HBoxContainer/BotaoMina 

var arrastando = false
var torre_fantasma: Node3D = null

func _ready():
	# Conexões dos botões
	botao_canhao.button_down.connect(_iniciar_arraste.bind(cena_canhao))
	botao_balista.button_down.connect(_iniciar_arraste.bind(cena_balista))
	botao_catapulta.button_down.connect(_iniciar_arraste.bind(cena_catapulta))
	botao_mina.button_down.connect(_iniciar_arraste.bind(cena_mina)) 
	
	botao_canhao.button_up.connect(_soltar_torre)
	botao_balista.button_up.connect(_soltar_torre)
	botao_catapulta.button_up.connect(_soltar_torre)
	botao_mina.button_up.connect(_soltar_torre) 

func _iniciar_arraste(cena_escolhida: PackedScene):
	if not cena_escolhida:
		print("ERRO: A cena desta construção não foi arrastada no Inspetor da UI!")
		return
		
	arrastando = true
	torre_fantasma = cena_escolhida.instantiate()
	mapa_3d.add_child(torre_fantasma)
	
	# NOVO: Se a torre tiver o nó "Alcance", nós mostramos a bolha!
	if torre_fantasma.has_node("Alcance"):
		torre_fantasma.get_node("Alcance").visible = true

func _soltar_torre():
	arrastando = false
	if torre_fantasma:
		# NOVO: Esconde a bolha de alcance antes de fixar a torre no mapa
		if torre_fantasma.has_node("Alcance"):
			torre_fantasma.get_node("Alcance").visible = false
			
		torre_fantasma = null 

func _process(_delta):
	if arrastando and torre_fantasma:
		mover_torre_com_mouse()

func mover_torre_com_mouse():
	if not camera:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = mapa_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		torre_fantasma.position = result.position
