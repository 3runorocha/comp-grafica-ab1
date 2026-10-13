# -*- coding: utf-8 -*-
# Gera os efeitos sonoros do jogo por sintese

import math
import os
import random
import struct
import wave

TAXA = 44100
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, "assets", "audio")


def silencio(duracao):
    return [0.0] * int(duracao * TAXA)


# Soma um trecho ao audio base a partir de um instante
def mistura(base, trecho, inicio):
    i = int(inicio * TAXA)
    faltando = i + len(trecho) - len(base)
    if faltando > 0:
        base.extend([0.0] * faltando)
    for k, v in enumerate(trecho):
        base[i + k] += v


# Gera um envelope de ataque rapido e queda exponencial
def envelope(n, ataque=0.005, queda=0.35):
    env = []
    amostras_ataque = max(1, int(ataque * TAXA))
    for i in range(n):
        if i < amostras_ataque:
            env.append(i / float(amostras_ataque))
        else:
            env.append(math.exp(-((i - amostras_ataque) / float(TAXA)) / queda))
    return env


# Gera uma nota com harmonicos
def tom(freq, duracao, volume=0.5, queda=0.35, harmonicos=(1.0, 0.35, 0.12)):
    n = int(duracao * TAXA)
    env = envelope(n, queda=queda)
    saida = []
    for i in range(n):
        t = i / float(TAXA)
        v = 0.0
        for h, peso in enumerate(harmonicos, start=1):
            v += peso * math.sin(2.0 * math.pi * freq * h * t)
        saida.append(v * env[i] * volume)
    return saida


# Gera uma batida de ruido com tom descendente
def batida(duracao, volume, f_ini, f_fim, estalo=0.5, queda=0.10):
    n = int(duracao * TAXA)
    env = envelope(n, ataque=0.002, queda=queda)
    saida = []
    fase = 0.0
    for i in range(n):
        p = i / float(n)
        freq = f_ini * ((f_fim / f_ini) ** p)
        fase += 2.0 * math.pi * freq / TAXA
        ruido = random.uniform(-1.0, 1.0) * math.exp(-i / (0.004 * TAXA))
        saida.append((math.sin(fase) * 0.85 + ruido * estalo) * env[i] * volume)
    return saida


# Grava as amostras em um arquivo wav
def gravar(nome, amostras):
    pico = max(1e-9, max(abs(v) for v in amostras))
    ganho = 0.89 / pico if pico > 0.89 else 1.0
    caminho = os.path.join(DESTINO, nome)
    with wave.open(caminho, "wb") as arq:
        arq.setnchannels(1)
        arq.setsampwidth(2)
        arq.setframerate(TAXA)
        arq.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v * ganho)) * 32767))
            for v in amostras))
    print("%-24s %5.2f s" % (nome, len(amostras) / float(TAXA)))


NOTAS = {
    "do4": 261.63, "mi4": 329.63, "sol4": 392.00,
    "do5": 523.25, "mi5": 659.25, "sol5": 783.99,
}


# Gera o som do portao positivo
def portao_positivo():
    saida = silencio(0.45)
    for k, nota in enumerate(("do5", "mi5", "sol5")):
        mistura(saida, tom(NOTAS[nota], 0.30, volume=0.45, queda=0.16), k * 0.055)
    return saida


# Gera o som do portao negativo
def portao_negativo():
    saida = silencio(0.55)
    for k, nota in enumerate(("sol4", "mi4", "do4")):
        mistura(saida, tom(NOTAS[nota], 0.34, volume=0.42, queda=0.18), k * 0.06)
    mistura(saida, batida(0.20, 0.45, 190.0, 55.0), 0.0)
    return saida


# Gera o som de passo
def passo(semente, agudo):
    random.seed(semente)
    return batida(0.13, 0.55, 150.0 * agudo, 48.0 * agudo,
                  estalo=0.85, queda=0.035)


if __name__ == "__main__":
    os.makedirs(DESTINO, exist_ok=True)
    random.seed(7)
    gravar("portao_positivo.wav", portao_positivo())
    gravar("portao_negativo.wav", portao_negativo())
    gravar("passo_a.wav", passo(11, 1.0))
    gravar("passo_b.wav", passo(23, 1.18))
    print("destino: %s" % DESTINO)
    print("musica: falta musica_loop.ogg ou .wav, que Bruno traz de banco open source")
