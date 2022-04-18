# This file is part of lapp.
#
# lapp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# lapp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lapp.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about lapp you can visit
# http://cdelord.fr/lapp

LUA_VERSION = 5.4.4
LUA_URL = http://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz

INSTALL_PATH = $(firstword $(wildcard $(PREFIX) $(HOME)/.local/bin $(HOME)/bin))

BUILD = .build
CACHE = .cache

LUA_ARCHIVE = $(CACHE)/lua-$(LUA_VERSION).tar.gz

LZ4_SRC = external/lz4/lib/lz4.c external/lz4/lib/lz4hc.c
LZ4_INC = external/lz4/lib

# Basic standard functions
STDLIBS_INC += lib/std
STDLIBS_SOURCES += $(wildcard lib/std/*.c)
STDLIBS_LUA += $(wildcard lib/std/*.lua)

# fs lib
STDLIBS_INC += lib/fs
STDLIBS_SOURCES += $(wildcard lib/fs/*.c)
STDLIBS_LUA += $(wildcard lib/fs/*.lua)

# ps lib
STDLIBS_INC += lib/ps
STDLIBS_SOURCES += $(wildcard lib/ps/*.c)
STDLIBS_LUA += $(wildcard lib/ps/*.lua)

# sys lib
STDLIBS_INC += lib/sys
STDLIBS_SOURCES += $(wildcard lib/sys/*.c)
STDLIBS_LUA += $(wildcard lib/sys/*.lua)

# lz4 lib
STDLIBS_INC += lib/lz4lib
STDLIBS_SOURCES += $(wildcard lib/lz4lib/*.c)
STDLIBS_LUA += $(wildcard lib/lz4lib/*.lua)

# crypt lib
STDLIBS_INC += lib/crypt
STDLIBS_SOURCES += $(wildcard lib/crypt/*.c)
STDLIBS_LUA += $(wildcard lib/crypt/*.lua)

# lpeg
LPEG_VERSION=1.0.2
LPEG_URL = http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-$(LPEG_VERSION).tar.gz
LPEG_SOURCES = $(addprefix $(BUILD)/lpeg-$(LPEG_VERSION)/,lpcap.c lpcode.c lpprint.c lptree.c lpvm.c)
LPEG_SCRIPTS = $(addprefix $(BUILD)/lpeg-$(LPEG_VERSION)/,re.lua)
STDLIBS_INC += lib/lpeg -I$(BUILD)/lpeg-$(LPEG_VERSION)
STDLIBS_SOURCES += $(wildcard lib/lpeg/*.c) $(LPEG_SOURCES)
STDLIBS_LUA += $(LPEG_SCRIPTS)

# luasocket
STDLIBS_INC += lib/luasocket
STDLIBS_SOURCES += $(wildcard lib/luasocket/*.c) $(wildcard external/luasocket/src/*.c)
STDLIBS_LUA += $(wildcard lib/luasocket/*.lua)
STDLIBS_LUA += $(wildcard external/luasocket/src/*.lua)

# Readline module
STDLIBS_INC += lib/rl
STDLIBS_SOURCES += lib/rl/rl.c

STDLIBS_CHUNKS = $(patsubst %.lua,$(BUILD)/%_chunk.c,$(STDLIBS_LUA))

CC_OPT = -O3 -flto -s
CC_OPT += -std=gnu99
CC_OPT += -ffunction-sections -fdata-sections -Wl,-gc-sections
CC_OPT += -Wall -Wextra -pedantic -Werror
CC_OPT += -Wstrict-prototypes
CC_OPT += -Wmissing-field-initializers
CC_OPT += -Wmissing-prototypes
CC_OPT += -Wmissing-declarations
CC_OPT += -Werror=switch-enum
CC_OPT += -Werror=implicit-fallthrough
CC_OPT += -Werror=missing-prototypes

MINGW_OPT = $(CC_OPT)
MINGW_OPT += -Wno-error=attributes

$(BUILD)/linux/.build/lpeg-$(LPEG_VERSION)/lpcode.o: CC_OPT += -Wno-error=switch-enum -Wno-error=implicit-fallthrough
$(BUILD)/win/.build/lpeg-$(LPEG_VERSION)/lpcode.o: MINGW_OPT += -Wno-error=switch-enum -Wno-error=implicit-fallthrough
$(BUILD)/linux/.build/lpeg-$(LPEG_VERSION)/lpvm.o: CC_OPT += -Wno-error=switch-enum -Wno-error=implicit-fallthrough
$(BUILD)/win/.build/lpeg-$(LPEG_VERSION)/lpvm.o: MINGW_OPT += -Wno-error=switch-enum -Wno-error=implicit-fallthrough
$(BUILD)/linux/external/luasocket/src/serial.o: CC_OPT += -Wno-error=missing-prototypes
$(BUILD)/linux/external/luasocket/src/unixdgram.o: CC_OPT += -Wno-error=missing-prototypes
$(BUILD)/linux/lrun: CC_OPT += -Wno-error=maybe-uninitialized
$(BUILD)/win/external/luasocket/src/serial.o: MINGW_OPT += -Wno-error=missing-prototypes
$(BUILD)/win/external/luasocket/src/options.o: MINGW_OPT += -Wno-error=implicit-function-declaration
$(BUILD)/win/lrun.exe: MINGW_OPT += -Wno-attributes

LUA_CC_OPT = -O3 -ffunction-sections -fdata-sections
LUA_LD_OPT = -flto -s -Wl,-gc-sections

CC = gcc
LUA = $(BUILD)/linux/lua-$(LUA_VERSION)/src/lua
LUAC = $(BUILD)/linux/lua-$(LUA_VERSION)/src/luac
LIBLUA = $(BUILD)/linux/lua-$(LUA_VERSION)/src/liblua.a
LRUN = $(BUILD)/linux/lrun
LAPP = $(BUILD)/linux/lapp
LUAX = $(BUILD)/linux/luax
CC_INC = -I. -I$(BUILD)
CC_INC += -I$(BUILD)/linux/lua-$(LUA_VERSION)/src
CC_INC += -I$(BUILD)/linux
CC_INC += -I$(LZ4_INC)
CC_INC += $(patsubst %,-I%,$(STDLIBS_INC))
CC_LIB = -lm -ldl -lreadline -lrt

MINGW_CC = x86_64-w64-mingw32-gcc
LIBLUAW = $(BUILD)/win/lua-$(LUA_VERSION)/src/liblua.a
LRUNW = $(BUILD)/win/lrun.exe
LAPPW = $(BUILD)/win/lapp.exe
LUAXW = $(BUILD)/win/luax.exe
LIBSSP_DLL = $(BUILD)/win/libssp-0.dll
TEST_LIBSSP_DLL = $(BUILD)/test/libssp-0.dll
MINGW_CC_INC = -I. -I$(BUILD)
MINGW_CC_INC += -I$(BUILD)/win/lua-$(LUA_VERSION)/src
MINGW_CC_INC += -I$(BUILD)/win
MINGW_CC_INC += -I$(LZ4_INC)
MINGW_CC_INC += $(patsubst %,-I%,$(STDLIBS_INC))
MINGW_CC_LIB = -lm -lws2_32 -ladvapi32 -lssp

KERNEL  := $(shell uname -s)
MACHINE := $(shell uname -m)

CC_OPT += -DKERNEL=$(KERNEL) -DMACHINE=$(MACHINE)

LAPP_TAR = $(BUILD)/linux/lapp-$(shell echo $(KERNEL) | tr A-Z a-z)-$(MACHINE).tar.gz
LAPP_ZIP = $(BUILD)/win/lapp-win-$(MACHINE).zip

ifeq ($(shell which $(MINGW_CC) 2>/dev/null),)
HAS_MINGW = 0
else
HAS_MINGW = 1
endif

CC_OPT += -DHAS_MINGW=$(HAS_MINGW)

ifeq ($(shell which wine 2>/dev/null),)
HAS_WINE = 0
else
HAS_WINE = 1
endif

.PHONY: all test diff linux windows install install_linux install_windows

.SECONDARY:

all: compile_flags.txt
all: linux
ifeq ($(HAS_MINGW),1)
all: windows
endif
all: test

red = /bin/echo -e "\x1b[31m[$1]\x1b[0m $2"
green = /bin/echo -e "\x1b[32m[$1]\x1b[0m $2"
blue = /bin/echo -e "\x1b[34m[$1]\x1b[0m $2"
cyan = /bin/echo -e "\x1b[36m[$1]\x1b[0m $2"

ifneq ($(shell which apt 2>/dev/null),)
dep:
	apt install make gcc libreadline-dev
else
ifneq ($(shell which dnf 2>/dev/null),)
dep:
	dnf install make gcc readline-devel
else
dep:
	echo "apt or dnf not found. Please install 'make', 'gcc' and 'libreadline-dev' (or equivalent on your OS)."
endif
endif

submodules:
	git submodule sync && git submodule update --init --recursive

linux: $(LAPP) $(LUAX) $(LAPP_TAR)

ifeq ($(HAS_MINGW),1)
windows: $(LAPPW) $(LUAXW) $(LIBSSP_DLL) $(LAPP_ZIP)
endif

clean:
	rm -rf $(BUILD)

distclean: clean
	rm -rf $(CACHE)

# install on Linux only
install: $(LAPP) $(LUAX)
	@test -n "$(INSTALL_PATH)" || (echo "No installation path found" && false)
	install -T $(LAPP) $(INSTALL_PATH)/$(notdir $(LAPP))
	install -T $(LUAX) $(INSTALL_PATH)/$(notdir $(LUAX))

test: $(BUILD)/test/ok.bytecode.lc
test: $(BUILD)/test/ok.host_linux_target_linux

ifeq ($(HAS_MINGW)$(HAS_WINE),11)
test: $(BUILD)/test/ok.host_linux_target_win.exe
test: $(BUILD)/test/ok.host_win_target_linux
test: $(BUILD)/test/ok.host_win_target_win.exe
test: $(BUILD)/test/same.linux_native_and_cross
test: $(BUILD)/test/same.win.exe_native_and_cross
endif

TEST_SOURCES = test/main.lua $(filter-out test/main.lua,$(wildcard test/*.lua))

$(BUILD)/test/ok.%: test/expected_result.txt $(BUILD)/test/res.%
	@$(call cyan,"DIFF",$^)
	@diff $^
	@touch $@

# Test executables

$(BUILD)/test/bin.bytecode.lc: $(LAPP) $(TEST_SOURCES)
	@$(call cyan,"LAPP",$@)
	@mkdir -p $(dir $@)
	$(LAPP) $(TEST_SOURCES) -o $@

$(BUILD)/test/bin.host_linux_target_%: $(LAPP) $(TEST_SOURCES)
	@$(call cyan,"LAPP",$@)
	@mkdir -p $(dir $@)
	$(LAPP) $(TEST_SOURCES) -o $@

$(BUILD)/test/bin.host_win_target_%: $(LAPPW) $(TEST_SOURCES) $(TEST_LIBSSP_DLL)
	@$(call cyan,"LAPP",$@)
	@mkdir -p $(dir $@)
	@wine $(LAPPW) $(TEST_SOURCES) -o $@
	@chmod +x $@

# Test results

diff: $(BUILD)/test/res.host_linux_target_linux test/expected_result.txt
	@meld $^

$(BUILD)/test/res.bytecode.lc: $(LRUN) $(BUILD)/test/bin.bytecode.lc
	@$(call cyan,"TEST",$@)
	$^ Lua is great; echo $$? > $@

$(BUILD)/test/res.host_%_target_linux: $(BUILD)/test/bin.host_%_target_linux
	@$(call cyan,"TEST",$@)
	@$< Lua is great; echo $$? > $@

$(BUILD)/test/res.host_%_target_win.exe: $(BUILD)/test/bin.host_%_target_win.exe $(TEST_LIBSSP_DLL)
	@$(call cyan,"TEST",$@)
	@wine $< Lua is great; echo $$? > $@

# Native and cross compilations shall produce the same executable

$(BUILD)/test/same.%_native_and_cross: $(BUILD)/test/bin.host_linux_target_% $(BUILD)/test/bin.host_win_target_%
	@$(call cyan,"DIFF",$^)
	@diff $^
	@touch $@

# clangd configuration file

compile_flags.txt: Makefile
	@(  echo "-Weverything";               \
	    echo "$(CC_OPT)" | tr " " "\n";    \
	    echo "$(CC_INC)" | tr " " "\n";    \
	) > $@

# current git version based on the last tag

$(BUILD)/lapp_version.h: $(wildcard .git/refs/tags) $(wildcard .git/index)
	@$(call cyan,"GEN",$@)
	@mkdir -p $(dir $@)
	@(  echo "#pragma once";                                    \
	    echo "#define LAPP_VERSION \"`git describe --tags`\"";  \
	) > $@

# Lua library

$(LUA) $(LUAC) $(LIBLUA) &: $(LUA_ARCHIVE)
	@$(call cyan,"MAKE",$@)
	@mkdir -p $(BUILD)/linux
	@tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/linux
	@sed -i "s/^CC=.*/CC=$(CC) -std=gnu99/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^CFLAGS= -O2 /CFLAGS= /" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^MYCFLAGS=.*/MYCFLAGS= $(LUA_CC_OPT)/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^MYLDFLAGS=.*/MYLDFLAGS= $(LUA_LD_OPT)/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	@make -j -C $(BUILD)/linux/lua-$(LUA_VERSION) linux

$(LIBLUAW): $(LUA_ARCHIVE)
	@$(call cyan,"MAKE",$@)
	@mkdir -p $(BUILD)/win
	@tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/win
	@sed -i "s/^CC=.*/CC=$(MINGW_CC) -std=gnu99/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^CFLAGS= -O2 /CFLAGS= /" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^MYCFLAGS=.*/MYCFLAGS= $(LUA_CC_OPT)/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	@sed -i "s/^MYLDFLAGS=.*/MYLDFLAGS= $(LUA_LD_OPT)/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	@make -j -C $(BUILD)/win/lua-$(LUA_VERSION) mingw

$(LUA_ARCHIVE):
	@$(call cyan,"WGET",$@)
	@mkdir -p $(dir $@)
	@wget -c $(LUA_URL) -O $(LUA_ARCHIVE)

# lapp compilation

VERSION_H = $(BUILD)/lapp_version.h

LAPP_SOURCES = lapp.c tools.c
LAPP_SOURCES += $(STDLIBS_SOURCES) $(STDLIBS_CHUNKS)
LAPP_SOURCES_LINUX = $(filter-out %/wsocket.c,$(LAPP_SOURCES))
LAPP_SOURCES_WIN = $(filter-out %/usocket.c %/serial.c %/unixdgram.c %/unixstream.c %/unix.c,$(LAPP_SOURCES))

LRUN_SOURCES = lrun.c tools.c
LRUN_SOURCES += $(STDLIBS_SOURCES)
LRUN_SOURCES_LINUX = $(filter-out %/wsocket.c,$(LRUN_SOURCES))
LRUN_SOURCES_WIN = $(filter-out %/usocket.c %/serial.c %/unixdgram.c %/unixstream.c %/unix.c,$(LRUN_SOURCES))

LRUN_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LRUN_SOURCES_LINUX))
LRUNW_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LRUN_SOURCES_WIN))

