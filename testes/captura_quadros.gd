extends Node

var _orla: Node3D = null
var _jogador: Node3D = null
var _n: int = 0
var _quadros: int = 240
var _portoes: int = 0
var _pasta: String = "user://quadros"
var _diario: FileAccess = null
var _sem: String = ""


# Le os argumentos, prepara o diario e inicia a partida
func _ready() -> void:
	process_priority = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		var p := arg.split("=")
		if p.size() != 2:
			continue
		match p[0]:
			"portoes": _portoes = int(p[1])
			"quadros": _quadros = int(p[1])
			"pasta": _pasta = p[1]
			"sem": _sem = p[1]

	Engine.max_fps = 60

	DirAccess.make_dir_recursive_absolute(_pasta)
	_diario = FileAccess.open(_pasta + "/diario.csv", FileAccess.WRITE)
	_diario.store_line("quadro,z_jogador,z_orla,contagem,portoes")

	var cena: Node = load("res://scenes/Main.tscn").instantiate()
	cena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cena)
	GameState.portoes_atravessados = _portoes
	_orla = cena.get_node("Orla") as Node3D
	_jogador = cena.get_node("Player") as Node3D
	cena.get_node("UI")._comecar(0)
	_desligar(cena)

	# Grava cada quadro depois de desenhado
	RenderingServer.frame_post_draw.connect(_gravar)
	printerr("=== captura: %d quadros em %s ===" % [_quadros, _pasta])


# Desliga o recurso indicado pelo argumento sem
func _desligar(cena: Node) -> void:
	if _sem == "":
		return
	if _sem == "sombra":
		(cena.get_node("Sol") as DirectionalLight3D).shadow_enabled = false
	elif _sem == "msaa":
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	elif _sem == "fade":
		for no in _orla.get_children():
			var malha := _primeira_malha(no)
			if malha == null:
				continue
			var mat := malha.get_surface_override_material(0)
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).distance_fade_mode = 					BaseMaterial3D.DISTANCE_FADE_DISABLED
				break
	elif _sem == "mataCurta":
		(cena.get_node("Sol") as DirectionalLight3D).directional_shadow_max_distance = 30.0
		for no in _orla.get_children():
			var mm := _primeira_malha(no)
			if mm != null and absf((no as Node3D).position.x) > 12.0:
				mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif _sem == "sombra8k":
		RenderingServer.directional_shadow_atlas_set_size(8192, true)
	elif _sem == "sombra16k":
		RenderingServer.directional_shadow_atlas_set_size(16384, true)
	elif _sem == "filtroalto":
		RenderingServer.directional_soft_shadow_filter_set_quality(
			RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	elif _sem == "bias":
		var sb := cena.get_node("Sol") as DirectionalLight3D
		sb.shadow_normal_bias = 3.0
		sb.shadow_bias = 0.2
	elif _sem == "sombracurta":
		(cena.get_node("Sol") as DirectionalLight3D).directional_shadow_max_distance = 25.0
	elif _sem == "sombrasuave":
		var sol := cena.get_node("Sol") as DirectionalLight3D
		sol.light_size = 0.6
		sol.shadow_blur = 3.0
	elif _sem == "sombra4":
		(cena.get_node("Sol") as DirectionalLight3D).directional_shadow_mode = 			DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	elif _sem == "mataSemSombra":
		for no in _orla.get_children():
			var m := _primeira_malha(no)
			if m != null and absf((no as Node3D).position.x) > 12.0:
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif _sem == "coqueiroSemSombra":
		for no in _orla.get_children():
			var m := _primeira_malha(no)
			if m != null:
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif _sem == "coqueiro":
		for no in _orla.get_children():
			(no as Node3D).visible = false
	printerr("rodada SEM %s" % _sem)


# Busca a primeira malha descendente do no
func _primeira_malha(no: Node) -> MeshInstance3D:
	for f in no.get_children():
		if f is MeshInstance3D:
			return f
		var r := _primeira_malha(f)
		if r != null:
			return r
	return null


# Grava o quadro renderizado em disco
func _gravar() -> void:
	if _n >= _quadros:
		return
	# Encerra a captura se a partida acabou
	if get_tree().paused and _n > 2:
		printerr("partida acabou no quadro %d, encerrando a captura" % _n)
		_diario.close()
		_quadros = _n
		get_tree().quit()
		return
	_n += 1
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png("%s/q%04d.png" % [_pasta, _n])
	_diario.store_line("%d,%.3f,%.3f,%d,%d" % [
		_n, _jogador.global_position.z, _orla.position.z,
		GameState.contagem, GameState.portoes_atravessados])
	if _n % 60 == 0:
		printerr("  %d/%d" % [_n, _quadros])
	if _n >= _quadros:
		_diario.close()
		printerr("captura pronta")
		get_tree().quit()
