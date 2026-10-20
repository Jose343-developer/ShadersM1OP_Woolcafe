#version 150 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 worldNormal;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;
    
    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 n = gl_NormalMatrix * gl_Normal;
    worldNormal = length(n) > 0.0001 ? normalize(n) : vec3(0.0, 1.0, 0.0);
}
