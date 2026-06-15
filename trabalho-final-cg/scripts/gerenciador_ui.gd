extends CanvasLayer

@export var cena_canhao: PackedScene 

# --- Referências Corrigidas ---
@onready var mapa_3d = get_parent() # Pega o nó 'Map'
@onready var camera = $"../GridMapPrimavera/Camera3D2" # Caminho exato para a câmera!
@onready var botao_canhao = $HBoxContainer/BotaoCanhao

var arrastando = false
var torre_fantasma: Node3D = null

func _ready():
	# Verificação de segurança automática
	if not camera:
		print("ERRO: A UI não conseguiu encontrar a Camera3D2 no GridMapPrimavera!")
		
	botao_canhao.button_down.connect(_iniciar_arraste)
	botao_canhao.button_up.connect(_soltar_torre)

func _iniciar_arraste():
	if not cena_canhao:
		print("ERRO: Você esqueceu de arrastar a cena do canhão para o Inspetor da UI!")
		return
		
	arrastando = true
	torre_fantasma = cena_canhao.instantiate()
	mapa_3d.add_child(torre_fantasma)
	print("Arraste iniciado!")

func _soltar_torre():
	arrastando = false
	if torre_fantasma:
		print("Canhão posicionado na coordenada: ", torre_fantasma.position)
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
