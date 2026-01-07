cd /d %~dp0
glslc shader.frag -o vkAnim_frag.spv
glslc shader.vert -o vkAnim_vert.spv
powershell -Command "Copy-Item *.spv ../../../build/install/bin/shaders/ -Force"
powershell -Command "Copy-Item -Recurse ../../../assets/* ../../../build/install/bin/assets/ -Force"
