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

LUA_VERSION = 5.4.3
LUA_URL = http://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz

INSTALL_PATH = $(HOME)/.local/bin

BUILD = .build

LUA_ARCHIVE = $(BUILD)/lua-$(LUA_VERSION).tar.gz

LZ4_SRC = external/lz4/lib/lz4.c external/lz4/lib/lz4hc.c
LZ4_INC = external/lz4/lib

CC_OPT = -Os -flto -s
CC_OPT += -std=gnu99
CC_OPT += -ffunction-sections -fdata-sections -Wl,-gc-sections
CC_OPT += -Wall -Wextra -pedantic -Werror
CC_OPT += -Wstrict-prototypes
CC_OPT += -Wmissing-field-initializers
CC_OPT += -Wmissing-prototypes
CC_OPT += -Wmissing-declarations
CC_OPT += -Werror=switch-enum

LUA_CC_OPT = -Os -ffunction-sections -fdata-sections
LUA_LD_OPT = -flto -s -Wl,-gc-sections

CC = gcc
LUA = $(BUILD)/linux/lua-$(LUA_VERSION)/src/lua
LIBLUA = $(BUILD)/linux/lua-$(LUA_VERSION)/src/liblua.a
LRUN = $(BUILD)/linux/lrun
LAPP = $(BUILD)/linux/lapp
CC_INC = -I$(BUILD)
CC_INC += -I$(BUILD)/linux/lua-$(LUA_VERSION)/src
CC_INC += -I$(BUILD)/linux
CC_INC += -I$(LZ4_INC)
CC_LIB = -lm -ldl

MINGW_CC = x86_64-w64-mingw32-gcc
LIBLUAW = $(BUILD)/win/lua-$(LUA_VERSION)/src/liblua.a
LRUNW = $(BUILD)/win/lrun.exe
LAPPW = $(BUILD)/win/lapp.exe
MINGW_CC_INC = -I$(BUILD)
MINGW_CC_INC += -I$(BUILD)/win/lua-$(LUA_VERSION)/src
MINGW_CC_INC += -I$(BUILD)/win
MINGW_CC_INC += -I$(LZ4_INC)
MINGW_CC_LIB = -lm

.PHONY: all test linux windows

.SECONDARY:

all: compile_flags.txt
all: linux
all: windows
all: test

linux: $(LAPP)

windows: $(LAPPW)

clean:
	rm -rf $(BUILD)

install: $(LAPP) $(LAPPW)
	install -T $(LAPP) $(INSTALL_PATH)/$(notdir $(LAPP))
	install -T $(LAPPW) $(INSTALL_PATH)/$(notdir $(LAPPW))

test: $(BUILD)/test/ok.host_linux_target_linux
test: $(BUILD)/test/ok.host_linux_target_windows.exe
test: $(BUILD)/test/ok.host_windows_target_linux
test: $(BUILD)/test/ok.host_windows_target_windows.exe
test: $(BUILD)/test/same.linux_native_and_cross
test: $(BUILD)/test/same.windows.exe_native_and_cross

TEST_SOURCES = test/main.lua test/lib.lua

$(BUILD)/test/ok.%: test/expected_result.txt $(BUILD)/test/res.%
	diff $^
	touch $@

# Test executables

$(BUILD)/test/bin.host_linux_target_%: $(LAPP) $(TEST_SOURCES)
	@mkdir -p $(dir $@)
	$(LAPP) $(TEST_SOURCES) -o $@

$(BUILD)/test/bin.host_windows_target_%: $(LAPPW) $(TEST_SOURCES)
	@mkdir -p $(dir $@)
	wine $(LAPPW) $(TEST_SOURCES) -o $@
	chmod +x $@

# Test results

$(BUILD)/test/res.host_%_target_linux: $(BUILD)/test/bin.host_%_target_linux
	$^ Lua is great > $@

$(BUILD)/test/res.host_%_target_windows.exe: $(BUILD)/test/bin.host_%_target_windows.exe
	wine $^ Lua is great | dos2unix > $@

# Native and cross compilations shall produce the same executable

$(BUILD)/test/same.%_native_and_cross: $(BUILD)/test/bin.host_linux_target_% $(BUILD)/test/bin.host_windows_target_%
	diff $^
	touch $@

# clangd configuration file

compile_flags.txt: Makefile
	@(  echo "-Weverything";               \
	    echo "$(CC_OPT)" | tr " " "\n";    \
	    echo "$(CC_INC)" | tr " " "\n";    \
	) > $@

# current git version based on the last tag

