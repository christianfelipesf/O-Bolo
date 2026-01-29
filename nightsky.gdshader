shader_type canvas_item;

uniform vec3 sky_color : source_color = vec3(0.01, 0.02, 0.07); // Azul profundo da noite
uniform vec3 horizon_color : source_color = vec3(0.05, 0.1, 0.25); // Azul um pouco mais claro no horizonte
uniform float star_density : hint_range(1.0, 300.0) = 100.0;
uniform float star_brightness_min : hint_range(0.0, 5.0) = 0.5;
uniform float star_brightness_max : hint_range(0.0, 10.0) = 3.0;
uniform float twinkle_speed : hint_range(0.1, 10.0) = 5.0; // Velocidade da cintilação
uniform float star_size_base : hint_range(0.0, 0.1) = 0.008; // Tamanho base das estrelas

// Funções de Ruído / Hash (Para pseudo-aleatoriedade estável)
// Baseado em iq (Inigo Quilez) - Excelente para shaders
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p = fract(p);
    return p;
}

vec2 hash22(vec2 p) {
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p, p.yx);
    return fract(p * vec2(p.x + 13.989, p.y + 17.53));
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    fp = fp * fp * (3.0 - 2.0 * fp); // smoothstep interpolation
    
    float tl = hash11(dot(ip, vec2(127.1, 311.7)));
    float tr = hash11(dot(ip + vec2(1.0, 0.0), vec2(127.1, 311.7)));
    float bl = hash11(dot(ip + vec2(0.0, 1.0), vec2(127.1, 311.7)));
    float br = hash11(dot(ip + vec2(1.0, 1.0), vec2(127.1, 311.7)));
    
    return mix(mix(tl, tr, fp.x), mix(bl, br, fp.x), fp.y);
}

void fragment() {
    // 1. Gradiente de fundo do céu e horizonte
    vec3 final_color = mix(sky_color, horizon_color, pow(UV.y, 1.5)); // Usar pow para um gradiente mais suave

    // 2. Campo de estrelas
    vec2 uv_scaled = UV * star_density;
    vec2 grid_id = floor(uv_scaled); // Identificador da célula
    vec2 cell_pos = fract(uv_scaled); // Posição dentro da célula (0 a 1)

    // Gerar propriedades únicas para cada potencial estrela
    vec2 star_prop = hash22(grid_id); // Usa hash22 para 2 valores aleatórios
    float star_exists = star_prop.x; // Se existe ou não (primeiro valor do hash)
    float star_random_offset = star_prop.y; // Deslocamento para cintilação individual (segundo valor)

    if (star_exists > 0.98) { // Chance de uma estrela aparecer (ajuste para mais ou menos)
        // Coordenadas para o "centro" da estrela dentro da célula
        vec2 star_center = vec2(0.5) + (star_exists - 0.98) * 5.0; // Pequeno ajuste para estrelas mais dispersas

        // Distância do pixel atual ao centro da estrela
        float dist = distance(cell_pos, star_center);

        // Calcula o brilho individual da estrela
        float individual_brightness = mix(star_brightness_min, star_brightness_max, hash11(grid_id.x + grid_id.y * 100.0));

        // Efeito de cintilação (piscar)
        float twinkle = sin(TIME * twinkle_speed + star_random_offset * 10.0) * 0.5 + 0.5;
        twinkle = pow(twinkle, 2.0); // Deixa o piscar mais acentuado

        // Formato da estrela (um brilho suave)
        float star_shape = smoothstep(star_size_base, star_size_base * 0.5, dist);
        
        // Adiciona a estrela à cor final
        final_color += vec3(star_shape) * individual_brightness * twinkle;
    }
    
    // Opcional: Adicionar um ruído de fundo sutil para simular nuvens distantes ou via láctea embaçada
    float cloud_noise = noise(UV * 5.0 + TIME * 0.05); // Ruído lento
    final_color += vec3(cloud_noise * 0.02); // Adiciona um brilho muito sutil

    COLOR = vec4(final_color, 1.0);
}