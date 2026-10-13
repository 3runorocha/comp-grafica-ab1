# -*- coding: utf-8 -*-
# Gera o blockout do mestre do Guerreiro e exporta em GLB e blend

import bpy
import math
import os

ALTURA_CORPO = 1.82
TOPO_CABECA = 1.82
BASE_CHAPEU = TOPO_CABECA

CORES = {
    "pele": (0.62, 0.42, 0.29, 1.0),
    "vermelho": (0.80, 0.14, 0.16, 1.0),
    "azul": (0.13, 0.33, 0.66, 1.0),
    "branco": (0.95, 0.95, 0.93, 1.0),
    "tronco": (0.46, 0.36, 0.26, 1.0),
    "folha": (0.17, 0.46, 0.22, 1.0),
}

_materiais = {}


# Cria ou reaproveita o material de uma cor
def material(nome):
    if nome in _materiais:
        return _materiais[nome]
    mat = bpy.data.materials.new(name=nome)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = CORES[nome]
    mat.diffuse_color = CORES[nome]
    _materiais[nome] = mat
    return mat


# Cria uma caixa com material
def caixa(nome, centro, tamanho, cor):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=centro)
    obj = bpy.context.active_object
    obj.name = nome
    obj.scale = tamanho
    obj.data.materials.append(material(cor))
    return obj


# Cria um cilindro com material
def cilindro(nome, centro, raio, altura, cor):
    bpy.ops.mesh.primitive_cylinder_add(radius=raio, depth=altura, location=centro, vertices=16)
    obj = bpy.context.active_object
    obj.name = nome
    obj.data.materials.append(material(cor))
    return obj


# Cria um cone com material
def cone(nome, centro, raio, altura, cor):
    bpy.ops.mesh.primitive_cone_add(radius1=raio, radius2=0.0, depth=altura, location=centro, vertices=12)
    obj = bpy.context.active_object
    obj.name = nome
    obj.data.materials.append(material(cor))
    return obj


# Limpa os objetos, malhas e materiais da cena
def limpar_cena():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bloco in (bpy.data.meshes, bpy.data.materials):
        for item in list(bloco):
            bloco.remove(item)


# Monta o corpo do mestre
def construir_corpo():
    # Monta as pernas
    montar_pernas(0.12, 0.74,
                  bota=(0.21, 0.30, 0.18), bota_z=0.09,
                  coxa=(0.19, 0.24, 0.56), coxa_z=0.46)

    caixa("camisa", (0.0, 0.0, 0.99), (0.52, 0.30, 0.54), "vermelho")
    caixa("ombros", (0.0, 0.0, 1.20), (0.64, 0.30, 0.14), "vermelho")

    # Monta os bracos
    montar_bracos(0.36, 1.22,
                  braco=(0.14, 0.16, 0.42), braco_z=1.00,
                  mao=(0.13, 0.15, 0.13), mao_z=0.76)

    # Monta pescoco e cabeca
    caixa("pescoco", (0.0, 0.0, 1.29), (0.17, 0.17, 0.08), "pele")
    caixa("cabeca", (0.0, 0.0, 1.57), (0.50, 0.44, 0.50), "pele")


# Monta as pernas separadas com o pivo no quadril
def montar_pernas(afastamento, quadril, bota, bota_z, coxa, coxa_z):
    for lado, sinal in (("esq", -1.0), ("dir", 1.0)):
        x = sinal * afastamento
        pe = caixa("bota_" + lado, (x, -0.03, bota_z), bota, "vermelho")
        perna = caixa("perna_" + lado, (x, 0.0, coxa_z), coxa, "azul")

        bpy.ops.object.select_all(action="DESELECT")
        pe.select_set(True)
        perna.select_set(True)
        bpy.context.view_layer.objects.active = perna
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.ops.object.join()

        bpy.context.scene.cursor.location = (x, 0.0, quadril)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)


# Monta os bracos separados com o pivo no ombro
def montar_bracos(afastamento, ombro, braco, braco_z, mao, mao_z):
    for lado, sinal in (("esq", -1.0), ("dir", 1.0)):
        x = sinal * afastamento
        punho = caixa("mao_" + lado, (x, 0.0, mao_z), mao, "pele")
        membro = caixa("braco_" + lado, (x, 0.0, braco_z), braco, "vermelho")

        bpy.ops.object.select_all(action="DESELECT")
        punho.select_set(True)
        membro.select_set(True)
        bpy.context.view_layer.objects.active = membro
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.ops.object.join()

        bpy.context.scene.cursor.location = (x, 0.0, ombro)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)


