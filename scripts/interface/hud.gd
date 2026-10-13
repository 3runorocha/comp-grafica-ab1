extends CanvasLayer

const COR_SUBIU := Color(0.35, 0.95, 0.5)
const COR_DESCEU := Color(1.0, 0.45, 0.4)
const COR_NEUTRA := Color.WHITE

@export var player_path: NodePath = ^"../Player"

@onready var _rotulo: Label = $Contagem
@onready var _distancia: Label = $Distancia

var _player: Node3D = null

var _tween: Tween = null


# Conecta ao sinal da contagem e mostra o valor inicial
func _ready() -> void:
    _player = Comum.achar(self, player_path, "hud") as Node3D
    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _rotulo.text = str(GameState.contagem)
    _ajustar_pivo()


# Atualiza o numero e anima escala e cor conforme subiu ou desceu
func _on_contagem_mudou(anterior: int, novo: int) -> void:
    _rotulo.text = str(novo)
    _ajustar_pivo()

    if _tween != null and _tween.is_valid():
        _tween.kill()

    var cor := COR_SUBIU if novo > anterior else COR_DESCEU
    _rotulo.modulate = cor
    _rotulo.scale = Vector2.ONE * 1.18

    _tween = create_tween().set_parallel(true)
    _tween.tween_property(_rotulo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _tween.tween_property(_rotulo, "modulate", COR_NEUTRA, 0.4)


# Atualiza o texto da distancia percorrida
func _process(_delta: float) -> void:
    if _player == null:
        return
    _distancia.text = "%s m" % _com_milhar(int(absf(_player.global_position.z)))


# Centraliza o pivo do rotulo da contagem
func _ajustar_pivo() -> void:
    _rotulo.pivot_offset = _rotulo.size * 0.5


# Formata o numero com ponto separando os milhares
func _com_milhar(valor: int) -> String:
    var texto := str(valor)
    var saida := ""
    var contador := 0
    for i in range(texto.length() - 1, -1, -1):
        saida = texto[i] + saida
        contador += 1
        if contador % 3 == 0 and i > 0:
            saida = "." + saida
    return saida
