extends Node3D

@export var player_path: NodePath = ^"../Player"
@export var cena_par: PackedScene
@export var pares_ativos: int = 3
@export var tempo_entre_pares: float = 2.0
@export var tempo_minimo_entre_pares: float = 0.9
@export var portoes_ate_tempo_minimo: int = 140
@export var espacamento_minimo: float = 20.0
@export var distancia_final: float = 0.0
@export var finish_path: NodePath = ^"../FinishLine"
@export var margem_atras: float = 18.0
@export var opaco_em_espacamentos: float = 1.15
@export var some_em_espacamentos: float = 1.5
@export var recuo_camera: float = 8.0

const MULTIPLICADORES: Array[int] = [2, 3]
const DIVISORES: Array[int] = [2, 3]
const MARGEM_MIN: float = 1.20
const MARGEM_MAX: float = 1.40
const CONTAGEM_BAIXA: int = 12
const CONTAGEM_ALTA: int = 400

var _player: Node3D = null
var _fila: Array[Node3D] = []
var _gastos: Array[Node3D] = []
var _possiveis := ContagensPossiveis.new()
var _z_frente: float = 0.0
var _rng := RandomNumberGenerator.new()


# Cria os pares iniciais e posiciona a linha de chegada
func _ready() -> void:
    _rng.randomize()
    _player = Comum.achar(self, player_path, "level_generator") as Node3D
    if _player == null or cena_par == null:
        push_warning("level_generator: falta o jogador ou a cena do par.")
        return

    _configurar_chegada()
    _possiveis.definir(GameState.contagem)
    _z_frente = _player.global_position.z

    for i in pares_ativos:
        var par: Node3D = cena_par.instantiate()
        add_child(par)
        par.consumido.connect(_on_par_consumido)
        _posicionar_a_frente(par)
        _decidir(par)
        _fila.append(par)


func _process(_delta: float) -> void:
    if _player == null or _fila.is_empty():
        return
    # Aposenta o primeiro par se ele ficou para tras sem ser consumido
    var primeiro: Node3D = _fila[0]
    if primeiro.global_position.z > _player.global_position.z + 10.0:
        _aposentar(primeiro)

    # Recicla os pares gastos que ja ficaram atras da margem
    for par in _gastos.duplicate():
        if par.global_position.z > _player.global_position.z + margem_atras:
            _gastos.erase(par)
            _reciclar(par)


func _on_par_consumido(par: Node3D) -> void:
    _aposentar.call_deferred(par)


# Move o par da fila para a lista de gastos
func _aposentar(par: Node3D) -> void:
    if not _fila.has(par):
        return
    _fila.erase(par)
    _gastos.append(par)


# Leva o par para a frente da pista com novos valores
func _reciclar(par: Node3D) -> void:
    _recalcular_possiveis()
    par.rearmar()
    _posicionar_a_frente(par)
    _decidir(par)
    _fila.append(par)


# Posiciona o par a frente e ajusta gatilho e sumico
func _posicionar_a_frente(par: Node3D) -> void:
    var espacamento := _espacamento()
    _z_frente -= espacamento
    par.global_position = Vector3(0.0, 0.0, _z_frente)
    par.ajustar_gatilho(_velocidade() / 60.0 * 6.0)
    var nascimento := absf(_z_frente - _player.global_position.z) + recuo_camera
    par.ajustar_sumico(
        espacamento * opaco_em_espacamentos + recuo_camera,
        minf(espacamento * some_em_espacamentos + recuo_camera, nascimento * 0.95))


func _espacamento() -> float:
    return maxf(espacamento_minimo, _velocidade() * _tempo_leitura())


func _velocidade() -> float:
    return Comum.velocidade(_player)


# Calcula a janela de leitura, que encolhe conforme os portoes passam
func _tempo_leitura() -> float:
    var progresso := clampf(
        float(GameState.portoes_atravessados) / float(maxi(portoes_ate_tempo_minimo, 1)),
        0.0, 1.0)
    return lerpf(tempo_entre_pares, tempo_minimo_entre_pares, progresso)


