esp-open-sdk
------------

This repository provides the integration scripts to build a complete
standalone SDK (with toolchain) for software development with the
Espressif ESP31b and ESP32 chips.

The complete SDK consists of:

1. esp108 architecture toolchain (100% OpenSource), based on https://github.com/jcmvbkbc/crosstool-NG

2. ESP32 RTOS  SDK from Espressif Systems. This component is only
   partially open source, (some libraries are provided as binary blobs).
    * https://github.com/espressif/ESP32_RTOS_SDK

Requirements and Dependencies
=============================

To build the standalone SDK and toolchain, you need a GNU/POSIX system
(Linux, BSD, MacOSX, Windows with Cygwin) with the standard GNU development
tools installed: bash, gcc, binutils, flex, bison, etc.

Please make sure that the machine you use to build the toolchain has at least
1G free RAM+swap (or more, which will speed up the build).

## Debian/Ubuntu

Ubuntu 14.04:
```
$ sudo apt-get install make unrar autoconf automake libtool gcc g++ gperf \
    flex bison texinfo gawk ncurses-dev libexpat-dev python python-serial sed \
    git unzip bash help2man
```

Later Debian/Ubuntu versions may require:
```
$ sudo apt-get install libtool-bin
```

## MacOS:
```bash
$ brew tap homebrew/dupes
$ brew install binutils coreutils automake wget gawk libtool gperf gnu-sed --with-default-names grep
$ export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

In addition to the development tools MacOS needs a case-sensitive filesystem.
You might need to create a virtual disk and build esp-open-sdk on it:
```bash
$ sudo hdiutil create ~/Documents/case-sensitive.dmg -volname "case-sensitive" -size 10g -fs "Case-sensitive HFS+"
$ sudo hdiutil mount ~/Documents/case-sensitive.dmg
$ cd /Volumes/case-sensitive
```

Building
========

Be sure to clone recursively:

```
$ git clone -b esp32 --recursive https://github.com/sermus/esp-open-sdk.git
```

The project can be built in two modes:

1. Where the toolchain and tools are kept separate from the vendor IoT SDK
   which contains binary blobs. This makes licensing more clear, and helps
   facilitate upgrades to vendor SDK releases.

2. A completely standalone ESP31b/32 SDK with the vendor SDK files merged
   into the toolchain. This mode makes it easier to build software (no
   additinal `-I` and `-L` flags are needed), but redistributability of
   this build is unclear and upgrades to newer vendor SDK releases are
   complicated. This mode is default for local builds. Note that if you
   want to redistribute the binary toolchain built with this mode, you
   should:

    1. Make it clear to your users that the release is bound to a
       particular vendor SDK and provide instructions how to upgrade
       to a newer vendor SDK releases.
    2. Abide by licensing terms of the vendor SDK.

To build the self-contained, standalone toolchain+SDK:

```
$ make STANDALONE=y
```

This is the default choice which most people are looking for, so just the
following is enough:

```
$ make
```

To build the bare Xtensa toolchain and leave ESP8266 SDK separate:

```
$ make STANDALONE=n
```

This will download all necessary components and compile them.

Using the toolchain
===================

Once you complete build process as described above, the toolchain (with
the Xtensa HAL library) will be available in the `xtensa-esp108-elf/`
subdirectory. Add `xtensa-esp108-elf/bin/` subdirectory to your `PATH`
environment variable to execute `xtensa-esp108-elf-gcc` and other tools.
At the end of build process, the exact command to set PATH correctly
for your case will be output. You may want to save it, as you'll need
the PATH set correctly each time you compile for Xtensa/ESP.

ESP32 RTOS SDK will be installed in `sdk/`. If you chose the non-standalone
SDK, run the compiler with the corresponding include and lib dir flags:

```
$ xtensa-esp108-elf-gcc -I$(THISDIR)/sdk/include      \
                        -I$(THISDIR)/sdk/lwip         \
                        -I$(THISDIR)/sdk/lwip/ipv4    \
                        -I$(THISDIR)/sdk/lwip/ipv6    \
                        -I$(THISDIR)/sdk/espressif    \
                        -L$(THISDIR)/sdk/lib 
```

If you use SDK in the standlone mode you need to build with these additional -I options (you may refer to the example Makefile in examples/rtos_hello_world and examples/esp_sgi_stl_tests)

```
$ xtensa-esp108-elf-gcc -I$(SYSROOT_HEADERS)/lwip         \
                        -I$(SYSROOT_HEADERS)/lwip/ipv4    \
                        -I$(SYSROOT_HEADERS)/lwip/ipv6    \
                        -I$(SYSROOT_HEADERS)/espressif    \
```
where SYSROOT_HEADERS may be obtained this way:
```
SYSROOT = $(shell $(CC) --print-sysroot)
SYSROOT_HEADERS = $(SYSROOT)/usr/include
```

Pulling updates
===============
The project is updated from time to time, to get updates and prepare to
build a new SDK, run:

```
$ make clean
$ git pull
$ git submodule sync
$ git submodule update
```

If you don't issue `make clean` (which causes toolchain and SDK to be
rebuilt from scratch on next `make`), you risk getting broken/inconsistent
results.

Additional configuration
========================

You can build a statically linked toolchain by uncommenting
`CT_STATIC_TOOLCHAIN=y` in the file `crosstool-config-overrides`. More
fine-tunable options may be available in that file and/or Makefile.

License
=======

esp-open-sdk is in its nature merely a makefile, and is in public domain.
However, the toolchain this makefile builds consists of many components,
each having its own license. You should study and abide them all.

Quick summary: gcc is under GPL, which means that if you're distributing
a toolchain binary you must be ready to provide complete toolchain sources
on the first request.

Vendor SDK comes under modified MIT license. Newlib,
used as C library comes with variety of BSD-like licenses. libgcc, compiler
support library, comes with a linking exception. All the above means that
for applications compiled with this toolchain, there are no specific
requirements regarding source availability of the application or toolchain.
(In other words, you can use it to build closed-source applications).
(There're however standard attribution requirements - see licences for
details).
