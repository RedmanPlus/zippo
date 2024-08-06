#version 410 core

in vec3 position;
in vec3 color;
in vec2 tex_coord;

out vec3 v_Color;
out vec2 TexCoord;

void main() {
    gl_Position = vec4(position, 1.0);
    v_Color = color;
    TexCoord = tex_coord;
}
