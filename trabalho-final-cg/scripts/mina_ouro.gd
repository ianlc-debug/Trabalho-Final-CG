extends Node3D

@export var ouro_por_ciclo: int = 25
@export var intervalo: float = 5.0

var gerenciador_ouro: Node = null
var timer_ouro: Timer = null


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
