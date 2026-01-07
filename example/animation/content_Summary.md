# CodeZipper Summary

**Source:** D:\code\w_cplus\animator\LearnOpengl_Mingw\mkdown
**Created:** 2026-01-07T23:30:35.021476
**Files:** 31
**Total Size:** 157706 bytes

<!-- CODEZIPPER_CONTENT_START -->

## File: include\animation.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 2832 bytes

```
#pragma once
#include "bone.h"
#include "model.h"

struct Morph
{
    // shapekey names and weight
    unordered_map<string, float> shapekeys;
    double timeStamp;
};

class Animation
{
public:
    Animation(const aiAnimation *animation, StringBoneInfoMap &modelBoneInfoMap, UIntStringMap &modelShapeKeysNameID);
    Bone *FindBone(const string &name);
    inline float GetTicksPerSecond() { return m_TicksPerSecond; }
    inline float GetDuration() { return m_Duration; }

public:
    // laod bone animations, also check missing bone
    void ReadBonesAnims(const aiAnimation *animation, StringBoneInfoMap &modelBoneInfoMap);
    void ReadMorphAnims(const aiAnimation *animation, UIntStringMap &modelShapeKeysNameID);

    unordered_map<string, float> morphAnimUpdate(float animationTime);

    string m_Name;
    float m_Duration;
    int m_TicksPerSecond;

    StringBoneMap m_BoneKeys;
    vector<Morph> m_MorphKeys;
};

class Animations
{
private:
    vector<Animation> m_Animations;
    vector<string> m_Names;
    BoneNode m_RootBoneNode;

public:
    Animations(const std::string &animationPath, Model *model);
    Animations(const aiScene *scene, Model *model);
    vector<Animation> &GetAnimations() { return m_Animations; }
    vector<string> GetAnimationNames() { return m_Names; }

    void ReadHierarchyData(BoneNode &dest, const aiNode *src);

    inline const BoneNode &GetBoneRootNode() { return m_RootBoneNode; }
};

class Animator
{
public:
    Animator(Animations *animations, Model *model);
    ~Animator()
    {
        glDeleteTextures(1, &boneMatrixTexture);
    }

    void UpdateAnimation(float dt);
    void PlayAnimation(Animation *pAnimation)
    {
        m_CurrentAnimation = pAnimation;
        m_CurrentTime = 0.0f;
    }
    inline void SetCurrentTime(float time) { m_CurrentTime = time; }

    void CalculateBoneTransform(const BoneNode *node, glm::mat4 parentTransform);

    inline std::vector<glm::mat4> &GetFinalBoneMatrices() { return m_FinalBoneMatrices; }
    inline float GetAnimationDuration() { return m_CurrentAnimation->m_Duration; }
    inline float GetCurrentFrame() { return m_CurrentTime; }
    inline std::string GetAnimationName() { return m_CurrentAnimation->m_Name; }

private:
    std::vector<glm::mat4> m_FinalBoneMatrices;
    Animation *m_CurrentAnimation;
    Animations *m_Animations;
    Model *m_Model;
    float m_CurrentTime;
    unsigned int boneMatrixTexture;
};

class ModelImporter
{
private:
    Model *m_Model = nullptr;
    Animations *m_Animations = nullptr;
    Animator *m_Animator = nullptr;
    Shader *m_Shader = nullptr;

public:
    static void ModelImport(const string path, Model **model, Animations **animations, Animator **animator, Shader &shader);
};
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\appcontrol.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1062 bytes

```
#ifndef __CONTEXTCTRL_H__
#define __CONTEXTCTRL_H__

#include <iostream>
#include <string>
#include <vector>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#ifndef RES_DIR
#define RES_DIR "../res/"
#endif

class AppControl
{
public:
    // all
    static unsigned int scr_width, scr_height;
    static glm::mat4 view, projection, vp;
    static float deltaTime;
    // light
    static glm::vec3 pointLightPos, pointLightColor;
    // text
    static float thickness,
        softness, outline_thickness, outline_softness;
    static glm::vec3 text_color;
    static glm::vec2 text_shadow_offset;
    // pbr ibl
    static glm::vec3 irradiance_color;
    // animation
    static std::vector<std::string> animNames;
    static int animIndex;
    static float playSpeed;
    static float duration;
    static float currentFrame;
    static bool playBackState;
    // shadow
    static float bias_offs;
    static float bias_mids;

};

typedef AppControl App;

#endif

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\AssimpGLMHelpers.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 994 bytes

```
#pragma once

#include<assimp/quaternion.h>
#include<assimp/vector3.h>
#include<assimp/matrix4x4.h>
#include<glm/glm.hpp>
#include<glm/gtc/quaternion.hpp>

class AssimpGLMHelpers
{
public:

	static inline glm::mat4 ConvertMatrixToGLMFormat(const aiMatrix4x4& from)
	{
		glm::mat4 to;
		//the a,b,c,d in assimp is the row ; the 1,2,3,4 is the column
		to[0][0] = from.a1; to[1][0] = from.a2; to[2][0] = from.a3; to[3][0] = from.a4;
		to[0][1] = from.b1; to[1][1] = from.b2; to[2][1] = from.b3; to[3][1] = from.b4;
		to[0][2] = from.c1; to[1][2] = from.c2; to[2][2] = from.c3; to[3][2] = from.c4;
		to[0][3] = from.d1; to[1][3] = from.d2; to[2][3] = from.d3; to[3][3] = from.d4;
		return to;
	}
	static inline glm::vec3 GetGLMVec(const aiVector3D& vec)
	{
		return glm::vec3(vec.x, vec.y, vec.z);
	}

	static inline glm::quat GetGLMQuat(const aiQuaternion& pOrientation)
	{
		return glm::quat(pOrientation.w, pOrientation.x, pOrientation.y, pOrientation.z);
	}
};

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\bone.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 7299 bytes

```
#pragma once

/* Container for bone data */
#include <iostream>
#include <iomanip>
#include <unordered_map>
#include <string>
#include <list>
#include <vector>

#include <assimp/scene.h>
#include <glm/glm.hpp>
#include <glm/gtx/quaternion.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "AssimpGLMHelpers.h"

#define COUTL(param) cout << #param << ":" << param << endl
#define COUT(param) cout << #param << ":" << param << " "
#define CHECK(param)                                        \
    if (!(param))                                           \
    {                                                       \
        cout << __FUNCTION__ <<" "<< #param << ":error" << endl; \
        exit(-1);                                           \
    }
// Missing bones are usually bones that are not used in animation except pose.
// In joins in blender, set it to 1 to load the full bone information.
#define MISSING_BONES 0

struct BoneNode
{
    glm::mat4 transformation;
    std::string name;
    int childrenCount;
    std::vector<BoneNode> children;
};

struct BoneInfo
{
    // id is index in finalBoneMatrices
    int id;
    // offset matrix transforms vertex from model space to bone space
    glm::mat4 offset;
};

struct KeyPosition
{
    glm::vec3 position;
    float timeStamp;
};

struct KeyRotation
{
    glm::quat orientation;
    float timeStamp;
};

struct KeyScale
{
    glm::vec3 scale;
    float timeStamp;
};

class Bone
{
public:
    Bone(const std::string &name, int ID, const aiNodeAnim *channel)
        : m_Name(name),
          m_ID(ID),
          m_LocalTransform(1.0f)
    {
        m_NumPositions = channel->mNumPositionKeys;

        for (int positionIndex = 0; positionIndex < m_NumPositions; ++positionIndex)
        {
            aiVector3D aiPosition = channel->mPositionKeys[positionIndex].mValue;
            float timeStamp = channel->mPositionKeys[positionIndex].mTime;
            m_Positions.push_back({AssimpGLMHelpers::GetGLMVec(aiPosition), timeStamp});
        }

        m_NumRotations = channel->mNumRotationKeys;
        for (int rotationIndex = 0; rotationIndex < m_NumRotations; ++rotationIndex)
        {
            aiQuaternion aiOrientation = channel->mRotationKeys[rotationIndex].mValue;
            float timeStamp = channel->mRotationKeys[rotationIndex].mTime;
            m_Rotations.push_back({AssimpGLMHelpers::GetGLMQuat(aiOrientation), timeStamp});
        }

        m_NumScalings = channel->mNumScalingKeys;
        for (int keyIndex = 0; keyIndex < m_NumScalings; ++keyIndex)
        {
            aiVector3D scale = channel->mScalingKeys[keyIndex].mValue;
            float timeStamp = channel->mScalingKeys[keyIndex].mTime;
            m_Scales.push_back({AssimpGLMHelpers::GetGLMVec(scale), timeStamp});
        }
    }

    void Update(float animationTime)
    {
        glm::mat4 translation = InterpolatePosition(animationTime);
        glm::mat4 rotation = InterpolateRotation(animationTime);
        glm::mat4 scale = InterpolateScaling(animationTime);
        m_LocalTransform = translation * rotation * scale;
    }

    glm::mat4 GetLocalTransform() { return m_LocalTransform; }
    std::string GetBoneName() const { return m_Name; }
    int GetBoneID() { return m_ID; }

    int GetPositionIndex(float animationTime)
    {
        int index = 0;
        for (index = 0; index < m_NumPositions - 1; ++index)
        {
            if (animationTime < m_Positions[index + 1].timeStamp)
                return index;
        }
        // If "Force Start/End Keying" is not selected when exporting the model in blender
        // Return last frame key index
        return index;
    }

    int GetRotationIndex(float animationTime)
    {
        int index = 0;
        for (index = 0; index < m_NumRotations - 1; ++index)
        {
            if (animationTime < m_Rotations[index + 1].timeStamp)
                return index;
        }
        return index;
    }

    int GetScaleIndex(float animationTime)
    {
        int index = 0;
        for (index = 0; index < m_NumScalings - 1; ++index)
        {
            if (animationTime < m_Scales[index + 1].timeStamp)
                return index;
        }
        return index;
    }

private:
    float GetScaleFactor(float lastTimeStamp, float nextTimeStamp, float animationTime)
    {
        return ((animationTime - lastTimeStamp) / (nextTimeStamp - lastTimeStamp));
    }

    glm::mat4 InterpolatePosition(float animationTime)
    {
        if (1 == m_NumPositions)
            return glm::translate(glm::mat4(1.0f), m_Positions[0].position);

        int pIndex = GetPositionIndex(animationTime);

        // If "Force Start/End Keying" is not selected when exporting the model in blender
        if ((pIndex == 0 && m_Positions[pIndex].timeStamp >= animationTime) || pIndex == m_NumPositions - 1)
            return glm::translate(glm::mat4(1.0f), m_Positions[pIndex].position);

        float scaleFactor = GetScaleFactor(m_Positions[pIndex].timeStamp, m_Positions[pIndex + 1].timeStamp, animationTime);
        glm::vec3 finalPosition = glm::mix(m_Positions[pIndex].position, m_Positions[pIndex + 1].position, scaleFactor);

        return glm::translate(glm::mat4(1.0f), finalPosition);
    }

    glm::mat4 InterpolateRotation(float animationTime)
    {
        if (1 == m_NumRotations)
            return glm::toMat4(m_Rotations[0].orientation);

        int pIndex = GetRotationIndex(animationTime);

        if ((pIndex == 0 && m_Rotations[pIndex].timeStamp >= animationTime) || pIndex == m_NumRotations - 1)
            return glm::toMat4(m_Rotations[pIndex].orientation);

        float scaleFactor = GetScaleFactor(m_Rotations[pIndex].timeStamp, m_Rotations[pIndex + 1].timeStamp, animationTime);
        glm::quat finalRotation = glm::slerp(m_Rotations[pIndex].orientation, m_Rotations[pIndex + 1].orientation, scaleFactor);

        return glm::toMat4(finalRotation);
    }

    glm::mat4 InterpolateScaling(float animationTime)
    {
        if (1 == m_NumScalings)
            return glm::scale(glm::mat4(1.0f), m_Scales[0].scale);

        int pIndex = GetScaleIndex(animationTime);

        if ((pIndex == 0 && m_Scales[pIndex].timeStamp >= animationTime) || pIndex == m_NumScalings - 1)
            return glm::scale(glm::mat4(1.0f), m_Scales[pIndex].scale);

        float scaleFactor = GetScaleFactor(m_Scales[pIndex].timeStamp, m_Scales[pIndex + 1].timeStamp, animationTime);
        glm::vec3 finalScale = glm::mix(m_Scales[pIndex].scale, m_Scales[pIndex + 1].scale, scaleFactor);

        return glm::scale(glm::mat4(1.0f), finalScale);
    }

    std::vector<KeyPosition> m_Positions;
    std::vector<KeyRotation> m_Rotations;
    std::vector<KeyScale> m_Scales;

public:
    int m_NumPositions;
    int m_NumRotations;
    int m_NumScalings;

    std::string m_Name;
    int m_ID;
    glm::mat4 m_LocalTransform;
};

typedef std::unordered_map<unsigned int, std::string> UIntStringMap;
typedef std::unordered_map<std::string, BoneInfo> StringBoneInfoMap;
typedef std::unordered_map<std::string, Bone> StringBoneMap;

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\camera.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 2837 bytes

```
#ifndef __CAMERA_H__
#define __CAMERA_H__

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/string_cast.hpp>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include "appcontrol.h"

enum CameraMovement
{
    MOVE_FORWARD = 0,
    MOVE_BACKWARD,
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP,
    MOVE_DOWN
};

// default camera angles
const float YAW = -90.0f;
const float PITCH = 0.0f;
const float SPEED = 2.0f;
const float SENSITIVITY = 0.1f;
const float FOV = 45.0f;
const float Z_VALUE = -3.0f;

class Camera
{
public:
    // camera Attributes
    glm::vec3 m_cameraPos;
    glm::vec3 m_cameraDir;
    glm::vec3 m_cameraUp;
    // euler Angles
    float m_Yaw;
    float m_Pitch;

    float m_Fov;
    // camera options
    float MovementSpeed = SPEED;
    float MouseSensitivity = SENSITIVITY;

    glm::mat4 GetViewMatrix();
    void ProcessKeyBoard(CameraMovement direction, float deltaTime);
    void ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch = true);
    void ProcessMouseScroll(float yoffset);
    void updateCameraVectors();
    inline void SetSpeed(float speed) { MovementSpeed = speed; }
    static glm::mat4 calculate_lookAt_matrix(glm::vec3 cameraPos, glm::vec3 cameraDir, glm::vec3 cameraUp);
    void loadCameraPosition(GLFWwindow *window);
    void saveCameraPosition(GLFWwindow *window);

    Camera(GLFWwindow *window) { loadCameraPosition(window); }

    Camera(glm::vec3 cameraPos = glm::vec3(0.0f, 0.0f, -Z_VALUE), glm::vec3 cameraDir = glm::vec3(0.0f, 0.0f, Z_VALUE), glm::vec3 cameraUp = glm::vec3(0.0f, 1.0f, 0.0f))
        : m_cameraPos(cameraPos),
          m_cameraDir(cameraDir),
          m_cameraUp(cameraUp),
          m_Yaw(YAW),
          m_Pitch(PITCH),
          m_Fov(FOV)
    {
        updateCameraVectors();
    }

    Camera(float posX, float posY, float posZ, float dirX, float dirY, float dirZ, float upX, float upY, float upZ, float yaw, float pitch, float fov)
        : m_cameraPos(glm::vec3(posX, posY, posZ)),
          m_cameraDir(glm::vec3(dirX, dirY, dirZ)),
          m_cameraUp(glm::vec3(upX, upY, upZ)),
          m_Yaw(yaw),
          m_Pitch(pitch),
          m_Fov(fov)
    {
        updateCameraVectors();
    }
    void SetCameraSettings(float posX, float posY, float posZ, float dirX, float dirY, float dirZ, float upX, float upY, float upZ, float yaw, float pitch, float fov)
    {
        m_cameraPos = glm::vec3(posX, posY, posZ);
        m_cameraDir = glm::vec3(dirX, dirY, dirZ);
        m_cameraUp = glm::vec3(upX, upY, upZ);
        m_Yaw = yaw;
        m_Pitch = pitch;
        m_Fov = fov;
        updateCameraVectors();
    }
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\framebuffer.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 836 bytes

```
#ifndef __FRAMEBUFFER_H__
#define __FRAMEBUFFER_H__

#include <iostream>
#include <glad/glad.h>
using namespace std;

enum TEXTURE_TYPE_ENUM
{
    TEXTURE_NORMAL_2D = 0,
    TEXTURE_DEPTH_2D,
    TEXTURE_DEPTH_CUBE
};

class FrameBuffer
{
public:
    GLenum mframebuffer_id;
    GLenum mtexture_id;
    GLenum mwidth, mheight;
    GLenum mtextureTarget;
    GLenum mtextureType;
    FrameBuffer(GLenum frame_width, GLenum frame_height, GLenum textureType = GL_TEXTURE_2D, GLenum textureTarget = GL_TEXTURE0, GLboolean depthmap = false);
    GLenum &GetTextureID() { return mtexture_id; }
    GLenum &GetFrameBufferID() { return mframebuffer_id; }
    void TextureBind();
    void Bind();
};

// class RenderBuffer
// {
//     RenderBuffer(GLenum frame_width, GLenum frame_height, vector<)
// };

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\main.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 4813 bytes

