extends Node3D

@export var cena_coqueiro: PackedScene
@export var periodo: float = 130.0
@export var cauda: float = 195.0
@export var alcance: float = 700.0
@export var espacamento: float = 13.0
@export var afastamento: float = 8.2
@export var fileiras_grama: int = 8
@export var passo_entre_fileiras: float = 4.4
@export var distancia_sumico: float = 660.0
@export var faixa_sumico: float = 160.0
@export var projeta_sombra: bool = true

var _player: Node3D = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.seed = 20261005
    _player = Comum.jogador(get_tree()) as Node3D
    if cena_coqueiro == null:
        push_warning("roadside: cena_coqueiro nao definida.")
        return
    _plantar()


# Desloca o cenario em saltos de um periodo acompanhando o jogador
func _process(_delta: float) -> void:
    if _player == null:
        return
    var z := Comum.posicao_suave(_player).z
    position.z = floorf(z / periodo) * periodo


# Monta o tapete de coqueiros, com o sorteio repetindo a cada periodo
func _plantar() -> void:
    var materiais := _materiais_que_somem()
    var por_periodo := int(round(periodo / espacamento))
    var vagas := int(ceil((cauda + alcance) / espacamento))

    var fileiras: Array[float] = [-afastamento, afastamento]
    for k in fileiras_grama:
        fileiras.append(afastamento + float(k + 1) * passo_entre_fileiras)

    for f in fileiras.size():
        # Sorteia desvio, giro e tamanho de um periodo
        var desvios: Array[float] = []
        var giros: Array[float] = []
        var tamanhos: Array[float] = []
        for i in por_periodo:
            desvios.append(_rng.randf_range(-0.7, 0.7))
            giros.append(_rng.randf_range(0.0, TAU))
            tamanhos.append(_rng.randf_range(0.82, 1.18))

        var recuo := espacamento * (float(f) / float(fileiras.size()))

        # Instancia os coqueiros da fileira
        for i in vagas:
            var k: int = i % por_periodo
            var arvore: Node3D = cena_coqueiro.instantiate()
            add_child(arvore)
            arvore.position = Vector3(
                fileiras[f] + desvios[k],
                0.0,
                cauda - float(i) * espacamento - recuo)
            arvore.rotation.y = giros[k]
            arvore.scale = Vector3.ONE * tamanhos[k]
            _aplicar_sumico(arvore, materiais)
            _aplicar_sombra(arvore)


# Cria os materiais do coqueiro com sumico por distancia
func _materiais_que_somem() -> Array[Material]:
    var modelo: Node3D = cena_coqueiro.instantiate()
    var malha := _achar_malha(modelo)
    var saida: Array[Material] = []
    if malha != null:
        for i in malha.mesh.get_surface_count():
            var base := malha.mesh.surface_get_material(i)
            if base is StandardMaterial3D:
                var copia: StandardMaterial3D = base.duplicate()
                copia.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
                copia.distance_fade_min_distance = distancia_sumico
                copia.distance_fade_max_distance = distancia_sumico - faixa_sumico
                saida.append(copia)
            else:
                saida.append(base)
    modelo.queue_free()
    return saida


# Aplica os materiais com sumico na malha do coqueiro
func _aplicar_sumico(arvore: Node3D, materiais: Array[Material]) -> void:
    var malha := _achar_malha(arvore)
    if malha == null:
        return
    for i in mini(materiais.size(), malha.get_surface_override_material_count()):
        malha.set_surface_override_material(i, materiais[i])


# Desliga a sombra do coqueiro quando projeta_sombra esta falso
func _aplicar_sombra(arvore: Node3D) -> void:
    if projeta_sombra:
        return
    var malha := _achar_malha(arvore)
    if malha != null:
        malha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# Procura a primeira MeshInstance3D na arvore do no
func _achar_malha(no: Node) -> MeshInstance3D:
    for f in no.get_children():
        if f is MeshInstance3D:
            return f
        var r := _achar_malha(f)
        if r != null:
            return r
    return null