LAPP_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LAPP_SOURCES_LINUX))
LAPP_OBJ += $(BUILD)/linux/lrun_linux_blob.o
ifeq ($(HAS_MINGW),1)
LAPP_OBJ += $(BUILD)/linux/lrun_win_blob.o
endif

LAPPW_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LAPP_SOURCES_WIN))
LAPPW_OBJ += $(BUILD)/win/lrun_linux_blob.o
ifeq ($(HAS_MINGW),1)
LAPPW_OBJ += $(BUILD)/win/lrun_win_blob.o
endif

LZ4_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LZ4_SRC))
LZ4W_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LZ4_SRC))

# Compilation

$(BUILD)/linux/%.o: %.c $(LIBLUA) $(VERSION_H)
	@$(call cyan,"CC",$@)
	@mkdir -p $(dir $@)
	@$(CC) -MD $(CC_OPT) $(CC_INC) -c $< -o $@

$(BUILD)/win/%.o: %.c $(LIBLUAW) $(VERSION_H)
	@$(call cyan,"CC",$@)
	@mkdir -p $(dir $@)
	@$(MINGW_CC) -MD $(MINGW_OPT) $(MINGW_CC_INC) -c $< -o $@

# Compilation of the generated source files

$(BUILD)/linux/%.o: $(BUILD)/%.c $(LIBLUA) $(VERSION_H)
	@$(call cyan,"CC",$@)
	@mkdir -p $(dir $@)
	@$(CC) -MD $(CC_OPT) $(CC_INC) -c $< -o $@