```
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <vector>
#include <cmath>
#include <random>
#include <wchar.h>
#include <locale>
#include <codecvt>
#include <algorithm>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "imgui/imgui.h"
#include "imgui/imgui_impl_glfw.h"
#include "imgui/imgui_impl_opengl3.h"

#include "ft2build.h"
#include FT_FREETYPE_H

#include "model.h"
#include "shader.h"
#include "texture.h"
#include "vertexarray.h"
#include "camera.h"
// #include "framebuffer.h"

#include "SceneDefault.h"
#include "SceneAnimations.h"
#include "SceneCascadedShadowMap.h"

#include "objectrender.h"
#include "appcontrol.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
using namespace std;
using namespace glm;

bool imgui_window_focus = false;

// ⠀⠀⠀⠀⠀⠀⠀⠀⣀⡤⠶⠚⡲⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠸⣧⣀⡶⣦⠘⣽⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⣀⠤⠟⢛⣿⠉⣾⢭⣀⡉⣳⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⡰⠋⣁⡴⠛⠉⢹⣟⣻⠀⣴⠶⠃⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⡼⠁⣞⢁⡠⠔⠒⠉⠉⠉⠉⠙⠲⡤⣀⠀⠀⡀⠀⠀⠀
// ⠀⠀⠀⠈⢉⠟⠉⠀⠀⠀⠀⠀⠀⠀⡀⠀⠘⣦⣉⠩⡇⠀⠀⡀
// ⠀⠀⠀⣠⠃⠀⠀⠀⢀⣠⡀⠀⠀⠀⠸⡢⡠⢿⣿⡇⠀⠈⡹⠁
// ⢠⡒⠋⠁⠀⡀⠀⠀⢀⠇⡵⣖⠀⠀⡀⢇⠉⠢⡉⢳⠀⢏⠁⠀
// ⠀⠉⢒⠖⢠⠀⠀⠀⡟⠀⣀⣈⠑⠢⠽⠝⢀⣶⣜⡄⠀⠈⡆⠀
// ⠀⢀⡏⠀⡄⠀⠀⠈⡇⠀⠿⠿⠃⡀⠀⡀⡀⠙⠉⠸⡄⠀⢸⠀
// ⠀⢸⠁⠀⡇⠀⠀⠀⢹⠀⠀⠜⠀⠈⠉⠀⠀⠀⠀⣠⠇⠀⠈⡆
// ⠀⢸⡄⠀⡇⠀⠀⠀⠘⣦⣀⣠⣤⣤⡴⠶⣶⣶⡿⣿⠁⡀⠀⡇
// ⠀⠀⢳⡄⢳⡀⠀⢠⠀⠹⣿⡾⠘⠖⠱⣶⣴⡆⣹⣧⣾⠃⣸⠃
// ⠀⠀⠀⠉⠳⠿⠶⣬⣿⣶⣾⣿⣦⣓⠘⢋⣛⣧⡴⠻⡃⠒⠁⠀
// ⠀⠀⠀⠀⢀⣠⡾⠿⣿⣄⣤⢹⡎⠉⠉⠍⠉⠁⠠⠀⢱⡀⠀⠀

// U -- UTF-32; L -- UTF-16; u8 -- UTF-8;
string text_string("| mashiro-真白-ましろ ❀ ⛅ ✯ ❅\n ᕕ(◠ڼ◠)ᕗ Ciallo～(∠・ω< )⌒★ (ᗜ˰ᗜ)\n 天动万象 I will have order 𒆚 𒆚 𒆙");
char text_buffer[4096]{"| mashiro-真白-ましろ ❀ ⛅ ✯ ❅\n ᕕ(◠ڼ◠)ᕗ Ciallo～(∠・ω< )⌒★ (ᗜ˰ᗜ)\n 天动万象 I will have order 𒆚 𒆚 𒆙"};
// u32string u32text_string(U"| mashiro-真白-ましろ ❀ ⛅ ✯ ❅\n ᕕ(◠ڼ◠)ᕗ Ciallo～(∠・ω< )⌒★ (ᗜ˰ᗜ)\n 天动万象 I will have order 𒆚 𒆚 𒆙");
// u32string u32text_string(U"Mm Nn 使徒来袭 \nmashiro-真白-ましろ ❀ ⛅ ✯ ❅\n ᕕ(◠ڼ◠)ᕗ Ciallo～(∠・ω< )⌒★ (ᗜ˰ᗜ)\n 天动万象 I will have order 𒆚 𒆚 𒆙");

float text_size(0.01);

glm::vec3 background_color(0.1);

float exposure = 1.0;
bool hdr = 1;
float _fresnel = 0.0;

float zbuffer_near = 0.01;
float zbuffer_far = 50.0f;

glm::vec3 lightColor(1.0f, 1.0f, 1.0f);

glm::vec3 lightPos(0.0f, 2.0f, 0.0f);
// glm::vec3 lightDirection(0.0f, 0.0f, -1.0f);
glm::vec3 lightDirection(0.213315, -0.295711, 0.931156);

glm::vec3 sunlight_color(1.0f);
glm::vec3 sunlight_pos(20.0f, 3.0f, 100.0f);

// glm::vec3 lightSpotPos(-2.0f, 4.0f, -1.0f);
glm::vec3 lightSpotPos(-2.62747, 3.14707, -8.38304);

glm::vec3 light_am_di_sp_directional(0.3f, 0.6f, 0.2f);
glm::vec3 lightColor_point(1.0f);
glm::vec3 light_am_di_sp_point(0.1f, 0.5f, 0.1f);
glm::vec3 lightColor_spot(1.0f);
glm::vec3 light_am_di_sp_spot(0.1f, 0.8f, 0.1f);

unsigned int light_distance_select_point = 2;
unsigned int light_distance_select_spot = 2;
vector<vector<float>> light_distance{{0.14, 0.07}, {0.07, 0.017}, {0.027, 0.0028}, {0.014, 0.0007}, {0.007, 0.0002}};
vector<int> light_distance_index{32, 65, 160, 325, 600};
// ----------------------------air - water ice -- glass diamond
vector<float> refractive_index{1.00, 1.33, 1.309, 1.51, 2.42};
// float refractive_rate = 1.20;

glm::vec3 sphereColor(0.5, 0.0, 0.0);

int material_shininess = 32;

bool lighting_mode_camera = false;
// bool depth_test = false;
// bool gamma = false;
bool hasSSAO = true;

unsigned int VAO, VBO;

int opengl_init();
void imgui_frame();
// void framebuffer_size_callback(GLFWwindow *window, int width, int height);
void processInput(GLFWwindow *window);
void key_callback(GLFWwindow *window, int key, int scancode, int action, int mods);
void mouse_callback(GLFWwindow *window, double xpos, double ypos);
void scroll_callback(GLFWwindow *window, double xoffset, double yoffset);
void mouse_button_callback(GLFWwindow *window, int button, int action, int mods);
void SceneLightConfig(Shader &shader, glm::mat4 view, glm::mat4 projuction);

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\mesh.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1493 bytes

```
#ifndef __MESH_H__
#define __MESH_H__

#include "glad/glad.h"
#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"

#include "shader.h"
#include <vector>
#define MAX_BONE_INFLUENCE 4

struct Vertex
{
    // position
    glm::vec3 Position;
    // normal
    glm::vec3 Normal;
    // texCoords
    glm::vec2 TexCoords;
    // tangent
    glm::vec3 Tangent;
    // bitangent
    glm::vec3 Bitangent;
    // bone indexes which will influence this vertex
    int m_BoneIDs[MAX_BONE_INFLUENCE];
    // weights from each bone
    float m_Weights[MAX_BONE_INFLUENCE];
};

struct Materials
{
    int id;
    string type;
    string path;
    // if mesh has color only, id = -1
    glm::vec3 color;
};

class Mesh
{
public:
    vector<glm::vec3> mPositions;
    vector<Vertex> vertices;
    vector<unsigned int> indices;
    vector<Materials> materials;
    unordered_map<string, vector<glm::vec3>> morphAnims;
    unsigned int VAO;
    Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Materials> materials);
    Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Materials> materials, unordered_map<string, vector<glm::vec3>> morphAnims);
    ~Mesh();
    void Draw(Shader &shader);
    void Draw(Shader &shader, unordered_map<string, float> morphanimkeys);
    void DrawInstance(Shader &shader);

private:
    unsigned int VBO, EBO;
    unsigned int VBO_Position;
    void setupMesh();
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\model.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 3156 bytes

```
#ifndef __MODEL_H__
#define __MODEL_H__

#include <glad/glad.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <stb_image.h>

#include "assimp/Importer.hpp"
#include "assimp/scene.h"
#include "assimp/postprocess.h"
#include "AssimpGLMHelpers.h"

#include "mesh.h"
#include "shader.h"
#include "bone.h"

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <map>
#include <unordered_map>
#include <vector>
#include <iomanip>
#include <thread>
#include <mutex>

struct TetxtureType
{
    aiTextureType type;
    string prefix;
};

class Model
{
public:
    // model data
    vector<Materials> m_materials; // stores all the textures loaded so far, optimization to make sure textures aren't loaded more than once.
    vector<std::unique_ptr<Mesh>> m_meshes;
    // vector<Animation> animations;
    string directory;
    bool gammaCorrection;
    bool GetshapeKeysNameID = false;
    // morph data
    unordered_map<string, vector<glm::vec3>> morphAnims;
    unordered_map<unsigned int, string> shapeKeysNameID;
    unordered_map<string, float> morphAnimKeys;

    // constructor, expects a filepath to a 3D model.
    Model(string const &path, bool gamma = false);
    Model(const aiScene *scene, const string path);
    ~Model();
    // draws the model, and thus all its meshes
    void Draw(Shader &shader);
    void DrawInstance(Shader &shader);
    auto &GetBoneInfoMap() { return m_BoneInfoMap; }
    int &GetBoneCount() { return m_BoneCounter; }

    void SetMorphAnimKeys(unordered_map<string, float> morphanimkeys) { morphAnimKeys = morphanimkeys; }

private:
    // for animation
    std::unordered_map<string, BoneInfo> m_BoneInfoMap;
    int m_BoneCounter = 0;
    void SetVertexBoneDataToDefault(Vertex &vertex)
    {
        for (int i = 0; i < MAX_BONE_INFLUENCE; ++i)
        {
            vertex.m_BoneIDs[i] = -1;
            vertex.m_Weights[i] = .0f;
        }
    }
    void SetVertexBoneData(Vertex &vertex, int boneID, float weight)
    {
        for (int i = 0; i < MAX_BONE_INFLUENCE; ++i)
        {
            if (vertex.m_BoneIDs[i] < 0)
            {
                vertex.m_Weights[i] = weight;
                vertex.m_BoneIDs[i] = boneID;
                break;
            }
        }
    }
    void ExtractBoneWeightForVertices(vector<Vertex> &vertices, aiMesh *mesh);

    // loads a model with supported ASSIMP extensions from file and stores the resulting meshes int the meshse vector.
    void loadModel(string const &path);
    // processes a node in a recursive. Processes each individual mesh located at the node and repeats this process on its children nodes
    void processNode(aiNode *node, const aiScene *scene);
    void processMesh(aiMesh *mesh, const aiScene *scene);
    // checks all material textures of a given type and loads the textures if they're not loaded yet.
    // the required info is returned as a Texture struct.
    void loadMaterialTextures(vector<Materials> &materials, aiMaterial *mat, aiTextureType type, string typeName);
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\objectrender.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1660 bytes

```
#ifndef __OBJECTRENDER_H__
#define __OBJECTRENDER_H__

#include <glad/glad.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <map>

#include "vertexarray.h"
#include "texture.h"
#include "shader.h"
#include "resource.h"
#include "appcontrol.h"
#include "model.h"

using namespace glm;

class SKYObject
{
private:
    Shader &m_shader;
    VertexArray &m_VAO;
    unsigned int m_skymap;

public:
    SKYObject(Shader &s, VertexArray &vao, unsigned int skymap);
    void Render();
};

class PBRObject
{
private:
    Shader &m_shader;
    Model *m_model = nullptr;

public:
    static bool initialized;
    static unsigned int envCubemap;
    static unsigned int irradianceMap;
    static unsigned int prefilterMap;
    static unsigned int brdfLUTTexture;
    static void PBRInit(Shader &s, string hdr_map);
    PBRObject(Shader &s,string model_path);
    ~PBRObject() { delete m_model; }
    void Render(mat4 &model, vec3 camera_pos);
};

class TextObject
{
private:
    Shader &m_shader;
    u32string m_u32str;
    VertexArray *m_VAO = nullptr;
    // x -> linespec; y -> wordspec
    vec2 m_Typography = vec2(8.0, 0.0);

public:
    void
    LoadString(u32string u32str, vec2 screenPos, vec2 typoglaphy);
    TextObject(Shader &s, u32string u32str, vec2 screenPos, vec2 typoglaphy) : m_shader(s)
    {
        m_shader.Bind();
        m_shader.SetUniform1i("textTexture", 0);
        LoadString(u32str, screenPos, typoglaphy);
    }
    ~TextObject()
    {
        if (m_VAO != nullptr)
            delete m_VAO;
    }
    void Render(mat4 &model);
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\resource.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1884 bytes

```
#ifndef __RESOURCE_H__
#define __RESOURCE_H__

#include <iostream>
#include <iomanip>
#include <vector>
#include <unordered_map>
#include <string>
#include <map>

#include <glad/glad.h>
#include "texture.h"
#include "shader.h"
#include "vertexarray.h"
#include "appcontrol.h"

#include "ft2build.h"
#include FT_FREETYPE_H

using namespace std;

class ResourceManager
{
public:
    static std::unordered_map<string, Shader> Shaders;
    static std::unordered_map<string, Texture> Textures;
    static std::unordered_map<string, VertexArray> VAOs;

    static void ShaderInit(string name);
    static void Clear();

    static Shader &SetShader(string name, int vertex, int fragment, int geometry = -1);
    static Shader &GetShader(std::string name);

    static void LoadTexture(const string name, const string file);
    static Texture &GetTexture(std::string name);

    static void SetVAO(string name, vector<unsigned int> bufferlayout, const void *vbo_data, unsigned int vbo_size, const int vbo_usage = GL_STATIC_DRAW,
                       const void *ibo_data = nullptr, unsigned int ibo_count = 0, const int ibo_usage = GL_STATIC_DRAW);
    static VertexArray &GetVAO(const string name);

private:
    ResourceManager() {}
};

extern vector<string> font_paths;
#define FONT_SIZE 30

struct Character
{
    glm::ivec2 Size;      // Size of glyph
    glm::ivec2 Bearing;   // Offset from baseline to left/top of glyph
    unsigned int Advance; // Horizontal offset to advance to next glyph
    glm::vec4 Offset;     // textTexture offset
};

class TextTexture
{
public:
    static GLuint mtextureID;
    static GLfloat mtextureWidth, mtextureHeight;
    static map<char32_t, Character> Characters;
    static GLuint ChToTexture(u32string u32str);
    static GLuint GetTetureID() { return mtextureID; }
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\scene.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1771 bytes

```
#ifndef __SCENE_H__
#define __SCENE_H__

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glad/glad.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "camera.h"
#include "resource.h"
#include "objectrender.h"
#include "model.h"
#include "animation.h"

#define DELETE_PTR(param) \
    if (param != nullptr) \
        delete param;

class Scene
{
public:
    Camera *sceneCamera = nullptr;

    float sceneNearPlane = 0.001;
    float sceneFarPlane = 50.0f;
    unsigned int sceneWidth, sceneHeight;

    Scene(Camera *camera, unsigned int scr_width, unsigned int scr_height)
        : sceneWidth(scr_width), sceneHeight(scr_height)
    {
        sceneCamera = camera;
        App::projection = glm::perspective(glm::radians(sceneCamera->m_Fov), (float)sceneWidth / (float)sceneHeight, sceneNearPlane, sceneFarPlane);
        App::view = sceneCamera->GetViewMatrix();
        App::vp = App::projection * App::view;

        // --------------------------------------------------- shader file
        // ResourceManager::ShaderInit(std::string(RES_DIR) + "shaders.glsl");
    }

    virtual ~Scene()
    {
        ResourceManager::Clear();
    }

    virtual void Update(float dt)
    {
        glClearColor(0.4f, 0.4f, 0.4f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        App::projection = glm::perspective(glm::radians(sceneCamera->m_Fov), (float)sceneWidth / (float)sceneHeight, sceneNearPlane, sceneFarPlane);
        App::view = sceneCamera->GetViewMatrix();
        App::vp = App::projection * App::view;
        App::deltaTime = dt;
    }
    virtual void processInput([[maybe_unused]] GLFWwindow *window) {}
    virtual void Render() {}
};

#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\SceneAnimations.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 356 bytes

```
#pragma once
#include "scene.h"

class SceneAnimations : public Scene
{
public:
    Model *modelHutao = nullptr;
    Animations *pAnimations = nullptr;
    Animator *pAnimator = nullptr;
    SceneAnimations(Camera *camera, unsigned int width, unsigned int height);
    virtual ~SceneAnimations() override;
    virtual void Render() override;
};
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\SceneCascadedShadowMap.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1488 bytes

```
#pragma once
#include "scene.h"

// CSM
class SceneCascadedShadowMap : public Scene
{
public:
    Model *modelHutao = nullptr;
    Texture *texture = nullptr;
    VertexArray *planeVA = nullptr;
    VertexArray *quadVA = nullptr;
    unsigned int matricesUBO;
    unsigned int lightFBO;
    unsigned int lightDepthMaps;

    unsigned int debugLayer = 0;
    const glm::vec3 lightDir = glm::normalize(glm::vec3(1.0f, 5.0f, 1.0f));
    unsigned int depthMapResolution = 1920;
    std::vector<glm::mat4> lightMatricesCache;
    std::vector<float> shadowCascadeLevels{5.0f, 10.0f, 20.0f};

    glm::mat4 cameraViewMatric;
    float cameraNearPlane = 0.001f;
    float cameraFarPlane = 30.0f;

    SceneCascadedShadowMap(Camera *camera, unsigned int width, unsigned int height);
    virtual ~SceneCascadedShadowMap() override;
    virtual void Render() override;
    virtual void processInput(GLFWwindow *window) override;

    void renderScene(Shader &shader);
    void renderQuad();
    std::vector<glm::mat4> getLightSpaceMatrices();
    std::vector<glm::vec4> getFrustumCornersWorldSpace(const glm::mat4 &projview);
    std::vector<glm::vec4> getFrustumCornersWorldSpace(const glm::mat4 &proj, const glm::mat4 &view);
    glm::mat4 getLightSpaceMatrix(const float nearPlane, const float farPlane);
    void drawCascadeVolumeVisualizers(const std::vector<glm::mat4> &lightMatrices, Shader *shader);
    void drawVisualizerFrustums(Shader *shader);
};

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\SceneDefault.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 459 bytes

```
#pragma once
#include "scene.h"

class SceneDefault : public Scene
{
public:
    Model *modelHutao = nullptr;
    Animations *pAnimations = nullptr;
    Animator *pAnimator = nullptr;
    
    TextObject *text = nullptr;
    PBRObject *pbr_model = nullptr;
    SKYObject *skybox = nullptr;

    SceneDefault(Camera *camera, unsigned int width, unsigned int height);
    virtual ~SceneDefault() override;
    virtual void Render() override;
};
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\shader.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 4884 bytes

```
#ifndef __SHADER_H__
#define __SHADER_H__

#include <glad/glad.h>
#include <glm/glm.hpp>
#include <GLFW/glfw3.h>
#include <unordered_map>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <cmath>
#include <algorithm>
using namespace std;

// #define GLSL_CODE_OUTPUT
#define CHECK_SHADER(shader, id)                                                                              \
    do                                                                                                        \
    {                                                                                                         \
        GLint success;                                                                                        \
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);                                                   \
        if (!success)                                                                                         \
        {                                                                                                     \
            GLchar infoLog[512];                                                                              \
            glGetShaderInfoLog(shader, 512, NULL, infoLog);                                                   \
            std::cout << "\033[37;41mERROR:: " << #shader << " ID:" << id << " ::COMPILATION_FAILED\033[0m\n" \
                      << infoLog << std::endl;                                                                \
            exit(1);                                                                                          \
        }                                                                                                     \
    } while (0)

#define CHECK_PROGRAM(program)                                                                 \
    do                                                                                         \
    {                                                                                          \
        GLint success;                                                                         \
        glGetProgramiv(program, GL_LINK_STATUS, &success);                                     \
        if (!success)                                                                          \
        {                                                                                      \
            GLchar infoLog[512];                                                               \
            glGetProgramInfoLog(program, 512, NULL, infoLog);                                  \
            std::cout << "\033[37;41mERROR:: " << #program << " ::COMPILATION_FAILED\033[0m\n" \
                      << infoLog << std::endl;                                                 \
            exit(1);                                                                           \
        }                                                                                      \
    } while (0)

// The contents of the glsl file must be separated by a swap symbol
class Shader
{
private:
    GLuint ProgramID;
    std::unordered_map<std::string, int> m_UniformLoationCache;
    static vector<string> vertexShaderSources;
    static vector<string> fragmentShaderSources;
    static vector<string> geometryShaderSources;

public:
    static bool CodeOutput;
    static void ShaderInit(const string filepath);
    Shader(unsigned int vertexShader_ID, unsigned int fragmentShader_ID, int geometryShader_ID);
    Shader(unsigned int vertexShader_ID, unsigned int fragmentShader_ID) : Shader(vertexShader_ID, fragmentShader_ID, -1) {}
    ~Shader() { glDeleteProgram(ProgramID); }
    inline void Bind() { glUseProgram(ProgramID); }
    void Unbind() const { glUseProgram(0); }
    static void Clear();
    GLuint &GetID() { return ProgramID; }