# Sorteia os lados do par e configura os portoes
func _decidir(par: Node3D) -> void:
    var margem := _rng.randf_range(MARGEM_MIN, MARGEM_MAX)
    var fixo_vence := _rng.randf() < 0.5
    var lados := _sortear_lados(margem, fixo_vence)

    # Sorteia de que lado da pista fica cada portao
    if _rng.randf() < 0.5:
        par.configurar(lados[0], lados[1], lados[2], lados[3])
    else:
        par.configurar(lados[2], lados[3], lados[0], lados[1])

    _possiveis.avancar(par.operacoes())


# Escolhe o tipo de par e devolve [op proporcional, valor, op fixa, valor]
func _sortear_lados(margem: float, fixo_vence: bool) -> Array:
    var base := _possiveis.media()

    if _sortear_positivo(base):
        return _par_positivo(base, margem, fixo_vence)

    var divisor := _divisor_exato(_possiveis.mdc())
    if divisor > 0:
        return _par_com_divisao(base, divisor, margem, fixo_vence)

    if base <= float(CONTAGEM_ALTA):
        return _par_positivo(base, margem, fixo_vence)
    return _par_de_subtracoes(base, margem)


# Monta um par de multiplicar contra somar
func _par_positivo(base: float, margem: float, fixo_vence: bool) -> Array:
    var m: int = MULTIPLICADORES[_rng.randi() % MULTIPLICADORES.size()]
    var empate := base * float(m - 1)
    return [
        Estado.Op.MULTIPLICAR, m,
        Estado.Op.SOMAR, _calibrar(empate, margem, fixo_vence, true),
    ]


# Monta um par de dividir contra subtrair
func _par_com_divisao(base: float, divisor: int, margem: float, fixo_vence: bool) -> Array:
    var empate := base * float(divisor - 1) / float(divisor)
    return [
        Estado.Op.DIVIDIR, divisor,
        Estado.Op.SUBTRAIR, _calibrar(empate, margem, fixo_vence, false),
    ]


# Monta um par com dois lados de subtracao
func _par_de_subtracoes(base: float, margem: float) -> Array:
    var leve := base * 0.3
    var sobra := maxi(_possiveis.minimo() - 2, 2)
    return [
        Estado.Op.SUBTRAIR, _valor_par(leve * margem, 2),
        Estado.Op.SUBTRAIR, mini(_valor_par(leve, 2), sobra),
    ]


# Calcula o valor do lado fixo a partir do ponto de empate
func _calibrar(empate: float, margem: float, deve_vencer: bool, maior_e_melhor: bool) -> int:
    var fator := margem if deve_vencer == maior_e_melhor else 1.0 / margem
    return _valor_par(empate * fator, 2)


# Decide se o proximo par sera positivo
func _sortear_positivo(base: float) -> bool:
    if base < float(CONTAGEM_BAIXA):
        return true
    if base > float(CONTAGEM_ALTA):
        return false
    return _rng.randf() < 0.58


# Escolhe um divisor que divide exato o mdc dado
func _divisor_exato(mdc: int) -> int:
    if mdc <= 0:
        return -1
    var candidatos := DIVISORES.duplicate()
    candidatos.shuffle()
    # Procura primeiro um divisor que deixa o resultado par
    for d in candidatos:
        if mdc % (2 * d) == 0:
            return d
    for d in candidatos:
        if mdc % d == 0:
            return d
    return -1


# Arredonda para um numero par, nunca abaixo do minimo
func _valor_par(x: float, minimo: int) -> int:
    var v := int(round(x / 2.0)) * 2
    return maxi(v, minimo)


# Refaz o conjunto de contagens possiveis a partir da contagem atual
func _recalcular_possiveis() -> void:
    _possiveis.definir(GameState.contagem)
    for par in _fila:
        _possiveis.avancar(par.operacoes())


# Posiciona ou esconde a linha de chegada conforme distancia_final
func _configurar_chegada() -> void:
    var chegada := Comum.achar(self, finish_path, "level_generator") as Area3D
    if chegada == null:
        return
    if distancia_final > 0.0:
        chegada.global_position.z = -distancia_final
        chegada.visible = true
        chegada.monitoring = true
    else:
        chegada.visible = false
        chegada.monitoring = false
