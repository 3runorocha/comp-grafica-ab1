extends Area3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)


# Conclui a partida quando o lider cruza a linha
func _on_body_entered(_corpo: Node3D) -> void:
    GameState.concluir()
