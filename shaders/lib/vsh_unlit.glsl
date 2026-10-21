// Vertex shader común para geometría sin normales útiles (partículas, textured).

#include "/lib/m1_common.glsl"

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 skyMul;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    skyMul = mix(vec3(1.0), skyTint, lmcoord.y * 0.45);
}