    int GetUniformLocation(const std::string &name);
    void SetUniform1b(const std::string &name, bool value);
    void SetUniform1i(const std::string &name, int value);
    void SetUniform1f(const std::string &name, float value);
    void SetUniform2f(const std::string &name, float f0, float f1);
    void SetUniform2f(const std::string &name, const glm::vec2 &value);
    void SetUniform3f(const std::string &name, float f0, float f1, float f2);
    void SetUniform3f(const std::string &name, const glm::vec3 &value);
    void SetUniform4f(const std::string &name, float f0, float f1, float f2, float f3);
    void SetUniform4f(const std::string &name, const glm::vec4 &value);
    void SetUniform2m(const std::string &name, const glm::mat2 &mat);
    void SetUniform3m(const std::string &name, const glm::mat3 &mat);
    void SetUniform4m(const std::string &name, const glm::mat4 &mat);
};

#endif

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\texture.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 623 bytes

```
#ifndef __TEXTURE_H__
#define __TEXTURE_H__

#define STBI_WINDOWS_UTF8

#include <iostream>
#include <vector>
#include <string>
#include "stb_image.h"
#include <glad/glad.h>
using namespace std;

class Texture
{
private:
    unsigned int m_TextureID;
    unsigned int m_TextureTarget;

public:
    Texture(const string &path, GLenum textureTarget = GL_TEXTURE0, GLenum wrapMode = GL_REPEAT, GLenum mapFilter = GL_LINEAR, bool gammaCorrection = false);
    ~Texture();
    void Bind();
    void UnBind();
    unsigned int &GetTextureID();
};

unsigned int loadCubemap(vector<string> faces);
#endif
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: include\vertexarray.h

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 4337 bytes

```
#ifndef __VERTEXARRAY_H__
#define __VERTEXARRAY_H__

#include <iostream>
#include <vector>
#include "glad/glad.h"

using namespace std;

struct VertexBufferElement
{
    unsigned int type;
    unsigned int count;
    unsigned char normalized;

    static unsigned int GetSizeOfType(unsigned int type)
    {
        switch (type)
        {
        case GL_FLOAT:
            return sizeof(GLfloat);
        case GL_UNSIGNED_INT:
            return sizeof(GLuint);
        case GL_UNSIGNED_BYTE:
            return sizeof(GLbyte);
        }
        std::cout << __FUNCTION__ << "unknown type" << std::endl;
        exit(-1);
        return 0;
    }
};

class BufferLayout
{
private:
    unsigned int m_Stride;
    vector<VertexBufferElement> m_Elements;

    void Push(unsigned int type, unsigned int count, unsigned char normalized)
    {
        m_Elements.push_back({type, count, normalized});
        m_Stride += count * VertexBufferElement::GetSizeOfType(type);
    }

public:
    BufferLayout(vector<unsigned int> vect) : m_Stride(0)
    {
        for (auto v : vect)
            Push(GL_FLOAT, v, GL_FALSE);
    }
    void AddUnsignedInt(unsigned int count) { Push(GL_UNSIGNED_INT, count, GL_FALSE); }
    void AddUnsignedByte(unsigned int count) { Push(GL_UNSIGNED_BYTE, count, GL_TRUE); }

    inline const vector<VertexBufferElement> GetElements() const { return m_Elements; }
    inline unsigned int GetStride() const { return m_Stride; }
};

class IndexBuffer
{
private:
    unsigned int m_Count;
    unsigned int m_IBO;

public:
    IndexBuffer(const void *data, unsigned int count, const int usage = GL_STATIC_DRAW) : m_Count(count)
    {
        glGenBuffers(1, &m_IBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_IBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, m_Count * sizeof(unsigned int), data, usage);
    };
    ~IndexBuffer() { glDeleteBuffers(1, &m_IBO); }
    void Bind() const { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_IBO); }
    void UnBind() const { glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); }
    inline unsigned int GetIboID() const { return m_IBO; }
    inline unsigned int GetCount() const { return m_Count; }
};

class VertexBuffer
{
private:
    unsigned int m_VBO;

public:
    VertexBuffer(const void *data, unsigned int size, const int usage = GL_STATIC_DRAW)
    {
        glGenBuffers(1, &m_VBO);
        glBindBuffer(GL_ARRAY_BUFFER, m_VBO);
        glBufferData(GL_ARRAY_BUFFER, size, data, usage);
    }
    ~VertexBuffer() { glDeleteBuffers(1, &m_VBO); }
    void Bind() const { glBindBuffer(GL_ARRAY_BUFFER, m_VBO); }
    void UnBind() const { glBindBuffer(GL_ARRAY_BUFFER, 0); }
};

class VertexArray
{
private:
    unsigned int m_VAO;
    VertexBuffer m_VBO;
    IndexBuffer *m_IBO = nullptr;

public:
    VertexArray(vector<unsigned int> bufferlayout, const void *vbo_data, unsigned int vbo_size, const int vbo_usage = GL_STATIC_DRAW,
                const void *ibo_data = nullptr, unsigned int ibo_count = 0, const int ibo_usage = GL_STATIC_DRAW)
        : m_VBO(vbo_data, vbo_size, vbo_usage)
    {
        BufferLayout layout(bufferlayout);
        glGenVertexArrays(1, &m_VAO);
        glBindVertexArray(m_VAO);
        m_VBO.Bind();
        if (ibo_data != nullptr)
        {
            m_IBO = new IndexBuffer(ibo_data, ibo_count, ibo_usage);
            (*m_IBO).Bind();
        }
        const vector<VertexBufferElement> elements = layout.GetElements();
        unsigned int offset = 0;
        for (unsigned int i = 0; i < elements.size(); ++i)
        {
            const VertexBufferElement element = elements[i];
            glEnableVertexAttribArray(i);
            glVertexAttribPointer(i, element.count, element.type, element.normalized, layout.GetStride(), (void *)(uintptr_t)(offset * element.GetSizeOfType(element.type)));
            offset += element.count;
        }
    }
    ~VertexArray()
    {
        glDeleteVertexArrays(1, &m_VAO);
        if (m_IBO != nullptr)
            delete m_IBO;
    }
    void Bind() { glBindVertexArray(m_VAO); }
    void UnBind() { glDeleteVertexArrays(1, &m_VAO); }
    VertexBuffer &GetVertexBuffer() { return m_VBO; }
    IndexBuffer &GetIndexBuffer() { return *m_IBO; }
};

#endif

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\animation.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 10474 bytes

```
#include "animation.h"

Animation::Animation(const aiAnimation *animation, StringBoneInfoMap &modelBoneInfoMap, UIntStringMap &modelShapeKeysNameID)
{
    cout << endl
         << "-----------Animation:"
         << "Name:" << animation->mName.data << endl;
    m_Name = animation->mName.data;
    m_Duration = animation->mDuration;
    m_TicksPerSecond = animation->mTicksPerSecond;
    cout << " Tick:" << m_TicksPerSecond << " Duration:" << m_Duration << " ";

    ReadBonesAnims(animation, modelBoneInfoMap);
    ReadMorphAnims(animation, modelShapeKeysNameID);
}

Bone *Animation::FindBone(const string &name)
{
    auto iter = m_BoneKeys.find(name);
    if (iter != m_BoneKeys.end())
        return &(iter->second);
    return nullptr;
}

void Animation::ReadBonesAnims(const aiAnimation *animation, StringBoneInfoMap &modelBoneInfoMap)
{
    // COUT(animation->mNumChannels);

    auto &boneInfoMap = modelBoneInfoMap;
    // reading channels(bones engaged in an animation and their keyframes)
    for (unsigned int i = 0; i < animation->mNumChannels; i++)
    {
        auto channel = animation->mChannels[i];
        std::string boneName = channel->mNodeName.data;

        // check missing bone
        if (boneInfoMap.find(boneName) != boneInfoMap.end())
            m_BoneKeys.insert(std::make_pair(boneName, Bone(boneName, boneInfoMap[boneName].id, channel)));
#if (MISSING_BONES)
        // add missing bones
        else
        {
            boneInfoMap[boneName].id = boneInfoMap.size();
            cout << "missing bone:" << boneName << " ";
        }
#endif
    }
    COUT(m_BoneKeys.size());
}

void Animation::ReadMorphAnims(const aiAnimation *animation, UIntStringMap &modelShapeKeysNameID)
{
    if (animation->mNumMorphMeshChannels)
    {
        auto morphmeshchannels = animation->mMorphMeshChannels[0];
        cout << "morphName:" << morphmeshchannels->mName.data << " ";

        for (unsigned int i = 0; i < morphmeshchannels->mNumKeys; ++i)
        {
            auto &keys = morphmeshchannels->mKeys[i];

            unordered_map<string, float> shapekeys;
            for (unsigned int j = 0; j < keys.mNumValuesAndWeights; ++j)
            {
                // cout << "v:" << keys.mValues[j] << " w:" << keys.mWeights[j] << " | ";
                shapekeys.insert(make_pair(modelShapeKeysNameID[(keys.mValues[j])].data(), keys.mWeights[j]));
            }

            // insert missing from last frame
            if (m_MorphKeys.size())
                for (auto &lastShapeKey : m_MorphKeys.back().shapekeys)
                {
                    if (shapekeys.count(lastShapeKey.first) == 0 && lastShapeKey.second != 0)
                        shapekeys.insert(lastShapeKey);
                }

            m_MorphKeys.emplace_back(Morph{shapekeys, keys.mTime});
        }

        // If "Force Start/End Key" is selected when exporting the fbx model in blender
        // This will add all shapekeys to the start / end frames, we don't need these
        // Reomve first and last frame
        if (modelShapeKeysNameID.size() == (*(m_MorphKeys.begin())).shapekeys.size())
            m_MorphKeys.erase(m_MorphKeys.begin());
        if (modelShapeKeysNameID.size() == (*(m_MorphKeys.end() - 1)).shapekeys.size())
            m_MorphKeys.pop_back();
    }
    COUTL(m_MorphKeys.size());
}

unordered_map<string, float> Animation::morphAnimUpdate(float animationTime)
{
    unordered_map<string, float> morphAnimKey;
    // Get morphAnim index
    unsigned int index;
    if (m_MorphKeys.size())
    {
        for (index = 0; index < m_MorphKeys.size() - 1; ++index)
        {
            if (animationTime < m_MorphKeys[index + 1].timeStamp)
                break;
        }
    }
    else
        return morphAnimKey;

    // first key frame and last key frame
    if (index == 0 || index == m_MorphKeys.size() - 1)
        return m_MorphKeys[index].shapekeys;

    int p0Index = index;
    int p1Index = p0Index + 1;

    float scaleFactor = (animationTime - m_MorphKeys[p0Index].timeStamp) / (m_MorphKeys[p1Index].timeStamp - m_MorphKeys[p0Index].timeStamp);

    for (const auto &pair : m_MorphKeys[p0Index].shapekeys)
    {
        string shapeKeyName = pair.first;
        float p0_weight = pair.second;
        float fin_weight;
        if (m_MorphKeys[p1Index].shapekeys.count(pair.first) != 0)
        {
            float p1_weight = m_MorphKeys[p1Index].shapekeys[pair.first];
            fin_weight = glm::mix(p0_weight, p1_weight, scaleFactor);
        }
        else
            fin_weight = p0_weight;

        morphAnimKey.emplace(shapeKeyName, fin_weight);
        // cout << shapeKeyName << ":" << fin_weight << " ";
    }
    return morphAnimKey;
}

Animations::Animations(const std::string &animationPath, Model *model)
{
    Assimp::Importer importer;
    const aiScene *scene = importer.ReadFile(animationPath, aiProcess_Triangulate);
    CHECK(scene && scene->mRootNode);

    // load bone nodes
    ReadHierarchyData(m_RootBoneNode, scene->mRootNode);

    // load bone morph animations
    COUTL(scene->mNumAnimations);
    for (unsigned int index = 0; index < scene->mNumAnimations; ++index)
    {
        auto animation = scene->mAnimations[index];
        m_Animations.emplace_back(Animation(animation, model->GetBoneInfoMap(), model->shapeKeysNameID));
        m_Names.push_back(animation->mName.data);
    }
}

Animations::Animations(const aiScene *scene, Model *model)
{
    // load bone nodes
    ReadHierarchyData(m_RootBoneNode, scene->mRootNode);

    // load bone morph animations
    COUTL(scene->mNumAnimations);
    for (unsigned int index = 0; index < scene->mNumAnimations; ++index)
    {
        auto animation = scene->mAnimations[index];
        m_Animations.emplace_back(Animation(animation, model->GetBoneInfoMap(), model->shapeKeysNameID));
        m_Names.push_back(animation->mName.data);
    }
}

void Animations::ReadHierarchyData(BoneNode &dest, const aiNode *src)
{
    CHECK(src);

    dest.name = src->mName.data;
    dest.transformation = AssimpGLMHelpers::ConvertMatrixToGLMFormat(src->mTransformation);
    dest.childrenCount = src->mNumChildren;

    for (unsigned int i = 0; i < src->mNumChildren; i++)
    {
        BoneNode newData;
        ReadHierarchyData(newData, src->mChildren[i]);
        dest.children.push_back(newData);
    }
}

Animator::Animator(Animations *animations, Model *model)
{
    if (animations == nullptr || animations->GetAnimations().empty())
    {
        std::cout << "animations is empty" << std::endl;
        exit(-1);
    }

    m_Animations = animations;
    m_Model = model;

    // default first animation
    m_CurrentTime = 0.0;
    m_CurrentAnimation = &m_Animations->GetAnimations()[0];
    m_FinalBoneMatrices.resize(m_Model->GetBoneInfoMap().size());

    // ---------------------------------- sampler2D boneMatrixImage;
    glGenTextures(1, &boneMatrixTexture);
    glBindTexture(GL_TEXTURE_2D, boneMatrixTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 4, m_Model->GetBoneInfoMap().size(), 0, GL_RGBA, GL_FLOAT, NULL);
}

void Animator::UpdateAnimation(float dt)
{
    if (m_CurrentAnimation)
    {
        m_CurrentTime += m_CurrentAnimation->GetTicksPerSecond() * dt;
        m_CurrentTime = fmod(m_CurrentTime, m_CurrentAnimation->GetDuration());

        auto morphAnimKeys = m_CurrentAnimation->morphAnimUpdate(m_CurrentTime);
        m_Model->SetMorphAnimKeys(morphAnimKeys);

        CalculateBoneTransform(&m_Animations->GetBoneRootNode(), glm::mat4(1.0f));
    }

    // ---------------------------  sampler2D boneMatrixImage;
    std::vector<float> pixelData(m_FinalBoneMatrices.size() * 16);
    memcpy(pixelData.data(), m_FinalBoneMatrices.data(), pixelData.size() * sizeof(float));
    // int elementIndex = 0;
    // for (unsigned int i = 0; i < transforms.size(); ++i)
    // {
    //     glm::mat4 boneMatrix = transforms[i];
    //     // loop row and column
    //     for (int j = 0; j < 4; ++j)
    //     {
    //         for (int k = 0; k < 4; ++k, ++elementIndex)
    //         {
    //             pixelData[elementIndex] = boneMatrix[j][k];
    //         }
    //     }
    // }
    // "boneMatrixImage", 10 -- GL_TEXTURE10
    glActiveTexture(GL_TEXTURE10);
    glBindTexture(GL_TEXTURE_2D, boneMatrixTexture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 4, m_FinalBoneMatrices.size(), GL_RGBA, GL_FLOAT, &pixelData[0]);
}

void Animator::CalculateBoneTransform(const BoneNode *node, glm::mat4 parentTransform)
{
    std::string nodeName = node->name;
    glm::mat4 nodeTransform = node->transformation;
    Bone *Bone = m_CurrentAnimation->FindBone(nodeName);

    if (Bone)
    {
        Bone->Update(m_CurrentTime);
        nodeTransform = Bone->GetLocalTransform();
    }

    glm::mat4 globalTransformation = parentTransform * nodeTransform;

    auto &boneInfoMap = m_Model->GetBoneInfoMap();
    if (boneInfoMap.find(nodeName) != boneInfoMap.end())
    {
        m_FinalBoneMatrices[boneInfoMap.at(nodeName).id] = globalTransformation * boneInfoMap.at(nodeName).offset;
    }

    for (int i = 0; i < node->childrenCount; i++)
    {
        CalculateBoneTransform(&node->children[i], globalTransformation);
    }
}

void ModelImporter::ModelImport(const string path, Model **model, Animations **animations, Animator **animator, Shader &shader)
{
    Assimp::Importer importer;
    const aiScene *scene = importer.ReadFile(path, aiProcess_Triangulate | aiProcess_GenSmoothNormals | aiProcess_FlipUVs | aiProcess_CalcTangentSpace);
    CHECK(scene && scene->mRootNode);
    shader.Bind();
    shader.SetUniform1i("boneMatrixImage", 10);

    if (*model != nullptr || *animations != nullptr || *animator != nullptr)
        cout
            << __FUNCTION__ << ":error" << endl;

    *model = new Model(scene, path);
    *animations = new Animations(scene, *model);
    *animator = new Animator(*animations, *model);
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\appcontrol.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1075 bytes

```
#include "appcontrol.h"

unsigned int AppControl::scr_width = 1920;
unsigned int AppControl::scr_height = 1080;
glm::mat4 AppControl::view = glm::mat4(1.0);
glm::mat4 AppControl::projection = glm::mat4(1.0);
glm::mat4 AppControl::vp = glm::mat4(1.0);
float AppControl::deltaTime = 0.0f;

glm::vec3 AppControl::pointLightPos = glm::vec3(.0f);
glm::vec3 AppControl::pointLightColor = glm::vec3(1.0f);

float AppControl::thickness = 0.5;
float AppControl::softness = 0.1;
float AppControl::outline_thickness = 0.5;
float AppControl::outline_softness = 0.01;
glm::vec3 AppControl::text_color = glm::vec3(0.2, 0.8, 0.9);
glm::vec2 AppControl::text_shadow_offset = glm::vec2(2.0, 2.0);

glm::vec3 AppControl::irradiance_color = glm::vec3(1.0);

std::vector<std::string> AppControl::animNames = {""};
int AppControl::animIndex = 0;
float AppControl::playSpeed = 1.0f;
float AppControl::duration = .0f;
float AppControl::currentFrame = .0f;
bool AppControl::playBackState = false;

float AppControl::bias_offs = 0.2f;
float AppControl::bias_mids = 12.0f;
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\camera.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 6115 bytes

