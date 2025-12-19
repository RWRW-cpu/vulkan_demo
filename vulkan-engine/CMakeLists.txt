
add_executable(vulkan-engine 
    main.cpp)

target_include_directories(vulkan-engine PUBLIC ${CMAKE_SOURCE_DIR})
target_link_libraries(vulkan-engine 
    PRIVATE
    glm  
    stb_image 
    glfw 
    Vulkan::Vulkan
    assimp)


install(TARGETS vulkan-engine 
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)