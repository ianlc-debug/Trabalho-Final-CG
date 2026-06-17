extends Node3D

@export var velocidade: float = 5.0
@export var vida_maxima: int = 100

var vida_atual: int

# --- NOVO: Pega a referência da barra de progresso na árvore ---
@onready var barra_vida: ProgressBar = $BarraVida3D/SubViewport/ProgressBar

# --- ADICIONADO: Variáveis de Lentidão ---
var fator_lentidao: float = 1.0
var tempo_lentidao: float = 0.0
var material_lento: StandardMaterial3D = null


func _ready():
	vida_atual = vida_maxima
	add_to_group("inimigos")
	
	# --- NOVO: Configura os valores iniciais da barra de vida ---
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual


func _process(delta):
	# Decrementar tempo de lentidão
	if tempo_lentidao > 0.0:
		tempo_lentidao -= delta
		if tempo_lentidao <= 0.0:
			fator_lentidao = 1.0
			_remover_material_recursivo(self)
			
	var seguidor = get_parent()
	
	if seguidor is PathFollow3D:
		seguidor.progress += (velocidade * fator_lentidao) * delta
		
		if seguidor.progress_ratio >= 0.99:
			print("Inimigo chegou na base!")
			# Notificar o mapa sobre o dano
			var mapa = seguidor.get_parent().get_parent()
			if mapa and mapa.has_method("registrar_dano_base"):
				mapa.registrar_dano_base()
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


func aplicar_lentidao(fator: float, tempo: float) -> void:
	fator_lentidao = min(fator_lentidao, fator)
	tempo_lentidao = max(tempo_lentidao, tempo)
	
	if not material_lento:
		material_lento = StandardMaterial3D.new()
		material_lento.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material_lento.albedo_color = Color(0.0, 0.5, 1.0, 0.4) # Azul Gelo translúcido
		
	_aplicar_material_recursivo(self, material_lento)


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
