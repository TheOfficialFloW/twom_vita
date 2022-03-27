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

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Wl,-q,--wrap,memcpy,--wrap,memmove,--wrap,memset -D_GNU_SOURCE -Wall -O3 -mfloat-abi=softfp")
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
)

add_custom_target(copy
  COMMAND cp eboot.bin D:/app/${VITA_TITLEID}/eboot.bin
  DEPENDS eboot.bin
)