$(BUILD)/win/%.o: $(BUILD)/%.c $(LIBLUAW) $(VERSION_H)
	@$(call cyan,"CC",$@)
	@mkdir -p $(dir $@)
	@$(MINGW_CC) -MD $(MINGW_OPT) $(MINGW_CC_INC) -c $< -o $@

# Runtime link

$(LRUN): $(LRUN_OBJ) $(LIBLUA) $(LZ4_OBJ)
	@$(call cyan,"LD",$@)
	@$(CC) $(CC_OPT) $(CC_INC) $^ $(CC_LIB) -o $@

$(LRUNW): $(LRUNW_OBJ) $(LIBLUAW) $(LZ4W_OBJ)
	@$(call cyan,"LD",$@)
	@$(MINGW_CC) $(MINGW_OPT) $(MINGW_CC_INC) $^ $(MINGW_CC_LIB) -o $@

# lapp link

$(LAPP): $(LAPP_OBJ) $(LIBLUA) $(LZ4_OBJ)
	@$(call cyan,"LD",$@)
	@$(CC) $(CC_OPT) $(CC_INC) $^ $(CC_LIB) -o $@

$(LAPPW): $(LAPPW_OBJ) $(LIBLUAW) $(LZ4W_OBJ)
	@$(call cyan,"LD",$@)
	@$(MINGW_CC) $(MINGW_OPT) $(MINGW_CC_INC) $^ $(MINGW_CC_LIB) -o $@

