shader_type spatial;

uniform vec3 cor_asfalto : source_color = vec3(0.21, 0.21, 0.23);
uniform vec3 cor_faixa_amarela : source_color = vec3(0.92, 0.76, 0.16);
uniform vec3 cor_faixa_branca : source_color = vec3(0.88, 0.88, 0.86);

uniform float meia_pista = 6.0;
uniform float afastamento_amarelo = 0.22;
uniform float largura_amarelo = 0.14;
uniform float largura_branco = 0.18;
uniform float traco = 4.0;
uniform float vao = 4.0;

varying vec3 mundo;

// Guarda a posicao do vertice no mundo
void vertex() {
    mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Retorna 1.0 dentro de uma faixa de largura w centrada em centro
float faixa(float x, float centro, float w) {
    return 1.0 - smoothstep(w * 0.5 - 0.02, w * 0.5 + 0.02, abs(x - centro));
}

// Pinta o asfalto com as faixas amarelas e brancas
void fragment() {
    vec3 cor = cor_asfalto;

    float amarelo = max(faixa(mundo.x, -afastamento_amarelo, largura_amarelo),
                        faixa(mundo.x, afastamento_amarelo, largura_amarelo));

    float ciclo = mod(mundo.z, traco + vao);
    float aceso = step(ciclo, traco);
    float branco = max(faixa(abs(mundo.x), meia_pista - 0.6, largura_branco), 0.0) * aceso;

    cor = mix(cor, cor_faixa_branca, branco);
    cor = mix(cor, cor_faixa_amarela, amarelo);

    ALBEDO = cor;
    ROUGHNESS = 0.85;
    SPECULAR = 0.2;
}