```
#include "../include/camera.h"
using namespace std;

glm::mat4 Camera::GetViewMatrix()
{

    return calculate_lookAt_matrix(m_cameraPos, m_cameraDir, m_cameraUp);
    // return glm::lookAt(m_cameraPos, m_cameraPos + m_cameraDir, m_cameraUp);
}

void Camera::ProcessKeyBoard(CameraMovement direction, float deltaTime)
{
    float velocity = MovementSpeed * deltaTime;
    glm::vec3 move_vector(0.0f, 0.0f, 0.0f);

    switch (direction)
    {
    case MOVE_FORWARD:
        move_vector = -glm::normalize(glm::cross(glm::cross(m_cameraDir, m_cameraUp), m_cameraUp));
        // move_vector = m_cameraDir;
        break;
    case MOVE_BACKWARD:
        move_vector = glm::normalize(glm::cross(glm::cross(m_cameraDir, m_cameraUp), m_cameraUp));
        // move_vector = -m_cameraDir;
        break;
    case MOVE_LEFT:
        move_vector = -glm::normalize(glm::cross(m_cameraDir, m_cameraUp));
        break;
    case MOVE_RIGHT:
        move_vector = glm::normalize(glm::cross(m_cameraDir, m_cameraUp));
        break;
    case MOVE_UP:
        move_vector = m_cameraUp;
        // move_vector = glm::normalize(glm::cross(glm::normalize(glm::cross(m_cameraDir, m_cameraUp)), m_cameraDir));
        break;
    case MOVE_DOWN:
        move_vector = -m_cameraUp;
        // move_vector = -glm::normalize(glm::cross(glm::normalize(glm::cross(m_cameraDir, m_cameraUp)), m_cameraDir));
        break;
    default:
        break;
    }

    move_vector *= velocity;
    m_cameraPos += move_vector;
}

// void Camera::ProcessKeyBoard(CameraMovement direction, float deltaTime)
// {
//     float velocity = MovementSpeed * deltaTime;
//     glm::vec3 move_vector(0.0f, 0.0f, 0.0f);

//     switch (direction)
//     {
//     case MOVE_FORWARD:
//         move_vector.z -= m_cameraFront;
//         break;
//     case MOVE_BACKWARD:
//         move_vector.z += 1.0f;
//         break;
//     case MOVE_LEFT:
//         move_vector.x -= 1.0f;
//         break;
//     case MOVE_RIGHT:
//         move_vector.x += 1.0f;
//         break;
//     case MOVE_UP:
//         move_vector.y += 1.0f;
//         break;
//     case MOVE_DOWN:
//         move_vector.y -= 1.0f;
//         break;
//     default:
//         break;
//     }

//     move_vector = glm::normalize(move_vector) * velocity;
//     m_cameraPos += move_vector;
// }

void Camera::ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch)
{
    xoffset *= MouseSensitivity;
    yoffset *= MouseSensitivity;

    m_Yaw += xoffset;
    m_Pitch += yoffset;

    if (constrainPitch)
    {
        m_Pitch = glm::clamp(m_Pitch, -89.0f, 89.0f);
    }

    updateCameraVectors();
}

void Camera::ProcessMouseScroll(float yoffset)
{
    m_Fov -= (float)yoffset;
    if (m_Fov < 1.0f)
        m_Fov = 1.0f;
    if (m_Fov > 89.0f)
        m_Fov = 89.0f;
}

void Camera::updateCameraVectors()
{
    m_cameraDir.x = cos(glm::radians(m_Pitch)) * cos(glm::radians(m_Yaw));
    m_cameraDir.y = sin(glm::radians(m_Pitch));
    m_cameraDir.z = cos(glm::radians(m_Pitch)) * sin(glm::radians(m_Yaw));
    // m_cameraDir = glm::normalize(direction);
}

void Camera::loadCameraPosition(GLFWwindow *window)
{
    std::ifstream file(string(RES_DIR) + "config.ini");
    if (file.is_open())
    {
        int SCR_X_POS = 0, SCR_Y_POS = 0;
        float posX,
            posY, posZ, dirX, dirY, dirZ, upX, upY, upZ, yaw, pitch;
        file >> posX >> posY >> posZ;
        file >> dirX >> dirY >> dirZ;
        file >> upX >> upY >> upZ;
        file >> yaw;
        file >> pitch;
        file >> SCR_X_POS;
        file >> SCR_Y_POS;
        glfwSetWindowPos(window, SCR_X_POS, SCR_Y_POS);
        file.close();
        SetCameraSettings(posX, posY, posZ, dirX, dirY, dirZ, upX, upY, upZ, yaw, pitch, FOV);
    }
    else
        SetCameraSettings(0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, FOV);
}

void Camera::saveCameraPosition(GLFWwindow *window)
{
    std::ofstream file(string(RES_DIR) + "config.ini");
    if (file.is_open())
    {
        int SCR_X_POS = 0, SCR_Y_POS = 0;
        file << m_cameraPos.x << " " << m_cameraPos.y << " " << m_cameraPos.z << "\n";
        file << m_cameraDir.x << " " << m_cameraDir.y << " " << m_cameraDir.z << "\n";
        file << m_cameraUp.x << " " << m_cameraUp.y << " " << m_cameraUp.z << "\n";
        file << m_Yaw << "\n";
        file << m_Pitch << "\n";
        // file << m_Fov << "\n";
        glfwGetWindowPos(window, &SCR_X_POS, &SCR_Y_POS);
        file << SCR_X_POS << "\n";
        file << SCR_Y_POS << "\n";
        file.close();
    }
}

// Custom implementation of the LookAt function
glm::mat4 Camera::calculate_lookAt_matrix(glm::vec3 position, glm::vec3 target, glm::vec3 worldUp)
{
    // 1. Position = known
    // 2. Calculate cameraDirection
    glm::vec3 zaxis = glm::normalize(-target);
    // 3. Get positive right axis vector
    glm::vec3 xaxis = glm::normalize(glm::cross(glm::normalize(worldUp), zaxis));
    // 4. Calculate camera up vector
    glm::vec3 yaxis = glm::cross(zaxis, xaxis);

    // Create translation and rotation matrix
    // In glm we access elements as mat[col][row] due to column-major layout
    glm::mat4 translation = glm::mat4(1.0f); // Identity matrix by default
    translation[3][0] = -position.x;         // Third column, first row
    translation[3][1] = -position.y;
    translation[3][2] = -position.z;
    glm::mat4 rotation = glm::mat4(1.0f);
    rotation[0][0] = xaxis.x; // First column, first row
    rotation[1][0] = xaxis.y;
    rotation[2][0] = xaxis.z;
    rotation[0][1] = yaxis.x; // First column, second row
    rotation[1][1] = yaxis.y;
    rotation[2][1] = yaxis.z;
    rotation[0][2] = zaxis.x; // First column, third row
    rotation[1][2] = zaxis.y;
    rotation[2][2] = zaxis.z;

    // Return lookAt matrix as combination of translation and rotation matrix
    return rotation * translation; // Remember to read from right to left (first translation then rotation)
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\main.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 10231 bytes

```
#include "main.h"

float deltaTime = 0.0f;
float lastFrame = 0.0f;
bool rightClick = true;
bool firstMouse = true;
bool controlKey = false;

// Camera camera;
GLFWwindow *window = nullptr;
Camera *camera = nullptr;
Scene *scene = nullptr;

int main(int argc, char *argv[])
{

    if (opengl_init())
        return -1;

    float initTime = glfwGetTime();

    camera = new Camera(window);
    ResourceManager::ShaderInit(std::string(RES_DIR) + "shaders.glsl");

    if (argc < 2)
    {
        std::cout << "Usage: opengl.exe [-cascaded | -animations]" << std::endl;
        scene = new SceneDefault(camera, App::scr_width, App::scr_height);
    }
    else
    {
        std::string arg = argv[1];
        if (arg == "-cascaded")
            scene = new SceneCascadedShadowMap(camera, App::scr_width, App::scr_height);
        else if (arg == "-animations")
            scene = new SceneAnimations(camera, App::scr_width, App::scr_height);
        else
        {
            std::cout << "Usage: opengl.exe [-cascaded | -animations]" << std::endl;
            scene = new SceneDefault(camera, App::scr_width, App::scr_height);
        }
    }

    lastFrame = glfwGetTime();
    cout << endl
         << "Initialization time(s):" << lastFrame - initTime << endl;

    while (!glfwWindowShouldClose(window))
    {
        processInput(window);

        float currentFrame = glfwGetTime();
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        imgui_frame();

        scene->Update(deltaTime);
        scene->Render();

        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // Cleanup
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    camera->saveCameraPosition(window);

    glfwTerminate();
    return 0;
}

int opengl_init()
{
    // glfw: initialize and configure
    // ------------------------------
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
    glfwWindowHint(GLFW_SAMPLES, 4);

    // glfw window creation
    // --------------------
    window = glfwCreateWindow(App::scr_width, App::scr_height, "mashiro", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    // glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    // glad: load all OpenGL function pointers
    // ---------------------------------------
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    glfwSetKeyCallback(window, key_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetMouseButtonCallback(window, mouse_button_callback);
    glfwSetScrollCallback(window, scroll_callback);
    glViewport(0, 0, App::scr_width, App::scr_height);

    // glEnable(GL_MULTISAMPLE); // Enabled by default on some drivers, but not all so always enable to make sure
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
    // glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    // glEnable(GL_FRAMEBUFFER_SRGB);
    // glEnable(GL_CULL_FACE);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    // ImGuiIO &io = ImGui::GetIO();
    // (void)io;
    // io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    const char *glsl_version = "#version 420";
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    return 0;
}

void imgui_frame()
{
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
    ImGui::Begin("LearnOpenGL");
    // ImGui::BeginChild("scrolling", ImVec2(0, 0), false, ImGuiWindowFlags_HorizontalScrollbar);

    imgui_window_focus = ImGui::IsWindowFocused();
    ImGui::PushItemWidth(140);
    ImGui::Text("Pos: %0.2f,%0.2f,%0.2f", camera->m_cameraPos.x, camera->m_cameraPos.y, camera->m_cameraPos.z);
    if (ImGui::Button("Pos_Reset"))
        camera->m_cameraPos = vec3(.0f);
    ImGui::Text("(%.3f ms)(%.1f fps)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
    if (ImGui::CollapsingHeader("Light"))
    {
        ImGui::SliderFloat3("PointLightPos", (float *)&App::pointLightPos, .0f, 4.0f);
        ImGui::SliderFloat3("PointLightColor", (float *)&App::pointLightColor, .0f, 1.0f);
    }
    if (ImGui::CollapsingHeader("PBR"))
    {
        ImGui::ColorEdit3(" point", (float *)&App::irradiance_color);
    }
    if (ImGui::CollapsingHeader("Text"))
    {
        ImGui::SliderFloat2("ShadowOffset", (float *)&App::text_shadow_offset, -5.0f, 5.0f);
        ImGui::PushItemWidth(40);
        ImGui::SliderFloat("Thickness", &App::thickness, 0.4, 0.8);
        ImGui::SliderFloat("Softness", &App::softness, 0.0, 0.5);
        ImGui::SliderFloat("OutlineThickness", &App::outline_thickness, 0.4, 0.8);
        ImGui::SliderFloat("OutlineSoftness", &App::outline_softness, 0.0, 0.1);
    }
    if (ImGui::CollapsingHeader("Animation", ImGuiTreeNodeFlags_DefaultOpen))
    {

        vector<const char *> itemLabels;
        for (const auto &item : App::animNames)
            itemLabels.push_back(item.c_str());
        ImGui::Combo("Animations", &App::animIndex, itemLabels.data(), itemLabels.size());

        ImGui::SliderFloat("PerFrame", &App::currentFrame, .0f, App::duration);
        if (ImGui::Button(App::playBackState ? "Pause" : "Play"))
            App::playBackState = !App::playBackState;
        ImGui::SameLine();
        ImGui::SliderFloat("PlaySpeed", &App::playSpeed, .1f, 2.0f);
    }
    if (ImGui::CollapsingHeader("Cascaded CSM"))
    {
        ImGui::SliderFloat("bias_offs", &AppControl::bias_offs, 0.1f, 2.0f);
        ImGui::SliderFloat("bias_mids", &AppControl::bias_mids, 1.0f, 25.0f);
    }
    // ImGui::EndChild();
    ImGui::End();
}

// void framebuffer_size_callback([[maybe_unused]] GLFWwindow *window, [[maybe_unused]] int width, [[maybe_unused]] int height)
// {
// make sure the viewport matches the new window dimensions; note that width and height
// will be significantly larger than specified on retina displays
// glViewport(0, 0, width, height);
// SCR_WIDTH = width;
// SCR_HEIGHT = height;
// int x = (width - SCR_WIDTH) / 4;
// int y = (height - SCR_HEIGHT) / 4;
// cout << width << " -/2 " << SCR_WIDTH << "=" << x << " " << height << " -/2 " << SCR_HEIGHT << "=" << y << endl;
// glViewport(x, y, SCR_WIDTH, SCR_HEIGHT);
// }

void processInput(GLFWwindow *window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    if (!imgui_window_focus)
    {
        if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_RIGHT, deltaTime);
        }
        if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_LEFT, deltaTime);
        }
        if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_FORWARD, deltaTime);
        }
        if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_BACKWARD, deltaTime);
        }
        if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_UP, deltaTime);
        }
        if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
        {
            camera->ProcessKeyBoard(MOVE_DOWN, deltaTime);
        }
        if (scene != nullptr)
            scene->processInput(window);
    }
}

void key_callback(GLFWwindow *window, int key, int scancode, int action, int mods)
{
    (void)(window);
    (void)(scancode);
    (void)(mods);
    if (key == GLFW_KEY_LEFT_CONTROL)
    {
        controlKey = (action == GLFW_PRESS || action == GLFW_REPEAT);
    }
}

void mouse_callback(GLFWwindow *window, double xpos, double ypos)
{
    (void)window;
    static float lastX = xpos, lastY = ypos;

    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
        return;
    }
    if (!rightClick && !imgui_window_focus)
    {
        float xoffset = xpos - lastX;
        float yoffset = lastY - ypos;
        lastX = xpos;
        lastY = ypos;
        camera->ProcessMouseMovement(xoffset, yoffset);
    }
}

void scroll_callback(GLFWwindow *window, double xoffset, double yoffset)
{
    static float speed_move = 2.0f;
    (void)window;
    (void)xoffset;
    if (!rightClick && controlKey)
    {
        camera->ProcessMouseScroll(yoffset);
    }
    else if (yoffset > 0)
    {
        speed_move += (speed_move < 1.0f) ? 0.1f : 0.5f;
        // speed_move += 0.1;
        camera->SetSpeed(speed_move);
    }
    else if (yoffset < 0)
    {
        speed_move -= (speed_move <= 1.0f) ? 0.1f : 0.5f;
        // speed_move -= 0.1;
        speed_move = std::max(speed_move, 0.1f);
        camera->SetSpeed(speed_move);
    }
}

void mouse_button_callback(GLFWwindow *window, int button, int action, int mods)
{
    (void)mods;
    if (button == GLFW_MOUSE_BUTTON_RIGHT && action == GLFW_PRESS && !imgui_window_focus)
    {
        static bool flag = true;
        if (flag)
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
            rightClick = false;
            firstMouse = true;
        }
        else
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
            rightClick = true;
        }
        flag = !flag;
    }
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\mesh.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 6642 bytes

```
#include "../include/mesh.h"

Mesh::Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Materials> materials)
{
    this->vertices = vertices;
    this->indices = indices;
    this->materials = materials;
    setupMesh();
}

Mesh::Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Materials> materials, unordered_map<string, vector<glm::vec3>> morphAnims)
{
    this->vertices = vertices;
    this->indices = indices;
    this->materials = materials;
    this->morphAnims = morphAnims;
    setupMesh();
}

Mesh::~Mesh()
{
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteBuffers(1, &EBO);
    glDeleteBuffers(1, &VBO_Position);
}

void Mesh::Draw([[maybe_unused]] Shader &shader)
{
    // bind appropriate textures
    for (unsigned int i = 0; i < materials.size(); i++)
    {
        // if (materials[i].id != -1)
        // {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, materials[i].id);
        // shader.SetUniform4f("colorOnly", glm::vec4(-1.0));
        // }
        // else
        //     shader.SetUniform4f("colorOnly", glm::vec4(materials[i].color, 1.0));
    }
    // draw mesh
    glBindVertexArray(VAO);

    // glBindBuffer(GL_ARRAY_BUFFER, 0);

    glDrawElements(GL_TRIANGLES, static_cast<unsigned int>(indices.size()), GL_UNSIGNED_INT, 0);
    // glDrawArrays(GL_TRIANGLES, 0, static_cast<unsigned int>(vertices.size()));
    // glDrawArrays(GL_TRIANGLE_STRIP, 0, static_cast<unsigned int>(vertices.size()));
    glBindVertexArray(0);

    // always good practice to set everything back to defaults once configured.
    glActiveTexture(GL_TEXTURE0);
}

void Mesh::Draw([[maybe_unused]] Shader &shader, unordered_map<string, float> morphanimkeys)
{
    // bind appropriate textures
    for (unsigned int i = 0; i < materials.size(); i++)
    {
        // if (materials[i].id != -1)
        // {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, materials[i].id);
        // shader.SetUniform4f("colorOnly", glm::vec4(-1.0));
        // }
        // else
        // shader.SetUniform4f("colorOnly", glm::vec4(materials[i].color, 1.0));
    }
    glBindVertexArray(VAO);

    if (!morphAnims.empty())
    {
        vector<glm::vec3> vers = mPositions;
        if (!morphanimkeys.empty())
        {
            for (const auto &morphanimkey : morphanimkeys)
            {
                string keyName = morphanimkey.first;
                float keyValue = morphanimkey.second;
                if (morphAnims.count(keyName))
                {
                    auto &positions = morphAnims[keyName];
                    for (unsigned int i = 0; i < mPositions.size(); ++i)
                    {
                        vers[i] += (positions[i] * keyValue);
                    }
                }
            }
        }
        glBindBuffer(GL_ARRAY_BUFFER, VBO_Position);
        glBufferSubData(GL_ARRAY_BUFFER, 0, vers.size() * sizeof(glm::vec3), vers.data());
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    glDrawElements(GL_TRIANGLES, static_cast<unsigned int>(indices.size()), GL_UNSIGNED_INT, 0);
    glBindVertexArray(0);

    // always good practice to set everything back to defaults once configured.
    glActiveTexture(GL_TEXTURE0);
}

void Mesh::DrawInstance([[maybe_unused]] Shader &shader)
{
    // bind appropriate textures
    for (unsigned int i = 0; i < materials.size(); i++)
    {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, materials[i].id);
    }

    // draw mesh
    glBindVertexArray(VAO);
    glDrawElementsInstanced(GL_TRIANGLES, static_cast<unsigned int>(indices.size()), GL_UNSIGNED_INT, 0, 3000);
    glBindVertexArray(0);

    // always good practice to set everything back to defaults once configured.
    glActiveTexture(GL_TEXTURE0);
}

void Mesh::setupMesh()
{
    // create buffers/arrays
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);

    // -------------
    if (morphAnims.size())
    {
        mPositions.resize(vertices.size());
        std::transform(vertices.begin(), vertices.end(), mPositions.begin(),
                       [](const Vertex &vertice)
                       { return vertice.Position; });
        glGenBuffers(1, &VBO_Position);
        glBindBuffer(GL_ARRAY_BUFFER, VBO_Position);
        glBufferData(GL_ARRAY_BUFFER, mPositions.size() * sizeof(glm::vec3), mPositions.data(), GL_DYNAMIC_DRAW);
    }

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (void *)0);

    // load data into vertex buffers
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // A greate thing about struct is that their memory layout is sequential for all its items.
    // The effect is that we can simply pass a pointer to the struct and it translates perfectly to a glm::vec3/2 array which again translates to 3/2 floats which translates to a byte array.
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(Vertex), &vertices[0], GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned int), &indices[0], GL_STATIC_DRAW);

    // set the vertex attribute pointers
    // vertex Positions
    if (morphAnims.size() == 0)
    {
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)0);
    }
    // vertex normals
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, Normal));
    // vertex texture coords
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, TexCoords));
    // vertex tangent
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, Tangent));
    // vertex bitangent
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, Bitangent));
    // ids
    glEnableVertexAttribArray(5);
    glVertexAttribIPointer(5, 4, GL_INT, sizeof(Vertex), (void *)offsetof(Vertex, m_BoneIDs));
    // weights
    glEnableVertexAttribArray(6);
    glVertexAttribPointer(6, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void *)offsetof(Vertex, m_Weights));
    glBindVertexArray(0);
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\model.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 15605 bytes

```
#include "model.h"

