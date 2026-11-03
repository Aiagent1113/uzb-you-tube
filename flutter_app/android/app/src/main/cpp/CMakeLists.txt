cmake_minimum_required(VERSION 3.18.1)

project("native-vault")

add_library(
    native-vault
    SHARED
    native-vault.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    native-vault
    ${log-lib}
)
