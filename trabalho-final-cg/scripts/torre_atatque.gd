extends Node3D

@export var dano: int = 25
@export var alcance: float = 8.0
@export var intervalo_ataque: float = 1.0

var pode_atacar := true
var alvo_atual: Node3D = null

func _process(_delta):
	if pode_atacar:
		alvo_atual = buscar_inimigo_no_alcance()
		
		if alvo_atual:
			atacar(alvo_atual)

func buscar_inimigo_no_alcance() -> Node3D:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var inimigo_mais_proximo: Node3D = null
	var menor_distancia := alcance
	
	for inimigo in inimigos:
		if not is_instance_valid(inimigo):
			continue
		
		var distancia = global_position.distance_to(inimigo.global_position)
		
		if distancia <= menor_distancia:
			menor_distancia = distancia
			inimigo_mais_proximo = inimigo
	
	return inimigo_mais_proximo

func atacar(inimigo: Node3D):
	pode_atacar = false
	
	if inimigo.has_method("tomar_dano"):
		inimigo.tomar_dano(dano)
		print(name, "atacou um inimigo!")
	
	await get_tree().create_timer(intervalo_ataque).timeout
	pode_atacar = true