// Most of the program startup time is spent on stbi_load loading textures.
// Using threads can speed up startup time a bit.
#define TEXTURE_THREAD 1

#if TEXTURE_THREAD
vector<thread> texture_threads;
std::mutex texture_mtx;
struct TextureData
{
    int width, height, nrComponents;
    unsigned int textureID;
    unsigned char *data;
};
vector<TextureData> textureData;

void TextureFromData(vector<TextureData> &textureData)
{
    for (auto &texture : textureData)
    {
        GLenum internalformat = 0;
        GLenum dataformat = 0;
        if (texture.nrComponents == 1)
        {
            internalformat = dataformat = GL_RED;
        }
        else if (texture.nrComponents == 3)
        {
            internalformat = GL_RGB;
            dataformat = GL_RGB;
        }
        else if (texture.nrComponents == 4)
        {
            internalformat = GL_RGBA;
            dataformat = GL_RGBA;
        }
        glBindTexture(GL_TEXTURE_2D, texture.textureID);
        glTexImage2D(GL_TEXTURE_2D, 0, internalformat, texture.width, texture.height, 0, dataformat, GL_UNSIGNED_BYTE, texture.data);
        glGenerateMipmap(GL_TEXTURE_2D);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        stbi_image_free(texture.data);
    }
    textureData.erase(textureData.begin(), textureData.end());
}

void TextureFromFileThread(unsigned int texture_id, string filename)
{
    stbi_set_flip_vertically_on_load(false);

    int width, height, nrComponents;
    unsigned char *data = stbi_load(filename.c_str(), &width, &height, &nrComponents, 0);
    if (data)
    {
        std::lock_guard<std::mutex> lock(texture_mtx);
        textureData.push_back({width, height, nrComponents, texture_id, data});
    }
    else
    {
        std::cout << "Texture failed to load at path: " << filename << std::endl;
        stbi_image_free(data);
    }
}

#else

unsigned int TextureFromFile(const char *path, const string &directory, bool gamma = false);
unsigned int TextureFromFile(const char *path, const string &directory, [[maybe_unused]] bool gamma)
{
    string filename = string(path);
    filename = directory + '/' + filename;

    unsigned int textureID;
    glGenTextures(1, &textureID);
    stbi_set_flip_vertically_on_load(false);

    int width, height, nrComponents;
    unsigned char *data = stbi_load(filename.c_str(), &width, &height, &nrComponents, 0);
    if (data)
    {
        GLenum internalformat = 0;
        GLenum dataformat = 0;
        if (nrComponents == 1)
        {
            internalformat = dataformat = GL_RED;
        }
        else if (nrComponents == 3)
        {
            internalformat = gamma ? GL_SRGB : GL_RGB;
            dataformat = GL_RGB;
        }
        else if (nrComponents == 4)
        {
            internalformat = gamma ? GL_SRGB : GL_RGBA;
            dataformat = GL_RGBA;
        }

        glBindTexture(GL_TEXTURE_2D, textureID);
        glTexImage2D(GL_TEXTURE_2D, 0, internalformat, width, height, 0, dataformat, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        stbi_image_free(data);
    }
    else
    {
        std::cout << "Texture failed to load at path: " << path << std::endl;
        stbi_image_free(data);
    }

    return textureID;
}
#endif

vector<TetxtureType> textureTypes{
    {aiTextureType_DIFFUSE, "d"},
    {aiTextureType_HEIGHT, "n"},
    {aiTextureType_NORMALS, "n"},
    {aiTextureType_METALNESS, "m"},
    {aiTextureType_SPECULAR, "m"},
    {aiTextureType_DIFFUSE_ROUGHNESS, "r"},
    {aiTextureType_SHININESS, "r"},
    {aiTextureType_LIGHTMAP, "a"},
    {aiTextureType_AMBIENT, "a"},
    {aiTextureType_EMISSIVE, "e"}};

Model::Model(string const &path, [[maybe_unused]] bool gamma)
{
#if TEXTURE_THREAD
    texture_threads.erase(texture_threads.begin(), texture_threads.end());
#endif

    loadModel(path);

#if TEXTURE_THREAD
    for (auto &thread : texture_threads)
        thread.join();
    TextureFromData(textureData);
#endif
}

Model::Model(const aiScene *scene, const string path)
{
#if TEXTURE_THREAD
    texture_threads.erase(texture_threads.begin(), texture_threads.end());
#endif

    // retrieve the directory path of the filepath
    directory = path.substr(0, path.find_last_of('/'));
    // process assimp's root node recursive
    processNode(scene->mRootNode, scene);

#if TEXTURE_THREAD
    for (auto &thread : texture_threads)
        thread.join();
    TextureFromData(textureData);
#endif
}

void Model::Draw(Shader &shader)
{
    for (unsigned int i = 0; i < m_meshes.size(); ++i)
        m_meshes[i]->Draw(shader, morphAnimKeys);
}

void Model::DrawInstance(Shader &shader)
{
    for (unsigned int i = 0; i < m_meshes.size(); ++i)
        m_meshes[i]->DrawInstance(shader);
}

Model::~Model()
{
    for (auto &material : m_materials)
        glDeleteTextures(1, (unsigned int *)&material.id);
}

void Model::loadModel(string const &path)
{
    // read file via assimp
    Assimp::Importer importer;
    const aiScene *scene = importer.ReadFile(path, aiProcess_Triangulate | aiProcess_GenSmoothNormals | aiProcess_FlipUVs | aiProcess_CalcTangentSpace);
    // check for errors
    if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) // if is Not Zero
    {
        cout << "ERROR::ASSIMP" << importer.GetErrorString() << endl;
    }
    // retrieve the directory path of the filepath
    directory = path.substr(0, path.find_last_of('/'));
    // process assimp's root node recursive
    processNode(scene->mRootNode, scene);
}

void Model::processNode(aiNode *node, const aiScene *scene)
{
    // process each mesh located at the current node
    for (unsigned int i = 0; i < node->mNumMeshes; i++)
    {
        // the node object only contains indices to index the actual objects in the scene.
        // the scene contains all the data, node is just to keep stuff organized (like relations between nodes).
        // COUT(node->mName.data);
        // COUTL(node->mNumMeshes);
        aiMesh *mesh = scene->mMeshes[node->mMeshes[i]];
        processMesh(mesh, scene);
        // COUTL("processMesh" << process);
    }
    // after we've processed all of the meshes (if any) we then recursively process each of the children nodes
    for (unsigned int i = 0; i < node->mNumChildren; i++)
    {
        processNode(node->mChildren[i], scene);
    }
}

void Model::processMesh(aiMesh *mesh, const aiScene *scene)
{
    // data to fill
    vector<Vertex> vertices;
    vector<unsigned int> indices;
    vector<Materials> materials;

    // ----------------------------morph shapeKeysNameID
    if (!GetshapeKeysNameID)
    {
        // first mesh storge all the shapekeys
        for (unsigned int i = 0; i < mesh->mNumAnimMeshes; ++i)
        {
            shapeKeysNameID.insert(make_pair(i, mesh->mAnimMeshes[i]->mName.data));
        }
        GetshapeKeysNameID = true;
    }

    //  ----------------------------morph
    unordered_map<string, vector<glm::vec3>> morphAnims;
    for (unsigned int i = 0; i < mesh->mNumAnimMeshes; ++i)
    {
        vector<glm::vec3> vecs;
        vecs.resize(mesh->mNumVertices);
        for (unsigned int j = 0; j < mesh->mNumVertices; j++)
        {
            vecs[j] = (AssimpGLMHelpers::GetGLMVec(mesh->mAnimMeshes[i]->mVertices[j] - mesh->mVertices[j]));
        }

        // The shapekey of the mesh has not changed, so it is not needed.
        bool nonZeroPresent = std::any_of(vecs.begin(), vecs.end(), [](const glm::vec3 &vec)
                                          { return vec != glm::vec3(.0f); });

        if (nonZeroPresent)
            morphAnims.insert(make_pair(mesh->mAnimMeshes[i]->mName.data, vecs));
    }

    // ----------------------------vertices
    vertices.resize(mesh->mNumVertices);
    for (unsigned int i = 0; i < mesh->mNumVertices; i++)
    {
        Vertex vertex;
        SetVertexBoneDataToDefault(vertex);

        vertex.Position = AssimpGLMHelpers::GetGLMVec(mesh->mVertices[i]);

        // normals
        if (mesh->HasNormals())
        {
            vertex.Normal = AssimpGLMHelpers::GetGLMVec(mesh->mNormals[i]);
        }
        // texture coordinates
        if (mesh->mTextureCoords[0]) // does the mesh contain texture coordinates?
        {
            glm::vec2 vec;
            // a vertex can contain up to 8 different texture coordinates. We thus make the assumption that we won't
            // use models where a vertex can have multiple texture coordinates so we always take the first set (0).
            vec.x = mesh->mTextureCoords[0][i].x;
            vec.y = mesh->mTextureCoords[0][i].y;
            vertex.TexCoords = vec;
            // tangent
            vertex.Tangent = AssimpGLMHelpers::GetGLMVec(mesh->mTangents[i]);
            // bitangent
            vertex.Bitangent = AssimpGLMHelpers::GetGLMVec(mesh->mBitangents[i]);
        }
        else
            vertex.TexCoords = glm::vec2(0.0f, 0.0f);

        vertices[i] = (vertex);
    }

    // ----------------------------indices
    for (unsigned int i = 0; i < mesh->mNumFaces; i++)
    {
        aiFace face = mesh->mFaces[i];
        // retrieve all indices of the face and store them in the indices vector
        for (unsigned int j = 0; j < face.mNumIndices; j++)
            indices.push_back(face.mIndices[j]);
    }

    // ----------------------------materials
    // DiffuseTexture = "map_Kd";
    // AmbientTexture = "map_Ka";
    // SpecularTexture = "map_Ks";
    // OpacityTexture = "map_d";
    // EmissiveTexture1 = "map_emissive";
    // EmissiveTexture2 = "map_Ke";
    // BumpTexture1 = "map_bump";
    // BumpTexture2 = "bump";
    // NormalTextureV1 = "map_Kn";
    // NormalTextureV2 = "norm";
    // ReflectionTexture = "refl";
    // DisplacementTexture1 = "map_disp";
    // DisplacementTexture2 = "disp";
    // SpecularityTexture = "map_ns";
    // RoughnessTexture = "map_Pr";
    // MetallicTexture = "map_Pm";
    // SheenTexture = "map_Ps";
    // RMATexture = "map_Ps";

    // gltf----------------------------obj---------------------------------name
    // aiTextureType_DIFFUSE           aiTextureType_DIFFUSE        map_Kd albedo      0
    // aiTextureType_NORMALS           aiTextureType_NORMALS        map_Kn normal      1
    // aiTextureType_METALNESS         aiTextureType_SPECULAR       map_Ks metallic    2
    // aiTextureType_DIFFUSE_ROUGHNESS aiTextureType_SHININESS      map_Ns roughness   3
    // aiTextureType_LIGHTMAP          aiTextureType_AMBIENT        map_Ka ao          4
    // aiTextureType_EMISSIVE          aiTextureType_EMISSIVE       map_Ke emissive    5
    aiMaterial *material = scene->mMaterials[mesh->mMaterialIndex];

    for (const auto &textureType : textureTypes)
    {
        loadMaterialTextures(materials, material, textureType.type, textureType.prefix);
    }

    // if there is no texture, colorOnly
    // if (materials.size() == 0)
    // {
    //     Materials material_temp;
    //     material_temp.id = -1;
    //     aiColor3D color;
    //     material->Get(AI_MATKEY_COLOR_DIFFUSE, color);
    //     material_temp.color = glm::vec3(color.r, color.g, color.b);
    //     materials.push_back(material_temp);
    // }

    // ---------------------------- BoneWeights
    ExtractBoneWeightForVertices(vertices, mesh);

    // return a mesh object created from the extracted mesh data
    if (morphAnims.size())
        // automatic expansion of emplace_back will cause copying
        // copy and destructor will be called. unique_ptr can avoid it
        m_meshes.emplace_back(std::make_unique<Mesh>(vertices, indices, materials, morphAnims));
    else
        m_meshes.emplace_back(std::make_unique<Mesh>(vertices, indices, materials));
}

void Model::ExtractBoneWeightForVertices(vector<Vertex> &vertices, aiMesh *mesh)
{
    int newBoneID = m_BoneInfoMap.size();
    for (unsigned int boneIndex = 0; boneIndex < mesh->mNumBones; ++boneIndex)
    {
        int boneID = -1;
        std::string boneName = mesh->mBones[boneIndex]->mName.C_Str();
        if (m_BoneInfoMap.find(boneName) == m_BoneInfoMap.end())
        {
            BoneInfo newBoneInfo;
            newBoneInfo.id = newBoneID;
            newBoneInfo.offset = AssimpGLMHelpers::ConvertMatrixToGLMFormat(mesh->mBones[boneIndex]->mOffsetMatrix);
            m_BoneInfoMap[boneName] = newBoneInfo;
            boneID = newBoneID;
            ++newBoneID;
        }
        else
        {
            boneID = m_BoneInfoMap[boneName].id;
        }
        CHECK(boneID != -1);
        auto weights = mesh->mBones[boneIndex]->mWeights;
        int numWeights = mesh->mBones[boneIndex]->mNumWeights;
        for (int weightIndex = 0; weightIndex < numWeights; ++weightIndex)
        {
            unsigned int vertexId = weights[weightIndex].mVertexId;
            float weight = weights[weightIndex].mWeight;
            CHECK(vertexId <= vertices.size());
            if (weight != .0f)
                SetVertexBoneData(vertices[vertexId], boneID, weight);
        }
    }
}

