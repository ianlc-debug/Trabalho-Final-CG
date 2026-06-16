extends Node3D

@export var velocidade: float = 20.0

var _dano: int = 0
var _alvo: Node3D = null
var _ultima_posicao_alvo: Vector3


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
	
	# Remove a munição do mapa
	queue_free()
