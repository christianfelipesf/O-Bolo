shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.01, 0.01, 0.02);
uniform vec3 cloud_color : source_color = vec3(0.05, 0.05, 0.08);
uniform vec3 lightning_color : source_color = vec3(0.4, 0.5, 0.8);
uniform float storm_density : hint_range(0.0, 1.0) = 0.8;
uniform float lightning_intensity : hint_range(0.0, 1.0) = 0.5;

// Função de ruído para criar volume
float hash(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453123);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

// FBM (Fractal Brownian Motion) para dar textura de tempestade
float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void sky() {
    vec3 dir = EYEDIR;
    float time = TIME;

    // 1. Nuvens Carregadas
    // Misturamos o ruído para criar áreas densas e buracos
    float cloud_shape = fbm(dir * 3.0 + time * 0.05);
    float storm_fbm = fbm(dir * 6.0 - time * 0.1);
    
    float final_clouds = smoothstep(1.0 - storm_density, 1.2 - storm_density, cloud_shape * storm_fbm);
    
    // 2. Lógica do Relâmpago (Flash interno)
    // O flash acontece em intervalos "caóticos"
    float flash_timer = time * 1.5;
    float flash_event = step(0.9, hash(vec3(floor(flash_timer), 0.0, 0.0)));
    float flash_pulse = flash_event * pow(fract(flash_timer), 8.0); // Pulso rápido
    
    // 3. Cor Final
    // A luz do raio ilumina as nuvens, não o céu vazio
    vec3 atmosphere = mix(sky_color, cloud_color, final_clouds);
    
    // Adiciona o brilho do raio "por trás" das nuvens
    vec3 lighting_effect = lightning_color * flash_pulse * lightning_intensity;
    
    // O raio ilumina mais as partes densas das nuvens (isso dá profundidade)
    vec3 final_output = atmosphere + (lighting_effect * (final_clouds + 0.5));
    
    // 4. O "Bolt" (O traço do raio opcional)
    if (flash_event > 0.0) {
        float bolt = smoothstep(0.75, 0.8, fbm(dir * 20.0 + time * 20.0));
        final_output += lightning_color * bolt * flash_pulse * 2.0;
    }

    COLOR = final_output;
}