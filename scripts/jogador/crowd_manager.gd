extends Node3D

const MAX_VISIVEL: int = 400
const ANGULO_AUREO: float = 2.39996323

@export var lider_path: NodePath = ^"../Player"
@export var cena_guerreiro: PackedScene
@export var espalhamento_base: float = 0.67
@export var escala_maxima: float = 1.0
@export var escala_minima: float = 0.26
@export var folga_atras: float = 0.35
@export var altura: float = 0.0
@export var velocidade_seguir: float = 9.0
@export var meia_largura_util: float = 5.7

var _lider: Node3D = null
var _corpos: Array[Node3D] = []
var _visiveis: int = 0
var _espalhamento: float = 0.76
var _escala_corpo: float = 1.0
var _recuo: float = 1.0
var _espalhamento_alvo: float = 0.76
var _escala_alvo: float = 1.0


func _ready() -> void:
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    _lider = Comum.achar(self, lider_path, "crowd_manager") as Node3D
    if _lider == null:
        return
    if cena_guerreiro == null:
        return

    # Cria o pool de corpos, cada um com sua fase de caminhada
    for i in MAX_VISIVEL:
        var corpo: Node3D = cena_guerreiro.instantiate()
        add_child(corpo)
        corpo.visible = false
        var caminhada := corpo.find_child("Caminhada", true, false)
        if caminhada != null:
            caminhada.definir_fase(2.0 * float(i) / float(MAX_VISIVEL))
        _corpos.append(corpo)

    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _aplicar(GameState.contagem, true)


func _on_contagem_mudou(_anterior: int, novo: int) -> void:
    _aplicar(novo, false)


func _aplicar(contagem: int, instantaneo: bool) -> void:
    _visiveis = clampi(contagem, 0, MAX_VISIVEL)

    # Calcula a escala e o espalhamento alvo para o grupo caber na ponte
    var passos := sqrt(float(maxi(_visiveis - 1, 1)))
    var cabe := meia_largura_util / (espalhamento_base * passos)
    _escala_alvo = clampf(minf(escala_maxima, cabe), escala_minima, escala_maxima)

    _espalhamento_alvo = espalhamento_base * _escala_alvo
    _recalcular_recuo()

    if instantaneo:
        _escala_corpo = _escala_alvo
        _espalhamento = _espalhamento_alvo
    _recalcular_recuo()

    # Acende os corpos que entram e ajusta a visibilidade na montagem
    var centro := _centro_da_formacao()
    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        if i < _visiveis and not corpo.visible:
            corpo.visible = true
            corpo.global_position = _vaga(i, centro)
            corpo.scale = Vector3.ONE * (_escala_alvo if instantaneo else _escala_alvo * 0.1)
        elif instantaneo:
            corpo.visible = i < _visiveis
            corpo.scale = Vector3.ONE * _escala_corpo


func _process(delta: float) -> void:
    if _lider == null:
        return

    # Aproxima escala e espalhamento dos alvos e recalcula o recuo
    var mudanca := Comum.peso(5.0, delta)
    _escala_corpo = lerpf(_escala_corpo, _escala_alvo, mudanca)
    _espalhamento = lerpf(_espalhamento, _espalhamento_alvo, mudanca)
    _recalcular_recuo()

    var centro := _centro_da_formacao()
    var ritmo := velocidade_seguir * maxf(1.0, Comum.velocidade(_lider) / 12.0)

    # Ajusta a escala de cada corpo e o move ate sua vaga
    var passo := Comum.peso(6.0, delta)
    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        if not corpo.visible:
            continue

        var alvo := _escala_corpo if i < _visiveis else 0.0
        corpo.scale = corpo.scale.lerp(Vector3.ONE * alvo, passo)
        if alvo == 0.0 and corpo.scale.x < 0.02:
            corpo.visible = false
            continue

        var vaga := _vaga(i, centro)
        var atraso := 1.0 - 0.45 * (float(i) / float(MAX_VISIVEL))
        var peso := Comum.peso(ritmo * atraso, delta)
        corpo.global_position = Vector3(
            lerpf(corpo.global_position.x, vaga.x, peso),
            vaga.y,
            vaga.z)



# Retorna o centro da formacao limitado a largura da ponte
func _centro_da_formacao() -> Vector3:
    var centro := Comum.posicao_suave(_lider)
    var margem := maxf(meia_largura_util - _raio_maximo(), 0.0)
    centro.x = clampf(centro.x, -margem, margem)
    return centro


# Calcula a posicao global da vaga na espiral da formacao
func _vaga(indice: int, centro: Vector3) -> Vector3:
    var angulo := float(indice) * ANGULO_AUREO
    var raio := _espalhamento * sqrt(float(indice))
    return Vector3(
        clampf(centro.x + cos(angulo) * raio, -meia_largura_util, meia_largura_util),
        altura,
        centro.z + sin(angulo) * raio + _recuo
    )


# Retorna o raio lateral maximo da formacao
func _raio_maximo() -> float:
    return _espalhamento * sqrt(float(maxi(_visiveis - 1, 0)))


# Recalcula o recuo do grupo em relacao ao lider
func _recalcular_recuo() -> void:
    var mais_adiantado := 0.0
    for i in _visiveis:
        var angulo := float(i) * ANGULO_AUREO
        var raio := _espalhamento * sqrt(float(i))
        mais_adiantado = minf(mais_adiantado, sin(angulo) * raio)
    _recuo = folga_atras - mais_adiantado
