#version 450

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec3 inPos;

layout(location = 0) out vec3 outTexCoord;

void main() {
    outTexCoord = inPos;
    // Remove translation from view matrix to keep skybox centered
    mat4 view = mat4(mat3(ubo.view)); 
    vec4 pos = ubo.proj * view * vec4(inPos, 1.0);
    gl_Position = pos.xyww; // z = w, so z/w = 1.0 (max depth)
}
