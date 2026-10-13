class_name ContagensPossiveis
extends RefCounted

var _valores: Array[int] = []


func _init(inicial: int = 1) -> void:
    definir(inicial)


# Recomeca o conjunto a partir de uma contagem conhecida
func definir(inicial: int) -> void:
    _valores = [maxi(inicial, 1)]


# Avanca o conjunto por um par, aplicando os dois lados a cada contagem
func avancar(operacoes: Array) -> void:
    var saida: Array[int] = []
    for n in _valores:
        for lado in operacoes:
            var r: int = Estado.resultado(lado[0], lado[1], n)
            if r > 0 and not saida.has(r):
                saida.append(r)
    _valores = saida if not saida.is_empty() else [Estado.CONTAGEM_INICIAL] as Array[int]


# Calcula a media do conjunto
func media() -> float:
    if _valores.is_empty():
        return float(Estado.CONTAGEM_INICIAL)
    var soma := 0
    for n in _valores:
        soma += n
    return float(soma) / float(_valores.size())


# Retorna a menor contagem possivel
func minimo() -> int:
    if _valores.is_empty():
        return Estado.CONTAGEM_INICIAL
    var menor: int = _valores[0]
    for n in _valores:
        menor = mini(menor, n)
    return menor


# Calcula o maximo divisor comum de todas as contagens possiveis
func mdc() -> int:
    if _valores.is_empty():
        return 0
    var g: int = _valores[0]
    for n in _valores:
        g = _mdc_de(g, n)
    return g


# Calcula o mdc de dois inteiros
static func _mdc_de(a: int, b: int) -> int:
    a = absi(a)
    b = absi(b)
    while b != 0:
        var resto := a % b
        a = b
        b = resto
    return a
