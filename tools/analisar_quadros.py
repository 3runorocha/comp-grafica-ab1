# Compara os quadros capturados e mede a cintilacao pixel a pixel

import sys
import pathlib
import numpy as np
from PIL import Image

COLUNAS = 8
LINHAS = 6


# Aplica uma media 3x3 na imagem
def borrar(a):
    p = np.pad(a, 1, mode="edge")
    s = np.zeros_like(a)
    for dy in (0, 1, 2):
        for dx in (0, 1, 2):
            s += p[dy:dy + a.shape[0], dx:dx + a.shape[1]]
    return s / 9.0


# Carrega a imagem em tons de cinza
def cinza(caminho):
    img = Image.open(caminho).convert("RGB")
    return np.asarray(img, dtype=np.float32).mean(axis=2)


# Le o diario da captura
def ler_diario(pasta):
    caminho = pasta / "diario.csv"
    if not caminho.exists():
        return {}
    linhas = caminho.read_text(encoding="utf-8").strip().splitlines()[1:]
    saida = {}
    anterior = None
    for linha in linhas:
        partes = linha.split(",")
        n = int(partes[0])
        z_orla = float(partes[2])
        contagem = int(partes[3])
        saida[n] = {
            "z_orla": z_orla,
            "contagem": contagem,
            "saltou": anterior is not None and abs(z_orla - anterior) > 1.0,
        }
        anterior = z_orla
    return saida


# Executa a analise dos quadros
def main():
    pasta = pathlib.Path(sys.argv[1])
    quadros = sorted(pasta.glob("q*.png"))
    if len(quadros) < 3:
        print("quadros de menos.")
        return
    diario = ler_diario(pasta)

    anterior = cinza(quadros[0])
    altura, largura = anterior.shape
    th, tl = altura // LINHAS, largura // COLUNAS

    # Mede movimento e cintilacao de cada par de quadros
    medidas = []
    for i, caminho in enumerate(quadros[1:], start=2):
        atual = cinza(caminho)
        d = np.abs(atual - anterior)
        suave = borrar(d)
        alta = np.abs(d - suave)

        telhas = alta[:LINHAS * th, :COLUNAS * tl]
        telhas = telhas.reshape(LINHAS, th, COLUNAS, tl).mean(axis=(1, 3))
        pior = np.unravel_index(np.argmax(telhas), telhas.shape)

        medidas.append({
            "q": i,
            "total": float(d.mean()),
            "movimento": float(suave.mean()),
            "cintilacao": float(alta.mean()),
            "telha_pior": float(telhas[pior]),
            "onde": (int(pior[0]), int(pior[1])),
            "saltou": diario.get(i, {}).get("saltou", False),
            "contagem": diario.get(i, {}).get("contagem", -1),
        })
        anterior = atual

    # Imprime o resumo geral
    tot = np.array([m["total"] for m in medidas])
    cin = np.array([m["cintilacao"] for m in medidas])
    mov = np.array([m["movimento"] for m in medidas])

    print("=== %d pares de quadros, %dx%d ===" % (len(medidas), largura, altura))
    print("diferenca total   mediana %6.3f   p99 %6.3f   pior %6.3f"
          % (np.median(tot), np.percentile(tot, 99), tot.max()))
    print("  movimento       mediana %6.3f   (parte borrada, esperada)"
          % np.median(mov))
    print("  cintilacao      mediana %6.3f   p99 %6.3f   pior %6.3f"
          % (np.median(cin), np.percentile(cin, 99), cin.max()))

    # Lista os quadros com mais cintilacao
    base = np.median(cin)
    print("\n--- quadros com mais cintilacao ---")
    print("%6s %12s %10s %12s %10s %8s" %
          ("quadro", "cintilacao", "x mediana", "telha pior", "onde", "evento"))
    for m in sorted(medidas, key=lambda x: -x["cintilacao"])[:12]:
        evento = []
        if m["saltou"]:
            evento.append("tapete")
        print("%6d %12.4f %10.2f %12.4f %10s %8s" %
              (m["q"], m["cintilacao"], m["cintilacao"] / max(base, 1e-9),
               m["telha_pior"], "l%d c%d" % m["onde"], " ".join(evento) or "-"))

    # Lista os quadros de salto do tapete
    saltos = [m for m in medidas if m["saltou"]]
    if saltos:
        print("\n--- os %d quadros de salto do tapete ---" % len(saltos))
        for m in saltos:
            print("  q%4d  total %6.3f (%4.1fx a mediana)  cintilacao %6.4f (%4.1fx)"
                  % (m["q"], m["total"], m["total"] / max(np.median(tot), 1e-9),
                     m["cintilacao"], m["cintilacao"] / max(base, 1e-9)))

    # Mostra a cintilacao por faixa da tela
    print("\n--- cintilacao por faixa da tela (soma da rodada) ---")
    anterior = cinza(quadros[0])
    acumulado = np.zeros((LINHAS, COLUNAS))
    for caminho in quadros[1:]:
        atual = cinza(caminho)
        d = np.abs(atual - anterior)
        alta = np.abs(d - borrar(d))
        t = alta[:LINHAS * th, :COLUNAS * tl]
        acumulado += t.reshape(LINHAS, th, COLUNAS, tl).mean(axis=(1, 3))
        anterior = atual
    acumulado /= len(quadros) - 1
    print("        " + "".join("%8d" % c for c in range(COLUNAS)))
    for l in range(LINHAS):
        print("linha %d " % l + "".join("%8.3f" % acumulado[l, c]
                                        for c in range(COLUNAS)))
    print("(linha 0 e o topo da tela, linha %d e o rodape)" % (LINHAS - 1))

    # Salva o pior par e o mapa da diferenca
    pior = max(medidas, key=lambda x: x["cintilacao"])
    a = Image.open(quadros[pior["q"] - 2]).convert("RGB")
    b = Image.open(quadros[pior["q"] - 1]).convert("RGB")
    d = np.abs(np.asarray(b, np.float32) - np.asarray(a, np.float32))
    mapa = np.clip(d * 12.0, 0, 255).astype(np.uint8)
    a.save(pasta / "pior_antes.png")
    b.save(pasta / "pior_depois.png")
    Image.fromarray(mapa).save(pasta / "pior_diferenca.png")
    print("\npior par gravado: quadros %d e %d, e o mapa da diferenca (12x)"
          % (pior["q"] - 1, pior["q"]))


if __name__ == "__main__":
    main()