$(BUILD)/lapp_version.h: $(wildcard .git/refs/tags) .git/index
	@mkdir -p $(dir $@)
	@(  echo "#pragma once";                                    \
	    echo "#define LAPP_VERSION \"`git describe --tags`\"";  \
	) > $@

# Lua library

$(LUA) $(LIBLUA) &: $(LUA_ARCHIVE)
	@mkdir -p $(BUILD)/linux
	tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/linux
	sed -i "s/^CC=.*/CC=$(CC) -std=gnu99/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^CFLAGS= -O2 /CFLAGS= /" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^MYCFLAGS=.*/MYCFLAGS= $(LUA_CC_OPT)/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^MYLDFLAGS=.*/MYLDFLAGS= $(LUA_LD_OPT)/" $(BUILD)/linux/lua-$(LUA_VERSION)/src/Makefile
	make -j -C $(BUILD)/linux/lua-$(LUA_VERSION) linux

$(LIBLUAW): $(LUA_ARCHIVE)
	@mkdir -p $(BUILD)/win
	tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/win
	sed -i "s/^CC=.*/CC=$(MINGW_CC) -std=gnu99/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^CFLAGS= -O2 /CFLAGS= /" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^MYCFLAGS=.*/MYCFLAGS= $(LUA_CC_OPT)/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	sed -i "s/^MYLDFLAGS=.*/MYLDFLAGS= $(LUA_LD_OPT)/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	make -j -C $(BUILD)/win/lua-$(LUA_VERSION) mingw

$(LUA_ARCHIVE):
	@mkdir -p $(dir $@)
	wget -c $(LUA_URL) -O $(LUA_ARCHIVE)

# lapp compilation

VERSION_H = $(BUILD)/lapp_version.h
LRUN_SOURCES = lrun.c tools.c
LAPP_SOURCES = lapp.c tools.c

LRUN_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LRUN_SOURCES))
LRUNW_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LRUN_SOURCES))

LAPP_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LAPP_SOURCES))
LAPP_OBJ += $(BUILD)/linux/lrun_linux_blob.o $(BUILD)/linux/lrun_windows_blob.o

LAPPW_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LAPP_SOURCES))
LAPPW_OBJ += $(BUILD)/win/lrun_linux_blob.o $(BUILD)/win/lrun_windows_blob.o

LZ4_OBJ = $(patsubst %.c,$(BUILD)/linux/%.o,$(LZ4_SRC))
LZ4W_OBJ = $(patsubst %.c,$(BUILD)/win/%.o,$(LZ4_SRC))

# Compilation

$(BUILD)/linux/%.o: %.c $(LIBLUA) $(VERSION_H)
	@mkdir -p $(dir $@)
	$(CC) -MD $(CC_OPT) $(CC_INC) -c $< -o $@

$(BUILD)/win/%.o: %.c $(LIBLUAW) $(VERSION_H)
	@mkdir -p $(dir $@)
	$(MINGW_CC) -MD $(CC_OPT) $(MINGW_CC_INC) -c $< -o $@

# Compilation of the generated source files

$(BUILD)/linux/%.o: $(BUILD)/%.c $(LIBLUA) $(VERSION_H)
	@mkdir -p $(dir $@)
	$(CC) -MD $(CC_OPT) $(CC_INC) -c $< -o $@

$(BUILD)/win/%.o: $(BUILD)/%.c $(LIBLUAW) $(VERSION_H)
	@mkdir -p $(dir $@)
	$(MINGW_CC) -MD $(CC_OPT) $(MINGW_CC_INC) -c $< -o $@

# Runtime link

$(LRUN): $(LRUN_OBJ) $(LIBLUA) $(LZ4_OBJ)
	$(CC) $(CC_OPT) $(CC_INC) $^ $(CC_LIB) -o $@

$(LRUNW): $(LRUNW_OBJ) $(LIBLUAW) $(LZ4W_OBJ)
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $^ -o $@

# lapp link

$(LAPP): $(LAPP_OBJ) $(LIBLUA) $(LZ4_OBJ)
	$(CC) $(CC_OPT) $(CC_INC) $^ $(CC_LIB) -o $@

$(LAPPW): $(LAPPW_OBJ) $(LIBLUAW) $(LZ4W_OBJ)
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $^ -o $@

# Runtime blob creation

$(BUILD)/lrun_linux_blob.c: $(LRUN) xxd.lua
	$(LUA) xxd.lua lrun_linux $< $@

$(BUILD)/lrun_windows_blob.c: $(LRUNW) xxd.lua
	$(LUA) xxd.lua lrun_windows $< $@

# Dependencies

-include $(BUILD)/linux/*.d
-include $(BUILD)/win/*.d
