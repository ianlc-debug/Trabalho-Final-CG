extends Node3D

@export var velocidade: float = 5.0
@export var vida_maxima: int = 100

var vida_atual: int

# --- NOVO: Pega a referência da barra de progresso na árvore ---
@onready var barra_vida: ProgressBar = $BarraVida3D/SubViewport/ProgressBar

# --- ADICIONADO: Variáveis de Lentidão ---
var fator_lentidao: float = 1.0
var tempo_lentidao: float = 0.0

# --- ADICIONADO: Efeito de Rastro ---
var tempo_acumulado_rastro: float = 0.0
@export var intervalo_rastro: float = 0.12

# --- Recursos estáticos compartilhados para evitar alocações constantes e stutters de shader ---
static var _mesh_bubble: SphereMesh = null
static var _mesh_spark: SphereMesh = null
static var _mesh_rastro: TorusMesh = null
static var _material_bubble_base: StandardMaterial3D = null
static var _material_spark: StandardMaterial3D = null
static var _material_rastro_base: StandardMaterial3D = null
static var _material_lento: StandardMaterial3D = null


func _ready():
	vida_atual = vida_maxima
	add_to_group("inimigos")
	
	# --- NOVO: Configura os valores iniciais da barra de vida ---
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual


func _process(delta):
	# Atualizar e spawnar rastro de elipses verdes
	tempo_acumulado_rastro += delta
	if tempo_acumulado_rastro >= intervalo_rastro:
		tempo_acumulado_rastro = 0.0
		_spawnar_elipse_rastro()

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
	
	_spawnar_explosao()
	
	var seguidor = get_parent()
	if seguidor is PathFollow3D:
		seguidor.queue_free()
	else:
		queue_free()


func _spawnar_explosao() -> void:
	var seguidor = get_parent()
	if not seguidor:
		return
	var mapa = seguidor.get_parent().get_parent()
	if not is_instance_valid(mapa):
		return
		
	var pos_explosao = global_position
	
	# Garante que os recursos de bolha estão criados e compartilhados
	if not _mesh_bubble:
		_mesh_bubble = SphereMesh.new()
		_mesh_bubble.radius = 0.4
		_mesh_bubble.height = 0.8
	if not _material_bubble_base:
		_material_bubble_base = StandardMaterial3D.new()
		_material_bubble_base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material_bubble_base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# 1. Bolha de explosão (Esfera que cresce e some)
	var bubble = MeshInstance3D.new()
	var mat_bubble = _material_bubble_base.duplicate()
	mat_bubble.albedo_color = Color(1.0, 0.6, 0.1, 0.9) # Laranja fogo
	
	var sm = _mesh_bubble
	sm.material = mat_bubble
	bubble.mesh = sm
	
	mapa.add_child(bubble)
	bubble.global_position = pos_explosao
	
	# Animar a bolha (cresce e some rápido)
	var tween = bubble.create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
	tween.tween_property(mat_bubble, "albedo_color", Color(1.0, 0.2, 0.0, 0.0), 0.35)
	tween.set_parallel(false)
	tween.tween_callback(bubble.queue_free)
	
	# Garante que os recursos de partículas estão criados e compartilhados
	if not _mesh_spark:
		_mesh_spark = SphereMesh.new()
		_mesh_spark.radius = 0.06
		_mesh_spark.height = 0.12
	if not _material_spark:
		_material_spark = StandardMaterial3D.new()
		_material_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material_spark.albedo_color = Color(1.0, 0.8, 0.2) # Amarelo/Dourado
	
	# 2. Partículas (Faíscas/Pedaços)
	var part = CPUParticles3D.new()
	part.emitting = true
	part.one_shot = true
	part.explosiveness = 0.9
	part.amount = 15
	part.lifetime = 0.5
	
	var spark_mesh = _mesh_spark
	spark_mesh.material = _material_spark
	part.mesh = spark_mesh
	
	part.direction = Vector3.UP
	part.spread = 180.0
	part.initial_velocity_min = 2.0
	part.initial_velocity_max = 5.0
	
	mapa.add_child(part)
	part.global_position = pos_explosao
	
	get_tree().create_timer(0.8).timeout.connect(part.queue_free)


func aplicar_lentidao(fator: float, tempo: float) -> void:
	fator_lentidao = min(fator_lentidao, fator)
	tempo_lentidao = max(tempo_lentidao, tempo)
	
	if not _material_lento:
		_material_lento = StandardMaterial3D.new()
		_material_lento.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material_lento.albedo_color = Color(0.0, 0.5, 1.0, 0.4) # Azul Gelo translúcido
		
	_aplicar_material_recursivo(self, _material_lento)


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


func _spawnar_elipse_rastro() -> void:
	var seguidor = get_parent()
	if not seguidor or not (seguidor is PathFollow3D):
		return
		
	var mapa = seguidor.get_parent().get_parent()
	if not is_instance_valid(mapa):
		return
		
	# Garante que os recursos do rastro estão criados e compartilhados
	if not _mesh_rastro:
		_mesh_rastro = TorusMesh.new()
		_mesh_rastro.inner_radius = 0.22
		_mesh_rastro.outer_radius = 0.28
		_mesh_rastro.ring_segments = 4
		_mesh_rastro.rings = 24
	if not _material_rastro_base:
		_material_rastro_base = StandardMaterial3D.new()
		_material_rastro_base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material_rastro_base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
	var mesh_inst = MeshInstance3D.new()
	var mat = _material_rastro_base.duplicate()
	mat.albedo_color = Color(0.2, 1.0, 0.4, 0.7) # Verde brilhante
	
	var torus = _mesh_rastro
	torus.material = mat
	mesh_inst.mesh = torus
	
	# Adiciona no mapa para que o rastro fique parado no mundo 3D
	mapa.add_child(mesh_inst)
	
	# Posicionar ligeiramente abaixo do OVNI
	mesh_inst.global_position = global_position - Vector3(0, 0.15, 0)
	mesh_inst.global_rotation = global_rotation
	
	# Formato de elipse (alongado horizontalmente)
	mesh_inst.scale = Vector3(1.3, 0.1, 0.7)
	
	# Animar expansão e fade out
	var tween = mesh_inst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_inst, "scale", Vector3(2.6, 0.05, 1.4), 0.6)
	tween.tween_property(mat, "albedo_color", Color(0.2, 1.0, 0.4, 0.0), 0.6)
	tween.set_parallel(false)
	tween.tween_callback(mesh_inst.queue_free)
