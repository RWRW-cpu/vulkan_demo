

#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(binding = 2) uniform BoneMatrices {
    mat4 bones[100];
} boneMatrices;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec2 inTexCoord;
layout(location = 3) in vec3 inNormal;
layout(location = 4) in ivec4 inBoneIDs;
layout(location = 5) in vec4 inWeights;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;

void main() {
    mat4 boneTransform = mat4(0.0);
    bool hasBones = false;
    for(int i = 0; i < 4; i++) {
        if(inBoneIDs[i] != -1) {
            boneTransform += boneMatrices.bones[inBoneIDs[i]] * inWeights[i];
            hasBones = true;
        }
    }
    
    if(!hasBones) {
        boneTransform = mat4(1.0);
    }

    gl_Position = ubo.proj * ubo.view * ubo.model * boneTransform * vec4(inPosition, 1.0);
    fragColor = inColor;
    fragTexCoord = inTexCoord;
}


