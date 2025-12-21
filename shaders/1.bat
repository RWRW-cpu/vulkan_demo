cd d:\code\w_cplus\vulkan\vulkan_demo1\example\33_cube-maps\shaders;
$env:Path = "D:\Program\VulkanSDK\1.3.296.0\Bin;$env:Path"; 
glslc skybox.vert -o skybox.vert.spv; 
glslc skybox.frag -o skybox.frag.spv; 
if ($?) { Write-Host "Shaders compiled successfully" -ForegroundColor Green } 
else { Write-Host "Compilation failed" -ForegroundColor Red }

Copy-Item d:\code\w_cplus\vulkan\vulkan_demo1\example\33_cube-maps\shaders\skybox.*.spv 
d:\code\w_cplus\vulkan\vulkan_demo1\build\install\bin\shaders\