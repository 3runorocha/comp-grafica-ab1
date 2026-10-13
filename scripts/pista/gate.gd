extends Area3D

signal atravessado(qual: Area3D)

@export var operacao: Estado.Op = Estado.Op.SOMAR:
    set(valor):
        operacao = valor
        _atualizar_visual()
@export var valor: int = 10:
    set(v):
        valor = v
        _atualizar_visual()

const COR_POSITIVA := Color(0.18, 0.72, 0.35)
const COR_NEGATIVA := Color(0.85, 0.24, 0.2)

const ALFA_CHEIO: float = 0.45

var _consumido: bool = false
var _material: StandardMaterial3D = null
var _opaco_ate: float = 0.0
var _some_em: float = 0.0

@onready var _placa: Label3D = $Placa
@onready var _painel: MeshInstance3D = $Painel


func _ready() -> void:
    _atualizar_visual()
    body_entered.connect(_on_body_entered)


# Atualiza o alfa do portao pela distancia ate a camera
func _process(_delta: float) -> void:
    _aplicar_sumico()


# Troca operacao e valor de uma vez
func configurar(nova_operacao: Estado.Op, novo_valor: int) -> void:
    operacao = nova_operacao
    valor = novo_valor
    _atualizar_visual()


# Ajusta a profundidade da caixa de gatilho
func ajustar_gatilho(profundidade: float) -> void:
    var forma := $Colisao.shape as BoxShape3D
    if forma != null:
        forma.size.z = maxf(profundidade, 3.0)


# Define a que distancia o portao fica opaco e a que distancia ele some
func ajustar_sumico(opaco_ate: float, some_em: float) -> void:
    _opaco_ate = opaco_ate
    _some_em = maxf(some_em, opaco_ate + 1.0)
    _aplicar_sumico()


# Calcula o alfa do painel e da placa pela distancia ate a camera
func _aplicar_sumico() -> void:
    if _material == null or _placa == null or _some_em <= 0.0:
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var dist := camera.global_position.distance_to(global_position)
    var visivel := clampf(
        (_some_em - dist) / (_some_em - _opaco_ate), 0.0, 1.0)
    _material.albedo_color.a = ALFA_CHEIO * visivel
    _placa.modulate.a = visivel


# Deixa o portao acionavel de novo
func rearmar() -> void:
    _consumido = false
    set_deferred(&"monitoring", true)


# Impede que este portao seja acionado
func desativar() -> void:
    _consumido = true
    set_deferred(&"monitoring", false)


# Avisa o par e aplica a operacao quando o lider atravessa
func _on_body_entered(_corpo: Node3D) -> void:
    if _consumido:
        return
    _consumido = true
    atravessado.emit(self)
    GameState.aplicar(operacao, valor)


# Atualiza texto da placa e cor do painel conforme a operacao
func _atualizar_visual() -> void:
    if not is_inside_tree():
        return
    var cor := COR_POSITIVA if Estado.e_positiva(operacao) else COR_NEGATIVA
    if _placa != null:
        _placa.text = Estado.texto(operacao, valor)
        _placa.modulate = Color.WHITE
    if _painel != null:
        var material := _painel.get_active_material(0)
        if material is StandardMaterial3D:
            _material = material.duplicate()
            _material.albedo_color = Color(cor.r, cor.g, cor.b, ALFA_CHEIO)
            _painel.material_override = _material
            _aplicar_sumico()
