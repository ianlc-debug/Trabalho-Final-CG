extends Node
class_name Salvamento

const SAVE_PATH = "user://progresso_jogo.json"

static func salvar_inverno_concluido(concluido: bool = true) -> void:
	var dados = {
		"inverno_concluido": concluido
	}
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()
		print("Progresso salvo: Fase de Inverno concluída = ", concluido)

static func is_inverno_concluido() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if arquivo:
		var conteudo = arquivo.get_as_text()
		arquivo.close()
		var json = JSON.new()
		if json.parse(conteudo) == OK:
			var dados = json.get_data()
			if dados is Dictionary and dados.has("inverno_concluido"):
				return dados["inverno_concluido"]
	return false
