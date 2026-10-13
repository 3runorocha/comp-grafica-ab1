# -*- coding: utf-8 -*-
# Gera o coqueiro da orla em blocos e exporta em GLB

import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import bpy
import blockout_mestre as base

ALTURA_TRONCO = 9.0
SEGMENTOS = 6
FOLHAS = 9


# Monta o coqueiro em blocos
def construir():
    base.limpar_cena()

    # Monta o tronco do coqueiro
    passo = ALTURA_TRONCO / float(SEGMENTOS)
    desvio = 0.0
    for i in range(SEGMENTOS):
        p = float(i) / float(SEGMENTOS - 1)
        largura = 0.42 - 0.17 * p
        desvio += 0.11 * p
        base.caixa("tronco_%d" % i,
                   (desvio, 0.0, passo * (float(i) + 0.5)),
                   (largura, largura, passo * 1.04),
                   "tronco")

    topo = (desvio, 0.0, ALTURA_TRONCO)

    # Monta as folhas da copa
    for i in range(FOLHAS):
        angulo = (math.tau / float(FOLHAS)) * float(i)
        queda = 0.42 + 0.12 * float(i % 3)
        comprimento = 3.1 - 0.35 * float(i % 2)
        meio = comprimento * 0.5
        folha = base.caixa(
            "folha_%d" % i,
            (topo[0] + math.cos(angulo) * math.cos(queda) * meio,
             topo[1] + math.sin(angulo) * math.cos(queda) * meio,
             topo[2] - math.sin(queda) * meio),
            (comprimento, 0.42, 0.10),
            "folha")
        folha.rotation_euler = (0.0, queda, angulo)

    # Monta o cacho de cocos
    for i in range(3):
        angulo = 2.1 * float(i)
        base.caixa("coco_%d" % i,
                   (topo[0] + math.cos(angulo) * 0.34,
                    topo[1] + math.sin(angulo) * 0.34,
                    topo[2] - 0.45),
                   (0.3, 0.3, 0.3), "tronco")


# Junta as pecas e exporta o coqueiro
def exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    alvo = bpy.data.objects.get("tronco_0")
    bpy.context.view_layer.objects.active = alvo
    bpy.ops.object.join()

    coqueiro = bpy.context.active_object
    coqueiro.name = "Coqueiro"
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    caminho = os.path.join(raiz, "assets", "coqueiro.glb")
    bpy.ops.export_scene.gltf(filepath=caminho, export_format="GLB")

    d = coqueiro.dimensions
    print("COQUEIRO largura %.2f altura %.2f" % (d.x, d.z))
    print("COQUEIRO vertices %d faces %d" % (
        len(coqueiro.data.vertices), len(coqueiro.data.polygons)))


if __name__ == "__main__":
    construir()
    exportar()
