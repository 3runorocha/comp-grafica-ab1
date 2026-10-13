extends Node

const NEBLINA := 0.005

var _cam: Camera3D = null
var _jogador: Node3D = null
var _n: int = 0
var _quadros: int = 900
var _portoes: int = 0
var _eventos: Array = []
var _por_quadro: Array = []

var _lista: Array = []
var _mat: Array = []
var _caixa: Array = []
var _px := PackedFloat32Array()
var _py := PackedFloat32Array()
var _pz := PackedFloat32Array()
var _peso := PackedFloat32Array()
var _esc := PackedFloat32Array()
var _vis := PackedByteArray()
var _valido := PackedByteArray()


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
	cena.get_node("UI")._comecar(0)
	printerr("=== auditoria: portoes=%d quadros=%d ===" % [_portoes, _quadros])


# Detecta as mudancas de cada no visual na tela
func _process(delta: float) -> void:
	if _cam == null:
		return
	if get_tree().paused:
		printerr("partida acabou no quadro %d" % _n)
		_relatorio()
		get_tree().quit()
		return
	_n += 1
	if _n == 1 or _n % 120 == 0:
		_montar_lista()
	if _n % 100 == 0:
		printerr("  quadro %d/%d" % [_n, _quadros])

	var v: float = Comum.velocidade(_jogador)
	var limite: float = v * delta * 2.0 + 1.0
	var soma: float = 0.0
	var cam: Vector3 = _cam.global_position

	for i in _lista.size():
		var no: VisualInstance3D = _lista[i]
		var pos: Vector3 = no.global_position
		var dx: float = pos.x - cam.x
		var dy: float = pos.y - cam.y
		var dz: float = pos.z - cam.z
		var dist: float = sqrt(dx * dx + dy * dy + dz * dz)
		var vis: int = 1 if no.is_visible_in_tree() else 0
		var esc: float = no.global_basis.get_scale().length()
		var peso: float = _calcular_peso(no, i, dist)

		if _valido[i] == 1:
			var mx: float = pos.x - _px[i]
			var my: float = pos.y - _py[i]
			var mz: float = pos.z - _pz[i]
			var andou: float = sqrt(mx * mx + my * my + mz * mz)
			var tipo: String = ""
			if andou > limite:
				tipo = "salto"
			elif vis != _vis[i]:
				tipo = "visivel"
			elif absf(peso - _peso[i]) > 0.02:
				tipo = "alfa"
			elif _esc[i] > 0.001 and absf(esc / _esc[i] - 1.0) > 0.02:
				tipo = "escala"

			# Registra o evento se o no estiver na tela
			if tipo != "" and not _rotulo(no).begins_with("Orla") and _na_tela(no, i):
				var ang: float = _tamanho(no, i) / maxf(dist, 1.0)
				var forca: float = maxf(peso, _peso[i]) * ang * ang * 1000.0
				soma += forca
				_eventos.append({
					"q": _n, "no": _rotulo(no), "tipo": tipo,
					"dist": dist, "peso": peso, "forca": forca, "andou": andou,
					"dpeso": absf(peso - _peso[i]),
				})

		# Guarda o estado atual para o proximo quadro
		_px[i] = pos.x
		_py[i] = pos.y
		_pz[i] = pos.z
		_vis[i] = vis
		_esc[i] = esc
		_peso[i] = peso
		_valido[i] = 1

	_por_quadro.append(soma)
	if _n >= _quadros:
		_relatorio()
		get_tree().quit()


# Refaz a lista de nos visuais mantendo o estado anterior
func _montar_lista() -> void:
	var antigos: Dictionary = {}
	for i in _lista.size():
		antigos[(_lista[i] as Node).get_instance_id()] = i
	var nova: Array = _visuais(get_tree().root)

	var px := PackedFloat32Array()
	var py := PackedFloat32Array()
	var pz := PackedFloat32Array()
	var peso := PackedFloat32Array()
	var esc := PackedFloat32Array()
	var vis := PackedByteArray()
	var val := PackedByteArray()
	px.resize(nova.size())
	py.resize(nova.size())
	pz.resize(nova.size())
	peso.resize(nova.size())
	esc.resize(nova.size())
	vis.resize(nova.size())
	val.resize(nova.size())

	for i in nova.size():
		var id: int = (nova[i] as Node).get_instance_id()
		if antigos.has(id):
			var j: int = antigos[id]
			px[i] = _px[j]
			py[i] = _py[j]
			pz[i] = _pz[j]
			peso[i] = _peso[j]
			esc[i] = _esc[j]
			vis[i] = _vis[j]
			val[i] = _valido[j]
		else:
			val[i] = 0

	_lista = nova
	_px = px
	_py = py
	_pz = pz
	_peso = peso
	_esc = esc
	_vis = vis
	_valido = val
	_mat.clear()
	_mat.resize(nova.size())
	_caixa.clear()
	_caixa.resize(nova.size())
	if _n == 1:
		printerr("nos visuais: %d" % nova.size())


# Calcula a visibilidade efetiva do no
func _calcular_peso(no: VisualInstance3D, i: int, dist: float) -> float:
	var t: float = exp(-NEBLINA * dist)
	var a: float = 1.0
	if no is Label3D:
		a = (no as Label3D).modulate.a
	var mat: Material = _material(no, i)
	if mat is StandardMaterial3D:
		var s := mat as StandardMaterial3D
		a *= s.albedo_color.a
		if s.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED:
			var lo: float = s.distance_fade_min_distance
			var hi: float = s.distance_fade_max_distance
			if lo > hi:
				a *= clampf((lo - dist) / maxf(lo - hi, 0.001), 0.0, 1.0)
			else:
				a *= clampf((dist - lo) / maxf(hi - lo, 0.001), 0.0, 1.0)
	return clampf(a * t, 0.0, 1.0)


