class_name Estado
extends Node

enum Op {
    SOMAR,
    SUBTRAIR,
    MULTIPLICAR,
    DIVIDIR,
}

const CONTAGEM_INICIAL: int = 10

signal contagem_mudou(anterior: int, novo: int)
signal fim_de_jogo
signal vitoria

var contagem: int = CONTAGEM_INICIAL
var portoes_atravessados: int = 0

var _acabou: bool = false


# Volta ao estado de inicio de fase
func reiniciar() -> void:
    var anterior := contagem
    contagem = CONTAGEM_INICIAL
    portoes_atravessados = 0
    _acabou = false
    if anterior != contagem:
        contagem_mudou.emit(anterior, contagem)


# Encerra a partida com vitoria
func concluir() -> void:
    if _acabou:
        return
    _acabou = true
    vitoria.emit()


# Aplica um portao sobre a contagem atual
func aplicar(op: Op, valor: int) -> void:
    if _acabou:
        return

    var anterior := contagem
    portoes_atravessados += 1
    contagem = resultado(op, valor, contagem)

    if contagem != anterior:
        contagem_mudou.emit(anterior, contagem)

    if contagem == 0:
        _acabou = true
        fim_de_jogo.emit()


# Calcula quanto sobra ao aplicar a operacao sobre n
static func resultado(op: Op, valor: int, n: int) -> int:
    var saida := n
    match op:
        Op.SOMAR:
            saida = n + valor
        Op.SUBTRAIR:
            saida = n - valor
        Op.MULTIPLICAR:
            saida = n * valor
        Op.DIVIDIR:
            if valor == 0:
                push_error("Portao de divisao com valor zero.")
                return n
            saida = floori(float(n) / float(valor))
    return maxi(saida, 0)


# Diz se a operacao tende a aumentar o cordao
static func e_positiva(op: Op) -> bool:
    return op == Op.SOMAR or op == Op.MULTIPLICAR


# Monta o texto curto da placa do portao
static func texto(op: Op, valor: int) -> String:
    match op:
        Op.SOMAR:
            return "+%d" % valor
        Op.SUBTRAIR:
            return "-%d" % valor
        Op.MULTIPLICAR:
            return "x%d" % valor
        Op.DIVIDIR:
            return "/%d" % valor
    return "?"
