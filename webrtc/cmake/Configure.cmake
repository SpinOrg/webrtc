if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.14)
    set(CMAKE_OSX_SYSROOT macosx10.14)
endif(APPLE)

set(WEBRTC_GEN_DEPENDS download)
if(UNIX AND NOT APPLE)
    set(WEBRTC_SYSROOT_COMMAND python3 build/linux/sysroot_scripts/install-sysroot.py --arch=${WEBRTC_ARCH})
    webrtc_command(
        NAME sysroot
        COMMAND ${WEBRTC_SYSROOT_COMMAND}
        WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
        DEPENDS download
    )
    list(APPEND WEBRTC_GEN_DEPENDS sysroot)
endif()

set(WEBRTC_CONFIGURE_COMMAND gn gen out/${WEBRTC_BUILD_TYPE} --args=${WEBRTC_GEN_ARGS})
webrtc_command(
    NAME gen
    COMMAND ${WEBRTC_CONFIGURE_COMMAND}
    WORKING_DIRECTORY ${WEBRTC_FOLDER}/src
    DEPENDS ${WEBRTC_GEN_DEPENDS}
)

webrtc_command(
    NAME configure
    COMMAND echo configure complete
    DEPENDS gen
)
