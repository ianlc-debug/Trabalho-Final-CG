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

var nivel: int = 1
var nivel_maximo: int = 3

func _ready() -> void:
	add_to_group("construcoes")


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
		if "gelo" in name.to_lower() or "gelo" in scene_file_path.to_lower():
			bala.set("eh_gelo", true)
		print(name, " disparou munição visual!")
	else:
		# Sistema de segurança: se esquecerem de colocar a munição no Inspector, dá o dano antigo direto
		if inimigo.has_method("tomar_dano"):
			inimigo.tomar_dano(dano)
	
	await get_tree().create_timer(intervalo_ataque).timeout
	pode_atacar = true


func obter_custo_upgrade() -> int:
	if nivel >= nivel_maximo:
		return 0
	return int(custo_compra_original() * 1.5 * nivel)


func obter_valor_venda() -> int:
	var total = custo_compra_original()
	for i in range(1, nivel):
		total += int(custo_compra_original() * 1.5 * i)
	return int(total * 0.5)


func custo_compra_original() -> int:
	var nome_l = name.to_lower()
	if "canhao" in nome_l or "canhão" in nome_l:
		return 100
	elif "balista" in nome_l:
		return 75
	elif "catapulta" in nome_l:
		return 150
	elif "gelo" in nome_l:
		return 125
	return 100


func pode_melhorar() -> bool:
	return nivel < nivel_maximo


func melhorar() -> void:
	if nivel >= nivel_maximo:
		return
	
	nivel += 1
	dano = int(dano * 1.4)
	alcance = alcance * 1.15
	intervalo_ataque = intervalo_ataque * 0.85
	
	# Visual feedforward: scale up slightly
	scale = Vector3(1.0 + (nivel - 1) * 0.1, 1.0 + (nivel - 1) * 0.1, 1.0 + (nivel - 1) * 0.1)
	
	# Apply visual color shift recursivelly
	var cor_nivel = Color(1.0, 1.0, 1.0)
	if nivel == 2:
		cor_nivel = Color(0.8, 0.8, 0.9) # Silver
	elif nivel == 3:
		cor_nivel = Color(1.0, 0.84, 0.0) # Gold
	
	_aplicar_cor_recursivo(self, cor_nivel)


func _aplicar_cor_recursivo(no: Node, cor: Color) -> void:
	if no is MeshInstance3D:
		var mat = no.get_active_material(0)
		if mat:
			var novo_mat = mat.duplicate()
			if novo_mat is StandardMaterial3D:
				novo_mat.albedo_color = novo_mat.albedo_color * cor
				no.material_override = novo_mat
	for filho in no.get_children():
		_aplicar_cor_recursivo(filho, cor)