void Model::loadMaterialTextures(vector<Materials> &materials, aiMaterial *mat, aiTextureType type, string typeName)
{
    for (unsigned int i = 0; i < mat->GetTextureCount(type); i++)
    {
        aiString str;
        mat->GetTexture(type, i, &str);
        // check if texture was loaded before and if so, continue to next iteration: skip loading a new texture
        bool skip = false;
        for (unsigned int j = 0; j < m_materials.size(); j++)
        {
            if (std::strcmp(m_materials[j].path.data(), str.C_Str()) == 0)
            {
                materials.push_back(m_materials[j]);
                skip = true; // a texture with the same filepath has already been loaded, continue to next one. (optimization)
                break;
            }
        }
        if (!skip)
        { // if texture hasn't been loaded already, load it
            Materials texture;

#if TEXTURE_THREAD
            unsigned int textureID;
            glGenTextures(1, &textureID);
            texture.id = textureID;
            string filepath = this->directory + '/' + str.C_Str();
            texture_threads.emplace_back(TextureFromFileThread, textureID, filepath);
#else
            texture.id = TextureFromFile(str.C_Str(), this->directory);
#endif
            // texture.id = TextureFromFile(str.C_Str(), this->directory);
            texture.type = typeName;
            texture.path = str.C_Str();
            materials.push_back(texture);
            m_materials.push_back(texture); // store it as texture loaded for entire model, to ensure we won't unnecessary load duplicate textures.
        }
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\objectrender.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 17479 bytes

```
#include "objectrender.h"

SKYObject::SKYObject(Shader &s, VertexArray &vao, unsigned int skymap)
    : m_shader(s), m_VAO(vao), m_skymap(skymap)
{
    if (skymap == 0)
        throw std::runtime_error("skymap is empty");
    m_shader.Bind();
    m_shader.SetUniform1i("skybox", 0);
    m_shader.SetUniform4m("projection", AppControl::projection);
}

void SKYObject::Render()
{
    m_VAO.Bind();
    m_shader.Bind();
    m_shader.SetUniform4m("view", AppControl::view);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, m_skymap);
    // shaderSKY.SetUniform1f("_fresnel", _fresnel);
    // glBindTexture(GL_TEXTURE_CUBE_MAP, irradianceMap);
    // glBindTexture(GL_TEXTURE_CUBE_MAP, prefilterMap);
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

const glm::vec3 lightPositions[] = {
    glm::vec3(-10.0f, 10.0f, 10.0f),
    glm::vec3(10.0f, 10.0f, 10.0f),
    glm::vec3(-10.0f, -10.0f, 10.0f),
    glm::vec3(10.0f, -10.0f, 10.0f),
};

bool PBRObject::initialized = false;
unsigned int PBRObject::envCubemap = 0;
unsigned int PBRObject::irradianceMap = 0;
unsigned int PBRObject::prefilterMap = 0;
unsigned int PBRObject::brdfLUTTexture = 0;

void PBRObject::PBRInit(Shader &s, string hdr_map)
{
    s.Bind();
    s.SetUniform1i("albedoMap", 0);
    s.SetUniform1i("normalMap", 1);
    s.SetUniform1i("metallicMap", 2);
    s.SetUniform1i("roughnessMap", 3);
    s.SetUniform1i("aoMap", 4);
    s.SetUniform1i("emissiveMap", 5);

    s.SetUniform1i("irradianceMap", 6);
    s.SetUniform1i("prefilterMap", 7);
    s.SetUniform1i("brdfLUT", 8);
    s.SetUniform1b("hasEmissive", 1);

    Shader &shaderHDR = ResourceManager::SetShader("HDR", 17, 19);
    Shader &shaderIrradiance = ResourceManager::SetShader("Irradiance", 17, 20);
    Shader &shaderPrefilter = ResourceManager::SetShader("Prefilter", 17, 21);
    Shader &shaderBRDF = ResourceManager::SetShader("BRDF", 18, 22);

    VertexArray &VAO_Cubes = ResourceManager::GetVAO("cubes");
    VertexArray &VAO_Frame = ResourceManager::GetVAO("frame");

#if 1 // -----------------------PBR IBL
      // pbr: setup framebuffer
      // ----------------------
    unsigned int captureFBO, captureRBO;
    glGenFramebuffers(1, &captureFBO);
    glGenRenderbuffers(1, &captureRBO);

    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    glBindRenderbuffer(GL_RENDERBUFFER, captureRBO);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 512, 512);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, captureRBO);

    // pbr: load the HDR environment map
    // ---------------------------------
    stbi_set_flip_vertically_on_load(true);
    int width, height, nrComponents;
    float *data = stbi_loadf(hdr_map.c_str(), &width, &height, &nrComponents, 0);
    unsigned int hdrTexture;
    if (data)
    {
        glGenTextures(1, &hdrTexture);
        glBindTexture(GL_TEXTURE_2D, hdrTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, width, height, 0, GL_RGB, GL_FLOAT, data); // note how we specify the texture's data value to be float

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        stbi_image_free(data);
    }
    else
    {
        std::cout << "Failed to load HDR image." << std::endl;
    }

    // pbr: setup cubemap to render to and attach to framebuffer
    // ---------------------------------------------------------
    // unsigned int envCubemap;
    glGenTextures(1, &envCubemap);
    glBindTexture(GL_TEXTURE_CUBE_MAP, envCubemap);
    for (unsigned int i = 0; i < 6; ++i)
    {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 512, 512, 0, GL_RGB, GL_FLOAT, nullptr);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    // pbr: set up projection and view matrices for capturing data onto the 6 cubemap face directions
    // ----------------------------------------------------------------------------------------------
    glm::mat4 captureProjection = glm::perspective(glm::radians(90.0f), 1.0f, 0.1f, 10.0f);
    glm::mat4 captureViews[] =
        {
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(1.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f, 0.0f)),
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(-1.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f, 0.0f)),
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 1.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f)),
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, -1.0f, 0.0f), glm::vec3(0.0f, 0.0f, -1.0f)),
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f), glm::vec3(0.0f, -1.0f, 0.0f)),
            glm::lookAt(glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, -1.0f), glm::vec3(0.0f, -1.0f, 0.0f))};

    // pbr: convert HDR equirectangular environment map to cubemap equivalent
    // ----------------------------------------------------------------------
    VAO_Cubes.Bind();
    shaderHDR.Bind();
    shaderHDR.SetUniform1i("equirectangularMap", 0);
    shaderHDR.SetUniform4m("projection", captureProjection);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, hdrTexture);

    glViewport(0, 0, 512, 512); // don't forget to configure the viewport to the capture dimensions.
    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    for (unsigned int i = 0; i < 6; ++i)
    {
        shaderHDR.SetUniform4m("view", captureViews[i]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, envCubemap, 0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // ------------------ test
    // envCubemap = hdrTexture;

    // then let OpenGL generate mipmaps from first mip face (combatting visible dots artifact)
    glBindTexture(GL_TEXTURE_CUBE_MAP, envCubemap);
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    // pbr: create an irradiance cubemap, and re-scale capture FBO to irradiance scale.
    // --------------------------------------------------------------------------------
    // unsigned int irradianceMap;
    glGenTextures(1, &irradianceMap);
    glBindTexture(GL_TEXTURE_CUBE_MAP, irradianceMap);
    for (unsigned int i = 0; i < 6; ++i)
    {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16F, 32, 32, 0, GL_RGB, GL_FLOAT, nullptr);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    glBindRenderbuffer(GL_RENDERBUFFER, captureRBO);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 32, 32);

    shaderIrradiance.Bind();
    shaderIrradiance.SetUniform1i("environmentMap", 0);
    shaderIrradiance.SetUniform4m("projection", captureProjection);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, envCubemap);
    glViewport(0, 0, 32, 32);
    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    for (unsigned int i = 0; i < 6; ++i)
    {
        shaderIrradiance.SetUniform4m("view", captureViews[i]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                               GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, irradianceMap, 0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // pbr: create a pre-filter cubemap, and re-scale capture FBO to pre-filter scale.
    // --------------------------------------------------------------------------------
    // unsigned int prefilterMap;
    glGenTextures(1, &prefilterMap);
    glBindTexture(GL_TEXTURE_CUBE_MAP, prefilterMap);
    for (unsigned int i = 0; i < 6; ++i)
    {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB16, 128, 128, 0, GL_RGB, GL_FLOAT, NULL);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    // be sure to set minification filter to mip_linear
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // generate mipmaps for the cubemap so OpenGL automatically allocates the required memory.
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    // pbr: run a quasi monte-carlo simulation on the environment lighting to create a prefilter (cube)map.
    // ----------------------------------------------------------------------------------------------------
    shaderPrefilter.Bind();
    shaderPrefilter.SetUniform1i("environmentMap", 0);
    shaderPrefilter.SetUniform4m("projection", captureProjection);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, envCubemap);
    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    unsigned int maxMipLevels = 5;
    for (unsigned int mip = 0; mip < maxMipLevels; ++mip)
    {
        // resize framebuffer according to mip-level size.
        unsigned int mipWidth = static_cast<unsigned int>(128 * pow(0.5, mip));
        unsigned int mipHeight = static_cast<unsigned int>(128 * pow(0.5, mip));
        glBindRenderbuffer(GL_RENDERBUFFER, captureRBO);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, mipWidth, mipHeight);
        glViewport(0, 0, mipWidth, mipHeight);
        float roughness = (float)mip / (float)(maxMipLevels - 1);
        shaderPrefilter.SetUniform1f("roughness", roughness);
        for (unsigned int i = 0; i < 6; ++i)
        {
            shaderPrefilter.SetUniform4m("view", captureViews[i]);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, prefilterMap, mip);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glDrawArrays(GL_TRIANGLES, 0, 36);
        }
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // pbr: generate a 2D LUT from the BRDF equations used.
    // ----------------------------------------------------
    // unsigned int brdfLUTTexture;
    glGenTextures(1, &brdfLUTTexture);
    // pre-allocate enough memory for the LUT texture;
    glBindTexture(GL_TEXTURE_2D, brdfLUTTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG16F, 512, 512, 0, GL_RG, GL_FLOAT, 0);
    // be sure to set wrapping mode to GL_CLAMP_TO_EDGE
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // then re-configure capture framebuffer object and render screen-space quad with BRDF shader.
    glBindFramebuffer(GL_FRAMEBUFFER, captureFBO);
    glBindRenderbuffer(GL_RENDERBUFFER, captureRBO);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, 512, 512);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, brdfLUTTexture, 0);
    glViewport(0, 0, 512, 512);
    VAO_Frame.Bind();
    shaderBRDF.Bind();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // initialize static shader uniforms before rendering
    glViewport(0, 0, AppControl::scr_width, AppControl::scr_height);
#endif

    initialized = true;
}

PBRObject::PBRObject(Shader &s, string model_path) : m_shader(s)
{
    if (!initialized)
        throw std::runtime_error("PBRObject not init");
    m_model = new Model(model_path);
}

void PBRObject::Render(mat4 &model, vec3 camera_pos)
{
    m_shader.Bind();
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_CUBE_MAP, irradianceMap);
    glActiveTexture(GL_TEXTURE7);
    glBindTexture(GL_TEXTURE_CUBE_MAP, prefilterMap);
    glActiveTexture(GL_TEXTURE8);
    glBindTexture(GL_TEXTURE_2D, brdfLUTTexture);
    // m_shader.SetUniform4m("view", AppControl::view);
    m_shader.SetUniform4m("vp", AppControl::vp);
    m_shader.SetUniform3f("camPos", camera_pos);
    for (unsigned int i = 0; i < sizeof(lightPositions) / sizeof(lightPositions[0]); ++i)
    {
        glm::vec3 newPos = lightPositions[i] + glm::vec3(sin(glfwGetTime() * 5.0) * 5.0, 0.0, 0.0);
        // lightPositions[i] = newPos;
        newPos = lightPositions[i];
        m_shader.SetUniform3f("lightPositions[" + std::to_string(i) + "]", newPos);
        m_shader.SetUniform3f("lightColors[" + std::to_string(i) + "]", AppControl::irradiance_color * 400.0f);
    }
    m_shader.SetUniform4m("model", model);
    m_shader.SetUniform3m("normalMatrix", glm::mat3(glm::transpose(glm::inverse(model))));
    m_model->Draw(m_shader);
}

void TextObject::LoadString(u32string u32str, vec2 screenPos, vec2 typography)
{
    m_u32str = u32str;
    m_Typography = typography;
    vector<float> vao_str;
    vector<GLuint> ibo_str;
    TextTexture::ChToTexture(m_u32str);

    unsigned int charsAdded = 0;
    for (auto c : m_u32str)
    {
        static float x_pos = screenPos.x;
        Character &ch = TextTexture::Characters[c];
        if (c == '\n')
        {
            screenPos.y -= (FONT_SIZE + m_Typography.x);
            screenPos.x = x_pos;
        }
        else
        {
            if (c != ' ')
            {
                float xpos = (screenPos.x + ch.Bearing.x);
                float ypos = (screenPos.y - (ch.Size.y - ch.Bearing.y));
                float w = ch.Size.x;
                float h = ch.Size.y;

                // update VBO for each character
                // float vertices[4][4] = {
                //     {xpos, ypos, 0.0f, 1.0f},
                //     {xpos, ypos + h, 0.0f, 0.0f},
                //     {xpos + w, ypos, 1.0f, 1.0f},
                //     {xpos + w, ypos + h, 1.0f, 0.0f}};
                // vec2(pos), vec4(texcoord(pre-calculate), texcoord )
                vector<float> vertices = {
                    xpos, ypos, ch.Offset.x, ch.Offset.y + ch.Offset.w, 0.0f, 1.0f,
                    xpos, ypos + h, ch.Offset.x, ch.Offset.y, 0.0f, 0.0f,
                    xpos + w, ypos, ch.Offset.x + ch.Offset.z, ch.Offset.y + ch.Offset.w, 1.0f, 1.0f,
                    xpos + w, ypos + h, ch.Offset.x + ch.Offset.z, ch.Offset.y, 1.0f, 0.0f};
                vao_str.insert(vao_str.end(), vertices.begin(), vertices.end());

                unsigned int startIndex = charsAdded * 4;
                ibo_str.push_back(startIndex);
                ibo_str.push_back(startIndex + 1);
                ibo_str.push_back(startIndex + 2);
                ibo_str.push_back(startIndex + 2);
                ibo_str.push_back(startIndex + 1);
                ibo_str.push_back(startIndex + 3);
                ++charsAdded;
            }
            screenPos.x += ((ch.Advance) + m_Typography.y);
        }
    }
    if (m_VAO != nullptr)
        delete m_VAO;
    m_VAO = new VertexArray({2, 4}, vao_str.data(), sizeof(float) * vao_str.size(), GL_STATIC_DRAW, ibo_str.data(), ibo_str.size(), GL_STATIC_DRAW);
}

void TextObject::Render(mat4 &model)
{
    glEnable(GL_BLEND);
    glDepthMask(GL_FALSE);

    m_shader.Bind();
    // m_shader.SetUniform3f("texColor", AppControl::text_color);
    static float movement = 0.1;
    movement += 0.3 * AppControl::deltaTime;
    m_shader.SetUniform1f("deltaTime", (movement));
    m_shader.SetUniform4m("mvp", AppControl::vp * model);
    m_shader.SetUniform1f("thickness", AppControl::thickness);
    m_shader.SetUniform1f("softness", AppControl::softness);
    m_shader.SetUniform1f("outline_thickness", AppControl::outline_thickness);
    m_shader.SetUniform1f("outline_softness", AppControl::outline_softness);
    m_shader.SetUniform2f("shadow_offset", AppControl::text_shadow_offset / 1000.0f);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, TextTexture::GetTetureID());

    (*m_VAO).Bind();
    glDrawElements(GL_TRIANGLES, (*m_VAO).GetIndexBuffer().GetCount(), GL_UNSIGNED_INT, 0);

    glDepthMask(GL_TRUE);
    glDisable(GL_BLEND);
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\resource.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 8794 bytes

```
#include "resource.h"

std::unordered_map<std::string, Texture> ResourceManager::Textures;
std::unordered_map<std::string, Shader> ResourceManager::Shaders;
std::unordered_map<std::string, VertexArray> ResourceManager::VAOs;

void ResourceManager::ShaderInit(string name)
{
    Shader::ShaderInit(name);
}

void ResourceManager::Clear()
{
    Shaders.erase(Shaders.begin(), Shaders.end());
    Textures.erase(Textures.begin(), Textures.end());
    VAOs.erase(VAOs.begin(), VAOs.end());
    // Shader::Clear();
}

Shader &ResourceManager::SetShader(string name, int vertex, int fragment, int geometry)
{
    auto it = Shaders.find(name);
    if (it == Shaders.end())
        return (Shaders.emplace(std::piecewise_construct,
                                std::forward_as_tuple(name), std::forward_as_tuple(vertex, fragment, geometry)))
            .first->second;
    else
        return (*it).second;
}

Shader &ResourceManager::GetShader(std::string name)
{
    try
    {
        return Shaders.at(name);
    }
    catch (const std::out_of_range &e)
    {
        cout << e.what() << ": " << name << endl;
        exit(1);
    }
}

void ResourceManager::LoadTexture(const string name, const string file)
{
    Textures.emplace(name, file);
}

Texture &ResourceManager::GetTexture(std::string name)
{
    try
    {
        return Textures.at(name);
    }
    catch (const std::out_of_range &e)
    {
        cout << e.what() << ": " << name << endl;
        exit(1);
    }
}

void ResourceManager::SetVAO(string name, vector<unsigned int> bufferlayout, const void *vbo_data, unsigned int vbo_size, const int vbo_usage,
                             const void *ibo_data, unsigned int ibo_count, const int ibo_usage)
{
    VAOs.emplace(std::piecewise_construct, std::forward_as_tuple(name),
                 std::forward_as_tuple(bufferlayout, vbo_data, vbo_size, vbo_usage, ibo_data, ibo_count, ibo_usage));
}

VertexArray &ResourceManager::GetVAO(const string name)
{
    try
    {
        return VAOs.at(name);
    }
    catch (const std::out_of_range &e)
    {
        cout << e.what() << ": " << name << endl;
        exit(1);
    }
}

vector<string> font_paths = {
    std::string(RES_DIR) + "fonts/base-split.woff",
    std::string(RES_DIR) + "fonts/HarmonyOS_Sans_SC_Medium.ttf",
    std::string(RES_DIR) + "fonts/NotoSansArabic-Medium.ttf",
    std::string(RES_DIR) + "fonts/NotoSansCanadianAboriginal-Medium.ttf",
    std::string(RES_DIR) + "fonts/NotoSansCuneiform-Regular.ttf",
    std::string(RES_DIR) + "fonts/NotoSansSymbols2-Regular.ttf",
    std::string(RES_DIR) + "fonts/NotoSans-ExtraBold.ttf",
};

map<char32_t, Character> TextTexture::Characters;
GLuint TextTexture::mtextureID = 0;
GLfloat TextTexture::mtextureWidth = 1000.0f;
GLfloat TextTexture::mtextureHeight = 1000.0f;

GLuint TextTexture::ChToTexture(u32string u32str)
{
    bool texture_needs_update = false;
    for (const auto &ch : u32str)
    {
        if (Characters.find(ch) == Characters.end())
        {
            texture_needs_update = true;
            break;
        }
    }
    if (!texture_needs_update)
        return -1;

    static bool first = true;
    if (first)
    {
        glGenTextures(1, &mtextureID);
        glBindTexture(GL_TEXTURE_2D, mtextureID);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, mtextureWidth, mtextureHeight, 0, GL_RED, GL_UNSIGNED_BYTE, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        first = false;
    }

    FT_Library ft;
    if (FT_Init_FreeType(&ft))
    {
        std::cout << "ERROR::FREETYPE: Could not init FreeType Library" << std::endl;
        return -1;
    }

    vector<FT_Face> faces;
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    for (const string &font_path : font_paths)
    {
        FT_Face face;
        if (FT_New_Face(ft, font_path.c_str(), 0, &face))
        {
            cout << "ERROR::FREETYPE: Failed to load font" << font_path << std::endl;
            return -1;
        }
        FT_Set_Pixel_Sizes(face, 0, FONT_SIZE);
        faces.push_back(face);
    }

    // double rotationAngle = 30.0;
    // FT_Matrix matrix;
    // FT_Vector pen;
    // double radians = rotationAngle * 3.14159 / 180.0;
    // matrix.xx = (FT_Fixed)(cos(radians) * 0x10000);
    // matrix.xy = (FT_Fixed)(-sin(radians) * 0x10000);
    // matrix.yx = (FT_Fixed)(sin(radians) * 0x10000);
    // matrix.yy = (FT_Fixed)(cos(radians) * 0x10000);
    // pen.x = 0;
    // pen.y = 0;

    glBindTexture(GL_TEXTURE_2D, mtextureID);

    for (const auto &ch : u32str)
    {
        if (Characters.find(ch) != Characters.end())
            continue;

        static float texture_sub_x = 0.0f, texture_sub_y = 0.0f;
        static unsigned int row_height = 0;

        for (const auto &face : faces)
        {
            FT_UInt glyphIndex = FT_Get_Char_Index(face, ch);
            if (glyphIndex == 0)
                continue;
            else
            {
                // FT_Set_Transform(face, &matrix, &pen);
                FT_Load_Char(face, ch, FT_LOAD_RENDER);
                FT_GlyphSlot slot = face->glyph;
                // if (hasSDF)
                // {
                FT_Render_Glyph(slot, FT_RENDER_MODE_SDF);
                // }

                Character character;
                if (ch == ' ')
                {
                    character.Advance = static_cast<unsigned int>((face->glyph->advance.x) >> 6);
                    Characters.insert(std::pair<FT_ULong, Character>(ch, character));
                }
                else
                {
                    if (texture_sub_x + slot->bitmap.width + 1 >= mtextureWidth)
                    {
                        texture_sub_y += row_height;
                        texture_sub_x = 0;
                        row_height = 0;
                        if (texture_sub_y >= (mtextureHeight - FONT_SIZE))
                            cout << "text texture no enough" << endl;
                    }

                    character = {
                        glm::ivec2(slot->bitmap.width, slot->bitmap.rows),
                        glm::ivec2(slot->bitmap_left, slot->bitmap_top),
                        static_cast<unsigned int>((slot->advance.x) >> 6),
                        glm::vec4(texture_sub_x / 1000.0f, texture_sub_y / 1000.0f, slot->bitmap.width / 1000.0f, slot->bitmap.rows / 1000.0f)}; // 26.6 or // 2^6=64 ((face)->glyph->advance.x)/64)
                    Characters.insert(std::pair<FT_ULong, Character>(ch, character));

                    glTexSubImage2D(GL_TEXTURE_2D, 0, texture_sub_x, texture_sub_y, slot->bitmap.width, slot->bitmap.rows, GL_RED, GL_UNSIGNED_BYTE, slot->bitmap.buffer);
                    texture_sub_x += slot->bitmap.width + 1;

                    row_height = std::max(row_height, slot->bitmap.rows);
                }
#if 0
                        if (ch == 'm')
                        {
                            for (unsigned int r = 0; r < face->glyph->bitmap.rows; ++r)
                            {
                                cout << endl;
                                for (unsigned int x = 0; x < face->glyph->bitmap.width; ++x)
                                {
                                    unsigned int index = r * face->glyph->bitmap.width + x;
                                    unsigned int value = face->glyph->bitmap.buffer[index];
                                    cout << setw(4) << (value) << " ";
                                }
                            }
                            cout << endl;
                            cout << "advance.x:" << face->glyph->advance.x << " advance.y:" << face->glyph->advance.y << endl;
                            cout << "bitmap.width:" << face->glyph->bitmap.width << " bitmap.rows:" << face->glyph->bitmap.rows << endl;
                            cout << "bitmap_left:" << face->glyph->bitmap_left << " bitmap_top:" << face->glyph->bitmap_top << endl;
                            cout << (face->size->metrics.height >> 6) << " advance.x>>6:" << ((face->glyph->advance.x) >> 6) << endl;
                        }
#endif
                break;
            }
        }
    }

    glBindTexture(GL_TEXTURE_2D, 0);

    for (auto &face : faces)
    {
        FT_Done_Face(face);
    }
    FT_Done_FreeType(ft);

    return 0;
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\SceneAnimations.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1936 bytes

```
#include "SceneAnimations.h"

SceneAnimations::SceneAnimations(Camera *camera, unsigned int width, unsigned int height) : Scene(camera, width, height)
{
    // compile shader for model
    ResourceManager::SetShader("modelAnim", 25, 24).Bind();
    ResourceManager::GetShader("modelAnim").SetUniform4m("pvm", App::vp * mat4(1.0));

    // load model data by assimp
    ModelImporter::ModelImport(string(RES_DIR) + "model/hutao/hutao_multi2.fbx", &modelHutao, &pAnimations, &pAnimator, ResourceManager::GetShader("modelAnim"));

    // imgui update
    App::animNames = pAnimations->GetAnimationNames();
    App::duration = pAnimator->GetAnimationDuration();
}

SceneAnimations::~SceneAnimations()
{
    DELETE_PTR(modelHutao)
    DELETE_PTR(pAnimations);
    DELETE_PTR(pAnimator);
}

void SceneAnimations::Render()
{
    glm::mat4 model = glm::mat4(1.0f);
    glEnable(GL_BLEND);

    //  --------------------------------------------------- model animation render
    if (App::animNames[App::animIndex] != pAnimator->GetAnimationName())
    {
        pAnimator->PlayAnimation(&pAnimations->GetAnimations()[App::animIndex]);
        App::duration = pAnimator->GetAnimationDuration();
    }
    if (App::playBackState)
    {
        pAnimator->UpdateAnimation(App::deltaTime * App::playSpeed);
        App::currentFrame = pAnimator->GetCurrentFrame();
    }
    else
    {
        pAnimator->SetCurrentTime(App::currentFrame);
        pAnimator->UpdateAnimation(.0f);
    }

    model = mat4(1.0f);
    model = glm::translate(model, glm::vec3(1.5f, .0f, 0.5f));
    // model = glm::scale(model, glm::vec3(0.01, 0.01, 0.01));
    // model = glm::scale(model, glm::vec3(0.1, 0.1, 0.1));

    auto &modelAnimShader = ResourceManager::GetShader("modelAnim");
    modelAnimShader.Bind();
    modelAnimShader.SetUniform4m("pvm", App::vp * model);
    modelHutao->Draw(modelAnimShader);
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\SceneCascadedShadowMap.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 19373 bytes

```
#include "SceneCascadedShadowMap.h"

SceneCascadedShadowMap::SceneCascadedShadowMap(Camera *camera, unsigned int width, unsigned int height) : Scene(camera, width, height)
{
    // compile shader for model
    // ResourceManager::SetShader("modelAnim", 25, 24).Bind();
    // ResourceManager::GetShader("modelAnim").SetUniform4m("pvm", App::vp * mat4(1.0));
    ResourceManager::SetShader("model", 20, 24).Bind();
    ResourceManager::GetShader("model").SetUniform4m("pvm", App::vp * mat4(1.0));

    // compile shader for CSM
    ResourceManager::SetShader("shader", 26, 31).Bind();
    ResourceManager::SetShader("simpleDepthShader", 8, 32, 2).Bind();
    ResourceManager::SetShader("debugDepthQuad", 7, 33).Bind();
    ResourceManager::SetShader("debugCascadeShader", 27, 34).Bind();

    cameraViewMatric = camera->GetViewMatrix();
    modelHutao = new Model(string(RES_DIR) + "model/hutao/hutao_multi2.fbx");

    texture = new Texture(string(RES_DIR) + "model/Dq_Uyutei/Area_Dq_Build_Common_TsgWood_01_T4_Diffuse.png");

    // configure light FBO
    // -----------------------
    glGenFramebuffers(1, &lightFBO);
    glGenTextures(1, &lightDepthMaps);
    glBindTexture(GL_TEXTURE_2D_ARRAY, lightDepthMaps);
    glTexImage3D(
        GL_TEXTURE_2D_ARRAY, 0, GL_DEPTH_COMPONENT32F, depthMapResolution, depthMapResolution, int(shadowCascadeLevels.size()) + 1,
        0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    constexpr float bordercolor[] = {1.0f, 1.0f, 1.0f, 1.0f};
    glTexParameterfv(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_BORDER_COLOR, bordercolor);
    glBindFramebuffer(GL_FRAMEBUFFER, lightFBO);
    glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, lightDepthMaps, 0);
    glDrawBuffer(GL_NONE);
    glReadBuffer(GL_NONE);
    int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {
        std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!";
        throw 0;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // configure UBO
    // --------------------
    glGenBuffers(1, &matricesUBO);
    glBindBuffer(GL_UNIFORM_BUFFER, matricesUBO);
    glBufferData(GL_UNIFORM_BUFFER, sizeof(glm::mat4x4) * 16, nullptr, GL_STATIC_DRAW);
    // --------- shader --- binding = 0
    glBindBufferBase(GL_UNIFORM_BUFFER, 0, matricesUBO);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    // shader configuration
    // --------------------
    auto &shader = ResourceManager::GetShader("shader");
    shader.Bind();
    shader.SetUniform1i("diffuseTexture", 0);
    shader.SetUniform1i("shadowMap", 1);
    auto &debugDepthQuad = ResourceManager::GetShader("debugDepthQuad");
    debugDepthQuad.Bind();
    debugDepthQuad.SetUniform1i("depthMap", 0);
}

SceneCascadedShadowMap::~SceneCascadedShadowMap()
{
    DELETE_PTR(modelHutao)
    DELETE_PTR(texture);
    DELETE_PTR(planeVA);
    DELETE_PTR(quadVA);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    glDeleteBuffers(1, &matricesUBO);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDeleteFramebuffers(1, &lightFBO);
    glDeleteTextures(1, &lightDepthMaps);
}

void SceneCascadedShadowMap::Render()
{
    glEnable(GL_BLEND);

    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 0. UBO setup
    const auto lightMatrices = getLightSpaceMatrices();
    glBindBuffer(GL_UNIFORM_BUFFER, matricesUBO);
    for (size_t i = 0; i < lightMatrices.size(); ++i)
    {
        glBufferSubData(GL_UNIFORM_BUFFER, i * sizeof(glm::mat4x4), sizeof(glm::mat4x4), &lightMatrices[i]);
    }
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    // 1. render depth of scene to texture (from light's perspective)
    // --------------------------------------------------------------
    // lightProjection = glm::perspective(glm::radians(45.0f), (GLfloat)SHADOW_WIDTH / (GLfloat)SHADOW_HEIGHT, near_plane, far_plane); // note that if you use a perspective projection matrix you'll have to change the light position as the current light position isn't enough to reflect the whole scene
    // render scene from light's point of view
    auto &simpleDepthShader = ResourceManager::GetShader("simpleDepthShader");
    simpleDepthShader.Bind();
    glBindFramebuffer(GL_FRAMEBUFFER, lightFBO);
    glViewport(0, 0, depthMapResolution, depthMapResolution);
    glClear(GL_DEPTH_BUFFER_BIT);
    // --------------------------
    // glEnable(GL_CULL_FACE);
    // glCullFace(GL_FRONT); // peter panning

    // glDisable(GL_CULL_FACE);

    renderScene(simpleDepthShader);
    // glEnable(GL_CULL_FACE);

    // glCullFace(GL_BACK);
    // glDisable(GL_CULL_FACE);
    //--------------------------

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // reset viewport
    glViewport(0, 0, App::scr_width, App::scr_height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // 2. render scene as normal using the generated depth/shadow map
    // --------------------------------------------------------------
    glViewport(0, 0, App::scr_width, App::scr_height);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    auto &shader = ResourceManager::GetShader("shader");
    shader.Bind();
    // glm::mat4 projection = glm::perspective(glm::radians(sceneCamera->m_Fov), (float)App::scr_width / (float)App::scr_height, cameraNearPlane, cameraFarPlane);
    glm::mat4 projection = glm::perspective(glm::radians(sceneCamera->m_Fov), (float)App::scr_width / (float)App::scr_height, cameraNearPlane, 50.0f);
    glm::mat4 view = sceneCamera->GetViewMatrix();
    shader.SetUniform4m("projection", AppControl::projection);
    shader.SetUniform4m("view", view);
    // set light uniforms
    shader.SetUniform3f("viewPos", sceneCamera->m_cameraPos);
    shader.SetUniform3f("lightDir", lightDir);
    // shader.SetUniform1f("farPlane", cameraFarPlane);
    shader.SetUniform1i("cascadeCount", shadowCascadeLevels.size());
    shader.SetUniform1f("bias_offs", AppControl::bias_offs);
    shader.SetUniform1f("bias_mids", AppControl::bias_mids);

    for (size_t i = 0; i < shadowCascadeLevels.size(); ++i)
    {
        shader.SetUniform1f("cascadePlaneDistances[" + std::to_string(i) + "]", shadowCascadeLevels[i]);
    }
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D_ARRAY, lightDepthMaps);

    renderScene(shader);

    // debug
    // --------------------------------------------------------------
    auto &debugCascadeShader = ResourceManager::GetShader("debugCascadeShader");
    if (lightMatricesCache.size() != 0)
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        debugCascadeShader.Bind();
        debugCascadeShader.SetUniform4m("projection", projection);
        debugCascadeShader.SetUniform4m("view", view);
        drawVisualizerFrustums(&debugCascadeShader);
        drawCascadeVolumeVisualizers(lightMatricesCache, &debugCascadeShader);
        glDisable(GL_BLEND);
    }

    // render Depth map to quad for visual debugging
    // ---------------------------------------------
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D_ARRAY, lightDepthMaps);
    auto &debugDepthQuad = ResourceManager::GetShader("debugDepthQuad");
    for (unsigned int Layer = 0; Layer <= shadowCascadeLevels.size(); ++Layer)
    {
        glViewport(0, (App::scr_height / 5) * Layer, App::scr_width / 5, App::scr_height / 5);
        debugDepthQuad.Bind();
        debugDepthQuad.SetUniform1i("layer", Layer);
        renderQuad();
    }

    glViewport(0, 0, App::scr_width, App::scr_height);
}

void SceneCascadedShadowMap::renderScene(Shader &shader)
{
    glm::mat4 model = glm::mat4(1.0f);
    model = glm::rotate(model, glm::radians(-90.0f), glm::normalize(glm::vec3(1.0, 0.0, 0.0)));
    shader.SetUniform4m("model", model);
    modelHutao->Draw(shader);

    if (planeVA == nullptr)
    {
        float planeVertices[] = {
            // positions            // normals         // texcoords
            -25.0f, 0.0f, 25.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f,   // 左上
            25.0f, 0.0f, 25.0f, 0.0f, 1.0f, 0.0f, 25.0f, 0.0f,   // 右上
            -25.0f, 0.0f, -25.0f, 0.0f, 1.0f, 0.0f, 0.0f, 25.0f, // 左下
            25.0f, 0.0f, -25.0f, 0.0f, 1.0f, 0.0f, 25.0f, 25.0f, // 右下
        };
        planeVA = new VertexArray({3, 3, 2}, planeVertices, sizeof(planeVertices));
    }
    // floor
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture->GetTextureID());
    model = glm::mat4(1.0f);
    shader.SetUniform4m("model", model);
    planeVA->Bind();
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void SceneCascadedShadowMap::renderQuad()
{
    if (quadVA == nullptr)
    {
        float quadVertices[] = {
            // positions        // texture Coords
            1.0f, 1.0f, 0.0f, 1.0f, 1.0f,   // 右上
            -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,  // 左上
            1.0f, -1.0f, 0.0f, 1.0f, 0.0f,  // 右下
            -1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // 左下
        };
        quadVA = new VertexArray({3, 2}, quadVertices, sizeof(quadVertices));
    }
    quadVA->Bind();
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindVertexArray(0);
}

void SceneCascadedShadowMap::drawCascadeVolumeVisualizers(const std::vector<glm::mat4> &lightMatrices, Shader *shader)
{
    std::vector<GLuint> visualizerVAOs(8);
    std::vector<GLuint> visualizerVBOs(8);
    std::vector<GLuint> visualizerEBOs(8);
    const GLuint indices[] = {
        0, 2, 3,
        0, 3, 1,
        4, 6, 2,
        4, 2, 0,
        5, 7, 6,
        5, 6, 4,
        1, 3, 7,
        1, 7, 5,
        6, 7, 3,
        6, 3, 2,
        1, 5, 4,
        0, 1, 4};
    const glm::vec4 colors[] = {
        {1.0, 0.0, 0.0, 0.5f},
        {0.0, 1.0, 0.0, 0.5f},
        {0.0, 0.0, 1.0, 0.5f},
    };
    for (unsigned int i = 0; i < lightMatrices.size(); ++i)
    {
        if (shadowCascadeLevels.size() + 1 != debugLayer)
            if (i != debugLayer)
                continue;
        const auto corners = getFrustumCornersWorldSpace(lightMatrices[i]);
        // const auto corners = getFrustumCornersWorldSpace(lightMatrices[i]);
        std::vector<glm::vec3> vec3s;
        for (const auto &v : corners)
        {
            vec3s.push_back(glm::vec3(v));
        }
        glGenVertexArrays(1, &visualizerVAOs[i]);
        glGenBuffers(1, &visualizerVBOs[i]);
        glGenBuffers(1, &visualizerEBOs[i]);
        glBindVertexArray(visualizerVAOs[i]);
        glBindBuffer(GL_ARRAY_BUFFER, visualizerVBOs[i]);
        glBufferData(GL_ARRAY_BUFFER, vec3s.size() * sizeof(glm::vec3), &vec3s[0], GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, visualizerEBOs[i]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36 * sizeof(GLuint), &indices[0], GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (void *)0);
        glBindVertexArray(visualizerVAOs[i]);
        shader->SetUniform4f("color", colors[i % 3]);

        glDrawElements(GL_TRIANGLES, GLsizei(36), GL_UNSIGNED_INT, 0);
        glDeleteBuffers(1, &visualizerVBOs[i]);
        glDeleteBuffers(1, &visualizerEBOs[i]);
        glDeleteVertexArrays(1, &visualizerVAOs[i]);
        glBindVertexArray(0);
    }
}

// draw Cascade Frustums Visualizers
void SceneCascadedShadowMap::drawVisualizerFrustums(Shader *shader)
{
    unsigned int cascadeLevels = shadowCascadeLevels.size() + 1;
    std::vector<GLuint> visualizerFrustumVAOs(cascadeLevels);
    std::vector<GLuint> visualizerFrustumVBOs(cascadeLevels);
    std::vector<GLuint> visualizerFrustumEBOs(cascadeLevels);

    const GLuint indices[] = {
        0, 2, 3,
        0, 3, 1,
        4, 6, 2,
        4, 2, 0,
        5, 7, 6,
        5, 6, 4,
        1, 3, 7,
        1, 7, 5,
        6, 7, 3,
        6, 3, 2,
        1, 5, 4,
        0, 1, 4};
    const glm::vec4 colors[] = {
        {1.0, 1.0, 1.0, 0.5f},
        {0.8, 1.0, 1.0, 0.5f},
        {1.0, 0.2, 0.6, 0.5f},
        {0.4, 0.5, 0.8, 0.5f},
        {0.2, 1.0, 0.2, 0.5f},
    };
    for (unsigned int i = 0; i < cascadeLevels; ++i)
    {
        if (shadowCascadeLevels.size() + 1 != debugLayer)
            if (i != debugLayer)
                continue;
        float nearPlane = 0.0f;
        float farPlane = 0.0f;
        if (i == 0)
        {
            nearPlane = cameraNearPlane;
            farPlane = shadowCascadeLevels[i];
        }
        else if (i < shadowCascadeLevels.size())
        {
            nearPlane = shadowCascadeLevels[i - 1];
            farPlane = shadowCascadeLevels[i];
        }
        else
        {
            nearPlane = shadowCascadeLevels[i - 1];
            farPlane = cameraFarPlane;
        }
        const auto proj = glm::perspective(
            glm::radians(sceneCamera->m_Fov), (float)App::scr_width / (float)App::scr_height, nearPlane,
            farPlane);
        const auto corners = getFrustumCornersWorldSpace(proj, cameraViewMatric);

        //---------------------------------
        glm::vec3 center = glm::vec3(0, 0, 0);
        for (const auto &v : corners)
        {
            center += glm::vec3(v);
        }
        center /= corners.size();
        //---------------------------------
        std::vector<glm::vec3> vec3s;
        for (const auto &v : corners)
        {
            // const auto trf = lightView * v;
            // vec3s.push_back(glm::vec3(trf));
            vec3s.push_back(glm::vec3(v));
        }

        glGenVertexArrays(1, &visualizerFrustumVAOs[i]);
        glGenBuffers(1, &visualizerFrustumVBOs[i]);
        glGenBuffers(1, &visualizerFrustumEBOs[i]);

        glBindVertexArray(visualizerFrustumVAOs[i]);

        glBindBuffer(GL_ARRAY_BUFFER, visualizerFrustumVBOs[i]);
        glBufferData(GL_ARRAY_BUFFER, vec3s.size() * sizeof(glm::vec3), &vec3s[0], GL_STATIC_DRAW);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, visualizerFrustumEBOs[i]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36 * sizeof(GLuint), &indices[0], GL_STATIC_DRAW);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (void *)0);

        glBindVertexArray(visualizerFrustumVAOs[i]);
        shader->SetUniform4f("color", colors[i % 5]);
        glDrawElements(GL_TRIANGLES, GLsizei(36), GL_UNSIGNED_INT, 0);

        glDeleteBuffers(1, &visualizerFrustumVBOs[i]);
        glDeleteBuffers(1, &visualizerFrustumEBOs[i]);
        glDeleteVertexArrays(1, &visualizerFrustumVAOs[i]);

        glBindVertexArray(0);
    }
}

