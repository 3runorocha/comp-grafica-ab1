class_name Comum
extends Object


# Busca um no pelo caminho
static func achar(dono: Node, caminho: NodePath, _quem: String) -> Node:
    return dono.get_node_or_null(caminho)


# Calcula o peso de interpolacao independente da taxa de quadros
static func peso(constante: float, delta: float) -> float:
    return 1.0 - exp(-constante * delta)


# Retorna a posicao do no interpolada entre os passos de fisica
static func posicao_suave(alvo: Node3D) -> Vector3:
    return alvo.get_global_transform_interpolated().origin


# Retorna a velocidade de avanco do lider, ou o valor padrao
static func velocidade(alvo: Node, padrao: float = 12.0) -> float:
    if alvo != null and "velocidade_frente" in alvo:
        return alvo.velocidade_frente
    return padrao


# Calcula quantos passos por segundo na velocidade dada
static func cadencia_passo(velocidade: float) -> float:
    return clampf(velocidade / 5.0, 3.0, 7.0)


# Retorna o jogador pelo grupo "jogador"
static func jogador(arvore: SceneTree) -> Node:
    return arvore.get_first_node_in_group(&"jogador")
