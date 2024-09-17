
if(NOT WIN32)
    find_package(PythonInterp 2.7 REQUIRED)
endif()

ExternalProject_Add(depot-tools
    GIT_REPOSITORY    https://chromium.googlesource.com/chromium/tools/depot_tools.git
    PREFIX            ${BINARY_ROOT}/depot_tools
    GIT_TAG "main"
    UPDATE_COMMAND    ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND   ""
)

ExternalProject_Get_Property(depot-tools SOURCE_DIR)
set(DEPOT_TOOLS_PATH ${SOURCE_DIR})
