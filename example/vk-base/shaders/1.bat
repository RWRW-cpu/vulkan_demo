cd d:\code\w_cplus\vulkan\vulkan_demo1\example\vk-base\shaders
glslc shader.frag -o vkBase_frag.spv
glslc shader.vert -o vkBase_vert.spv
powershell -Command Copy-Item d:\code\w_cplus\vulkan\vulkan_demo1\example\vk-base\shaders\*.spv d:\code\w_cplus\vulkan\vulkan_demo1\build\install\bin\shaders\
