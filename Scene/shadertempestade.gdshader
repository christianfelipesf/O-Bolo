shader_type canvas_item;

// Configurações do Shader
uniform vec4 color_cloud : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Cor das nuvens (Branco)
uniform float speed : hint_range(0.0, 2.0) = 0.5;                   // Velocidade do movimento
uniform float density : hint_range(0.0, 2.0) = 0.8;                 // Densidade das nuvens
uniform float softness : hint_range(0.0, 2.0) = 1.0;                // Suavidade das bordas

// Função para gerar ruído (FBM - Fractal Brownian Motion)
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // Cria o movimento baseado no tempo
    vec2 uv = UV * 3.0;
    vec2 movement = vec2(TIME * speed, TIME * speed * 0.2);

    // Gera as camadas de nuvens
    float n = fbm(uv + movement);

    // Ajusta o contraste e a densidade
    float mask = smoothstep(1.0 - density, 1.0 - density + (softness * 0.5), n);

    // Aplica a cor final com a máscara de transparência
    COLOR = vec4(color_cloud.rgb, mask * color_cloud.a);
}