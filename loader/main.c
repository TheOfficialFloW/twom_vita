/* main.c -- This War of Mine .so loader
 *
 * Copyright (C) 2021 Andy Nguyen
 *
 * This software may be modified and distributed under the terms
 * of the MIT license.  See the LICENSE file for details.
 */

#include <psp2/io/dirent.h>
#include <psp2/io/fcntl.h>
#include <psp2/kernel/clib.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/appmgr.h>
#include <psp2/apputil.h>
#include <psp2/ctrl.h>
#include <psp2/power.h>
#include <psp2/rtc.h>
#include <psp2/touch.h>
#include <kubridge.h>
#include <vitashark.h>
#include <vitaGL.h>

#define AL_ALEXT_PROTOTYPES
#include <AL/alext.h>
#include <AL/efx.h>

#include <malloc.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <wchar.h>
#include <wctype.h>

#include <math.h>
#include <math_neon.h>

#include <errno.h>
#include <ctype.h>
#include <setjmp.h>
#include <sys/time.h>
#include <sys/stat.h>

#include "main.h"
#include "config.h"
#include "dialog.h"
#include "so_util.h"
#include "sha1.h"

int pstv_mode = 0;

int sceLibcHeapSize = MEMORY_SCELIBC_MB * 1024 * 1024;
int _newlib_heap_size_user = MEMORY_NEWLIB_MB * 1024 * 1024;

unsigned int _pthread_stack_default_user = 1 * 1024 * 1024;

unsigned int _oal_thread_priority = 64;
unsigned int _oal_thread_affinity = 0x40000;

so_module twom_mod;

void *__wrap_memcpy(void *dest, const void *src, size_t n) {
  return sceClibMemcpy(dest, src, n);
}

void *__wrap_memmove(void *dest, const void *src, size_t n) {
  return sceClibMemmove(dest, src, n);
}

void *__wrap_memset(void *s, int c, size_t n) {
  return sceClibMemset(s, c, n);
}

