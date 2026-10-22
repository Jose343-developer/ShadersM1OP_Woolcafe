uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 viewNormal;
out vec3 worldPos;     // Posición en mundo para micro-ondas estables (no se mueven con la cámara)
out float waterTop;    // 1.0 = cara superior del agua, 0.0 = laterales

void main() {
    vec4 position = gl_Vertex;
    
    // Ondulación ligera de vértices (Cero impacto en FPS en chip M1)
    float wave = sin(frameTimeCounter * 2.5 + position.x * 1.5 + position.z * 1.5) * 0.035;
    position.y += wave;

    gl_Position = gl_ModelViewProjectionMatrix * position;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;
    
    viewPos = (gl_ModelViewMatrix * position).xyz;
    vec3 n = gl_NormalMatrix * gl_Normal;
    float n2 = dot(n, n);
    viewNormal = n2 > 1e-8 ? n * inversesqrt(n2) : vec3(0.0, 1.0, 0.0);

    // Calculado por vértice (barato) en lugar de por píxel
    worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + cameraPosition;
    waterTop = step(0.9, gl_Normal.y);
}