std::vector<glm::vec4> SceneCascadedShadowMap::getFrustumCornersWorldSpace(const glm::mat4 &projview)
{
    const auto inv = glm::inverse(projview);
    std::vector<glm::vec4> frustumCorners;
    for (unsigned int x = 0; x < 2; ++x)
    {
        for (unsigned int y = 0; y < 2; ++y)
        {
            for (unsigned int z = 0; z < 2; ++z)
            {
                const glm::vec4 pt = inv * glm::vec4(2.0f * x - 1.0f, 2.0f * y - 1.0f, 2.0f * z - 1.0f, 1.0f);
                frustumCorners.push_back(pt / pt.w);
            }
        }
    }
    return frustumCorners;
}

std::vector<glm::vec4> SceneCascadedShadowMap::getFrustumCornersWorldSpace(const glm::mat4 &proj, const glm::mat4 &view)
{
    return getFrustumCornersWorldSpace(proj * view);
}

glm::mat4 SceneCascadedShadowMap::getLightSpaceMatrix(const float nearPlane, const float farPlane)
{
    const auto proj = glm::perspective(
        glm::radians(45.0f), (float)App::scr_width / (float)App::scr_height, nearPlane,
        farPlane);
    // glm::mat4 cameraView = glm::lookAt(camera->m_cameraPos + lightDir, camera->m_cameraPos, glm::vec3(0.0f, 1.0f, 0.0f));
    // const auto corners = getFrustumCornersWorldSpace(proj, cameraView);
    const auto corners = getFrustumCornersWorldSpace(proj, sceneCamera->GetViewMatrix());
    glm::vec3 center = glm::vec3(0, 0, 0);
    for (const auto &v : corners)
    {
        center += glm::vec3(v);
    }
    center /= corners.size();
    const auto lightView = glm::lookAt(center + lightDir, center, glm::vec3(0.0f, 1.0f, 0.0f));
    float minX = std::numeric_limits<float>::max();
    float maxX = std::numeric_limits<float>::lowest();
    float minY = std::numeric_limits<float>::max();
    float maxY = std::numeric_limits<float>::lowest();
    float minZ = std::numeric_limits<float>::max();
    float maxZ = std::numeric_limits<float>::lowest();
    for (const auto &v : corners)
    {
        const auto trf = lightView * v;

        minX = std::min(minX, trf.x);
        maxX = std::max(maxX, trf.x);
        minY = std::min(minY, trf.y);
        maxY = std::max(maxY, trf.y);
        minZ = std::min(minZ, trf.z);
        maxZ = std::max(maxZ, trf.z);
    }
    // The direction facing in lightViewSpace () is -Z
    // So farPlane should be minZ and nearPlane should be maxZ
    // lookAt in center, that is, minZ < 0, maxZ > 0
    // The direction facing in lightProjectionSpace (NDC) is +Z
    // So farPlane = -minZ, nearPlane = -maxZ
    auto temp = -minZ;
    minZ = -maxZ;
    maxZ = temp;
    // Tune this parameter according to the scene
    // auto mid = (maxZ - minZ) / 2;
    // minZ -= mid * 5.0f;
    // maxZ += mid * 5.0f;
    const glm::mat4 lightProjection = glm::ortho(minX, maxX, minY, maxY, minZ, maxZ);

    return lightProjection * lightView;
}

