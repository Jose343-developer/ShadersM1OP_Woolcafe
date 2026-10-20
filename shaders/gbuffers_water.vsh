#version 150 compatibility

uniform float frameTimeCounter;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 worldNormal;

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
    worldNormal = length(n) > 0.0001 ? normalize(n) : vec3(0.0, 1.0, 0.0);
}