cd d:\code\w_cplus\vulkan\vulkan_demo1\example\nanite\shaders
glslc shader.frag -o nanite_frag.spv
glslc shader.vert -o nanite_vert.spv
powershell -Command Copy-Item d:\code\w_cplus\vulkan\vulkan_demo1\example\nanite\shaders\*.spv d:\code\w_cplus\vulkan\vulkan_demo1\build\install\bin\shaders\