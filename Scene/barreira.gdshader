shader_type canvas_item;

uniform vec4 barrier_color : source_color = vec4(0.0, 0.5, 1.0, 0.5); // Azul transparente
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wave_frequency : hint_range(0.0, 50.0) = 15.0;

// Função para gerar um ruído visual simples
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Efeito de movimento ondulado (energizado)
    float wave = sin(uv.y * wave_frequency + TIME * wave_speed) * 0.02;
    uv.x += wave;

    // Base da textura (se houver uma imagem no Sprite)
    vec4 tex_color = texture(TEXTURE, uv);
    
    // Criando a "trama" de energia
    float energy_grid = sin(uv.y * 20.0 - TIME * wave_speed) * 0.5 + 0.5;
    
    // Cor final combinando a transparência e o brilho
    vec4 final_color = barrier_color;
    final_color.a *= (0.3 + energy_grid * 0.4); // Oscila a transparência
    
    // Aplica o brilho (Glow/Bloom) multiplicando a cor RGB
    final_color.rgb *= glow_intensity;
    
    // Mantém o recorte da forma original do Sprite se ele tiver alpha
    final_color.a *= tex_color.a;

    COLOR = final_color;
}