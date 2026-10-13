# -*- coding: utf-8 -*-
# Gera o blockout do guerreiro do cordao e exporta em GLB

import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import bpy
import blockout_mestre as base

ESCALA = 1.0


# Monta o corpo e o capacete do guerreiro
def construir():
    base.limpar_cena()

    # Monta as pernas
    base.montar_pernas(0.10, 0.58,
                       bota=(0.17, 0.24, 0.14), bota_z=0.07,
                       coxa=(0.15, 0.19, 0.44), coxa_z=0.36)

    # Monta tronco, bracos e cabeca
    base.caixa("camisa", (0.0, 0.0, 0.78), (0.41, 0.24, 0.42), "vermelho")
    base.caixa("ombros", (0.0, 0.0, 0.94), (0.50, 0.24, 0.11), "vermelho")
    base.caixa("braco_esq", (-0.28, 0.0, 0.80), (0.11, 0.13, 0.34), "vermelho")
    base.caixa("braco_dir", (0.28, 0.0, 0.80), (0.11, 0.13, 0.34), "vermelho")
    base.caixa("cabeca", (0.0, 0.0, 1.24), (0.39, 0.35, 0.39), "pele")

    # Monta o capacete
    topo = 1.43
    base.caixa("aro", (0.0, 0.0, topo + 0.05), (0.46, 0.40, 0.10), "branco")
    base.caixa("corpo_capacete", (0.0, 0.0, topo + 0.24), (0.40, 0.33, 0.28), "branco")
    base.caixa("torre", (0.0, 0.0, topo + 0.50), (0.17, 0.20, 0.24), "branco")
    base.cone("telhado", (0.0, 0.0, topo + 0.72), 0.125, 0.20, "vermelho")


# Junta as pecas e exporta o guerreiro
def exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Junta tudo menos as pernas
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        if obj.type == "MESH" and not obj.name.startswith("perna_"):
            obj.select_set(True)
    corpo = bpy.data.objects.get("camisa")
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.join()


    # Gira o modelo 180 graus e aplica a rotacao
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.transform.rotate(value=math.pi, orient_axis="Z",
                             center_override=(0.0, 0.0, 0.0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    guerreiro = bpy.context.active_object
    guerreiro.name = "Guerreiro"
    # Aplica a escala em todas as pecas
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            obj.scale = (ESCALA, ESCALA, ESCALA)
            obj.location = obj.location * ESCALA
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    # Coloca a origem do corpo na origem do mundo
    bpy.ops.object.select_all(action="DESELECT")
    guerreiro.select_set(True)
    bpy.context.view_layer.objects.active = guerreiro
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    # Exporta o GLB
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "assets")
    caminho = os.path.join(destino, "guerreiro_blockout.glb")
    bpy.ops.export_scene.gltf(filepath=caminho, export_format="GLB")

    d = guerreiro.dimensions
    print("GUERREIRO largura %.2f altura %.2f" % (d.x, d.z))
    print("GUERREIRO vertices %d faces %d" % (
        len(guerreiro.data.vertices), len(guerreiro.data.polygons)))
    print("GUERREIRO glb %s" % caminho)


if __name__ == "__main__":
    construir()
    exportar()
