extends Node

var _n: int = 0
var _tocou_efeito: bool = false


# Carrega a cena principal e inicia a partida
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cena: Node = load("res://scenes/Main.tscn").instantiate()
	cena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cena)
	cena.get_node("UI")._comecar(0)


# Imprime o estado da trilha e dos efeitos apos 90 quadros
func _process(_delta: float) -> void:
	_n += 1
	for voz in Audio.get_children():
		if voz is AudioStreamPlayer and voz.bus == &"Efeitos" and voz.playing:
			_tocou_efeito = true
	if _n < 90:
		return

	var m: AudioStreamPlayer = null
	for f in Audio.get_children():
		if f is AudioStreamPlayer and f.bus == &"Musica":
			m = f
			break

	print("=== audio ===")
	if m == null or m.stream == null:
		print("trilha: NENHUMA carregada")
	else:
		var loop := "?"
		if "loop" in m.stream:
			loop = str(m.stream.loop)
		print("trilha: %s" % m.stream.get_class())
		print("  tocando: %s" % m.playing)
		print("  em loop: %s" % loop)
		print("  duracao: %.1f s" % m.stream.get_length())
		print("  posicao: %.2f s" % m.get_playback_position())
	print("efeito de passo tocou: %s" % _tocou_efeito)
	print("=== fim ===")
	get_tree().quit()
