extends Node3D

@export var player_path: NodePath = ^"../Player"

var _player: Node3D = null


func _ready() -> void:
    _player = Comum.achar(self, player_path, "ground_follow") as Node3D


# Move o chao junto com o jogador em Z
func _process(_delta: float) -> void:
    if _player == null:
        return
    global_position.z = Comum.posicao_suave(_player).z
