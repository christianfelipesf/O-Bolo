shader_type canvas_item;

// Parâmetros de Cor
uniform vec4 sky_color : source_color = vec4(0.05, 0.07, 0.1, 0.5);
uniform vec4 cloud_color : source_color = vec4(0.1, 0.15, 0.2, 0.8);
uniform vec3 lightning_color : source_color = vec3(0.7, 0.8, 1.0);

// Parâmetros da Chuva
uniform float rain_amount : hint_range(0.0, 1.0) = 0.6;
uniform float rain_speed : hint_range(0.0, 10.0) = 5.0; // Velocidade aumentada
uniform float rain_slant : hint_range(-1.0, 1.0) = 0.2;
uniform float drop_length : hint_range(0.1, 5.0) = 1.5; // Controle do comprimento

// Parâmetros da Tempestade
uniform float cloud_density : hint_range(0.0, 2.0) = 1.0;
uniform float cloud_speed : hint_range(0.0, 2.0) = 0.3; // Velocidade das nuvens
uniform float lightning_frequency : hint_range(0.0, 1.0) = 0.2;

// Funções de Ruído
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Ruído suave para nuvens
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;

    // 1. NUVENS EM MOVIMENTO
    // Adicionado movimento em X e Y baseado no tempo
    vec2 cloud_uv = uv * 2.0;
    cloud_uv.x += time * cloud_speed;
    cloud_uv.y += time * (cloud_speed * 0.2);

    // Distorção para as nuvens parecerem mais orgânicas
    float n = noise(cloud_uv + noise(cloud_uv * 0.8 + time * 0.1));

    vec4 cloud_layer = mix(vec4(0.0), cloud_color, n * cloud_density);

    // 2. RELÂMPAGOS
    float lightning = step(1.0 - lightning_frequency * 0.01, hash(vec2(floor(time * 10.0), 0.0)));
    float flash = lightning * hash(vec2(time)) * 2.0;
    cloud_layer.rgb += lightning_color * flash * n;
    cloud_layer.a += flash * 0.3;

    // 3. CHUVA COM PINGOS CURTOS
    float rain = 0.0;
    vec2 rain_dir = vec2(rain_slant, 1.0);

    for (int i = 1; i <= 3; i++) {
        float fi = float(i);
        // Multiplicamos o Y por um valor menor para encurtar o pingo visualmente
        vec2 rain_uv = uv * vec2(40.0 * fi, 10.0 / drop_length);
        rain_uv.x -= uv.y * rain_slant * 15.0;
        rain_uv -= rain_dir * time * rain_speed * (1.0 + fi * 0.1);

        float r = hash(floor(rain_uv));
        if (r > 1.0 - (rain_amount * 0.15)) {
            // Smoothstep mais restrito para criar um pingo definido e curto
            float drop = smoothstep(0.4, 0.5, fract(rain_uv.y)) * smoothstep(0.6, 0.5, fract(rain_uv.y));
            float side_taper = smoothstep(0.2, 0.0, distance(fract(rain_uv).x, 0.5));
            rain += drop * side_taper * r;
        }
    }

    // Mistura Final
    vec3 final_rgb = cloud_layer.rgb + (vec3(rain) * 0.6);
    float final_a = clamp(cloud_layer.a + rain * 0.4, 0.0, 1.0);

    // Vinheta
    float vignette = 1.0 - distance(uv, vec2(0.5));
    final_a *= pow(vignette, 0.4);

    COLOR = vec4(final_rgb, final_a);
}