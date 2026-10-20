#version 150 compatibility

uniform sampler2D texture;

in vec2 texcoord;
in vec4 glcolor;

void main() {
    vec4 col = texture2D(texture, texcoord) * glcolor;
    gl_FragData[0] = col;
}
