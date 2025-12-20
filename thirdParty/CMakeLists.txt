#assimp
set(BUILD_SHARED_LIBS OFF)
set(ASSIMP_BUILD_ALL_EXPORTERS_BY_DEFAULT OFF)
set(ASSIMP_BUILD_TESTS OFF)
set(ASSIMP_INSTALL OFF)
set(ASSIMP_INSTALL_PDB OFF)
add_subdirectory(assimp)

# glm
add_library(glm INTERFACE)
set(GLM_DIR ${CMAKE_CURRENT_SOURCE_DIR}/glm)
target_sources(glm INTERFACE ${GLM_DIR}/glm/glm.hpp)
target_include_directories(glm SYSTEM INTERFACE ${GLM_DIR})


#glfw
set(BUILD_SHARED_LIBS OFF CACHE BOOL "")
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "")
set(GLFW_BUILD_TESTS OFF CACHE BOOL "")
set(GLFW_BUILD_DOCS OFF CACHE BOOL "")
set(GLFW_INSTALL OFF CACHE BOOL "")
add_subdirectory(glfw)
# set_target_properties(glfw PROPERTIES FOLDER "thirdParty" POSITION_INDEPENDENT_CODE ON)


# stbimage
set(STB_IMAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/stb_image")
add_library(stb_image STATIC "${STB_IMAGE_DIR}/stb_image.h" 
    "${STB_IMAGE_DIR}/stb_image_write.h"
    "${STB_IMAGE_DIR}/stb_image.cpp")
target_include_directories(stb_image PUBLIC ${STB_IMAGE_DIR})
set_target_properties(stb_image PROPERTIES FOLDER "thirdParty" POSITION_INDEPENDENT_CODE ON)
