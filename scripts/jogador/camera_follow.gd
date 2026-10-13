extends Camera3D

@export var alvo_path: NodePath = ^"../Player"
@export var deslocamento: Vector3 = Vector3(0.0, 5.5, 8.0)
@export var altura_do_olhar: float = 1.6
@export var acompanha_lateral: float = 0.6
@export var suavidade: float = 6.0

var _alvo: Node3D = null


# Acha o alvo e posiciona e orienta a camera
func _ready() -> void:
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    _alvo = Comum.achar(self, alvo_path, "camera_follow") as Node3D
    if _alvo == null:
        return
    global_position = _posicao_desejada()
    _fixar_orientacao()


# Segue o alvo, suavizando so o lateral
func _process(delta: float) -> void:
    if _alvo == null:
        return

    var desejada := _posicao_desejada()
    var peso := Comum.peso(suavidade, delta)
    global_position = Vector3(
        lerpf(global_position.x, desejada.x, peso),
        desejada.y,
        desejada.z)


# Define a inclinacao fixa da camera em direcao ao ponto de olhar
func _fixar_orientacao() -> void:
    var ate_o_olhar := Vector3(0.0, altura_do_olhar, 0.0) - deslocamento
    var chao := sqrt(ate_o_olhar.x * ate_o_olhar.x + ate_o_olhar.z * ate_o_olhar.z)
    rotation = Vector3(atan2(ate_o_olhar.y, chao), 0.0, 0.0)


# Calcula a posicao alvo da camera a partir do alvo e do deslocamento
func _posicao_desejada() -> Vector3:
    var alvo := _alvo_posicao()
    var base := alvo + deslocamento
    base.x = alvo.x * acompanha_lateral
    return base


func _alvo_posicao() -> Vector3:
    return Comum.posicao_suave(_alvo)
