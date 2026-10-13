extends Node

var _cam: Camera3D = null
var _orla: Node3D = null
var _gerador: Node3D = null
var _n: int = 0
var _quadros: int = 2000
var _portoes: int = 0

var _z_orla: float = 0.0
var _contagem_ant: int = -1
var _portoes_ant: int = -1
var _deltas: Array = []
var _eventos: Array = []
var _objetos: Array = []
var _recursos: Array = []
var _memoria: Array = []
var _chamadas: Array = []
var _nos: Array = []
const AQUECIMENTO: int = 120


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

	# Desliga o limite de quadros e o vsync
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var cena: Node = load("res://scenes/Main.tscn").instantiate()
	cena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cena)
	GameState.portoes_atravessados = _portoes
	_cam = cena.get_node("Camera") as Camera3D
	_orla = cena.get_node("Orla") as Node3D
	_gerador = cena.get_node("Gerador") as Node3D
	cena.get_node("UI")._comecar(0)
	_z_orla = _orla.position.z
	printerr("=== quadro: portoes=%d quadros=%d ===" % [_portoes, _quadros])


# Registra o tempo de quadro, os contadores do motor e os eventos de jogo
func _process(delta: float) -> void:
	if _orla == null:
		return
	if get_tree().paused:
		printerr("partida acabou no quadro %d" % _n)
		_relatorio()
		get_tree().quit()
		return
	_n += 1

	var saltou_tapete: bool = absf(_orla.position.z - _z_orla) > 1.0
	var mudou_contagem: bool = GameState.contagem != _contagem_ant
	var passou_portao: bool = GameState.portoes_atravessados != _portoes_ant
	_z_orla = _orla.position.z
	_contagem_ant = GameState.contagem
	_portoes_ant = GameState.portoes_atravessados

	if _n > AQUECIMENTO:
		_deltas.append(delta)
		_objetos.append(Performance.get_monitor(Performance.OBJECT_COUNT))
		_recursos.append(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
		_memoria.append(Performance.get_monitor(Performance.MEMORY_STATIC))
		_chamadas.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		_nos.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if saltou_tapete or mudou_contagem or passou_portao:
			_eventos.append({
				"q": _n, "delta": delta,
				"tapete": saltou_tapete,
				"contagem": mudou_contagem,
				"portao": passou_portao,
			})

	if _n >= _quadros:
		_relatorio()
		get_tree().quit()


# Imprime as estatisticas de tempo de quadro
func _relatorio() -> void:
	if _deltas.size() < 20:
		print("quadros de menos para medir.")
		return
	var ordem: Array = _deltas.duplicate()
	ordem.sort()
	var mediana: float = ordem[ordem.size() / 2]
	var p99: float = ordem[int(float(ordem.size()) * 0.99)]
	print("\n=== tempo de quadro, %d quadros ===" % _deltas.size())
	print("mediana %.2f ms   p99 %.2f ms   pior %.2f ms" % [
		mediana * 1000.0, p99 * 1000.0, ordem[ordem.size() - 1] * 1000.0])

	# Conta os quadros acima do limite de engasgo
	var limite: float = mediana * 3.0
	print("limite de engasgo: %.2f ms (3x a mediana)" % (limite * 1000.0))

	var engasgos: int = 0
	for d in _deltas:
		if d > limite:
			engasgos += 1
	print("quadros acima do limite: %d (%.2f%%)" % [
		engasgos, 100.0 * float(engasgos) / float(_deltas.size())])

	print("\n--- o engasgo bate com que evento? ---")
	_linha("salto do tapete", "tapete", limite, mediana)
	_linha("mudanca de contagem", "contagem", limite, mediana)
	_linha("portao atravessado", "portao", limite, mediana)

	print("\n--- quadros de evento mais lentos ---")
	var ordenados: Array = _eventos.duplicate()
	ordenados.sort_custom(func(a, b): return a["delta"] > b["delta"])
	for k in mini(12, ordenados.size()):
		var e: Dictionary = ordenados[k]
		var quem: String = ""
		if e["tapete"]:
			quem += "tapete "
		if e["contagem"]:
			quem += "contagem "
		if e["portao"]:
			quem += "portao "
		print("  q%5d  %7.2f ms  %5.1fx a mediana  %s" % [
			e["q"], e["delta"] * 1000.0, e["delta"] / mediana, quem])
	print("=== fim ===")


# Imprime as estatisticas de um tipo de evento
func _linha(rotulo: String, chave: String, limite: float, mediana: float) -> void:
	var n: int = 0
	var lentos: int = 0
	var pior: float = 0.0
	var soma: float = 0.0
	for e in _eventos:
		if not e[chave]:
			continue
		n += 1
		soma += e["delta"]
		pior = maxf(pior, e["delta"])
		if e["delta"] > limite:
			lentos += 1
	if n == 0:
		print("%-22s nao ocorreu" % rotulo)
		return
	print("%-22s %4d vezes, %3d acima do limite (%5.1f%%), medio %6.2f ms (%4.1fx), pior %7.2f ms (%5.1fx)" % [
		rotulo, n, lentos, 100.0 * float(lentos) / float(n),
		soma / float(n) * 1000.0, soma / float(n) / mediana,
		pior * 1000.0, pior / mediana])