int debugPrintf(char *text, ...) {
#ifdef DEBUG
  va_list list;
  static char string[0x8000];

  va_start(list, text);
  vsprintf(string, text, list);
  va_end(list);

  SceUID fd = sceIoOpen("ux0:data/twom_log.txt", SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
  if (fd >= 0) {
    sceIoWrite(fd, string, strlen(string));
    sceIoClose(fd);
  }
#endif
  return 0;
}

int __android_log_print(int prio, const char *tag, const char *fmt, ...) {
#ifdef DEBUG
  va_list list;
  static char string[0x8000];

  va_start(list, fmt);
  vsprintf(string, fmt, list);
  va_end(list);

  // debugPrintf("[LOG] %s: %s\n", tag, string);
#endif
  return 0;
}

int __android_log_write(int prio, const char *tag, const char *text) {
#ifdef DEBUG
  // printf("[LOG] %s: %s\n", tag, text);
#endif
  return 0;
}

int ret0(void) {
  return 0;
}

int ret1(void) {
  return 1;
}

int clock_gettime(int clk_ik, struct timespec *t) {
  struct timeval now;
  int rv = gettimeofday(&now, NULL);
  if (rv)
    return rv;
  t->tv_sec = now.tv_sec;
  t->tv_nsec = now.tv_usec * 1000;
  return 0;
}

int pthread_once_fake(volatile int *once_control, void (*init_routine) (void)) {
  if (!once_control || !init_routine)
    return -1;
  if (__sync_lock_test_and_set(once_control, 1) == 0)
    (*init_routine)();
  return 0;
}

int pthread_create_fake(pthread_t *thread, const void *unused, void *entry, void *arg) {
  return pthread_create(thread, NULL, entry, arg);
}

int pthread_mutexattr_init_fake(int *attr) {
  *attr = 0;
  return 0;
}

int pthread_mutexattr_destroy_fake(int *attr) {
  return 0;
}

int pthread_mutexattr_settype_fake(int *attr, int type) {
  *attr = type;
  return 0;
}

int pthread_mutex_init_fake(SceKernelLwMutexWork **work, int *mutexattr) {
  int recursive = (mutexattr && *mutexattr == 1);
  *work = (SceKernelLwMutexWork *)memalign(8, sizeof(SceKernelLwMutexWork));
  if (sceKernelCreateLwMutex(*work, "mutex", recursive ? SCE_KERNEL_MUTEX_ATTR_RECURSIVE : 0, 0, NULL) < 0)
    return -1;
  return 0;
}

int pthread_mutex_destroy_fake(SceKernelLwMutexWork **work) {
  if (sceKernelDeleteLwMutex(*work) < 0)
    return -1;
  free(*work);
  return 0;
}

int pthread_mutex_lock_fake(SceKernelLwMutexWork **work) {
  if (sceKernelLockLwMutex(*work, 1, NULL) < 0)
    return -1;
  return 0;
}

int pthread_mutex_trylock_fake(SceKernelLwMutexWork **work) {
  if (sceKernelTryLockLwMutex(*work, 1) < 0)
    return -1;
  return 0;
}

int pthread_mutex_unlock_fake(SceKernelLwMutexWork **work) {
  if (sceKernelUnlockLwMutex(*work, 1) < 0)
    return -1;
  return 0;
}

int sem_init_fake(int *uid, int pshared, unsigned value) {
  *uid = sceKernelCreateSema("sema", 0, value, 0x7fffffff, NULL);
  if (*uid < 0)
    return -1;
  return 0;
}

int sem_post_fake(int *uid) {
  if (sceKernelSignalSema(*uid, 1) < 0)
    return -1;
  return 0;
}

int sem_wait_fake(int *uid) {
  if (sceKernelWaitSema(*uid, 1, NULL) < 0)
    return -1;
  return 0;
}

int sem_timedwait_fake(int *uid, const struct timespec *abstime) {
  struct timespec now = {0};
  clock_gettime(0, &now);
  SceUInt timeout = (abstime->tv_sec * 1000 * 1000 + abstime->tv_nsec / 1000) - (now.tv_sec * 1000 * 1000 + now.tv_nsec / 1000);
  if (timeout < 0)
    timeout = 0;
  if (sceKernelWaitSema(*uid, 1, &timeout) < 0)
    return -1;
  return 0;
}

int sem_destroy_fake(int *uid) {
  if (sceKernelDeleteSema(*uid) < 0)
    return -1;
  return 0;
}

static int *TotalMemeorySizeInMB = NULL;

void DeteremineSystemMemory(void) {
  *TotalMemeorySizeInMB = MEMORY_NEWLIB_MB;
}

int FileSystem__IsAbsolutePath(void *this, const char *path) {
  return strncmp(path, "ux0:", 4) == 0;
}

char *ShaderManager__GetShaderPath(void) {
  return DATA_PATH "/Common/Shaders";
}

char *interesting_files[] = {
  // "Common/Shaders/Shaders.DefBin",
  // "Common/Shaders/simpleshader.vsh",
  // "Common/Shaders/simpleshader.fsh",
  // "Common/Shaders/meshwireframe.vsh",
  // "Common/Shaders/meshwireframe.fsh",
  // "Common/Shaders/meshoutlines.vsh",
  // "Common/Shaders/meshoutlines.fsh",
  // "Common/Shaders/font.vsh",
  // "Common/Shaders/font.fsh",
  // "Common/Shaders/ui.vsh",
  // "Common/Shaders/ui.fsh",
  // "Common/Shaders/blurcomposition.vsh",
  // "Common/Shaders/blurcomposition.fsh",
  // "Common/Shaders/video.vsh",
  // "Common/Shaders/video.fsh",
  // "Common/Shaders/collisionvis.vsh",
  // "Common/Shaders/collisionvis.fsh",
  // "Common/Shaders/deferredcomposition.vsh",
  // "Common/Shaders/deferredcomposition.fsh",
  // "Common/Shaders/postfseupscale.vsh",
  // "Common/Shaders/postfseupscale.fsh",
  // "Common/Shaders/glowsource.vsh",
  // "Common/Shaders/glowsource.fsh",
  // "Common/Shaders/gaussblur.vsh",
  // "Common/Shaders/gaussblur.fsh",
  // "Common/Shaders/mobilepostprocessoutlines.vsh",
  // "Common/Shaders/mobilepostprocessoutlines.fsh",
  // "Common/Shaders/mobilepostprocesskosovo.vsh",
  // "Common/Shaders/mobilepostprocesskosovo.fsh",
  // "Common/Shaders/particle.vsh",
  // "Common/Shaders/particle.fsh",
  // "Common/Shaders/mobilemeshsolid.vsh",
  // "Common/Shaders/mobilemeshsolid.fsh",
  // "Common/Shaders/sfxquad.vsh",
  // "Common/Shaders/sfxquad.fsh",
  // "Common/Shaders/mobilemeshtranslucent.vsh",
  // "Common/Shaders/mobilemeshtranslucent.fsh",
  // "Common/Shaders/graph.vsh",
  // "Common/Shaders/graph.fsh",
  // "Common/Shaders/light.vsh",
  // "Common/Shaders/light.fsh",
  // "Common/Shaders/lightfinalcomponents.vsh",
  // "Common/Shaders/lightfinalcomponents.fsh",
  // "Common/Shaders/mobileitdroundprogress.vsh",
  // "Common/Shaders/mobileitdroundprogress.fsh",
};

void *(* FileReader__Constructor)(void *this, char *file, char *ext, char *folder, int crc);
void *(* FileReader__Deconstructor)(void *this);
int (* FileReader__Read)(void *this, void *buf, int length);
int (* FileReader__GetFileLength)(void *this);

int WriteFile(char *file, void *buf, int size) {
  SceUID fd = sceIoOpen(file, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
  if (fd < 0)
    return fd;

  int written = sceIoWrite(fd, buf, size);

  sceIoClose(fd);
  return written;
}

void dump_shaders() {
  for (int i = 0; i < sizeof(interesting_files) / sizeof(char **); i++) {
    char *file = malloc(0x1000);
    memset(file, 0, 0x1000);

    FileReader__Constructor(file, interesting_files[i], 0, 0, 0);

    int size = FileReader__GetFileLength(file);
    // debugPrintf("%s %x\n", interesting_files[i], size);
    char *buf = malloc(size);

    FileReader__Read(file, buf, size);
    FileReader__Deconstructor(file);

    char path[128];
    sprintf(path, DATA_PATH "/%s", interesting_files[i]);
    WriteFile(path, buf, size);

    free(buf);

    free(file);
  }

  sceKernelExitProcess(0);
}

void PresentGLContext(void) {
  vglSwapBuffers(GL_FALSE);
}

extern void *__cxa_guard_acquire;
extern void *__cxa_guard_release;

void patch_game(void) {
  FileReader__Constructor = (void *)so_symbol(&twom_mod, "_ZN10FileReaderC2EPKcS1_S1_j");
  FileReader__Deconstructor = (void *)so_symbol(&twom_mod, "_ZN10FileReaderD2Ev");
  FileReader__Read = (void *)so_symbol(&twom_mod, "_ZN10FileReader4ReadEPvj");
  FileReader__GetFileLength = (void *)so_symbol(&twom_mod, "_ZNK10FileReader13GetFileLengthEv");
  // hook_addr(so_symbol(&twom_mod, "_ZN14ResourceShader15_LoadFromSourceERPcRjPK9_FILETIMEj"), (uintptr_t)&dump_shaders);

  hook_addr(so_symbol(&twom_mod, "_ZN10FileSystem14IsAbsolutePathEPKc"), (uintptr_t)&FileSystem__IsAbsolutePath);
  hook_addr(so_symbol(&twom_mod, "_ZN13ShaderManager13GetShaderPathEv"), (uintptr_t)&ShaderManager__GetShaderPath);

  hook_addr(so_symbol(&twom_mod, "__cxa_guard_acquire"), (uintptr_t)&__cxa_guard_acquire);
  hook_addr(so_symbol(&twom_mod, "__cxa_guard_release"), (uintptr_t)&__cxa_guard_release);

  hook_addr(so_symbol(&twom_mod, "_Z17GetApkAssetOffsetPKcRj"), (uintptr_t)ret0);

  TotalMemeorySizeInMB = (int *)so_symbol(&twom_mod, "TotalMemeorySizeInMB");
  hook_addr(so_symbol(&twom_mod, "_Z22DeteremineSystemMemoryv"), (uintptr_t)DeteremineSystemMemory);

  hook_addr(so_symbol(&twom_mod, "_ZN14GoogleServices10IsSignedInEv"), (uintptr_t)ret0);
  hook_addr(so_symbol(&twom_mod, "_Z12SetGLContextv"), (uintptr_t)ret0);
  hook_addr(so_symbol(&twom_mod, "_Z16PresentGLContextv"), (uintptr_t)PresentGLContext);

  hook_addr(so_symbol(&twom_mod, "_ZN11GameConsole5PrintEhhPKcz"), (uintptr_t)ret0);
  hook_addr(so_symbol(&twom_mod, "_ZN11GameConsole12PrintWarningEhPKcz"), (uintptr_t)ret0);
  hook_addr(so_symbol(&twom_mod, "_ZN11GameConsole10PrintErrorEhPKcz"), (uintptr_t)ret0);
}

extern void *__aeabi_atexit;
extern void *__aeabi_idiv;
extern void *__aeabi_idivmod;
extern void *__aeabi_ldivmod;
extern void *__aeabi_uidiv;
extern void *__aeabi_uidivmod;
extern void *__aeabi_uldivmod;
extern void *__cxa_atexit;
extern void *__cxa_finalize;
extern void *__gnu_unwind_frame;
extern void *__stack_chk_fail;

static int __stack_chk_guard_fake = 0x42424242;

static char *__ctype_ = (char *)&_ctype_;

static FILE __sF_fake[0x100][3];

int stat_hook(const char *pathname, void *statbuf) {
  struct stat st;
  int res = stat(pathname, &st);
  if (res == 0)
    *(uint64_t *)(statbuf + 0x30) = st.st_size;
  return res;
}

void glTexImage2DHook(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void * data) {
  if (level == 0)
    glTexImage2D(target, level, internalformat, width, height, border, format, type, data);
}

void glCompressedTexImage2DHook(GLenum target, GLint level, GLenum format, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const void * data) {
  printf("compressed called\n");
  // mips for PVRTC textures break when they're under 1 block in size
  if (level == 0)
    glCompressedTexImage2D(target, level, format, width, height, border, imageSize, data);
}

static so_default_dynlib default_dynlib[] = {
  // { "ANativeWindow_release", (uintptr_t)&ANativeWindow_release },
  // { "ANativeWindow_setBuffersGeometry", (uintptr_t)&ANativeWindow_setBuffersGeometry },
  // { "_Unwind_Complete", (uintptr_t)&_Unwind_Complete },
  // { "_Unwind_DeleteException", (uintptr_t)&_Unwind_DeleteException },
  // { "_Unwind_GetDataRelBase", (uintptr_t)&_Unwind_GetDataRelBase },
  // { "_Unwind_GetLanguageSpecificData", (uintptr_t)&_Unwind_GetLanguageSpecificData },
  // { "_Unwind_GetRegionStart", (uintptr_t)&_Unwind_GetRegionStart },
  // { "_Unwind_GetTextRelBase", (uintptr_t)&_Unwind_GetTextRelBase },
  // { "_Unwind_RaiseException", (uintptr_t)&_Unwind_RaiseException },
  // { "_Unwind_Resume", (uintptr_t)&_Unwind_Resume },
  // { "_Unwind_Resume_or_Rethrow", (uintptr_t)&_Unwind_Resume_or_Rethrow },
  // { "_Unwind_VRS_Get", (uintptr_t)&_Unwind_VRS_Get },
  // { "_Unwind_VRS_Set", (uintptr_t)&_Unwind_VRS_Set },
  { "__aeabi_atexit", (uintptr_t)&__aeabi_atexit },
  { "__aeabi_idiv", (uintptr_t)&__aeabi_idiv },
  { "__aeabi_idivmod", (uintptr_t)&__aeabi_idivmod },
  { "__aeabi_ldivmod", (uintptr_t)&__aeabi_ldivmod },
  { "__aeabi_uidiv", (uintptr_t)&__aeabi_uidiv },
  { "__aeabi_uidivmod", (uintptr_t)&__aeabi_uidivmod },
  { "__aeabi_uldivmod", (uintptr_t)&__aeabi_uldivmod },
  { "__android_log_print", (uintptr_t)&__android_log_print },
  { "__android_log_write", (uintptr_t)&__android_log_write },
  { "__cxa_atexit", (uintptr_t)&__cxa_atexit },
  { "__cxa_finalize", (uintptr_t)&__cxa_finalize },
  { "__errno", (uintptr_t)&__errno },
  { "__gnu_unwind_frame", (uintptr_t)&__gnu_unwind_frame },
  // { "__google_potentially_blocking_region_begin", (uintptr_t)&__google_potentially_blocking_region_begin },
  // { "__google_potentially_blocking_region_end", (uintptr_t)&__google_potentially_blocking_region_end },
  { "__sF", (uintptr_t)&__sF_fake },
  { "__stack_chk_fail", (uintptr_t)&__stack_chk_fail },
  { "__stack_chk_guard", (uintptr_t)&__stack_chk_guard_fake },
  { "_ctype_", (uintptr_t)&__ctype_ },
  { "abort", (uintptr_t)&abort },
  // { "accept", (uintptr_t)&accept },
  { "acos", (uintptr_t)&acos },
  { "acosf", (uintptr_t)&acosf },
  { "alBufferData", (uintptr_t)&alBufferData },
  { "alDeleteBuffers", (uintptr_t)&alDeleteBuffers },
  { "alDeleteSources", (uintptr_t)&alDeleteSources },
  { "alDistanceModel", (uintptr_t)&alDistanceModel },
  { "alGenBuffers", (uintptr_t)&alGenBuffers },
  { "alGenSources", (uintptr_t)&alGenSources },
  { "alGetError", (uintptr_t)&alGetError },
  { "alGetSourcei", (uintptr_t)&alGetSourcei },
  { "alGetString", (uintptr_t)&alGetString },
  // { "alHackPause", (uintptr_t)&alHackPause },
  // { "alHackResume", (uintptr_t)&alHackResume },
  { "alListenerfv", (uintptr_t)&alListenerfv },
  { "alSourcePlay", (uintptr_t)&alSourcePlay },
  { "alSourceQueueBuffers", (uintptr_t)&alSourceQueueBuffers },
  { "alSourceStop", (uintptr_t)&alSourceStop },
  { "alSourceUnqueueBuffers", (uintptr_t)&alSourceUnqueueBuffers },
  { "alSourcef", (uintptr_t)&alSourcef },
  { "alSourcefv", (uintptr_t)&alSourcefv },
  { "alSourcei", (uintptr_t)&alSourcei },
  { "alcCloseDevice", (uintptr_t)&alcCloseDevice },
  { "alcCreateContext", (uintptr_t)&alcCreateContext },
  { "alcDestroyContext", (uintptr_t)&alcDestroyContext },
  { "alcGetProcAddress", (uintptr_t)&alcGetProcAddress },
  { "alcGetString", (uintptr_t)&alcGetString },
  { "alcMakeContextCurrent", (uintptr_t)&alcMakeContextCurrent },
  { "alcOpenDevice", (uintptr_t)&alcOpenDevice },
  { "alcProcessContext", (uintptr_t)&alcProcessContext },
  { "alcSuspendContext", (uintptr_t)&alcSuspendContext },
  { "asin", (uintptr_t)&asin },
  { "asinf", (uintptr_t)&asinf },
  { "atan", (uintptr_t)&atan },
  { "atan2", (uintptr_t)&atan2 },
  { "atan2f", (uintptr_t)&atan2f },
  { "atanf", (uintptr_t)&atanf },
  { "atoi", (uintptr_t)&atoi },
  { "atoll", (uintptr_t)&atoll },
  // { "bind", (uintptr_t)&bind },
  { "bsearch", (uintptr_t)&bsearch },
  { "btowc", (uintptr_t)&btowc },
  { "calloc", (uintptr_t)&calloc },
  { "ceil", (uintptr_t)&ceil },
  { "ceilf", (uintptr_t)&ceilf },
  { "clearerr", (uintptr_t)&clearerr },
  { "clock_gettime", (uintptr_t)&clock_gettime },
  // { "close", (uintptr_t)&close },
  { "cos", (uintptr_t)&cos },
  { "cosf", (uintptr_t)&cosf },
  { "cosh", (uintptr_t)&cosh },
  // { "eglChooseConfig", (uintptr_t)&eglChooseConfig },
  // { "eglCreateContext", (uintptr_t)&eglCreateContext },
  // { "eglCreateWindowSurface", (uintptr_t)&eglCreateWindowSurface },
  // { "eglDestroyContext", (uintptr_t)&eglDestroyContext },
  // { "eglDestroySurface", (uintptr_t)&eglDestroySurface },
  // { "eglGetConfigAttrib", (uintptr_t)&eglGetConfigAttrib },
  { "eglGetDisplay", (uintptr_t)&ret0 },
  // { "eglGetProcAddress", (uintptr_t)&eglGetProcAddress },
  // { "eglInitialize", (uintptr_t)&eglInitialize },
  // { "eglMakeCurrent", (uintptr_t)&eglMakeCurrent },
  { "eglQueryString", (uintptr_t)&ret0 },
  // { "eglQuerySurface", (uintptr_t)&eglQuerySurface },
  // { "eglSwapBuffers", (uintptr_t)&eglSwapBuffers },
  // { "eglTerminate", (uintptr_t)&eglTerminate },
  { "exit", (uintptr_t)&exit },
  { "exp", (uintptr_t)&exp },
  { "expf", (uintptr_t)&expf },
  { "fclose", (uintptr_t)&fclose },
  { "fdopen", (uintptr_t)&fdopen },
  { "ferror", (uintptr_t)&ferror },
  { "fflush", (uintptr_t)&fflush },
  { "fgets", (uintptr_t)&fgets },
  { "floor", (uintptr_t)&floor },
  { "floorf", (uintptr_t)&floorf },
  { "fmod", (uintptr_t)&fmod },
  { "fmodf", (uintptr_t)&fmodf },
  { "fopen", (uintptr_t)&fopen },
  { "fprintf", (uintptr_t)&fprintf },
  { "fputc", (uintptr_t)&fputc },
  { "fputs", (uintptr_t)&fputs },
  { "fread", (uintptr_t)&fread },
  { "free", (uintptr_t)&free },
  { "frexp", (uintptr_t)&frexp },
  { "fseek", (uintptr_t)&fseek },
  { "fstat", (uintptr_t)&fstat },
  { "ftell", (uintptr_t)&ftell },
  { "fwrite", (uintptr_t)&fwrite },
  { "getc", (uintptr_t)&getc },
  { "getwc", (uintptr_t)&getwc },
  { "glActiveTexture", (uintptr_t)&glActiveTexture },
  { "glAttachShader", (uintptr_t)&glAttachShader },
  { "glBindAttribLocation", (uintptr_t)&glBindAttribLocation },
  { "glBindBuffer", (uintptr_t)&glBindBuffer },
  { "glBindFramebuffer", (uintptr_t)&glBindFramebuffer },
  { "glBindRenderbuffer", (uintptr_t)&ret0 },
  { "glBindTexture", (uintptr_t)&glBindTexture },
  { "glBlendEquation", (uintptr_t)&glBlendEquation },
  { "glBlendFunc", (uintptr_t)&glBlendFunc },
  { "glBufferData", (uintptr_t)&glBufferData },
  { "glBufferSubData", (uintptr_t)&glBufferSubData },
  { "glCheckFramebufferStatus", (uintptr_t)&glCheckFramebufferStatus },
  { "glClear", (uintptr_t)&glClear },
  { "glClearColor", (uintptr_t)&glClearColor },
  { "glClearDepthf", (uintptr_t)&glClearDepthf },
  { "glClearStencil", (uintptr_t)&glClearStencil },
  { "glColorMask", (uintptr_t)&glColorMask },
  { "glCompileShader", (uintptr_t)&glCompileShader },
  { "glCompressedTexImage2D", (uintptr_t)&glCompressedTexImage2DHook },
  { "glCreateProgram", (uintptr_t)&glCreateProgram },
  { "glCreateShader", (uintptr_t)&glCreateShader },
  { "glCullFace", (uintptr_t)&glCullFace },
  { "glDeleteBuffers", (uintptr_t)&glDeleteBuffers },
  { "glDeleteFramebuffers", (uintptr_t)&glDeleteFramebuffers },
  { "glDeleteProgram", (uintptr_t)&glDeleteProgram },
  { "glDeleteRenderbuffers", (uintptr_t)&ret0 },
  { "glDeleteShader", (uintptr_t)&glDeleteShader },
  { "glDeleteTextures", (uintptr_t)&glDeleteTextures },
  { "glDepthFunc", (uintptr_t)&glDepthFunc },
  { "glDepthMask", (uintptr_t)&glDepthMask },
  { "glDisable", (uintptr_t)&glDisable },
  { "glDisableVertexAttribArray", (uintptr_t)&glDisableVertexAttribArray },
  { "glDrawArrays", (uintptr_t)&glDrawArrays },
  { "glDrawElements", (uintptr_t)&glDrawElements },
  { "glEnable", (uintptr_t)&glEnable },
  { "glEnableVertexAttribArray", (uintptr_t)&glEnableVertexAttribArray },
  { "glFinish", (uintptr_t)&glFinish },
  { "glFramebufferRenderbuffer", (uintptr_t)&ret0 },
  { "glFramebufferTexture2D", (uintptr_t)&glFramebufferTexture2D },
  { "glGenBuffers", (uintptr_t)&glGenBuffers },
  { "glGenFramebuffers", (uintptr_t)&glGenFramebuffers },
  { "glGenRenderbuffers", (uintptr_t)&ret0 },
  { "glGenTextures", (uintptr_t)&glGenTextures },
  { "glGetError", (uintptr_t)&glGetError },
  { "glGetIntegerv", (uintptr_t)&glGetIntegerv },
  { "glGetProgramInfoLog", (uintptr_t)&glGetProgramInfoLog },
  { "glGetProgramiv", (uintptr_t)&glGetProgramiv },
  { "glGetShaderInfoLog", (uintptr_t)&glGetShaderInfoLog },
  { "glGetShaderPrecisionFormat", (uintptr_t)&ret0 },
  { "glGetShaderiv", (uintptr_t)&glGetShaderiv },
  { "glGetString", (uintptr_t)&glGetString },
  { "glGetUniformLocation", (uintptr_t)&glGetUniformLocation },
  { "glLinkProgram", (uintptr_t)&glLinkProgram },
  { "glPolygonOffset", (uintptr_t)&glPolygonOffset },
  { "glRenderbufferStorage", (uintptr_t)&ret0 },
  { "glScissor", (uintptr_t)&glScissor },
  { "glShaderSource", (uintptr_t)&glShaderSource },
  { "glStencilFunc", (uintptr_t)&glStencilFunc },
  { "glStencilMask", (uintptr_t)&glStencilMask },
  { "glStencilOp", (uintptr_t)&glStencilOp },
  { "glTexImage2D", (uintptr_t)&glTexImage2DHook },
  { "glTexParameteri", (uintptr_t)&glTexParameteri },
  { "glUniform1i", (uintptr_t)&glUniform1i },
  { "glUniform4fv", (uintptr_t)&glUniform4fv },
  { "glUniformMatrix4fv", (uintptr_t)&glUniformMatrix4fv },
  { "glUseProgram", (uintptr_t)&glUseProgram },
  { "glValidateProgram", (uintptr_t)&ret0 },
  { "glVertexAttribPointer", (uintptr_t)&glVertexAttribPointer },
  { "glViewport", (uintptr_t)&glViewport },
  // { "inet_addr", (uintptr_t)&inet_addr },
  // { "ioctl", (uintptr_t)&ioctl },
  { "isalnum", (uintptr_t)&isalnum },
  { "isalpha", (uintptr_t)&isalpha },
  { "iscntrl", (uintptr_t)&iscntrl },
  { "islower", (uintptr_t)&islower },
  { "ispunct", (uintptr_t)&ispunct },
  { "isspace", (uintptr_t)&isspace },
  { "isupper", (uintptr_t)&isupper },
  { "iswctype", (uintptr_t)&iswctype },
  { "isxdigit", (uintptr_t)&isxdigit },
  { "ldexp", (uintptr_t)&ldexp },
  // { "listen", (uintptr_t)&listen },
  { "localtime_r", (uintptr_t)&localtime_r },
  { "log", (uintptr_t)&log },
  { "log10", (uintptr_t)&log10 },
  { "longjmp", (uintptr_t)&longjmp },
  { "lrand48", (uintptr_t)&lrand48 },
  { "lrint", (uintptr_t)&lrint },
  { "lrintf", (uintptr_t)&lrintf },
  { "lseek", (uintptr_t)&lseek },
  { "malloc", (uintptr_t)&malloc },
  { "mbrtowc", (uintptr_t)&mbrtowc },
  { "memchr", (uintptr_t)&memchr },
  { "memcmp", (uintptr_t)&memcmp },
  { "memcpy", (uintptr_t)&memcpy },
  { "memmove", (uintptr_t)&memmove },
  { "memset", (uintptr_t)&memset },
  { "mkdir", (uintptr_t)&mkdir },
  { "modf", (uintptr_t)&modf },
  // { "poll", (uintptr_t)&poll },
  { "pow", (uintptr_t)&pow },
  { "powf", (uintptr_t)&powf },
  { "printf", (uintptr_t)&printf },
  { "pthread_attr_destroy", (uintptr_t)&ret0 },
  { "pthread_attr_init", (uintptr_t)&ret0 },
  { "pthread_attr_setdetachstate", (uintptr_t)&ret0 },
  { "pthread_create", (uintptr_t)&pthread_create_fake },
  { "pthread_getschedparam", (uintptr_t)&pthread_getschedparam },
  { "pthread_getspecific", (uintptr_t)&pthread_getspecific },
  { "pthread_key_create", (uintptr_t)&pthread_key_create },
  { "pthread_key_delete", (uintptr_t)&pthread_key_delete },
  { "pthread_mutex_destroy", (uintptr_t)&pthread_mutex_destroy_fake },
  { "pthread_mutex_init", (uintptr_t)&pthread_mutex_init_fake },
  { "pthread_mutex_lock", (uintptr_t)&pthread_mutex_lock_fake },
  { "pthread_mutex_trylock", (uintptr_t)&pthread_mutex_trylock_fake },
  { "pthread_mutex_unlock", (uintptr_t)&pthread_mutex_unlock_fake },
  { "pthread_mutexattr_destroy", (uintptr_t)&pthread_mutexattr_destroy_fake },
  { "pthread_mutexattr_init", (uintptr_t)&pthread_mutexattr_init_fake },
  { "pthread_mutexattr_settype", (uintptr_t)&pthread_mutexattr_settype_fake },
  { "pthread_once", (uintptr_t)&pthread_once_fake },
  { "pthread_self", (uintptr_t)&pthread_self },
  { "pthread_setschedparam", (uintptr_t)&pthread_setschedparam },
  { "pthread_setspecific", (uintptr_t)&pthread_setspecific },
  { "putc", (uintptr_t)&putc },
  { "putwc", (uintptr_t)&putwc },
  { "qsort", (uintptr_t)&qsort },
  // { "read", (uintptr_t)&read },
  { "realloc", (uintptr_t)&realloc },
  // { "recv", (uintptr_t)&recv },
  { "rint", (uintptr_t)&rint },
  { "sem_destroy", (uintptr_t)&sem_destroy_fake },
  { "sem_init", (uintptr_t)&sem_init_fake },
  { "sem_post", (uintptr_t)&sem_post_fake },
  { "sem_timedwait", (uintptr_t)&sem_timedwait_fake },
  { "sem_wait", (uintptr_t)&sem_wait_fake },
  // { "send", (uintptr_t)&send },
  // { "sendto", (uintptr_t)&sendto },
  { "setjmp", (uintptr_t)&setjmp },
  // { "setlocale", (uintptr_t)&setlocale },
  // { "setsockopt", (uintptr_t)&setsockopt },
  { "setvbuf", (uintptr_t)&setvbuf },
  { "sin", (uintptr_t)&sin },
  { "sinf", (uintptr_t)&sinf },
  { "sinh", (uintptr_t)&sinh },
  { "snprintf", (uintptr_t)&snprintf },
  // { "socket", (uintptr_t)&socket },
  { "sprintf", (uintptr_t)&sprintf },
  { "sqrt", (uintptr_t)&sqrt },
  { "sqrtf", (uintptr_t)&sqrtf },
  { "srand48", (uintptr_t)&srand48 },
  { "sscanf", (uintptr_t)&sscanf },
  { "stat", (uintptr_t)&stat_hook },
  { "strcasecmp", (uintptr_t)&strcasecmp },
  { "strcat", (uintptr_t)&strcat },
  { "strchr", (uintptr_t)&strchr },
  { "strcmp", (uintptr_t)&strcmp },
  { "strcoll", (uintptr_t)&strcoll },
  { "strcpy", (uintptr_t)&strcpy },
  { "strcspn", (uintptr_t)&strcspn },
  { "strerror", (uintptr_t)&strerror },
  { "strftime", (uintptr_t)&strftime },
  { "strlen", (uintptr_t)&strlen },
  { "strncasecmp", (uintptr_t)&strncasecmp },
  { "strncat", (uintptr_t)&strncat },
  { "strncmp", (uintptr_t)&strncmp },
  { "strncpy", (uintptr_t)&strncpy },
  { "strpbrk", (uintptr_t)&strpbrk },
  { "strrchr", (uintptr_t)&strrchr },
  { "strstr", (uintptr_t)&strstr },
  { "strtod", (uintptr_t)&strtod },
  { "strtol", (uintptr_t)&strtol },
  { "strtoul", (uintptr_t)&strtoul },
  { "strxfrm", (uintptr_t)&strxfrm },
  // { "syscall", (uintptr_t)&syscall },
  { "tan", (uintptr_t)&tan },
  { "tanf", (uintptr_t)&tanf },
  { "tanh", (uintptr_t)&tanh },
  { "time", (uintptr_t)&time },
  { "tolower", (uintptr_t)&tolower },
  { "toupper", (uintptr_t)&toupper },
  { "towlower", (uintptr_t)&towlower },
  { "towupper", (uintptr_t)&towupper },
  { "ungetc", (uintptr_t)&ungetc },
  { "ungetwc", (uintptr_t)&ungetwc },
  { "usleep", (uintptr_t)&usleep },
  { "vsnprintf", (uintptr_t)&vsnprintf },
  { "vsprintf", (uintptr_t)&vsprintf },
  { "vswprintf", (uintptr_t)&vswprintf },
  { "wcrtomb", (uintptr_t)&wcrtomb },
  { "wcscoll", (uintptr_t)&wcscoll },
  { "wcsftime", (uintptr_t)&wcsftime },
  { "wcslen", (uintptr_t)&wcslen },
  { "wcsxfrm", (uintptr_t)&wcsxfrm },
  { "wctob", (uintptr_t)&wctob },
  { "wctype", (uintptr_t)&wctype },
  { "wmemchr", (uintptr_t)&wmemchr },
  { "wmemcmp", (uintptr_t)&wmemcmp },
  { "wmemcpy", (uintptr_t)&wmemcpy },
  { "wmemmove", (uintptr_t)&wmemmove },
  { "wmemset", (uintptr_t)&wmemset },
  // { "write", (uintptr_t)&write },
  // { "writev", (uintptr_t)&writev },
};

int check_kubridge(void) {
  int search_unk[2];
  return _vshKernelSearchModuleByName("kubridge", search_unk);
}

int file_exists(const char *path) {
  SceIoStat stat;
  return sceIoGetstat(path, &stat) >= 0;
}

static char fake_vm[0x1000];
static char fake_env[0x1000];

enum MethodIDs {
  UNKNOWN = 0,
  INIT,
  IS_JOYSTICK_PRESENT,
  IS_TOUCH_PRESENT,
} MethodIDs;

typedef struct {
  char *name;
  enum MethodIDs id;
} NameToMethodID;

static NameToMethodID name_to_method_ids[] = {
  { "<init>", INIT },
  { "IsJoystickPresent", IS_JOYSTICK_PRESENT },
  { "IsTouchPresent", IS_TOUCH_PRESENT },
};

int GetMethodID(void *env, void *class, const char *name, const char *sig) {
  printf("%s\n", name);

  for (int i = 0; i < sizeof(name_to_method_ids) / sizeof(NameToMethodID); i++) {
    if (strcmp(name, name_to_method_ids[i].name) == 0) {
      return name_to_method_ids[i].id;
    }
  }

  return UNKNOWN;
}

int GetStaticMethodID(void *env, void *class, const char *name, const char *sig) {
  printf("%s\n", name);

  for (int i = 0; i < sizeof(name_to_method_ids) / sizeof(NameToMethodID); i++) {
    if (strcmp(name, name_to_method_ids[i].name) == 0)
      return name_to_method_ids[i].id;
  }

  return UNKNOWN;
}

void CallStaticVoidMethodV(void *env, void *obj, int methodID, uintptr_t *args) {
}

int CallStaticBooleanMethodV(void *env, void *obj, int methodID, uintptr_t *args) {
  switch (methodID) {
    case IS_JOYSTICK_PRESENT:
      return 1;
    case IS_TOUCH_PRESENT:
      return 1;
    default:
      return 0;
  }
  return 0;
}

void *FindClass(void) {
  return (void *)0x41414141;
}

void *NewGlobalRef(void) {
  return (void *)0x42424242;
}

void *NewObjectV(void *env, void *clazz, int methodID, uintptr_t args) {
  return (void *)0x43434343;
}

void *GetObjectClass(void *env, void *obj) {
  return (void *)0x44444444;
}

char *NewStringUTF(void *env, char *bytes) {
  return bytes;
}

char *GetStringUTFChars(void *env, char *string, int *isCopy) {
  return string;
}

int GetJavaVM(void *env, void **vm) {
  *vm = fake_vm;
  return 0;
}

int GetEnv(void *vm, void **env, int r2) {
  *env = fake_env;
  return 0;
}

enum {
  AKEYCODE_BUTTON_A = 96,
  AKEYCODE_BUTTON_B = 97,
  AKEYCODE_BUTTON_X = 99,
  AKEYCODE_BUTTON_Y = 100,
  AKEYCODE_BUTTON_L1 = 102,
  AKEYCODE_BUTTON_R1 = 103,
  AKEYCODE_BUTTON_L2 = 104,
  AKEYCODE_BUTTON_R2 = 105,
  AKEYCODE_BUTTON_THUMBL = 106,
  AKEYCODE_BUTTON_THUMBR = 107,
  AKEYCODE_BUTTON_START = 108,
};

typedef struct {
  uint32_t sce_button;
  uint32_t android_button;
} ButtonMapping;

static ButtonMapping mapping[] = {
  { SCE_CTRL_CROSS,     AKEYCODE_BUTTON_A },
  { SCE_CTRL_CIRCLE,    AKEYCODE_BUTTON_B },
  { SCE_CTRL_SQUARE,    AKEYCODE_BUTTON_X },
  { SCE_CTRL_TRIANGLE,  AKEYCODE_BUTTON_Y },
  { SCE_CTRL_L1,        AKEYCODE_BUTTON_L1 },
  { SCE_CTRL_R1,        AKEYCODE_BUTTON_R1 },
  { SCE_CTRL_L2,        AKEYCODE_BUTTON_L2 },
  { SCE_CTRL_R3,        AKEYCODE_BUTTON_R2 },
  { SCE_CTRL_L3,        AKEYCODE_BUTTON_THUMBL },
  { SCE_CTRL_R3,        AKEYCODE_BUTTON_THUMBR },
  { SCE_CTRL_START,     AKEYCODE_BUTTON_START },
};

static int rear_mapping[] = {
  AKEYCODE_BUTTON_THUMBR,
  AKEYCODE_BUTTON_R2,
  AKEYCODE_BUTTON_THUMBL,
  AKEYCODE_BUTTON_L2
};

int ctrl_thread(SceSize args, void *argp) {
  int (* Java_com_android_Game11Bits_GameLib_touchDown)(void *env, void *obj, int id, float x, float y) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_touchDown");
  int (* Java_com_android_Game11Bits_GameLib_touchUp)(void *env, void *obj, int id, float x, float y) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_touchUp");
  int (* Java_com_android_Game11Bits_GameLib_touchMove)(void *env, void *obj, int id, float x, float y) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_touchMove");

  int (* Java_com_android_Game11Bits_GameLib_enableJoystick)(void *env, void *obj, int enabled) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_enableJoystick");
  int (* Java_com_android_Game11Bits_GameLib_joystickEvent)(void *env, void *obj, float axisX, float axisY, float axisZ, float axisRZ, float axisHatX, float axisHatY, float axisLtrigger, float axisRtrigger) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_joystickEvent");
  int (* Java_com_android_Game11Bits_GameLib_keyEvent)(void *env, void *obj, int keycode, int down) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_keyEvent");

  Java_com_android_Game11Bits_GameLib_enableJoystick(fake_env, NULL, 1);

  float lastLx = 0.0f, lastLy = 0.0f, lastRx = 0.0f, lastRy = 0.0f;
  int lastUp = 0, lastDown = 0, lastLeft = 0, lastRight = 0;

  int lastX[2] = { -1, -1 };
  int lastY[2] = { -1, -1 };
  int backTouchState[4] = {0, 0, 0, 0};

  uint32_t old_buttons = 0, current_buttons = 0, pressed_buttons = 0, released_buttons = 0;

  while (1) {
    SceTouchData touch;
    sceTouchPeek(SCE_TOUCH_PORT_FRONT, &touch, 1);

    for (int i = 0; i < 2; i++) {
      if (i < touch.reportNum) {
        int x = (int)((float)touch.report[i].x * (float)SCREEN_W / 1920.0f);
        int y = (int)((float)touch.report[i].y * (float)SCREEN_H / 1088.0f);

        if (lastX[i] == -1 || lastY[i] == -1)
          Java_com_android_Game11Bits_GameLib_touchDown(fake_env, NULL, i, x, y);
        else if (lastX[i] != x || lastY[i] != y)
          Java_com_android_Game11Bits_GameLib_touchMove(fake_env, NULL, i, x, y);
        lastX[i] = x;
        lastY[i] = y;
      } else {
        if (lastX[i] != -1 || lastY[i] != -1)
          Java_com_android_Game11Bits_GameLib_touchUp(fake_env, NULL, i, lastX[i], lastY[i]);
        lastX[i] = -1;
        lastY[i] = -1;
      }
    }
    
    if (!pstv_mode) {
      int currTouch[4] = {0, 0, 0, 0};
      sceTouchPeek(SCE_TOUCH_PORT_BACK, &touch, 1);
      for (int i = 0; i < touch.reportNum; i++) {
        int x = touch.report[i].x;
        int y = touch.report[i].y;
        if (x > 960) {
          if (y > 544) {
            if (!backTouchState[0]) {
              Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, AKEYCODE_BUTTON_THUMBR, 1);
              backTouchState[0] = 1;
            }
            currTouch[0] = 1;
          } else {
            if (!backTouchState[1]) {
              Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, AKEYCODE_BUTTON_R2, 1);
              backTouchState[1] = 1;
            }
            currTouch[1] = 1;
          }
        } else {
          if (y > 544) {
            if (!backTouchState[2]) {
              Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, AKEYCODE_BUTTON_THUMBL, 1);
              backTouchState[2] = 1;
            }
            currTouch[2] = 1;
          } else {
            if (!backTouchState[3]) {
              Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, AKEYCODE_BUTTON_L2, 1);
              backTouchState[3] = 1;
            }
            currTouch[3] = 1;
          }
        }
      }
      for (int i = 0; i < 4; i++) {
        if (!currTouch[i] && backTouchState[i]) {
          backTouchState[i] = 0;
          Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, rear_mapping[i], 0);
        }
      }
    }

    SceCtrlData pad;
    sceCtrlPeekBufferPositiveExt2(0, &pad, 1);

    old_buttons = current_buttons;
    current_buttons = pad.buttons;
    pressed_buttons = current_buttons & ~old_buttons;
    released_buttons = ~current_buttons & old_buttons;

    for (int i = 0; i < sizeof(mapping) / sizeof(ButtonMapping); i++) {
      if (pressed_buttons & mapping[i].sce_button)
        Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, mapping[i].android_button, 1);
      if (released_buttons & mapping[i].sce_button)
        Java_com_android_Game11Bits_GameLib_keyEvent(fake_env, NULL, mapping[i].android_button, 0);
    }

    float currLx = pad.lx >= 128-32 && pad.lx <= 128+32 ? 0.0f : ((float)pad.lx - 128.0f) / 128.0f;
    float currLy = pad.ly >= 128-32 && pad.ly <= 128+32 ? 0.0f : ((float)pad.ly - 128.0f) / 128.0f;
    float currRx = pad.rx >= 128-32 && pad.rx <= 128+32 ? 0.0f : ((float)pad.rx - 128.0f) / 128.0f;
    float currRy = pad.ry >= 128-32 && pad.ry <= 128+32 ? 0.0f : ((float)pad.ry - 128.0f) / 128.0f;
    int currUp = (pad.buttons & SCE_CTRL_UP) ? 1 : 0;
    int currDown = (pad.buttons & SCE_CTRL_DOWN) ? 1 : 0;
    int currLeft = (pad.buttons & SCE_CTRL_LEFT) ? 1 : 0;
    int currRight = (pad.buttons & SCE_CTRL_RIGHT) ? 1 : 0;

    if (currLx != lastLx || currLy != lastLy || currRx != lastRx || currRy != lastRy ||
	    currUp != lastUp || currDown != lastDown || currLeft != lastLeft || currRight != lastRight) {
      lastLx = currLx;
      lastLy = currLy;
      lastRx = currRx;
      lastRy = currRy;
      lastUp = currUp;
      lastDown = currDown;
      lastLeft = currLeft;
      lastRight = currRight;
      float hat_y = currUp ? -1.0f : (currDown ? 1.0f : 0.0f);
      float hat_x = currLeft ? -1.0f : (currRight ? 1.0f : 0.0f);
      Java_com_android_Game11Bits_GameLib_joystickEvent(fake_env, NULL, currLx, currLy, currRx, currRy, hat_x, hat_y, 0.0f, 0.0f);
    }

    sceKernelDelayThread(1000);
  }

  return 0;
}

