extends Node3D

@export var velocidade: float = 20.0

var _dano: int = 0
var _alvo: Node3D = null
var _ultima_posicao_alvo: Vector3

# --- ADICIONADO: Variável de Gelo ---
var eh_gelo: bool = false


# Função chamada pela torre assim que a munição nasce
func configurar(alvo_node: Node3D, dano_torre: int) -> void:
	_alvo = alvo_node
	_dano = dano_torre
	if is_instance_valid(_alvo):
		_ultima_posicao_alvo = _alvo.global_position


func _process(delta: float) -> void:
	# Se o inimigo ainda existir, atualizamos a posição real dele
	if is_instance_valid(_alvo):
		_ultima_posicao_alvo = _alvo.global_position
	
	# Calcula a direção até o alvo
	var direcao = (_ultima_posicao_alvo - global_position).normalized()
	
	# Move a munição
	global_position += direcao * velocidade * delta
	
	# Faz a munição olhar para frente (essencial para flechas e virotes da balista)
	if global_position.distance_to(_ultima_posicao_alvo) > 0.1:
		look_at(_ultima_posicao_alvo, Vector3.UP)
	
	# Se chegou perto o suficiente do alvo, causa o impacto
	if global_position.distance_to(_ultima_posicao_alvo) < 0.5:
		_causar_impacto()


func _causar_impacto() -> void:
	# Aplica o dano se o inimigo ainda estiver vivo
	if is_instance_valid(_alvo) and _alvo.has_method("tomar_dano"):
		_alvo.tomar_dano(_dano)
		# Se for projétil de gelo, aplica lentidão
		if eh_gelo and _alvo.has_method("aplicar_lentidao"):
			_alvo.aplicar_lentidao(0.5, 2.5) # 50% de lentidão por 2.5s
	
	# Spawnar efeitos de partículas
	_spawnar_particulas_impacto()
	
	# Remove a munição do mapa
	queue_free()


func _spawnar_particulas_impacto() -> void:
	var part = CPUParticles3D.new()
	part.emitting = true
	part.one_shot = true
	part.explosiveness = 1.0
	part.amount = 12
	part.lifetime = 0.4
	
	# Criação da mesh para as partículas
	var sm = SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	
	var mat = StandardMaterial3D.new()
	if eh_gelo:
		mat.albedo_color = Color(0.0, 0.7, 1.0) # Azul gelo brilhante
	else:
		mat.albedo_color = Color(1.0, 0.45, 0.1) # Laranja fogo
	
	sm.material = mat
	part.mesh = sm
	
	part.direction = Vector3.UP
	part.spread = 180.0
	part.initial_velocity_min = 2.0
	part.initial_velocity_max = 4.0
	
	get_tree().current_scene.add_child(part)
	part.global_position = global_position
	
	# Liberação automática
	get_tree().create_timer(0.6).timeout.connect(part.queue_free)

