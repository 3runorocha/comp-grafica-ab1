extends CanvasLayer

@export var player_path: NodePath = ^"../Player"

@onready var _menu: Control = $Menu
@onready var _vitoria: Control = $Vitoria
@onready var _derrota: Control = $Derrota
@onready var _resultado: Label = $Vitoria/Caixa/Resultado
@onready var _placar_derrota: Label = $Derrota/Caixa/Mensagem

var _player: Node = null
var _paineis: Array[Control] = []


# Reinicia o estado, conecta sinais e botoes e abre o menu inicial
func _ready() -> void:
    GameState.reiniciar()
    _player = Comum.achar(self, player_path, "ui")

    _paineis = [_menu, _vitoria, _derrota]

    GameState.fim_de_jogo.connect(_on_derrota)
    GameState.vitoria.connect(_on_vitoria)

    $Menu/Caixa/BotaoTeclado.pressed.connect(_comecar.bind(0))
    $Menu/Caixa/BotaoMouse.pressed.connect(_comecar.bind(1))
    for painel in [_vitoria, _derrota]:
        painel.get_node("Caixa/BotaoReiniciar").pressed.connect(_reiniciar)

    _mostrar(_menu)
    $Menu/Caixa/BotaoTeclado.grab_focus()


# Reinicia a partida ao confirmar num painel de fim
func _unhandled_input(evento: InputEvent) -> void:
    if not evento.is_action_pressed(&"ui_accept"):
        return
    if _fim_aberto():
        _reiniciar()


func _fim_aberto() -> bool:
    return _vitoria.visible or _derrota.visible


# Mostra so o painel escolhido e pausa a partida enquanto houver painel
func _mostrar(painel: Control) -> void:
    for outro in _paineis:
        outro.visible = outro == painel

    var pausado := painel != null
    get_tree().paused = pausado

    if pausado:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Fecha o menu e inicia a partida no modo escolhido
func _comecar(modo: int) -> void:
    _mostrar(null)
    if _player != null:
        _player.definir_modo(modo)


# Mostra o painel de vitoria com o resultado
func _on_vitoria() -> void:
    _resultado.text = "Voce chegou com %d guerreiros, %d metros" % [GameState.contagem, _metros()]
    _mostrar(_vitoria)
    $Vitoria/Caixa/BotaoReiniciar.grab_focus()


# Mostra o painel de derrota com a distancia percorrida
func _on_derrota() -> void:
    _placar_derrota.text = "Voce percorreu %d metros" % _metros()
    _mostrar(_derrota)
    $Derrota/Caixa/BotaoReiniciar.grab_focus()


# Despausa, reinicia o estado e recarrega a cena
func _reiniciar() -> void:
    get_tree().paused = false
    GameState.reiniciar()
    get_tree().reload_current_scene()


# Retorna a distancia percorrida pelo jogador em metros
func _metros() -> int:
    if _player == null:
        return 0
    return int(absf(_player.global_position.z))
