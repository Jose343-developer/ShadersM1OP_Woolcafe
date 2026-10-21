// Vertex shader común para geometría con normales (terreno, bloques, entidades, mano).
// La difusa de sol/luna y el tinte de cielo son lineales sobre una cara plana,
// así que calcularlos por vértice da el mismo resultado que por píxel, pero
// cuesta una fracción en el M1.

#include "/lib/m1_common.glsl"

#ifndef CELESTIAL_SCALE
#define CELESTIAL_SCALE 1.0
#endif

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 viewNormal;
out vec3 skyMul;
out float celestialLight;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;

    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    vec3 n = gl_NormalMatrix * gl_Normal;
    float n2 = dot(n, n);
    viewNormal = n2 > 1e-8 ? n * inversesqrt(n2) : vec3(0.0, 1.0, 0.0);

    float sky = lmcoord.y;
    skyMul = mix(vec3(1.0), skyTint, sky * 0.45);

    // sunPosition mide 100 -> *0.01 sustituye a normalize()
    vec3 celestialDir = sunPosition * (0.01 * celestialSign);
    celestialLight = max(dot(viewNormal, celestialDir), 0.0) * sky * celestialStrength * CELESTIAL_SCALE;
}
