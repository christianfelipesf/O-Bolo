shader_type canvas_item;

global uniform vec2 player_pos;

group_uniforms Visuals;
uniform vec4 color_top : source_color = vec4(0.3, 0.8, 0.4, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.05, 0.2, 0.1, 1.0);
uniform float density = 60.0;
uniform float grass_width : hint_range(0.01, 0.5) = 0.15;
uniform float grass_height : hint_range(0.1, 1.0) = 0.7;

group_uniforms Interaction;
uniform float influence_radius = 80.0;
uniform float push_strength = 0.4;
uniform int shape_mode : hint_range(0, 1) = 0; // 0: Radial, 1: Quadrado
uniform float softness = 0.5;

float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    // 1. Grade de células
    vec2 g_uv = UV * density;
    vec2 id = floor(g_uv);
    vec2 f_uv = fract(g_uv) - 0.5;
    
    // 2. Variação de posição por célula
    float h = hash(id);
    vec2 offset = vec2(h - 0.5, hash(id + 15.2) - 0.5) * 0.4;
    f_uv -= offset;
    
    // 3. Cálculo da Distância (Radial vs Quadrado)
    // Nota: Em um ColorRect real, multiplique UV pela escala do objeto para ter pixels reais
    vec2 world_scale = 1.0 / SCREEN_PIXEL_SIZE; // Exemplo para pegar escala da tela
    vec2 diff = (UV * 500.0) - player_pos; // 500.0 é um exemplo de tamanho do ColorRect
    
    float dist;
    if (shape_mode == 0) {
        dist = length(diff); // Radial
    } else {
        vec2 abs_diff = abs(diff);
        dist = max(abs_diff.x, abs_diff.y); // Quadrado (Chebyshev)
    }
    
    // 4. Máscara de influência
    float influence = smoothstep(influence_radius, influence_radius * softness, dist);
    
    // 5. Deformação (Vento + Player)
    float wind = sin(TIME * 2.0 + id.x) * 0.05;
    vec2 push_dir = normalize(diff + 0.001); 
    f_uv.x += wind + (push_dir.x * influence * push_strength);
    f_uv.y += (push_dir.y * influence * push_strength);

    // 6. Desenho da Lâmina com largura e altura configuráveis
    float current_width = grass_width * (1.0 - f_uv.y); 
    float shape = smoothstep(current_width, current_width - 0.05, abs(f_uv.x));
    
    // Altura controlada pelo uniform e pelo gradiente da célula
    float height_mask = smoothstep(grass_height - 0.5, -0.5, f_uv.y);
    
    float final_mask = shape * height_mask;
    
    // 7. Pintura
    vec3 final_color = mix(color_bottom.rgb, color_top.rgb, f_uv.y + 0.5);
    COLOR = vec4(final_color, final_mask);
}