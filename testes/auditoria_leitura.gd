extends Node

var _cam: Camera3D = null
var _jogador: Node3D = null
var _gerador: Node3D = null
var _n: int = 0
var _quadros: int = 4000
var _portoes: int = 0
var _visto: Dictionary = {}
var _chegadas: Array = []


# Carrega a cena principal e inicia a partida
func _ready() -> void:
	process_priority = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		var p := arg.split("=")
		if p.size() == 2 and p[0] == "portoes":
			_portoes = int(p[1])
		elif p.size() == 2 and p[0] == "quadros":
			_quadros = int(p[1])

	var cena: Node = load("res://scenes/Main.tscn").instantiate()
	cena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cena)
	GameState.portoes_atravessados = _portoes
	_cam = cena.get_node("Camera") as Camera3D
	_jogador = cena.get_node("Player") as Node3D
	_gerador = cena.get_node("Gerador") as Node3D
	cena.get_node("UI")._comecar(0)
	printerr("=== leitura: portoes=%d quadros=%d ===" % [_portoes, _quadros])


# Acompanha o alfa de cada portao ate o jogador chegar nele
func _process(_delta: float) -> void:
	if _gerador == null:
		return
	if get_tree().paused:
		printerr("partida acabou no quadro %d" % _n)
		_relatorio()
		get_tree().quit()
		return
	_n += 1

	var v: float = Comum.velocidade(_jogador)
	var z_jogador: float = _jogador.global_position.z

	for par in _gerador.get_children():
		for portao in (par as Node3D).get_children():
			if not (portao is Area3D):
				continue
			var painel := portao.get_node_or_null(^"Painel") as MeshInstance3D
			if painel == null:
				continue
			var mat := painel.material_override
			if not (mat is StandardMaterial3D):
				continue
			var alfa: float = (mat as StandardMaterial3D).albedo_color.a / 0.45
			var frente: float = portao.global_position.z - z_jogador
			if frente > 0.0:
				continue
			var falta: float = -frente

			# Registra quando o portao fica opaco e quando o jogador chega
			var id: int = portao.get_instance_id()
			if not _visto.has(id) or _visto[id]["falta"] < falta:
				_visto[id] = {"falta": falta, "opaco_em": -1.0, "v": v}
			var e: Dictionary = _visto[id]
			e["falta"] = falta
			if e["opaco_em"] < 0.0 and alfa >= 0.98:
				e["opaco_em"] = falta
				e["v"] = v
			if falta < 2.0 and not e.has("fechado"):
				e["fechado"] = true
				_chegadas.append({
					"opaco_em": e["opaco_em"], "v": e["v"], "alfa": alfa,
				})

	if _n >= _quadros:
		_relatorio()
		get_tree().quit()


# Imprime a antecedencia com que os portoes ficaram opacos
func _relatorio() -> void:
	print("\n=== %d chegadas de portao ===" % _chegadas.size())
	if _chegadas.is_empty():
		return
	var segundos: Array = []
	var nunca: int = 0
	for c in _chegadas:
		if c["opaco_em"] < 0.0:
			nunca += 1
			continue
		segundos.append(c["opaco_em"] / maxf(c["v"], 0.001))
	if segundos.is_empty():
		print("NENHUM portao chegou a ficar opaco.")
		return
	segundos.sort()
	print("antecedencia com que o portao fica opaco, em segundos de viagem:")
	print("  pior %.2f   p10 %.2f   mediana %.2f   melhor %.2f" % [
		segundos[0], segundos[int(float(segundos.size()) * 0.1)],
		segundos[segundos.size() / 2], segundos[segundos.size() - 1]])
	print("portoes que nunca ficaram opacos: %d de %d" % [nunca, _chegadas.size()])
	var abaixo: int = 0
	for s in segundos:
		if s < 1.0:
			abaixo += 1
	print("chegaram com menos de 1 s de leitura opaca: %d (%.1f%%)" % [
		abaixo, 100.0 * float(abaixo) / float(segundos.size())])
	print("=== fim ===")
