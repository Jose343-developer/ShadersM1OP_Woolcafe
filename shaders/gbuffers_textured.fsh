#version 150 compatibility

/* DRAWBUFFERS:0 */

#include "/lib/m1_common.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 skyMul;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * glcolor;
    if (albedo.a < 0.05) discard;

    vec3 light = texture2D(lightmap, lmcoord).rgb * skyMul;

    if (handLight > 0.0) {
        vec3 L; float dist;
        light += TORCH_COLOR * (torchAtten(viewPos, L, dist) * handLight * 1.25);
    }

    gl_FragData[0] = vec4(albedo.rgb * light, albedo.a);
}
