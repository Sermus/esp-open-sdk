
# Whether to merge SDK into Xtensa toolchain, producing standalone
# ESP32 toolchain. Use 'n' if you want generic Xtensa toolchain
# which can be used with multiple SDK versions.
STANDALONE = y

# Directory to install toolchain to, by default inside current dir.
TOOLCHAIN = $(TOP)/xtensa-esp108-elf


# Vendor SDK version to install, see VENDOR_SDK_ZIP_* vars below
# for supported versions.
VENDOR_SDK = 2.0.0

.PHONY: crosstool-NG toolchain romizedlibs libnewlibport libstdc++port sdk



TOP = $(PWD)
SHELL = /bin/bash
PATCH = patch -b -N
UNZIP = unzip -q -o
VENDOR_SDK_ZIP = $(VENDOR_SDK_ZIP_$(VENDOR_SDK))
VENDOR_SDK_DIR = $(VENDOR_SDK_DIR_$(VENDOR_SDK))

VENDOR_SDK_ZIP_2.0.0 = ESP32_RTOS_SDK-2.0.0.zip
VENDOR_SDK_DIR_2.0.0 = ESP32_RTOS_SDK-2.0.0

all: standalone sdk sdk_patch libnewlibport libstdc++port $(TOOLCHAIN)/bin/xtensa-esp108-elf-gcc
	@echo
	@echo "Xtensa toolchain is built, to use it:"
	@echo
	@echo 'export PATH=$(TOOLCHAIN)/bin:$$PATH'
	@echo
ifneq ($(STANDALONE),y)
	@echo "Espressif ESP32 SDK is installed. Toolchain contains only Open Source components"
	@echo "To link external proprietary libraries add:"
	@echo
	@echo "xtensa-esp108-elf-gcc -I$(TOP)/sdk/include -L$(TOP)/sdk/lib"
	@echo
else
	@echo "Espressif esp32 SDK is installed, its libraries and headers are merged with the toolchain"
	@echo
endif

standalone: sdk sdk_patch toolchain
ifeq ($(STANDALONE),y)
	@echo "Installing vendor SDK headers into toolchain sysroot"
	@cp -Rf sdk/include/* $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/include/
	@cp -aRf sdk/third_party/include/* $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/include/
	@cp -aRf sdk/extra_include/* $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/include/
	@echo "Installing vendor SDK libs into toolchain sysroot"
	@cp -Rf sdk/lib/* $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/
	@echo "Installing vendor SDK linker scripts into toolchain sysroot"
	@cp sdk/ld/* $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/
	@echo "Installing port lib headers into toolchain sysroot"
	@cp -Rf esp_stdcpp_port/cpp_routines.h $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/include/cpp_routines.h
	@echo "Removing crosstool-NG's libc as sdk provides its own one"
	rm -f $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/lib/libc.a
	@echo "Installing SDK tools into toolchain"
	@cp sdk/tools/esptool.py $(TOOLCHAIN)/bin/
	@chmod u+x $(TOOLCHAIN)/bin/esptool.py
	@cp sdk/tools/gen_appbin.py $(TOOLCHAIN)/bin/
	@chmod u+x $(TOOLCHAIN)/bin/gen_appbin.py

endif

clean: clean-sdk
	make -C crosstool-NG clean MAKELEVEL=0
	make -C esp_stdcpp_port clean MAKELEVEL=0
	-rm -rf crosstool-NG/.build/src
	-rm -rf $(TOOLCHAIN)

toolchain: $(TOOLCHAIN)/bin/xtensa-esp108-elf-gcc

$(TOOLCHAIN)/bin/xtensa-esp108-elf-gcc: crosstool-NG/ct-ng
	make -C crosstool-NG -f ../Makefile _toolchain

_toolchain:
	./ct-ng xtensa-esp108-elf
	sed -r -i.org s%CT_PREFIX_DIR=.*%CT_PREFIX_DIR="$(TOOLCHAIN)"% .config
	sed -r -i s%CT_INSTALL_DIR_RO=y%"#"CT_INSTALL_DIR_RO=y% .config
	cat ../crosstool-config-overrides >> .config
	./ct-ng build

clean-sysroot:
	rm -rf $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/*
	rm -rf $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/include/*

crosstool-NG: crosstool-NG/ct-ng

crosstool-NG/ct-ng: crosstool-NG/bootstrap
	make -C crosstool-NG -f ../Makefile _ct-ng

_ct-ng:
	./bootstrap
	./configure --prefix=`pwd`
	make MAKELEVEL=0
	make install MAKELEVEL=0

crosstool-NG/bootstrap:
	@echo "You cloned without --recursive, fetching submodules for you."
	git submodule update --init --recursive

libnewlibport: $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libnewlibport.a

$(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libnewlibport.a: $(TOOLCHAIN)/bin/xtensa-esp108-elf-gcc sdk sdk_patch toolchain standalone
	make -C esp_newlib_port -f ../Makefile _libnewlibport
	cp -f esp_newlib_port/libnewlibport.a $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libnewlibport.a

_libnewlibport:
	PATH=$(TOOLCHAIN)/bin:$(PATH) make

libstdc++port: $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libstdc++port.a

$(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libstdc++port.a: $(TOOLCHAIN)/bin/xtensa-esp108-elf-gcc sdk sdk_patch toolchain standalone
	make -C esp_stdcpp_port -f ../Makefile _libstdc++port
	cp -f esp_stdcpp_port/libstdc++port.a $(TOOLCHAIN)/xtensa-esp108-elf/sysroot/usr/lib/libstdc++port.a

_libstdc++port:
	PATH=$(TOOLCHAIN)/bin:$(PATH) make

sdk: $(VENDOR_SDK_DIR)/.dir
	ln -snf $(VENDOR_SDK_DIR) sdk

$(VENDOR_SDK_DIR)/.dir: $(VENDOR_SDK_ZIP)
	$(UNZIP) $^
	-mv LICENSE $(VENDOR_SDK_DIR)
	touch $@

sdk_patch: $(VENDOR_SDK_DIR)/.dir .sdk_patch_$(VENDOR_SDK)

.sdk_patch_2.0.0:
	@touch $@

clean-sdk:
	rm -rf $(VENDOR_SDK_DIR)
	rm -f sdk
	rm -f .sdk_patch_$(VENDOR_SDK)
	make -C esp-open-lwip -f Makefile.open clean

ESP32_RTOS_SDK-2.0.0.zip:
	wget --content-disposition "https://github.com/espressif/ESP32_RTOS_SDK/archive/v2.0.0.zip"