# Runtime blob creation

$(BUILD)/lrun_linux_blob.c: $(LRUN) xxd.lua
	@$(call cyan,"XXD",$<)
	@$(LUA) xxd.lua lrun_linux $< $@

$(BUILD)/lrun_win_blob.c: $(LRUNW) xxd.lua
	@$(call cyan,"XXD",$<)
	@$(LUA) xxd.lua lrun_win $< $@

# Standard runtime chunks

$(BUILD)/%_chunk.c: $(BUILD)/%.luao xxd.lua
	@$(call cyan,"XXD",$<)
	@$(LUA) xxd.lua $(notdir $(basename $<))_chunk $< $@

$(BUILD)/%.luao: %.lua
	@$(call cyan,"LUAC",$<)
	@mkdir -p $(dir $@)
	@$(LUAC) -o $@ $<

# lpeg

$(LPEG_SOURCES) $(LPEG_SCRIPTS) &: $(CACHE)/$(notdir $(LPEG_URL))
	@$(call cyan,"TAR",$@)
	@tar -xzf $< -C $(BUILD)
	@touch $(LPEG_SOURCES) $(LPEG_SCRIPTS)

$(CACHE)/$(notdir $(LPEG_URL)):
	@$(call cyan,"WGET",$@)
	@mkdir -p $(dir $@)
	@wget -c $(LPEG_URL) -O $@

