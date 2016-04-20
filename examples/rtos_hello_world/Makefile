CC = xtensa-esp108-elf-gcc
CXX = xtensa-esp108-elf-g++
AR = xtensa-esp108-elf-ar
OBJCOPY = xtensa-esp108-elf-objcopy
SYSROOT = $(shell $(CC) --print-sysroot)
SYSROOT_HEADERS = $(SYSROOT)/usr/include
CFLAGS = -I. -Iuser -Istltest \
            -I$(SYSROOT_HEADERS)/lwip         \
            -I$(SYSROOT_HEADERS)/lwip/ipv4    \
            -I$(SYSROOT_HEADERS)/lwip/ipv6    \
            -I$(SYSROOT_HEADERS)/espressif    \
            -ffunction-sections -fdata-sections -nostdlib -mlongcalls -mtext-section-literals
CXXFLAGS = $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11
LD       := $(CXX)
LDLIBS = -nostdlib -Wl,--start-group -lmain -lfreertos -lnet80211 -lwpa -llwip -lpp -lphy -lcrypto -lhal -lrtc -lstdc++port -lstdc++ -lc -lnewlibport -lm  -Wl,--end-group -lgcc
LDSCRIPT = pro.map1.1.ld
LDROMSCRIPT = pro.rom.addr.ld
LDDIR = $(SYSROOT)/usr/lib
LDFLAGS = -T$(LDSCRIPT) -T$(LDROMSCRIPT) -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static -Wl,-gc-sections

%1/%.o: %.c
	$(CC) $(CFLAGS) -std=gnu90 -c $$< -o $$@

%1/%.o: %.cpp
	$(CXX) $(CXXFLAGS)  -c $$< -o $$@

src = user_main.c 

obj := $(src:.c=.o)
obj := $(obj:.cpp=.o)

rtos_hello_world-bins: rtos_hello_world
	@echo "Run objcopy, please wait..."
	@$(OBJCOPY) --only-section .text -O binary $< eagle.app.v7.text.bin
	@$(OBJCOPY) --only-section .data -O binary $< eagle.app.v7.data.bin
	@$(OBJCOPY) --only-section .rodata -O binary $< eagle.app.v7.rodata.bin
	@$(OBJCOPY) --only-section .irom0.text -O binary $< eagle.app.v7.irom0text.bin
	@$(OBJCOPY) --only-section .drom0.text -O binary $< eagle.app.v7.drom0text.bin
	@rm -f irom0_flash.bin drom1.bin user.ota
	@echo "objcopy done"
	@echo "launching gen_appbin"
	@gen_appbin.py $< $(LDDIR)/$(LDSCRIPT) 0 0 . .
	@echo "Done"

rtos_hello_world: rtos_hello_world.a
	$(CC) $(LDFLAGS) -Wl,-Map=$@.map -Wl,--start-group $(LDLIBS) $^ -Wl,--end-group -o $@

rtos_hello_world.a: $(obj)
	$(AR) cru $@ $^

flash: rtos_hello_world-bins
	esptool.py write_flash --flash_freq 40m --flash_mode qio --flash_size 2MB 0x04000 drom0.bin 0x40000 irom0_flash.bin	

clean:
	rm -f rtos_hello_world.map rtos_hello_world.a rtos_hello_world $(obj) *.bin user.ota

