set(DEPOT_TOOLS_CONFIG_COMMAND git config core.autocrlf false)
set(DEPOT_TOOLS_CONFIG_DEPENDS "")
if(TARGET depot-tools)
    list(APPEND DEPOT_TOOLS_CONFIG_DEPENDS depot-tools)
endif()

webrtc_command(
    NAME depot-tools-config
    COMMAND ${DEPOT_TOOLS_CONFIG_COMMAND}
    WORKING_DIRECTORY ${DEPOT_TOOLS_PATH}
    DEPENDS ${DEPOT_TOOLS_CONFIG_DEPENDS}
)

set(WEBRTC_FETCH_COMMAND gclient config --unmanaged --name src https://webrtc.googlesource.com/src)
webrtc_command(
    NAME config
    COMMAND ${WEBRTC_FETCH_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}
    DEPENDS depot-tools-config
)

set(WEBRTC_SYNC_COMMAND gclient sync --revision ${WEBRTC_GIT_REVISION} --nohooks --reset --no-history --shallow)
webrtc_command(
    NAME sync
    COMMAND ${WEBRTC_SYNC_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}
    DEPENDS config
)

set(WEBRTC_HOOKS_COMMAND gclient runhooks)
webrtc_command(
    NAME hooks
    COMMAND ${WEBRTC_HOOKS_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}
    DEPENDS sync
)

if(DEFINED ENV{GYP_DEFINES})
    message(WARNING GYP_DEFINES is already set to $ENV{GYP_DEFINES})
else()
    if(APPLE)
        if(ARCH STREQUAL "arm64")
            set(ENV{GYP_DEFINES} "target_arch=arm64")
        else()
            set(ENV{GYP_DEFINES} "target_arch=x64")
        endif()
    else()
        set(ENV{GYP_DEFINES} "target_arch=ia32")
    endif()
endif()

set(WEBRTC_DOWNLOAD_DEPENDS config sync hooks)

set(WEBRTC_BORINGSSL_STRING_INCLUDE_COMMAND
    git apply --recount --verbose --ignore-space-change --ignore-whitespace
    ${CMAKE_CURRENT_SOURCE_DIR}/patch/boringssl-string-include.patch)
webrtc_command(
    NAME boringssl-string-include
    COMMAND ${WEBRTC_BORINGSSL_STRING_INCLUDE_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
    DEPENDS sync
)
list(APPEND WEBRTC_DOWNLOAD_DEPENDS boringssl-string-include)

if(NOLOG)
    set(WEBRTC_NOLOG_COMMAND git apply --3way --ignore-space-change --ignore-whitespace ${CMAKE_CURRENT_SOURCE_DIR}/patch/Disable-debug-build-log.patch)
    webrtc_command(
        NAME nolog
        COMMAND ${WEBRTC_NOLOG_COMMAND}
        WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
        DEPENDS sync
    )
    list(APPEND WEBRTC_DOWNLOAD_DEPENDS nolog)
endif()
if(UNIX AND NOT APPLE)
    set(WEBRTC_STDCXX_COMMAND git apply --verbose --ignore-space-change --ignore-whitespace ${CMAKE_CURRENT_SOURCE_DIR}/patch/linux_stdcxx_compatibility_patch.patch)
    webrtc_command(
        NAME unixstdcxx
        COMMAND ${WEBRTC_STDCXX_COMMAND}
        WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
        DEPENDS sync
    )
    list(APPEND WEBRTC_DOWNLOAD_DEPENDS unixstdcxx)
endif()

set(WEBRTC_DCSCTP_TUNING_COMMAND
    git apply --recount --verbose --ignore-space-change --ignore-whitespace
    ${CMAKE_CURRENT_SOURCE_DIR}/patch/dcsctp-production-tuning.patch)
webrtc_command(
    NAME dcsctp-production-tuning
    COMMAND ${WEBRTC_DCSCTP_TUNING_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
    DEPENDS ${WEBRTC_DOWNLOAD_DEPENDS}
)
list(APPEND WEBRTC_DOWNLOAD_DEPENDS dcsctp-production-tuning)

if(WEBRTC_ENABLE_NETWORK_BENCHMARKING)
    set(WEBRTC_DCSCTP_DIAGNOSTICS_COMMAND
        git apply --recount --verbose --ignore-space-change --ignore-whitespace
        ${CMAKE_CURRENT_SOURCE_DIR}/patch/dcsctp-transport-diagnostics.patch)
    webrtc_command(
        NAME dcsctp-diagnostics
        COMMAND ${WEBRTC_DCSCTP_DIAGNOSTICS_COMMAND}
        WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
        DEPENDS ${WEBRTC_DOWNLOAD_DEPENDS}
    )
    list(APPEND WEBRTC_DOWNLOAD_DEPENDS dcsctp-diagnostics)
endif()
if(CUBBIT)
    set(WEBRTC_LIBCXXABI_PATCH_COMMAND git apply --3way --ignore-space-change --ignore-whitespace ${CMAKE_CURRENT_SOURCE_DIR}/patch/libc++abi/Enable-cxa_thread_atexit-for-linux.patch)
    webrtc_command(
        NAME libcxxabi-patch
        COMMAND ${WEBRTC_LIBCXXABI_PATCH_COMMAND}
        WORKING_DIRECTORY ${WEBRTC_FOLDER}/src/buildtools/third_party/libc++abi
        DEPENDS sync
    )
    list(APPEND WEBRTC_DOWNLOAD_DEPENDS libcxxabi-patch)
endif()

if(WIN32)
    set(
        DEPOT_TOOLS_PIP_COMMAND
        "${DEPOT_TOOLS_PATH}/python3.bat" -m pip install pywin32)
    webrtc_command(
        NAME depot-tools-pip
        COMMAND ${DEPOT_TOOLS_PIP_COMMAND}
        WORKING_DIRECTORY ${DEPOT_TOOLS_PATH}
        DEPENDS sync
    )
    list(APPEND WEBRTC_DOWNLOAD_DEPENDS depot-tools-pip)
endif()

webrtc_command(
    NAME download
    COMMAND echo download completed
    DEPENDS ${WEBRTC_DOWNLOAD_DEPENDS}
)
