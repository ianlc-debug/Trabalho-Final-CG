extends Node3D

@export var ouro_por_ciclo: int = 25
@export var intervalo: float = 5.0

var gerenciador_ouro: Node = null
var timer_ouro: Timer = null

var nivel: int = 1
var nivel_maximo: int = 3


func _ready() -> void:
	add_to_group("construcoes")


func configurar_gerenciador_ouro(gerenciador: Node) -> void:
	gerenciador_ouro = gerenciador
	_iniciar_timer()


func _iniciar_timer() -> void:
	if timer_ouro:
		return
	
	timer_ouro = Timer.new()
	timer_ouro.wait_time = intervalo
	timer_ouro.one_shot = false
	
	add_child(timer_ouro)
	timer_ouro.timeout.connect(_gerar_ouro)
	timer_ouro.start()


func _gerar_ouro() -> void:
	if gerenciador_ouro and gerenciador_ouro.has_method("adicionar_ouro"):
		gerenciador_ouro.adicionar_ouro(ouro_por_ciclo)


func obter_custo_upgrade() -> int:
	if nivel >= nivel_maximo:
		return 0
	return int(125 * 1.5 * nivel)


func obter_valor_venda() -> int:
	var total = 125
	for i in range(1, nivel):
		total += int(125 * 1.5 * i)
	return int(total * 0.5)


func pode_melhorar() -> bool:
	return nivel < nivel_maximo


func melhorar() -> void:
	if nivel >= nivel_maximo:
		return
	
	nivel += 1
	ouro_por_ciclo = int(ouro_por_ciclo * 1.6)
	intervalo = intervalo * 0.85
	
	# Restart timer with new interval
	if timer_ouro:
		timer_ouro.wait_time = intervalo
		timer_ouro.start()
	
	# Visual feedback: scale up slightly
	scale = Vector3(1.0 + (nivel - 1) * 0.1, 1.0 + (nivel - 1) * 0.1, 1.0 + (nivel - 1) * 0.1)
	
	# Tint visually
	var cor_nivel = Color(1.0, 1.0, 1.0)
	if nivel == 2:
		cor_nivel = Color(0.8, 0.8, 0.9)
	elif nivel == 3:
		cor_nivel = Color(1.0, 0.84, 0.0)
	
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
