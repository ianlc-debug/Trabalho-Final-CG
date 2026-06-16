extends Node3D

# --- NOVO: Vaga para colocar a munição da torre ---
@export var cena_projetil: PackedScene

@export var dano: int = 25
@export var alcance: float = 8.0
@export var intervalo_ataque: float = 1.0

var pode_atacar: bool = true
var alvo_atual: Node3D = null
var esta_ativa: bool = false

var inimigos_rastreados: Array[Node3D] = []


func ativar_torre() -> void:
	esta_ativa = true


func _process(_delta: float) -> void:
	if not esta_ativa:
		return
		
	_atualizar_alvo()
	
	if is_instance_valid(alvo_atual):
		_mirar_no_alvo()
		if pode_atacar:
			_atacar(alvo_atual)


func _atualizar_alvo() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	
	var i = inimigos_rastreados.size() - 1
	while i >= 0:
		var inimigo = inimigos_rastreados[i]
		if not is_instance_valid(inimigo) or global_position.distance_to(inimigo.global_position) > alcance:
			inimigos_rastreados.remove_at(i)
		i -= 1
	
	for inimigo in inimigos:
		if is_instance_valid(inimigo):
			var distancia = global_position.distance_to(inimigo.global_position)
			if distancia <= alcance and not inimigo in inimigos_rastreados:
				inimigos_rastreados.append(inimigo)
	
	if not is_instance_valid(alvo_atual) or not alvo_atual in inimigos_rastreados:
		alvo_atual = _encontrar_mais_proximo(inimigos_rastreados)


func _encontrar_mais_proximo(lista: Array[Node3D]) -> Node3D:
	var mais_proximo: Node3D = null
	var menor_distancia: float = alcance + 1.0
	
	for inimigo in lista:
		if is_instance_valid(inimigo):
			var distancia = global_position.distance_to(inimigo.global_position)
			if distancia < menor_distancia:
				menor_distancia = distancia
				mais_proximo = inimigo
	return mais_proximo


func _mirar_no_alvo() -> void:
	if is_instance_valid(alvo_atual):
		var posicao_alvo: Vector3 = alvo_atual.global_position
		posicao_alvo.y = global_position.y
		
		if global_position.distance_to(posicao_alvo) > 0.1:
			look_at(posicao_alvo, Vector3.UP)


# --- MODIFICADO: Agora cria o tiro em vez de dar dano instantâneo ---
func _atacar(inimigo: Node3D) -> void:
	pode_atacar = false
	
	if cena_projetil:
		var bala = cena_projetil.instantiate() as Node3D
		
		# Adiciona o tiro direto na raiz do mapa (para ele voar livre, independente da rotação da torre)
		get_tree().current_scene.add_child(bala)
		
		# Define onde o tiro vai nascer. Se a torre tiver um Marker3D chamado "PontoDisparo", nasce nele.
		# Caso contrário, nasce um pouco acima do centro da torre.
		if has_node("PontoDisparo"):
			bala.global_position = get_node("PontoDisparo").global_position
		else:
			bala.global_position = global_position + Vector3(0, 1.2, 0)
		
		# Ativa o projétil passando quem ele deve perseguir e o dano desta torre
		bala.configurar(inimigo, dano)
		print(name, " disparou munição visual!")
	else:
		# Sistema de segurança: se esquecerem de colocar a munição no Inspector, dá o dano antigo direto
		if inimigo.has_method("tomar_dano"):
			inimigo.tomar_dano(dano)
	
	await get_tree().create_timer(intervalo_ataque).timeout
	pode_atacar = true
