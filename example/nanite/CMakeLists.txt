
add_executable(nanite
    main.cpp
    Control.cpp
    Control.h)

target_include_directories(nanite 
    PUBLIC 
    ${CMAKE_SOURCE_DIR})

target_link_libraries(nanite 
    PRIVATE
        glm  
        stb_image 
        glfw 
        Vulkan::Vulkan
        assimp
        meshoptimizer
        metis)


install(TARGETS nanite 
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)