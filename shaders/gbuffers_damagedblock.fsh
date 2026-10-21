#version 150 compatibility

/* DRAWBUFFERS:0 */

uniform sampler2D texture;

in vec2 texcoord;
in vec4 glcolor;

void main() {
    gl_FragData[0] = texture2D(texture, texcoord) * glcolor;
}
