extends Node3D

@export var velocidade: float = 5.0
@export var vida_maxima: int = 100

var vida_atual: int

# --- NOVO: Pega a referência da barra de progresso na árvore ---
@onready var barra_vida: ProgressBar = $BarraVida3D/SubViewport/ProgressBar

func _ready():
	vida_atual = vida_maxima
	add_to_group("inimigos")
	
	# --- NOVO: Configura os valores iniciais da barra de vida ---
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual

func _process(delta):
	var seguidor = get_parent()
	
	if seguidor is PathFollow3D:
		seguidor.progress += velocidade * delta
		
		if seguidor.progress_ratio >= 0.99:
			print("Inimigo chegou na base!")
			seguidor.queue_free()

func tomar_dano(dano: int):
	vida_atual -= dano
	print("Inimigo tomou dano:", dano, " Vida restante:", vida_atual)
	
	# --- NOVO: Atualiza o visual da barra com a vida restante ---
	if barra_vida:
		barra_vida.value = vida_atual
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("Inimigo morreu!")
	
	var seguidor = get_parent()
	
	if seguidor is PathFollow3D:
		seguidor.queue_free()
	else:
		queue_free()
