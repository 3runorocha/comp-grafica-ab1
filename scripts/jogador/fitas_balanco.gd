extends Node3D

@export var player_path: NodePath = ^".."
@export var ondulacao_graus: float = 9.0
@export var atraso_entre_fitas: float = 0.45
@export var inclinacao_graus: float = 30.0
@export var velocidade_referencia: float = 45.0
@export var reacao_lateral_graus: float = 18.0

var _fitas: Array[Node3D] = []
var _caminhada: Node = null
var _player: Node = null
var _t: float = 0.0


# Acha o jogador, as fitas e a caminhada do modelo
func _ready() -> void:
    _player = get_node_or_null(player_path)
    _coletar(self)
    _caminhada = find_child("Caminhada", true, false)


func _process(delta: float) -> void:
    _t += delta

    # Calcula a inclinacao pela velocidade e o empurrao lateral
    var velocidade := Comum.velocidade(_player)
    var vento := clampf(velocidade / velocidade_referencia, 0.0, 1.0)
    var deitar := -deg_to_rad(inclinacao_graus) * vento

    var lateral := 0.0
    if _player != null and "velocity" in _player:
        lateral = -deg_to_rad(reacao_lateral_graus) * clampf(_player.velocity.x / 10.0, -1.0, 1.0)

    # Aplica a ondulacao do passo em cada fita
    var passo := TAU * _ciclo_do_passo()
    for i in _fitas.size():
        var forca := 0.3 + 0.7 * vento
        var onda := deg_to_rad(ondulacao_graus) * forca * sin(passo - float(i) * atraso_entre_fitas)
        _fitas[i].rotation = Vector3(deitar + onda, 0.0, lateral)


# Retorna o ciclo de passo da caminhada
func _ciclo_do_passo() -> float:
    if _caminhada == null:
        return 0.0
    return _caminhada.ciclo()


# Procura recursivamente os nos de fita
func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D and filho.name.begins_with("fita"):
            _fitas.append(filho)
        _coletar(filho)
