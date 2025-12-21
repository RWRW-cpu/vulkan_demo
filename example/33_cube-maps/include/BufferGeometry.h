#pragma once
#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#define GLM_ENABLE_EXPERIMENTAL
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/hash.hpp>

#include <string>
#include <vector>
#include <iostream>

using namespace std;

const float PI = glm::pi<float>();

// mesh.h中也定义此属性
struct Vertex
{
  glm::vec3 Position;  // 顶点位置
  glm::vec3 Normal;    // 法线
  glm::vec2 TexCoords; // 纹理坐标

  glm::vec3 Tangent;   // 切线
  glm::vec3 Bitangent; // 副切线
};

class BufferGeometry
{
public:
  vector<Vertex> vertices;
  vector<unsigned int> indices;
  unsigned int VAO;

  void logParameters()
  {
    for (unsigned int i = 0; i < vertices.size(); i++)
    {
      // cout << "-----------------" << endl;
      // cout << "vertex ->> x: " << vertices[i].Position.x << ",y: " << vertices[i].Position.y << ",z: " << vertices[i].Position.z << endl;
      // cout << "normal ->> x: " << vertices[i].Normal.x << ",y: " << vertices[i].Normal.y << ",z: " << vertices[i].Normal.z << endl;
      // cout << "TexCoords ->> x: " << vertices[i].TexCoords.x << ",y: " << vertices[i].TexCoords.y << endl;
      // cout << "-----------------" << endl;
    }
  }

  // 计算切线向量并添加到顶点属性中
  void computeTangents()
  {
  }

  void dispose()
  {

  }

private:
  glm::mat4 matrix = glm::mat4(1.0f);

protected:
  unsigned int VBO, EBO;

  void setupBuffers()
  {
   
  }
};

