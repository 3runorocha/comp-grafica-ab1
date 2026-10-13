extends CharacterBody3D

enum Modo {
    TECLADO,
    MOUSE,
}

@export var modo: Modo = Modo.TECLADO
@export var velocidade_frente: float = 12.0
@export var velocidade_maxima: float = 0.0
@export var ganho_por_portao: float = 1.1
@export var velocidade_lateral: float = 10.0
@export var meia_largura_pista: float = 4.0
@export var sensibilidade_mouse: float = 0.012
@export var suavidade: float = 12.0

var _alvo_x: float = 0.0
var _velocidade_inicial: float = 12.0


func _ready() -> void:
    _velocidade_inicial = velocidade_frente
    _alvo_x = global_position.x
    _aplicar_modo()


# Troca a fonte de controle
func definir_modo(novo: Modo) -> void:
    modo = novo
    _aplicar_modo()


# Trata Esc, recaptura do cursor e movimento do mouse
func _unhandled_input(evento: InputEvent) -> void:
    if evento.is_action_pressed(&"ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return

    if modo != Modo.MOUSE:
        return

    if evento is InputEventMouseButton and evento.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        return

    if evento is InputEventMouseMotion:
        _mover_alvo(evento.relative.x * sensibilidade_mouse)


# Le o teclado e move o lider para frente e ate o alvo lateral
func _physics_process(delta: float) -> void:
    _acelerar()

    if modo == Modo.TECLADO:
        var eixo := Input.get_axis(&"mover_esquerda", &"mover_direita")
        if not is_zero_approx(eixo):
            _mover_alvo(eixo * velocidade_lateral * delta)

    var erro := _alvo_x - global_position.x
    velocity.x = clampf(erro * suavidade, -velocidade_lateral, velocidade_lateral)
    velocity.z = -velocidade_frente
    velocity.y = 0.0

    move_and_slide()


# Aumenta a velocidade de avanco conforme os portoes atravessados
func _acelerar() -> void:
    var subida := ganho_por_portao * float(GameState.portoes_atravessados)
    velocidade_frente = _velocidade_inicial + subida
    if velocidade_maxima > 0.0:
        velocidade_frente = minf(velocidade_frente, velocidade_maxima)


# Desloca o alvo lateral dentro dos limites da pista
func _mover_alvo(quanto: float) -> void:
    _alvo_x = clampf(_alvo_x + quanto, -meia_largura_pista, meia_largura_pista)


# Ajusta o modo do cursor conforme a fonte de controle
func _aplicar_modo() -> void:
    if DisplayServer.get_name() == "headless":
        return
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if modo == Modo.MOUSE else Input.MOUSE_MODE_VISIBLE