# luax

$(LUAX): $(LAPP) luax.lua
	$(LAPP) luax.lua -o $@

$(LUAXW): $(LAPP) luax.lua
	$(LAPP) luax.lua -o $@

# libssp-0.dll

# define variable $1 if $2 exists
define defvar
ifneq ($(wildcard $(strip $(2))),)
$(strip $(1)) := $(strip $(2))
endif
endef

ifeq ($(HAS_MINGW),1)

$(eval $(call defvar, MINGW_LIBSSP_DLL, /usr/x86_64-w64-mingw32/sys-root/mingw/bin/libssp-0.dll))  # Fedora 35
$(eval $(call defvar, MINGW_LIBSSP_DLL, /usr/lib/gcc/i686-w64-mingw32/10-posix/libssp-0.dll))      # Ubuntu 21.10

ifeq ($(MINGW_LIBSSP_DLL),)
$(error libssp-0.dll not found)
endif

$(LIBSSP_DLL): $(MINGW_LIBSSP_DLL)
	cp $< $@

$(TEST_LIBSSP_DLL): $(MINGW_LIBSSP_DLL)
	cp $< $@

endif

# Binary archives

$(LAPP_TAR): README.md $(LAPP) $(LUAX) $(LRUN)
	tar -czf $@ \
		-C $(dir $(word 1,$^)) $(notdir $(word 1,$^)) \
		-C $(dir $(word 2,$^)) $(notdir $(wordlist 2,4,$^))

$(LAPP_ZIP): README.md $(LAPPW) $(LUAXW) $(LRUNW) $(LIBSSP_DLL)
	zip -j $@ $^

# Dependencies

-include $(shell find $(BUILD) -name "*.d" 2>/dev/null)