# Obtem o material do no
func _material(no: VisualInstance3D, i: int) -> Material:
	if not (no is GeometryInstance3D):
		return null
	var g := no as GeometryInstance3D
	if g.material_override != null:
		return g.material_override
	if _mat[i] != null:
		return _mat[i]
	var achado: Material = null
	if no is MeshInstance3D:
		var m := no as MeshInstance3D
		if m.get_surface_override_material_count() > 0:
			achado = m.get_surface_override_material(0)
		if achado == null and m.mesh != null and m.mesh.get_surface_count() > 0:
			achado = m.mesh.surface_get_material(0)
	_mat[i] = achado
	return achado


# Obtem a caixa delimitadora do no
func _caixa_de(no: VisualInstance3D, i: int) -> AABB:
	if _caixa[i] == null:
		_caixa[i] = no.get_aabb()
	return _caixa[i]


# Calcula o tamanho do no no mundo
func _tamanho(no: VisualInstance3D, i: int) -> float:
	var caixa: AABB = _caixa_de(no, i)
	var s: Vector3 = no.global_basis.get_scale()
	return Vector3(caixa.size.x * s.x, caixa.size.y * s.y, caixa.size.z * s.z).length()


# Verifica se algum canto da caixa esta no frustum
func _na_tela(no: VisualInstance3D, i: int) -> bool:
	var caixa: AABB = _caixa_de(no, i)
	for k in 8:
		if _cam.is_position_in_frustum(no.global_transform * caixa.get_endpoint(k)):
			return true
	return false


# Coleta todos os nos visuais da arvore
func _visuais(raiz: Node) -> Array:
	var saida: Array = []
	var pilha: Array = [raiz]
	while not pilha.is_empty():
		var no: Node = pilha.pop_back()
		if no is VisualInstance3D and no != _cam:
			saida.append(no)
		for f in no.get_children():
			pilha.append(f)
	return saida


# Gera um rotulo agrupavel para o no
func _rotulo(no: Node) -> String:
	var caminho: String = String(no.get_path())
	for chave in ["Orla", "Gerador", "Crowd", "Chao", "Player", "FinishLine"]:
		if caminho.contains("/" + chave):
			return chave + ":" + no.get_class()
	return no.name + ":" + no.get_class()


# Imprime o resumo da auditoria
func _relatorio() -> void:
	print("\n--- quadros com mais mudanca na tela ---")
	var indices: Array = []
	for i in _por_quadro.size():
		indices.append(i)
	indices.sort_custom(func(a, b): return _por_quadro[a] > _por_quadro[b])
	var ordem: Array = _por_quadro.duplicate()
	ordem.sort()
	print("mediana por quadro: %.3f   pior: %.3f" % [
		ordem[ordem.size() / 2], ordem[ordem.size() - 1]])
	for k in mini(12, indices.size()):
		var q: int = indices[k]
		print("  quadro %4d  forca %8.2f" % [q + 1, _por_quadro[q]])

	print("\n--- eventos na tela, agrupados ---")
	var grupos: Dictionary = {}
	for ev in _eventos:
		var chave: String = ev["no"] + " / " + ev["tipo"]
		if not grupos.has(chave):
			grupos[chave] = {"n": 0, "forca": 0.0, "dmin": 1e9, "dmax": 0.0, "pmax": 0.0, "amax": 0.0, "quadros": {}}
		var g: Dictionary = grupos[chave]
		g["n"] += 1
		g["forca"] += ev["forca"]
		g["dmin"] = minf(g["dmin"], ev["dist"])
		g["dmax"] = maxf(g["dmax"], ev["dist"])
		g["pmax"] = maxf(g["pmax"], ev["peso"])
		g["amax"] = maxf(g["amax"], ev["andou"])
		g["quadros"][ev["q"]] = true

	var chaves: Array = grupos.keys()
	chaves.sort_custom(func(a, b): return grupos[a]["forca"] > grupos[b]["forca"])
	print("%-32s %6s %7s %9s %9s %9s %6s %7s" % [
		"no / evento", "n", "quadros", "forca", "dist min", "dist max", "visib", "salto"])
	for c in chaves:
		var g: Dictionary = grupos[c]
		print("%-32s %6d %7d %9.1f %9.1f %9.1f %6.2f %7.2f" % [
			c, g["n"], g["quadros"].size(), g["forca"], g["dmin"], g["dmax"],
			g["pmax"], g["amax"]])
	print("\ntotal de eventos na tela: %d" % _eventos.size())

	print("\n--- dez eventos isolados mais fortes ---")
	var ordenados: Array = _eventos.duplicate()
	ordenados.sort_custom(func(a, b): return a["forca"] > b["forca"])
	for k in mini(16, ordenados.size()):
		var ev: Dictionary = ordenados[k]
		print("  q%4d  %-26s %-8s dist %6.1f  visib %.2f  salto %7.2f  dalfa %.2f  forca %8.2f" % [
			ev["q"], ev["no"], ev["tipo"], ev["dist"], ev["peso"], ev["andou"],
			ev["dpeso"], ev["forca"]])
	print("=== fim ===")
