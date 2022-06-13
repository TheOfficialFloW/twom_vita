cmake_minimum_required(VERSION 2.8)

if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  if(DEFINED ENV{VITASDK})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VITASDK}/share/vita.toolchain.cmake" CACHE PATH "toolchain file")
  else()
    message(FATAL_ERROR "Please define VITASDK to point to your SDK path!")
  endif()
endif()

project(TWOM C CXX)
include("${VITASDK}/share/vita.cmake" REQUIRED)
set(VITA_APP_NAME "This War of Mine")
set(VITA_TITLEID  "TWOM00000")
set(VITA_VERSION  "01.00")
set(VITA_MKSFOEX_FLAGS "-d ATTRIBUTE2=12")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Wl,-q,--wrap,memcpy,--wrap,memmove,--wrap,memset -D_GNU_SOURCE -Wall -O3")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -std=c++11")

add_executable(TWOM
  loader/main.c
  loader/dialog.c
  loader/so_util.c
  loader/sha1.c
)

target_link_libraries(TWOM
  -Wl,--whole-archive pthread -Wl,--no-whole-archive
  m
  stdc++
  openal
  imgui
  vitaGL
  vitashark
  SceShaccCgExt
  taihen_stub
  mathneon
  mpg123
  kubridge_stub
  SceAppMgr_stub
  SceAppUtil_stub
  SceAudio_stub
  SceAudioIn_stub
  SceCtrl_stub
  SceCommonDialog_stub
  SceDisplay_stub
  SceKernelDmacMgr_stub
  SceRazorHud_stub
  SceRazorCapture_stub
  SceFios2_stub
  SceGxm_stub
  SceLibcBridge_stub
  SceShaccCg_stub
  SceSysmodule_stub
  ScePower_stub
  SceTouch_stub
  SceVshBridge_stub
)

vita_create_self(eboot.bin TWOM UNSAFE)
vita_create_vpk(TWOM.vpk ${VITA_TITLEID} eboot.bin
  VERSION ${VITA_VERSION}
  NAME ${VITA_APP_NAME}
  FILE ${CMAKE_SOURCE_DIR}/livearea/icon0.png sce_sys/icon0.png
       ${CMAKE_SOURCE_DIR}/livearea/bg.png sce_sys/livearea/contents/bg.png
       ${CMAKE_SOURCE_DIR}/livearea/frame1.png sce_sys/livearea/contents/frame1.png
       ${CMAKE_SOURCE_DIR}/livearea/frame2.png sce_sys/livearea/contents/frame2.png
       ${CMAKE_SOURCE_DIR}/livearea/template.xml sce_sys/livearea/contents/template.xml
       ${CMAKE_SOURCE_DIR}/gamefiles/settings.cfg settings.cfg
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/blurcomposition.fsh Common/Shaders/blurcomposition.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/blurcomposition.vsh Common/Shaders/blurcomposition.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/font.fsh Common/Shaders/font.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/font.vsh Common/Shaders/font.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/gaussblur.fsh Common/Shaders/gaussblur.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/gaussblur.vsh Common/Shaders/gaussblur.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/glowsource.fsh Common/Shaders/glowsource.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/glowsource.vsh Common/Shaders/glowsource.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/graph.fsh Common/Shaders/graph.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/graph.vsh Common/Shaders/graph.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/light.fsh Common/Shaders/light.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/light.vsh Common/Shaders/light.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/meshoutlines.fsh Common/Shaders/meshoutlines.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/meshoutlines.vsh Common/Shaders/meshoutlines.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobileitdroundprogress.fsh Common/Shaders/mobileitdroundprogress.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobileitdroundprogress.vsh Common/Shaders/mobileitdroundprogress.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilemeshsolid.fsh Common/Shaders/mobilemeshsolid.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilemeshsolid.vsh Common/Shaders/mobilemeshsolid.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilemeshtranslucent.fsh Common/Shaders/mobilemeshtranslucent.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilemeshtranslucent.vsh Common/Shaders/mobilemeshtranslucent.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilepostprocesskosovo.fsh Common/Shaders/mobilepostprocesskosovo.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilepostprocesskosovo.vsh Common/Shaders/mobilepostprocesskosovo.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilepostprocessoutlines.fsh Common/Shaders/mobilepostprocessoutlines.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/mobilepostprocessoutlines.vsh Common/Shaders/mobilepostprocessoutlines.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/particle.fsh Common/Shaders/particle.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/particle.vsh Common/Shaders/particle.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/postfseupscale.fsh Common/Shaders/postfseupscale.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/postfseupscale.vsh Common/Shaders/postfseupscale.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/sfxquad.fsh Common/Shaders/sfxquad.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/sfxquad.vsh Common/Shaders/sfxquad.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/simpleshader.fsh Common/Shaders/simpleshader.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/simpleshader.vsh Common/Shaders/simpleshader.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/ui.fsh Common/Shaders/ui.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/ui.vsh Common/Shaders/ui.vsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/video.fsh Common/Shaders/video.fsh
       ${CMAKE_SOURCE_DIR}/gamefiles/Common/Shaders/video.vsh Common/Shaders/video.vsh
)

add_custom_target(copy
  COMMAND cp eboot.bin D:/app/${VITA_TITLEID}/eboot.bin
  DEPENDS eboot.bin
)