int main(int argc, char *argv[]) {
  sceCtrlSetSamplingModeExt(SCE_CTRL_MODE_ANALOG_WIDE);
  sceTouchSetSamplingState(SCE_TOUCH_PORT_FRONT, SCE_TOUCH_SAMPLING_STATE_START);
  sceTouchSetSamplingState(SCE_TOUCH_PORT_BACK, SCE_TOUCH_SAMPLING_STATE_START);

  scePowerSetArmClockFrequency(444);
  scePowerSetBusClockFrequency(222);
  scePowerSetGpuClockFrequency(222);
  scePowerSetGpuXbarClockFrequency(166);
  
  pstv_mode = sceKernelGetModel() == 0x20000 ? 1 : 0;

  if (check_kubridge() < 0)
    fatal_error("Error kubridge.skprx is not installed.");

  if (!file_exists("ur0:/data/libshacccg.suprx") && !file_exists("ur0:/data/external/libshacccg.suprx"))
    fatal_error("Error libshacccg.suprx is not installed.");

  // Check if we want to start TWoM: Stories
  int stories_mode = 0;
  sceAppUtilInit(&(SceAppUtilInitParam){}, &(SceAppUtilBootParam){});
  SceAppUtilAppEventParam eventParam;
  sceClibMemset(&eventParam, 0, sizeof(SceAppUtilAppEventParam));
  sceAppUtilReceiveAppEvent(&eventParam);
  if (eventParam.type == 0x05) {
    char buffer[2048];
    sceAppUtilAppEventParseLiveArea(&eventParam, buffer);
    if (strstr(buffer, "stories"))
      stories_mode = 1;
  }

  if (so_load(&twom_mod, stories_mode ? SO_DLC_PATH : SO_PATH, LOAD_ADDRESS) < 0)
    fatal_error("Error could not load %s.", stories_mode ? SO_DLC_PATH : SO_PATH);

  so_relocate(&twom_mod);
  so_resolve(&twom_mod, default_dynlib, sizeof(default_dynlib), 0);

  patch_game();
  so_flush_caches(&twom_mod);

  so_initialize(&twom_mod);

  vglSetupRuntimeShaderCompiler(SHARK_OPT_UNSAFE, SHARK_ENABLE, SHARK_ENABLE, SHARK_ENABLE);
  vglSetupGarbageCollector(127, 0x20000);
  vglInitExtended(0, SCREEN_W, SCREEN_H, MEMORY_VITAGL_THRESHOLD_MB * 1024 * 1024, SCE_GXM_MULTISAMPLE_4X);

  int (* Java_com_android_Game11Bits_GameLib_initOBBFile)(void *env, void *obj, const char *file, int filesize) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_initOBBFile");
  int (* Java_com_android_Game11Bits_GameLib_init)(void *env, void *obj, const char *ApkFilePath, const char *StorageFilePath, const char *CacheFilePath, int resX, int resY, int sdkVersion) = (void *)so_symbol(&twom_mod, "Java_com_android_Game11Bits_GameLib_init");

  memset(fake_vm, 'A', sizeof(fake_vm));
  *(uintptr_t *)(fake_vm + 0x00) = (uintptr_t)fake_vm; // just point to itself...
  *(uintptr_t *)(fake_vm + 0x10) = (uintptr_t)ret0;
  *(uintptr_t *)(fake_vm + 0x18) = (uintptr_t)GetEnv;

  memset(fake_env, 'A', sizeof(fake_env));
  *(uintptr_t *)(fake_env + 0x00) = (uintptr_t)fake_env; // just point to itself...
  *(uintptr_t *)(fake_env + 0x18) = (uintptr_t)FindClass;
  *(uintptr_t *)(fake_env + 0x54) = (uintptr_t)NewGlobalRef;
  *(uintptr_t *)(fake_env + 0x5C) = (uintptr_t)ret0; // DeleteLocalRef
  *(uintptr_t *)(fake_env + 0x74) = (uintptr_t)NewObjectV;
  *(uintptr_t *)(fake_env + 0x7C) = (uintptr_t)GetObjectClass;
  *(uintptr_t *)(fake_env + 0x84) = (uintptr_t)GetMethodID;
  *(uintptr_t *)(fake_env + 0x1C4) = (uintptr_t)GetStaticMethodID;
  *(uintptr_t *)(fake_env + 0x238) = (uintptr_t)CallStaticVoidMethodV;
  *(uintptr_t *)(fake_env + 0x1D8) = (uintptr_t)CallStaticBooleanMethodV;
  *(uintptr_t *)(fake_env + 0x29C) = (uintptr_t)NewStringUTF;
  *(uintptr_t *)(fake_env + 0x2A4) = (uintptr_t)GetStringUTFChars;
  *(uintptr_t *)(fake_env + 0x2A8) = (uintptr_t)ret0; // ReleaseStringUTFChars
  *(uintptr_t *)(fake_env + 0x36C) = (uintptr_t)GetJavaVM;

  struct stat st;
  stat(DATA_PATH "/main.obb", &st);
  Java_com_android_Game11Bits_GameLib_initOBBFile(fake_env, NULL, DATA_PATH "/main.obb", st.st_size);
  Java_com_android_Game11Bits_GameLib_init(fake_env, (void *)0x41414141, "apk", DATA_PATH, NULL, SCREEN_W, SCREEN_H, 0);

  SceUID ctrl_thid = sceKernelCreateThread("ctrl_thread", (SceKernelThreadEntry)ctrl_thread, 0x10000100, 128 * 1024, 0, 0, NULL);
  sceKernelStartThread(ctrl_thid, 0, NULL);

  return sceKernelExitDeleteThread(0);
}
