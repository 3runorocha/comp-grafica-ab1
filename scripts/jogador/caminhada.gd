extends Node3D

@export var passada_graus: float = 26.0
@export var bracada_graus: float = 19.0
@export var altura_do_salto: float = 0.045
@export var velocidade_do_salto_cheio: float = 40.0

var _perna_esq: Node3D = null
var _perna_dir: Node3D = null
var _braco_esq: Node3D = null
var _braco_dir: Node3D = null
var _corpo: Node3D = null
var _altura_base: float = 0.0
var _player: Node = null
var _fase: float = 0.0
var _ciclo: float = 0.0


# Acha o jogador, o corpo e os membros do modelo
func _ready() -> void:
    _player = Comum.jogador(get_tree())
    _corpo = get_parent() as Node3D
    _coletar(get_parent())
    if _corpo != null:
        _altura_base = _corpo.position.y


# Retorna o ponto atual do ciclo de passo
func ciclo() -> float:
    return _ciclo + _fase


# Define a fase do ciclo desta instancia
func definir_fase(fase: float) -> void:
    _fase = fase


func _process(delta: float) -> void:
    # Avanca o ciclo e balanca as pernas
    var velocidade := Comum.velocidade(_player)
    _ciclo += Comum.cadencia_passo(velocidade) * delta

    var angulo := TAU * (_ciclo + _fase) * 0.5
    var onda := sin(angulo)
    var abertura := deg_to_rad(passada_graus) * onda
    if _perna_esq != null:
        _perna_esq.rotation.x = abertura
    if _perna_dir != null:
        _perna_dir.rotation.x = -abertura

    # Balanca os bracos em oposicao as pernas
    var bracada := deg_to_rad(bracada_graus) * onda
    if _braco_esq != null:
        _braco_esq.rotation.x = -bracada
    if _braco_dir != null:
        _braco_dir.rotation.x = bracada

    # Sobe e desce o corpo a cada passo
    if _corpo != null:
        var forca := clampf(velocidade / velocidade_do_salto_cheio, 0.3, 1.0)
        _corpo.position.y = _altura_base + altura_do_salto * forca * absf(sin(angulo))


# Procura recursivamente as pernas e os bracos do modelo
func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D:
            if filho.name.begins_with("perna_esq"):
                _perna_esq = filho
            elif filho.name.begins_with("perna_dir"):
                _perna_dir = filho
            elif filho.name.begins_with("braco_esq"):
                _braco_esq = filho
            elif filho.name.begins_with("braco_dir"):
                _braco_dir = filho
        _coletar(filho)
