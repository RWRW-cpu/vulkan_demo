
add_executable(33_cube-maps
    source/main.cpp
)

target_include_directories(33_cube-maps 
    PRIVATE
        include)

target_link_libraries(33_cube-maps 
    PRIVATE
    glm  
    stb_image 
    glfw 
    Vulkan::Vulkan
    assimp)


install(TARGETS 33_cube-maps
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)