std::vector<glm::mat4> SceneCascadedShadowMap::getLightSpaceMatrices()
{
    std::vector<glm::mat4> ret;
    for (size_t i = 0; i < shadowCascadeLevels.size() + 1; ++i)
    {
        if (i == 0)
        {
            ret.push_back(getLightSpaceMatrix(cameraNearPlane, shadowCascadeLevels[i]));
        }
        else if (i < shadowCascadeLevels.size())
        {
            ret.push_back(getLightSpaceMatrix(shadowCascadeLevels[i - 1], shadowCascadeLevels[i]));
        }
        else
        {
            ret.push_back(getLightSpaceMatrix(shadowCascadeLevels[i - 1], cameraFarPlane));
        }
    }
    return ret;
}

void SceneCascadedShadowMap::processInput(GLFWwindow *window)
{
    static int plusPress = GLFW_RELEASE;
    if (glfwGetKey(window, GLFW_KEY_N) == GLFW_RELEASE && plusPress == GLFW_PRESS)
    {
        debugLayer++;
        if (debugLayer > shadowCascadeLevels.size() + 1)
        {
            debugLayer = 0;
        }
    }
    plusPress = glfwGetKey(window, GLFW_KEY_N);
    static int cPress = GLFW_RELEASE;
    if (glfwGetKey(window, GLFW_KEY_C) == GLFW_RELEASE && cPress == GLFW_PRESS)
    {
        lightMatricesCache = getLightSpaceMatrices();
        cameraViewMatric = sceneCamera->GetViewMatrix();
    }
    cPress = glfwGetKey(window, GLFW_KEY_C);
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\SceneDefault.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 7083 bytes

```
#include "SceneDefault.h"

const float CubesVertices[] = {
    // Back face
    -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, // Bottom-left
    0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 1.0f, 1.0f,   // top-right
    0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 1.0f, 0.0f,  // bottom-right
    0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 1.0f, 1.0f,   // top-right
    -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, // bottom-left
    -0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f, 0.0f, 1.0f,  // top-left
    // Front face
    -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // bottom-left
    0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f,  // bottom-right
    0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,   // top-right
    0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f,   // top-right
    -0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,  // top-left
    -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, // bottom-left
    // Left face
    -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f, 1.0f, 0.0f,   // top-right
    -0.5f, 0.5f, -0.5f, -1.0f, 0.0f, 0.0f, 1.0f, 1.0f,  // top-left
    -0.5f, -0.5f, -0.5f, -1.0f, 0.0f, 0.0f, 0.0f, 1.0f, // bottom-left
    -0.5f, -0.5f, -0.5f, -1.0f, 0.0f, 0.0f, 0.0f, 1.0f, // bottom-left
    -0.5f, -0.5f, 0.5f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f,  // bottom-right
    -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f, 1.0f, 0.0f,   // top-right
    // Right face
    0.5f, 0.5f, 0.5f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f,   // top-left
    0.5f, -0.5f, -0.5f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f, // bottom-right
    0.5f, 0.5f, -0.5f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f,  // top-right
    0.5f, -0.5f, -0.5f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f, // bottom-right
    0.5f, 0.5f, 0.5f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f,   // top-left
    0.5f, -0.5f, 0.5f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f,  // bottom-left
    // Bottom face
    -0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f, 0.0f, 1.0f, // top-right
    0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f, 1.0f, 1.0f,  // top-left
    0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f, 1.0f, 0.0f,   // bottom-left
    0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f, 1.0f, 0.0f,   // bottom-left
    -0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f,  // bottom-right
    -0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f, 0.0f, 1.0f, // top-right
    // Top face
    -0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, // top-left
    0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f,   // bottom-right
    0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f,  // top-right
    0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f,   // bottom-right
    -0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, // top-left
    -0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f   // bottom-left
};

const float FrameVertices[] = {
    // positions        // texture Coords
    -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
    -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 0.0f, 1.0f, 1.0f,
    1.0f, -1.0f, 0.0f, 1.0f, 0.0f};

const u32string u32text_string(U"使徒来袭 \nmashiro-真白-ましろ ❀ ⛅ ✯ ❅\n ᕕ(◠ڼ◠)ᕗ Ciallo～(∠・ω< )⌒★ (ᗜ˰ᗜ)\n 天动万象 I will have order 𒆚 𒆚 𒆙");

SceneDefault::SceneDefault(Camera *camera, unsigned int width, unsigned int height) : Scene(camera, width, height)
{
    // --------------------------------------------------- skybox vao
    ResourceManager::SetVAO("cubes", {3, 3, 2}, CubesVertices, sizeof(CubesVertices));
    ResourceManager::SetVAO("frame", {3, 2}, FrameVertices, sizeof(FrameVertices));
    // --------------------------------------------------- model shader
    ResourceManager::SetShader("model", 20, 24).Bind();
    ResourceManager::GetShader("model").SetUniform4m("pvm", App::vp * mat4(1.0));
    // compile shader for model
    ResourceManager::SetShader("modelAnim", 25, 24).Bind();
    ResourceManager::GetShader("modelAnim").SetUniform4m("pvm", App::vp * mat4(1.0));

    // load model data by assimp
    ModelImporter::ModelImport(string(RES_DIR) + "model/hutao/hutao_multi2.fbx", &modelHutao, &pAnimations, &pAnimator, ResourceManager::GetShader("modelAnim"));

    // imgui update
    App::animNames = pAnimations->GetAnimationNames();
    App::duration = pAnimator->GetAnimationDuration();

    // --------------------------------------------------- pbr model
    PBRObject::PBRInit(ResourceManager::SetShader("PBR", 16, 18), string(RES_DIR) + "image/newport_loft.hdr");
    pbr_model = new PBRObject(ResourceManager::GetShader("PBR"), string(RES_DIR) + "model/DamagedHelmet/glTF/DamagedHelmet.gltf");

    // --------------------------------------------------- skybox
    // need to be after PBRObject -- PBRObject::envCubemap
    skybox = new SKYObject(ResourceManager::SetShader("SKY", 4, 4), ResourceManager::GetVAO("cubes"), PBRObject::envCubemap);

    // --------------------------------------------------- text
    text = new TextObject(ResourceManager::SetShader("text", 19, 23), u32text_string, vec2(0.0), vec2(8.0, 0.0));
}

SceneDefault::~SceneDefault()
{
    DELETE_PTR(modelHutao)
    DELETE_PTR(pAnimations);
    DELETE_PTR(pAnimator);

    DELETE_PTR(text);
    DELETE_PTR(pbr_model);
    DELETE_PTR(skybox);
}

void SceneDefault::Render()
{
    glm::mat4 model = glm::mat4(1.0f);
    glEnable(GL_BLEND);

    //  --------------------------------------------------- model animation render
    if (App::animNames[App::animIndex] != pAnimator->GetAnimationName())
    {
        pAnimator->PlayAnimation(&pAnimations->GetAnimations()[App::animIndex]);
        App::duration = pAnimator->GetAnimationDuration();
    }
    if (App::playBackState)
    {
        pAnimator->UpdateAnimation(App::deltaTime * App::playSpeed);
        App::currentFrame = pAnimator->GetCurrentFrame();
    }
    else
    {
        pAnimator->SetCurrentTime(App::currentFrame);
        pAnimator->UpdateAnimation(.0f);
    }

    model = mat4(1.0f);
    model = glm::translate(model, glm::vec3(1.5f, .0f, 0.5f));
    // model = glm::scale(model, glm::vec3(0.01, 0.01, 0.01));
    // model = glm::scale(model, glm::vec3(0.1, 0.1, 0.1));

    auto &modelAnimShader = ResourceManager::GetShader("modelAnim");
    modelAnimShader.Bind();
    modelAnimShader.SetUniform4m("pvm", App::vp * model);
    modelHutao->Draw(modelAnimShader);

    //  --------------------------------------------------- pbr model render
    ResourceManager::GetShader("PBR").Bind();
    model = glm::mat4(1.0f);
    model = glm::translate(model, glm::vec3(-1.0f, 0.0f, 0.0f));
    model = glm::scale(model, glm::vec3(0.5, 0.5, 0.5));
    model = glm::rotate(model, glm::radians((float)90), glm::normalize(glm::vec3(1.0, 0.0, 0.0)));
    pbr_model->Render(model, sceneCamera->m_cameraPos);

    //  --------------------------------------------------- skybox render
    skybox->Render();

    //  --------------------------------------------------- text render
    model = glm::mat4(1.0f);
    model = glm::scale(model, vec3(0.01));
    // text->LoadString(u32text_string1, vec2(.0), vec2(8.0, 0.0));
    text->Render(model);
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\shader.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 6977 bytes

```
#include "shader.h"

vector<string> Shader::vertexShaderSources;
vector<string> Shader::fragmentShaderSources;
vector<string> Shader::geometryShaderSources;
bool Shader::CodeOutput;

void Shader::ShaderInit(const string filepath)
{
    std::ifstream file(filepath);
    if (!file.is_open())
    {
        std::cerr << "Failed to open file: " << filepath << std::endl;
        exit(0);
    }

    std::stringstream currentShader;
    std::string line;
    bool inVertexShader = false;
    bool inFragmentShader = false;
    bool inGeometryShader = false;

    while (std::getline(file, line))
    {
        if (line.substr(0, 2) == "//")
        {
            continue;
        }
        if (line.find("#shader vertex") != std::string::npos)
        {
            inVertexShader = true;
        }
        else if (line.find("#shader fragment") != std::string::npos)
        {
            inFragmentShader = true;
        }
        else if (line.find("#shader geometry") != std::string::npos)
        {
            inGeometryShader = true;
        }
        else if (!line.empty())
        {
            currentShader << line << "\n";
        }
        else if (inVertexShader)
        {
            vertexShaderSources.push_back(currentShader.str());
            currentShader.str("");
            currentShader.clear();
            inVertexShader = false;
        }
        else if (inFragmentShader)
        {
            fragmentShaderSources.push_back(currentShader.str());
            currentShader.str("");
            currentShader.clear();
            inFragmentShader = false;
        }
        else if (inGeometryShader)
        {
            geometryShaderSources.push_back(currentShader.str());
            currentShader.str("");
            currentShader.clear();
            inGeometryShader = false;
        }
    }
    if (inVertexShader)
    {
        vertexShaderSources.push_back(currentShader.str());
    }
    if (inFragmentShader)
    {
        fragmentShaderSources.push_back(currentShader.str());
    }
    if (inGeometryShader)
    {
        geometryShaderSources.push_back(currentShader.str());
    }
}

Shader::Shader(unsigned int vertexShader_ID, unsigned int fragmentShader_ID, int geometryShader_ID)
{
    if (vertexShaderSources[vertexShader_ID].empty())
    {
        throw std::runtime_error("vertexShader_ID is empty");
    }
    if (fragmentShaderSources[fragmentShader_ID].empty())
    {
        throw std::runtime_error("fragmentShader_ID is empty");
    }
    if (geometryShader_ID != -1 && geometryShaderSources[geometryShader_ID].empty())
    {
        throw std::runtime_error("geometryShader_ID is empty");
    }
    const char *vertexShaderSource = vertexShaderSources[vertexShader_ID].c_str();
    const char *fragmentShaderSource = fragmentShaderSources[fragmentShader_ID].c_str();
    const char *geometryShaderSource;
    if (geometryShader_ID != -1)
        geometryShaderSource = geometryShaderSources[geometryShader_ID].c_str();

    if (CodeOutput)
    {
        cout << vertexShaderSource << endl;
        cout << fragmentShaderSource << endl;
        if (geometryShader_ID != -1)
            cout << geometryShaderSource << endl;
    }
    unsigned int vertexShader, fragmentShader, geometryShader = 0;

    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    CHECK_SHADER(vertexShader, vertexShader_ID);

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    CHECK_SHADER(fragmentShader, fragmentShader_ID);

    if (geometryShader_ID != -1)
    {
        geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
        glShaderSource(geometryShader, 1, &geometryShaderSource, NULL);
        glCompileShader(geometryShader);
        CHECK_SHADER(geometryShader, geometryShader_ID);
    }

    ProgramID = glCreateProgram();
    glAttachShader(ProgramID, vertexShader);
    glAttachShader(ProgramID, fragmentShader);
    if (geometryShader_ID != -1)
        glAttachShader(ProgramID, geometryShader);
    glLinkProgram(ProgramID);
    CHECK_PROGRAM(ProgramID);

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    if (geometryShader_ID != -1)
        glDeleteShader(geometryShader);
}

int Shader::GetUniformLocation(const std::string &name)
{
    if (m_UniformLoationCache.find(name) != m_UniformLoationCache.end())
        return m_UniformLoationCache[name];

    int location = glGetUniformLocation(ProgramID, name.c_str());
    if (location == -1)
    {
        std::cout << "No active uniform variable with name " << name << " foune" << std::endl;
    }

    m_UniformLoationCache[name] = location;
    return location;
}

void Shader::SetUniform1b(const std::string &name, bool value)
{
    glUniform1i(GetUniformLocation(name), (int)value);
}

void Shader::SetUniform1i(const std::string &name, int value)
{
    glUniform1i(GetUniformLocation(name), value);
}

void Shader::SetUniform1f(const std::string &name, float f0)
{
    glUniform1f(GetUniformLocation(name), f0);
}

void Shader::SetUniform2f(const std::string &name, float f0, float f1)
{
    glUniform2f(GetUniformLocation(name), f0, f1);
}

void Shader::SetUniform2f(const std::string &name, const glm::vec2 &value)
{
    glUniform2fv(GetUniformLocation(name), 1, &value[0]);
}

void Shader::SetUniform3f(const std::string &name, float f0, float f1, float f2)
{
    glUniform3f(GetUniformLocation(name), f0, f1, f2);
}

void Shader::SetUniform3f(const std::string &name, const glm::vec3 &value)
{
    glUniform3fv(GetUniformLocation(name), 1, &value[0]);
}

void Shader::SetUniform4f(const std::string &name, float f0, float f1, float f2, float f3)
{
    glUniform4f(GetUniformLocation(name), f0, f1, f2, f3);
}

void Shader::SetUniform4f(const std::string &name, const glm::vec4 &value)
{
    glUniform4fv(GetUniformLocation(name), 1, &value[0]);
}

void Shader::SetUniform2m(const std::string &name, const glm::mat2 &mat)
{
    glUniformMatrix2fv(GetUniformLocation(name), 1, GL_FALSE, &mat[0][0]);
}

void Shader::SetUniform3m(const std::string &name, const glm::mat3 &mat)
{
    glUniformMatrix3fv(GetUniformLocation(name), 1, GL_FALSE, &mat[0][0]);
}

void Shader::SetUniform4m(const std::string &name, const glm::mat4 &mat)
{
    glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, &mat[0][0]);
}

void Shader::Clear()
{
    vertexShaderSources.erase(vertexShaderSources.begin(),vertexShaderSources.end());
    fragmentShaderSources.erase(fragmentShaderSources.begin(),fragmentShaderSources.end());
    geometryShaderSources.erase(geometryShaderSources.begin(),geometryShaderSources.end());
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: src\texture.cpp

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 3138 bytes

```
#include "texture.h"

Texture::Texture(const string &path, GLenum textureTarget, GLenum wrapMode, GLenum mapFilter, bool gammaCorrection)
{
    m_TextureTarget = textureTarget;
    glGenTextures(1, &m_TextureID);
    glBindTexture(GL_TEXTURE_2D, m_TextureID);

    int width, height, nrChannels;
    stbi_set_flip_vertically_on_load(false); // tell stb_image.h to flip loaded texture's on the y-axis.
    unsigned char *data = stbi_load(path.c_str(), &width, &height, &nrChannels, 0);
    if (data)
    {
        GLenum internalformat = 0;
        GLenum dataformat = 0;
        if (nrChannels == 1)
        {
            internalformat = dataformat = GL_RED;
        }
        else if (nrChannels == 3)
        {
            internalformat = gammaCorrection ? GL_SRGB : GL_RGB;
            dataformat = GL_RGB;
        }
        else if (nrChannels == 4)
        {
            internalformat = gammaCorrection ? GL_SRGB : GL_RGBA;
            dataformat = GL_RGBA;
        }
        glTexImage2D(GL_TEXTURE_2D, 0, internalformat, width, height, 0, dataformat, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode); // set texture wrapping to GL_REPEAT (default wrapping method)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, mapFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mapFilter);
    }
    else
    {
        std::cout << "Failed to load texture path: " << path << std::endl;
        exit(0);
    }
    stbi_image_free(data);
}

Texture::~Texture()
{
    glDeleteTextures(1, &m_TextureID);
}

void Texture::Bind()
{
    glActiveTexture(m_TextureTarget);
    glBindTexture(GL_TEXTURE_2D, m_TextureID);
}

void Texture::UnBind()
{
    glBindTexture(GL_TEXTURE_2D, 0);
}

unsigned int &Texture::GetTextureID()
{
    return m_TextureID;
}

unsigned int loadCubemap(vector<string> faces)
{
    unsigned int textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);

    int width, height, nrChannals;
    for (unsigned int i = 0; i < faces.size(); ++i)
    {
        unsigned char *data = stbi_load(faces[i].c_str(), &width, &height, &nrChannals, 0);
        if (data)
        {
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
            stbi_image_free(data);
        }
        else
        {
            cout << "Cubemap texture failed to load at path: " << faces[i] << endl;
            stbi_image_free(data);
        }
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    return textureID;
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

<!-- CODEZIPPER_CONTENT_END -->