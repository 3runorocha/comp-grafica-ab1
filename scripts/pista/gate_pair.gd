extends Node3D

signal consumido(par: Node3D)

@onready var _divisor: MeshInstance3D = get_node_or_null(^"Divisor")

var _mat_divisor: StandardMaterial3D = null


func _ready() -> void:
    for portao in _portoes():
        portao.atravessado.connect(_on_atravessado)


# Desativa o outro lado quando um portao e atravessado
func _on_atravessado(vencedor: Area3D) -> void:
    for portao in _portoes():
        if portao != vencedor:
            portao.desativar()
    consumido.emit(self)


# Define os dois lados de uma vez
func configurar(op_esq: Estado.Op, val_esq: int, op_dir: Estado.Op, val_dir: int) -> void:
    var lados := _portoes()
    if lados.size() != 2:
        return
    lados[0].configurar(op_esq, val_esq)
    lados[1].configurar(op_dir, val_dir)


# Retorna as operacoes atuais, na ordem esquerda e direita
func operacoes() -> Array:
    var saida: Array = []
    for portao in _portoes():
        saida.append([portao.operacao, portao.valor])
    return saida


# Repassa a profundidade de gatilho aos dois lados
func ajustar_gatilho(profundidade: float) -> void:
    for portao in _portoes():
        portao.ajustar_gatilho(profundidade)


# Repassa aos dois lados as distancias de opacidade e sumico
func ajustar_sumico(opaco_ate: float, some_em: float) -> void:
    for portao in _portoes():
        portao.ajustar_sumico(opaco_ate, some_em)
    _sumico_do_divisor(opaco_ate, some_em)


# Configura o sumico por distancia no material do divisor
func _sumico_do_divisor(opaco_ate: float, some_em: float) -> void:
    if _divisor == null:
        return
    if _mat_divisor == null:
        var base := _divisor.material_override
        if not (base is StandardMaterial3D):
            return
        _mat_divisor = (base as StandardMaterial3D).duplicate()
        _mat_divisor.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
        _divisor.material_override = _mat_divisor
    _mat_divisor.distance_fade_min_distance = some_em
    _mat_divisor.distance_fade_max_distance = opaco_ate


# Devolve os dois lados ao estado acionavel
func rearmar() -> void:
    for portao in _portoes():
        portao.rearmar()


# Lista os portoes filhos do par
func _portoes() -> Array[Area3D]:
    var lista: Array[Area3D] = []
    for filho in get_children():
        if filho is Area3D:
            lista.append(filho)
    return lista