# Monta o capacete em forma de catedral
def construir_capacete():
    base = BASE_CHAPEU

    caixa("aro", (0.0, 0.0, base + 0.06), (0.58, 0.50, 0.12), "branco")
    caixa("corpo_capacete", (0.0, 0.0, base + 0.27), (0.52, 0.42, 0.30), "branco")

    for lado, x in (("esq", -0.19), ("dir", 0.19)):
        caixa("torre_" + lado, (x, 0.0, base + 0.59), (0.15, 0.20, 0.34), "branco")
        cone("telhado_" + lado, (x, 0.0, base + 0.85), 0.115, 0.20, "vermelho")

    caixa("torre_centro", (0.0, 0.0, base + 0.65), (0.20, 0.24, 0.46), "branco")
    cone("telhado_centro", (0.0, 0.0, base + 0.99), 0.145, 0.22, "vermelho")
    caixa("cruz_haste", (0.0, 0.0, base + 1.19), (0.035, 0.035, 0.20), "vermelho")
    caixa("cruz_braco", (0.0, 0.0, base + 1.22), (0.14, 0.035, 0.035), "vermelho")


# Monta as fitas atras da cabeca
def construir_fitas():
    topo = BASE_CHAPEU + 0.02
    cores = ("azul", "branco", "vermelho")
    recuo = 0.25
    largura = 0.05
    passo = 0.088
    comprimentos = (1.00, 0.92, 0.98, 0.98, 0.92, 1.00)

    fitas = []
    for i in range(6):
        x = -0.22 + i * passo
        comprimento = comprimentos[i]
        fita = caixa("fita_%d" % i,
                     (x, recuo, topo - comprimento * 0.5),
                     (largura, 0.02, comprimento),
                     cores[i % 3])
        fitas.append((fita, x, topo))
    return fitas


# Move o pivo de cada fita para o topo dela
def pivo_no_topo(fitas):
    for fita, x, topo in fitas:
        bpy.context.scene.cursor.location = (x, 0.25, topo)
        bpy.ops.object.select_all(action="DESELECT")
        fita.select_set(True)
        bpy.context.view_layer.objects.active = fita
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)


# Junta as pecas e exporta o mestre
def juntar_e_exportar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Junta corpo e capacete, deixando fitas, pernas e bracos soltos
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        solto = (obj.name.startswith("fita_")
                 or obj.name.startswith("perna_")
                 or obj.name.startswith("braco_"))
        if obj.type == "MESH" and not solto:
            obj.select_set(True)
    corpo = bpy.data.objects.get("camisa")
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.join()


    # Gira o modelo 180 graus e aplica a rotacao
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.transform.rotate(value=math.pi, orient_axis="Z",
                             center_override=(0.0, 0.0, 0.0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    mestre = bpy.context.active_object
    mestre.name = "Mestre"

    # Coloca a origem do corpo nos pes
    bpy.ops.object.select_all(action="DESELECT")
    mestre.select_set(True)
    bpy.context.view_layer.objects.active = mestre
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    # Exporta o GLB e salva o blend
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "assets")
    os.makedirs(destino, exist_ok=True)

    caminho_glb = os.path.join(destino, "mestre_blockout.glb")
    bpy.ops.export_scene.gltf(filepath=caminho_glb, export_format="GLB")

    caminho_blend = os.path.join(destino, "mestre_blockout.blend")
    bpy.ops.wm.save_as_mainfile(filepath=caminho_blend)

    dim = mestre.dimensions
    print("BLOCKOUT largura %.2f  profundidade %.2f  altura %.2f" % (dim.x, dim.y, dim.z))
    print("BLOCKOUT vertices %d  faces %d" % (len(mestre.data.vertices), len(mestre.data.polygons)))
    print("BLOCKOUT glb   %s" % caminho_glb)
    print("BLOCKOUT blend %s" % caminho_blend)


if __name__ == "__main__":
    limpar_cena()
    construir_corpo()
    construir_capacete()
    pivo_no_topo(construir_fitas())
    juntar_e_exportar()
