#ifndef __CONFIG_H__
#define __CONFIG_H__

#define DEBUG

#define LOAD_ADDRESS 0x98000000

#define MEMORY_SCELIBC_MB 4
#define MEMORY_NEWLIB_MB 240
#define MEMORY_VITAGL_THRESHOLD_MB 8

#define DATA_PATH "ux0:data/twom"
#define SO_PATH DATA_PATH "/" "libAndroidGame.so"
#define SO_DLC_PATH DATA_PATH "/" "libAndroidGameStories.so"

#define SCREEN_W 960
#define SCREEN_H 544

#endif
