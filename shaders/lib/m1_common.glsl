// ============================================================================
//  M1_ShaderPack_Woolcafe - Núcleo común optimizado para Apple Silicon (M1)
// ----------------------------------------------------------------------------
//  Reglas de arquitectura (GPU Apple = TBDR, Tile-Based Deferred Rendering):
//   1. Todo lo que depende solo de la hora / mano se calcula en CPU una vez por
//      frame (custom uniforms en shaders.properties) -> 0 ALU por píxel.
//   2. Lo que es lineal por cara (difusa sol/luna, tinte de cielo) va en el
//      vertex shader: un bloque = 4 vértices vs. cientos de píxeles.
//   3. Un solo render target (DRAWBUFFERS:0) -> mínimo ancho de banda de tile.
//   4. Sin 'discard' en geometría sólida -> el HSR del M1 sigue activo.
//   5. Sin pow()/normalize() redundantes: inversesqrt y multiplicaciones.
// ============================================================================

// --- Uniforms precalculados en CPU (shaders.properties) ---
uniform float dayFactor;          // 0 = noche, 1 = día
uniform float sunsetFactor;       // 1 en amanecer/atardecer
uniform float celestialSign;      // +1 sol sobre horizonte, -1 luna
uniform float celestialStrength;  // intensidad difusa sol/luna
uniform float handLight;          // max(luz mano principal, segunda mano) / 15
uniform float handSide;           // +0.35 mano derecha, -0.35 mano izquierda
uniform float handInvRadius;      // 1 / radio de la antorcha en mano
uniform vec3  skyTint;            // tinte atmosférico (noche/día/atardecer)

uniform vec3 sunPosition;         // espacio de vista, longitud 100 en Iris/OptiFine

const vec3 TORCH_COLOR = vec3(1.0, 0.70, 0.38);

// Atenuación de antorcha en mano. Usa inversesqrt (1 instrucción en Apple GPU)
// en lugar de length() + normalize() + divisiones.
float torchAtten(vec3 viewPos, out vec3 L, out float dist) {
    vec3 toLight = vec3(handSide, -0.35, -0.2) - viewPos;
    float d2 = dot(toLight, toLight);
    float invD = inversesqrt(max(d2, 1e-6));
    dist = d2 * invD;
    L = toLight * invD;

    float edgeFade = 1.0 - smoothstep(0.35, 1.0, min(dist * handInvRadius, 1.0));
    return edgeFade / (1.0 + 0.35 * dist + 0.06 * d2);
}
