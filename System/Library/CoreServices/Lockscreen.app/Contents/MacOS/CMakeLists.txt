cmake_minimum_required(VERSION 3.21)
project(SwiftDE-RunQML)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick)
find_package(LayerShellQt REQUIRED)

add_executable(SwiftDE-RunQML
    runner.cpp
    processrunner.cpp
)
target_link_libraries(SwiftDE-RunQML PRIVATE
    Qt6::Gui Qt6::Qml Qt6::Quick
    LayerShellQt::Interface
)
