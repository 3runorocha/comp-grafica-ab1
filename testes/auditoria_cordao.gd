extends Node

var _cam: Camera3D = null
var _cordao: Node3D = null
var _corpos: Array = []
var _n: int = 0
var _quadros: int = 5000
var _portoes: int = 0

var _escala_ant: float = -1.0
var _espalhamento_ant: float = -1.0
var _recuo_ant: float = -1.0
var _contagem_ant: int = -1
var _z_ant := PackedFloat32Array()
var _s_ant := PackedFloat32Array()

var _lider: Node3D = null
var _folga_minima: float = 1e9
var _quadros_sobrepondo: int = 0
var _trocas: Array = []
var _quadros_com_passo: int = 0
var _maior_passo_z: float = 0.0
var _soma_passo_z: float = 0.0


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
	_cordao = cena.get_node("Crowd") as Node3D
	_lider = cena.get_node("Player") as Node3D
	cena.get_node("UI")._comecar(0)
	_corpos = _cordao.get("_corpos")
	_z_ant.resize(_corpos.size())
	_s_ant.resize(_corpos.size())
	printerr("=== cordao: %d corpos no pool, portoes=%d ===" % [_corpos.size(), _portoes])


# Mede a cada quadro a folga ate o lider e as mudancas do cordao
func _process(_delta: float) -> void:
	if _cordao == null:
		return
	if get_tree().paused:
		printerr("partida acabou no quadro %d" % _n)
		_relatorio()
		get_tree().quit()
		return
	_n += 1
	if _n % 1000 == 0:
		printerr("  quadro %d/%d" % [_n, _quadros])

	var escala: float = _cordao.get("_escala_corpo")
	var espalhamento: float = _cordao.get("_espalhamento")
	var recuo: float = _cordao.get("_recuo")
	var visiveis: int = _cordao.get("_visiveis")

	# Mede a folga entre o cordao e o lider
	var z_lider: float = Comum.posicao_suave(_lider).z
	var folga: float = 1e9
	for corpo in _corpos:
		if corpo.visible and corpo.scale.x > 0.2:
			folga = minf(folga, corpo.global_position.z - z_lider)
	if folga < 1e8:
		_folga_minima = minf(_folga_minima, folga)
		if folga < 0.0:
			_quadros_sobrepondo += 1

	# Mede a variacao de escala de cada corpo
	var passo_z: float = 0.0
	var passo_escala: float = 0.0
	for i in _corpos.size():
		var corpo: Node3D = _corpos[i]
		if not corpo.visible:
			_z_ant[i] = 0.0
			_s_ant[i] = 0.0
			continue
		var s: float = corpo.scale.x
		if _s_ant[i] > 0.0001:
			passo_escala = maxf(passo_escala, absf(s / _s_ant[i] - 1.0))
		_s_ant[i] = s

	# Registra as mudancas de escala e de geometria da formacao
	if _escala_ant >= 0.0:
		var d_escala: float = absf(escala - _escala_ant) / maxf(_escala_ant, 0.001)
		var d_esp: float = absf(espalhamento - _espalhamento_ant)
		var d_recuo: float = absf(recuo - _recuo_ant)
		passo_z = d_recuo + d_esp * sqrt(float(maxi(visiveis - 1, 0)))
		if passo_z > 0.001 or d_escala > 0.001:
			_trocas.append({
				"q": _n, "contagem": _contagem_ant, "nova": visiveis,
				"d_escala": d_escala, "passo_z": passo_z,
				"escala": escala, "dist": _distancia_do_cordao(),
			})
		if passo_z > 0.01:
			_quadros_com_passo += 1
			_soma_passo_z += passo_z
			_maior_passo_z = maxf(_maior_passo_z, passo_z)

	_escala_ant = escala
	_espalhamento_ant = espalhamento
	_recuo_ant = recuo
	_contagem_ant = visiveis

	if _n >= _quadros:
		_relatorio()
		get_tree().quit()


# Distancia da camera ate o primeiro corpo visivel
func _distancia_do_cordao() -> float:
	for corpo in _corpos:
		if corpo.visible:
			return _cam.global_position.distance_to(corpo.global_position)
	return -1.0


# Imprime o resumo da medicao
func _relatorio() -> void:
	print("\n=== cordao: %d quadros medidos ===" % _n)
	print("quadros com tranco de vaga acima de 0.01: %d (%.1f%%)" % [
		_quadros_com_passo, 100.0 * float(_quadros_com_passo) / float(maxi(_n, 1))])
	if _quadros_com_passo > 0:
		print("tranco medio: %.3f unidades   maior: %.3f unidades" % [
			_soma_passo_z / float(_quadros_com_passo), _maior_passo_z])
	print("folga minima ate o lider: %.3f   quadros com cordao a frente dele: %d" % [
		_folga_minima, _quadros_sobrepondo])
	print("\n--- mudancas de contagem: o que muda para TODOS de uma vez ---")
	print("%6s %9s %7s %10s %9s %9s" % [
		"quadro", "contagem", "nova", "d escala", "tranco Z", "dist cam"])
	var mostradas: int = 0
	for t in _trocas:
		if t["contagem"] == t["nova"]:
			continue
		print("%6d %9d %7d %9.1f%% %9.3f %9.1f" % [
			t["q"], t["contagem"], t["nova"], t["d_escala"] * 100.0,
			t["passo_z"], t["dist"]])
		mostradas += 1
		if mostradas >= 16:
			break
	print("\ntotal de trocas de contagem: %d" % _contar_trocas())
	print("=== fim ===")


# Conta as trocas de contagem registradas
func _contar_trocas() -> int:
	var n: int = 0
	for t in _trocas:
		if t["contagem"] != t["nova"]:
			n += 1
	return n
