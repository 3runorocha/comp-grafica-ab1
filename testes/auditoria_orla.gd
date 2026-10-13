extends Node

const NEBLINA := 0.005
const TOLERANCIA := 0.3
const VISIVEL_MINIMO := 0.02

var _cam: Camera3D = null
var _orla: Node3D = null
var _palmas: Array = []
var _n: int = 0
var _quadros: int = 6000
var _portoes: int = 0
var _z_orla: float = 0.0
var _antes: Array = []
var _saltos: Array = []


# Carrega a cena principal e coleta as malhas dos coqueiros
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
	_orla = cena.get_node("Orla") as Node3D
	cena.get_node("UI")._comecar(0)

	for no in _orla.get_children():
		var malha := _malha(no)
		if malha != null:
			_palmas.append(malha)
	_z_orla = _orla.position.z
	printerr("=== orla: %d coqueiros, portoes=%d, quadros=%d ===" % [
		_palmas.size(), _portoes, _quadros])


# Compara os coqueiros visiveis antes e depois de cada salto do tapete
func _process(_delta: float) -> void:
	if _cam == null:
		return
	if get_tree().paused:
		printerr("partida acabou no quadro %d" % _n)
		_relatorio()
		get_tree().quit()
		return
	_n += 1
	if _n % 1000 == 0:
		printerr("  quadro %d/%d" % [_n, _quadros])

	var saltou: bool = absf(_orla.position.z - _z_orla) > 1.0
	var agora: Array = _retrato()

	if saltou and not _antes.is_empty():
		_saltos.append(_comparar(_antes, agora))

	_z_orla = _orla.position.z
	_antes = agora
	if _n >= _quadros:
		_relatorio()
		get_tree().quit()


# Lista os coqueiros visiveis na tela
func _retrato() -> Array:
	var inverso: Transform3D = _cam.global_transform.affine_inverse()
	var saida: Array = []
	for malha in _palmas:
		var no: Node3D = (malha as Node3D).get_parent() as Node3D
		var pos: Vector3 = no.global_position
		var rel: Vector3 = inverso * pos
		if rel.z > 0.0:
			continue
		var frente: float = -rel.z
		var dist: float = pos.distance_to(_cam.global_position)
		var peso: float = _peso(dist)
		if peso < VISIVEL_MINIMO:
			continue
		if not _cam.is_position_in_frustum(pos):
			continue
		saida.append([pos, no.rotation.y, no.scale.x, peso, frente])
	return saida


# Calcula a visibilidade efetiva pela distancia
func _peso(dist: float) -> float:
	var t: float = exp(-NEBLINA * dist)
	var lo: float = _orla.distancia_sumico
	var hi: float = lo - _orla.faixa_sumico
	return t * clampf((lo - dist) / maxf(lo - hi, 0.001), 0.0, 1.0)


# Conta os coqueiros que sumiram e apareceram no salto
func _comparar(antes: Array, depois: Array) -> Dictionary:
	var casado_d := {}
	var sumiram: float = 0.0
	var n_sumiram: int = 0
	var dist_sumiram: float = 1e9

	var cestas := _indexar(depois)
	for a in antes:
		var j: int = _casar(a, depois, cestas, casado_d)
		if j < 0:
			sumiram += a[3]
			n_sumiram += 1
			dist_sumiram = minf(dist_sumiram, a[4])
		else:
			casado_d[j] = true

	var apareceram: float = 0.0
	var n_apareceram: int = 0
	var dist_apareceram: float = 1e9
	for j in depois.size():
		if not casado_d.has(j):
			apareceram += depois[j][3]
			n_apareceram += 1
			dist_apareceram = minf(dist_apareceram, depois[j][4])

	return {
		"q": _n,
		"na_tela": depois.size(),
		"sumiram": n_sumiram, "peso_sumiram": sumiram, "dist_sumiram": dist_sumiram,
		"apareceram": n_apareceram, "peso_apareceram": apareceram,
		"dist_apareceram": dist_apareceram,
	}


# Agrupa as posicoes em cestas espaciais
func _indexar(lista: Array) -> Dictionary:
	var cestas := {}
	for j in lista.size():
		var c: Vector3i = _cesta(lista[j][0])
		if not cestas.has(c):
			cestas[c] = []
		cestas[c].append(j)
	return cestas


func _cesta(v: Vector3) -> Vector3i:
	return Vector3i(int(floor(v.x / 2.0)), int(floor(v.y / 2.0)), int(floor(v.z / 2.0)))


# Procura um coqueiro correspondente nas cestas vizinhas
func _casar(a: Array, depois: Array, cestas: Dictionary, usados: Dictionary) -> int:
	var base: Vector3i = _cesta(a[0])
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var c := base + Vector3i(dx, dy, dz)
				if not cestas.has(c):
					continue
				for j in cestas[c]:
					if usados.has(j):
						continue
					var b: Array = depois[j]
					if (a[0] as Vector3).distance_to(b[0]) > TOLERANCIA:
						continue
					if absf(a[1] - b[1]) > 0.02:
						continue
					if absf(a[2] - b[2]) > 0.01:
						continue
					return j
	return -1


# Busca a primeira malha descendente do no
func _malha(no: Node) -> MeshInstance3D:
	for f in no.get_children():
		if f is MeshInstance3D:
			return f
		var r := _malha(f)
		if r != null:
			return r
	return null


# Imprime o resumo dos saltos
func _relatorio() -> void:
	print("\n=== saltos do tapete: %d ===" % _saltos.size())
	if _saltos.is_empty():
		print("nenhum salto no periodo medido.")
		return
	print("%6s %8s %9s %9s %10s %10s %10s" % [
		"quadro", "na tela", "sumiram", "apareceram", "peso sumiu", "peso surgiu", "dist min"])
	var soma_sum: float = 0.0
	var soma_ap: float = 0.0
	var pior: float = 0.0
	for s in _saltos:
		soma_sum += s["peso_sumiram"]
		soma_ap += s["peso_apareceram"]
		pior = maxf(pior, maxf(s["peso_sumiram"], s["peso_apareceram"]))
	for k in mini(10, _saltos.size()):
		var s: Dictionary = _saltos[k]
		var d: float = minf(s["dist_sumiram"], s["dist_apareceram"])
		print("%6d %8d %9d %10d %10.2f %11.2f %10.1f" % [
			s["q"], s["na_tela"], s["sumiram"], s["apareceram"],
			s["peso_sumiram"], s["peso_apareceram"], d if d < 1e8 else -1.0])
	print("\nmedia por salto: %.2f de peso sumindo, %.2f aparecendo" % [
		soma_sum / float(_saltos.size()), soma_ap / float(_saltos.size())])
	print("pior salto: %.2f de peso trocado" % pior)
	print("=== fim ===")
