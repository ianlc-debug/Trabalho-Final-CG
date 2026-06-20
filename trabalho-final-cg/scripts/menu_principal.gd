extends Control

# Caminhos para os arquivos das fases
@export var cena_primavera: PackedScene
@export var cena_inverno: PackedScene

# Referências das Telas
@onready var tela_inicial: Control = $TelaInicial
@onready var tela_fases: Control = $TelaFases
@onready var tela_creditos: Control = $TelaCreditos

# Botões da Tela Inicial
@onready var botao_jogar: Button = $TelaInicial/BotaoJogar
@onready var botao_creditos: Button = $TelaInicial/BotaoCreditos

# Botões da Tela de Fases
@onready var botao_primavera: Button = $TelaFases/BotaoPrimavera
@onready var botao_inverno: Button = $TelaFases/BotaoInverno
@onready var botao_voltar_fases: Button = $TelaFases/BotaoVoltar

# Botão da Tela de Créditos
@onready var botao_voltar_creditos: Button = $TelaCreditos/BotaoVoltarCreditos


func _ready() -> void:
	# Estado inicial: apenas a tela principal visível
	tela_inicial.visible = true
	tela_fases.visible = false
	tela_creditos.visible = false
	
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# Configurar cursor de mãozinha para os novos botões (se não fez no editor)
	botao_voltar_creditos.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Conexões da Tela Inicial
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_creditos.pressed.connect(_on_botao_creditos_pressed)
	
	# Conexões da Tela de Fases
	botao_primavera.pressed.connect(_on_botao_primavera_pressed)
	botao_inverno.pressed.connect(_on_botao_inverno_pressed)
	botao_voltar_fases.pressed.connect(_on_botao_voltar_fases_pressed)
	
	# Conexão da Tela de Créditos
	botao_voltar_creditos.pressed.connect(_on_botao_voltar_creditos_pressed)


# --- NAVEGAÇÃO ---

func _on_botao_jogar_pressed() -> void:
	tela_inicial.visible = false
	tela_fases.visible = true

func _on_botao_creditos_pressed() -> void:
	# Abre a tela de créditos
	tela_inicial.visible = false
	tela_creditos.visible = true

func _on_botao_voltar_fases_pressed() -> void:
	tela_fases.visible = false
	tela_inicial.visible = true

func _on_botao_voltar_creditos_pressed() -> void:
	# Volta dos créditos para a tela inicial
	tela_creditos.visible = false
	tela_inicial.visible = true


# --- SELEÇÃO DE FASES ---

func _on_botao_primavera_pressed() -> void:
	if cena_primavera:
		get_tree().change_scene_to_packed(cena_primavera)
	else:
		get_tree().change_scene_to_file("res://Scenes/mapa_primavera.tscn")

func _on_botao_inverno_pressed() -> void:
	if cena_inverno:
		get_tree().change_scene_to_packed(cena_inverno)
	else:
		get_tree().change_scene_to_file("res://Scenes/mapa_inverno.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			var novo_estado = not Salvamento.is_inverno_concluido()
			Salvamento.salvar_inverno_concluido(novo_estado)
			print("MENU DEBUG: Conclusao do Inverno alterada para: ", novo_estado)
