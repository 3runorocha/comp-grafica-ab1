extends Node

const PASTA := "res://assets/audio/"
const VOZES := 8
const MUSICA := [
    "musica_loop.ogg", "musica_loop.mp3", "musica_loop.wav",
    "musica.ogg", "musica.mp3", "musica.wav",
]
const EXTENSOES := [".ogg", ".mp3", ".wav"]

var _musica: AudioStreamPlayer = null
var _vozes: Array[AudioStreamPlayer] = []
var _proxima: int = 0
var _cache: Dictionary = {}

var _player: Node = null
var _ate_o_passo: float = 0.0
var _pe_direito: bool = false


# Cria os tocadores de musica e de efeitos e liga o sinal da contagem
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _musica = AudioStreamPlayer.new()
    _musica.bus = &"Musica"
    add_child(_musica)
    _tocar_musica()

    for i in VOZES:
        var voz := AudioStreamPlayer.new()
        voz.bus = &"Efeitos"
        add_child(voz)
        _vozes.append(voz)

    GameState.contagem_mudou.connect(_on_contagem_mudou)


func _process(delta: float) -> void:
    _passos(delta)


# Toca um efeito pelo nome do arquivo, sem extensao
func tocar(nome: String) -> void:
    var fluxo: AudioStream = null
    for ext in EXTENSOES:
        fluxo = _carregar(nome + ext)
        if fluxo != null:
            break
    if fluxo == null:
        return
    var voz := _vozes[_proxima]
    _proxima = (_proxima + 1) % VOZES
    voz.stream = fluxo
    voz.play()


# Toca o som do portao conforme a contagem subiu ou desceu
func _on_contagem_mudou(anterior: int, novo: int) -> void:
    if GameState.portoes_atravessados <= 0:
        return
    tocar("portao_positivo" if novo > anterior else "portao_negativo")


# Toca os passos na cadencia da corrida, alternando os dois pes
func _passos(delta: float) -> void:
    if get_tree().paused:
        return
    if _player == null or not is_instance_valid(_player):
        _player = Comum.jogador(get_tree())
        if _player == null:
            return

    var por_segundo := Comum.cadencia_passo(Comum.velocidade(_player))
    _ate_o_passo -= delta
    if _ate_o_passo > 0.0:
        return
    _ate_o_passo = 1.0 / por_segundo
    tocar("passo_b" if _pe_direito else "passo_a")
    _pe_direito = not _pe_direito


# Carrega um arquivo de audio, guardando o resultado em cache
func _carregar(arquivo: String) -> AudioStream:
    if _cache.has(arquivo):
        return _cache[arquivo]
    var caminho := PASTA + arquivo
    if not ResourceLoader.exists(caminho):
        _cache[arquivo] = null
        return null
    var fluxo: AudioStream = load(caminho)
    _cache[arquivo] = fluxo
    return fluxo


# Procura a trilha entre os nomes aceitos e toca em loop
func _tocar_musica() -> void:
    for nome in MUSICA:
        var fluxo := _carregar(nome)
        if fluxo != null:
            _musica.stream = _em_loop(fluxo)
            _musica.play()
            return


# Liga o loop no fluxo de audio conforme o formato
func _em_loop(fluxo: AudioStream) -> AudioStream:
    if fluxo is AudioStreamWAV:
        fluxo.loop_mode = AudioStreamWAV.LOOP_FORWARD
        fluxo.loop_begin = 0
    elif fluxo is AudioStreamOggVorbis:
        fluxo.loop = true
    elif fluxo is AudioStreamMP3:
        fluxo.loop = true
    return fluxo
