# Guerreiros

Jogo em Godot 4 para a AB1 de Computação Gráfica (COMP381), UFAL.
Tema: Cultura de Alagoas e Ensino Fundamental da Matemática.

Autor: Bruno Rocha.

## O que é

Um *runner* infinito na orla de Maceió. O jogador conduz um cordão de
personagens do folguedo do Guerreiro alagoano e atravessa portões que aplicam
as quatro operações sobre o tamanho do grupo.

A matemática é a própria decisão, não um quiz. Cada par de portões tem um lado
proporcional (`×2`, `÷3`) e um lado fixo (`+40`, `-18`), e qual vence depende de
quantos guerreiros você tem: com 10, `+40` ganha de `×2`; com 60, é o contrário.
Os dois lados têm sempre o mesmo sinal, então também não dá para escolher pela
cor.

## Como rodar

Requer Godot 4.

```bash
godot --path .
```

`F5` para jogar. No menu escolhe-se teclado (setas ou A/D) ou mouse.

## Os cinco requisitos da AB1

| requisito | onde está |
|---|---|
| Modelar objetos | Mestre, guerreiro e coqueiro, modelados em Blender pelos scripts em `tools/` |
| Aplicar transformações | Translação, rotação e escala em tempo real: pernas e braços giram, fitas ondulam, o cordão escala com a contagem |
| Interação mouse/teclado | Controle lateral por setas, A/D ou mouse |
| Som/música | Trilha em loop, passos e efeitos de portão |
| Navegação completa | Do menu à tela de fim, por teclado ou mouse |

## Pesquisa cultural

Em [`docs/guerreiro-referencia.md`](docs/guerreiro-referencia.md), com fontes.
Os chapéus do Guerreiro têm formato de igrejas, e os do mestre representam
catedrais: daí o capacete com três torres. A paleta é a da bandeira de Alagoas.

## Estrutura

```
scenes/        cenas
scripts/       nucleo, jogador, pista, interface
shaders/       faixas do asfalto
tools/         scripts de Blender que geram os modelos
docs/          pesquisa cultural
assets/        modelos e áudio
```
