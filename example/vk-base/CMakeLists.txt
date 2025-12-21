
add_executable(vk-base
    main.cpp)

target_include_directories(vk-base PUBLIC ${CMAKE_SOURCE_DIR})
target_link_libraries(vk-base 
    PRIVATE
    glm  
    stb_image 
    glfw 
    Vulkan::Vulkan
    assimp)


install(TARGETS vk-base 
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)