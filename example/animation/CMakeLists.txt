
add_executable(animation
    main.cpp)

target_include_directories(animation PUBLIC ${CMAKE_SOURCE_DIR})
target_link_libraries(animation 
    PRIVATE
    glm  
    stb_image 
    glfw 
    Vulkan::Vulkan
    assimp)


install(TARGETS animation 
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)