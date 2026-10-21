#version 150 compatibility

out vec2 texcoord;
out vec4 glcolor;
out vec2 quadPos;   // Coordenada local del quad del sol/luna en [-1, 1]

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor  = gl_Color;

    // Sol y luna son un quad de 4 vértices consecutivos. Derivamos la esquina
    // a partir de gl_VertexID: funciona aunque la textura esté en un atlas.
    int id = gl_VertexID & 3;
    quadPos = vec2((id == 1 || id == 2) ? 1.0 : -1.0,
                   (id >= 2) ? 1.0 : -1.0);
}
