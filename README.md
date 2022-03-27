# TWoM Vita

<p align="center"><img src="./screenshots/game.png"></p>

This is a wrapper/port of *This War of Mine* and *This War Of Mine: Stories - Father's Promise* for the *PS Vita*.

The port works by loading the official Android ARMv7 executables in memory, resolving their imports with native functions and patching them in order to properly run.

## Notes

This port, as specified before also, can be used to run *This War Of Mine: Stories - Father's Promise* as well. Check the *Setup Instructions* paragraph to understand how to set it up.
There also is support for all DLCs of base game (*Season Pass* and *The Little Ones*). You can find more information regarding this contents in the *DLCs Support* paragraph.

## Changelog

### v1.0

- Initial release.

## Setup Instructions (For End Users)

In order to properly install the game, you'll have to follow these steps precisely:

- Install [kubridge](https://github.com/TheOfficialFloW/kubridge/releases/) and [FdFix](https://github.com/TheOfficialFloW/FdFix/releases/) by copying `kubridge.skprx` and `fd_fix.skprx` to your taiHEN plugins folder (usually `ux0:tai`) and adding two entries to your `config.txt` under `*KERNEL`:
  
```
  *KERNEL
  ux0:tai/kubridge.skprx
  ux0:tai/fd_fix.skprx
```

**Note** Don't install fd_fix.skprx if you're using rePatch plugin

- **Optional**: Install [PSVshell](https://github.com/Electry/PSVshell/releases) to overclock your device to 500Mhz.
- Install `libshacccg.suprx`, if you don't have it already, by following [this guide](https://samilops2.gitbook.io/vita-troubleshooting-guide/shader-compiler/extract-libshacccg.suprx).
- Obtain your copy of *This War of Mine* legally for Android in form of an `.apk` file and one or more `.obb` files (usually `com.elevenbitstudios.twommobile.obb` located inside the `/sdcard/android/obb/com.elevenbitstudios.twommobile/`) folder. [You can get all the required files directly from your phone](https://stackoverflow.com/questions/11012976/how-do-i-get-the-apk-of-an-installed-app-without-root-access) or by using an apk extractor you can find in the play store. The apk can be extracted with whatever Zip extractor you prefer (eg: WinZip, WinRar, etc...) since apk is basically a zip file. You can rename `.apk` to `.zip` to open them with your default zip extractor.
- Open the apk with your zip explorer and extract the file `libAndroidGame.so` from the `lib/armeabi-v7a` folder to `ux0:data/twom`. 
- Rename `com.elevenbitstudios.twommobile.obb` to `main.obb` and place it inside `ux0:data/twom`.
- **Optional**: The vpk supports *This War of Mine: Stories - Father's Promise* as well. In order to install and play it, open its relative apk and place the file `libAndroidGame.so` from the `lib/armeabi-v7a` folder inside `ux0:data/twom` renamed as `libAndroidGameStories.so`. 

## DLCs Support

DLCs for *This War of Mine* can be enabled by editing a config file named *settings.cfg* located inside *ux0:app/TWOM00000*.
We strongly encourage to enable support for these contents solely if you possess these contents on your Android device.
Sadly, we have no way to propose a license check on Vita against your purchased in-game contents on Android, so show respect and support *11 bit studios* first before proceeding.
Open the file *ux0:app/TWOM00000/settings.cfg* and change *enable_dlcs=0* to *enable_dlcs=1*.

## Build Instructions (For Developers)

In order to build the loader, you'll need a [vitasdk](https://github.com/vitasdk) build fully compiled with softfp usage.  
You can find a precompiled version here: https://github.com/vitasdk/buildscripts/actions/runs/1102643776.  
Additionally, you'll need these libraries to be compiled as well with `-mfloat-abi=softfp` added to their CFLAGS:

- [mpg123](http://www.mpg123.de/download/mpg123-1.25.10.tar.bz2)

  - Apply [mpg123.patch](https://github.com/vitasdk/packages/blob/master/mpg123/mpg123.patch) using `patch -Np0 -i mpg123.patch`.

  - ```bash
    autoreconf -fi
    CFLAGS="-DPSP2 -mfloat-abi=softfp" ./configure --host=arm-vita-eabi --prefix=$VITASDK/arm-vita-eabi --disable-shared --enable-static --enable-fifo=no --enable-ipv6=no --enable-network=no --enable-int-quality=no --with-cpu=neon --with-default-audio=dummy --with-optimization=3
    make install
    ```

- [openal-soft](https://github.com/isage/openal-soft/tree/vita-1.19.1)

  - ```bash
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE=${VITASDK}/share/vita.toolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-mfloat-abi=softfp .. && make install
    ```

- [libmathneon](https://github.com/Rinnegatamante/math-neon)

  - ```bash
    make install
    ```

- [vitaShaRK](https://github.com/Rinnegatamante/vitaShaRK)

  - ```bash
    make install
    ```

- [kubridge](https://github.com/TheOfficialFloW/kubridge)

  - ```bash
    mkdir build && cd build
    cmake .. && make install
    ```

- [vitaGL](https://github.com/Rinnegatamante/vitaGL)

  - ````bash
    make SOFTFP_ABI=1 SAMPLERS_SPEEDHACK=1 SAMPLER_UNIFORMS=1 NO_DEBUG=1 install
    ````

After all these requirements are met, you can compile the loader with the following commands:

```bash
mkdir build && cd build
cmake .. && make
```

## Credits

- Rinnegatamante for porting the renderer using vitaGL and making various improvements to the port.
- gl33ntwine for the Livearea assets.
