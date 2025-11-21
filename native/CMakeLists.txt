cmake_minimum_required(VERSION 3.15)
project(mouse_controller)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../build)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/../build)

# 源文件
set(SOURCES
    src/mouse_controller.cpp
)

# 头文件
set(HEADERS
    src/mouse_controller.h
)

# 创建动态链接库
add_library(mouse_controller SHARED ${SOURCES} ${HEADERS})

# 设置编译定义
target_compile_definitions(mouse_controller PRIVATE BUILDING_DLL)

# Windows特定设置
if(WIN32)
    target_link_libraries(mouse_controller PRIVATE user32)
endif()

# 设置输出名称
set_target_properties(mouse_controller PROPERTIES
    OUTPUT_NAME "mouse_controller"
    PREFIX ""
)
