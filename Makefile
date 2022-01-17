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
LAPP = $(BUILD)/linux/lapp
CC_INC = -I$(BUILD)
CC_INC += -I$(BUILD)/linux/lua-$(LUA_VERSION)/src
CC_INC += -I$(BUILD)/linux
CC_INC += -I$(LZ4_INC)
CC_LIB = -lm -ldl

MINGW_CC = x86_64-w64-mingw32-gcc
LIBLUAW = $(BUILD)/win/lua-$(LUA_VERSION)/src/liblua.a
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
	@mkdir -p $(BUILD)/test
	$(LAPP) $(TEST_SOURCES) -o $@

$(BUILD)/test/bin.host_windows_target_%: $(LAPPW) $(TEST_SOURCES)
	@mkdir -p $(BUILD)/test
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

compile_flags.txt: Makefile
	@(  echo "-Weverything";               \
	    echo "$(CC_OPT)" | tr " " "\n";    \
	    echo "$(CC_INC)" | tr " " "\n";    \
	) > $@

$(BUILD)/lapp_version.h: Makefile
	@mkdir -p $(dir $@)
	@(  echo "#pragma once";                                    \
	    echo "#define LAPP_VERSION \"`git describe --tags`\"";  \
	) > $@

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

HEADERS = header.h $(BUILD)/lapp_version.h
LRUN_SOURCES = lrun.c tools.c
LRUN_BLOB_SOURCES = $(BUILD)/linux/lrun_blob.c $(BUILD)/win/lrun_blob.c
LAPP_SOURCES = lapp.c tools.c

$(LAPP): $(LAPP_SOURCES) $(LRUN_BLOB_SOURCES) $(HEADERS) $(LIBLUA)
	$(CC) $(CC_OPT) $(CC_INC) $(LAPP_SOURCES) $(LZ4_SRC) $(LIBLUA) $(CC_LIB) -o $@

$(LAPPW): $(LAPP_SOURCES) $(LRUN_BLOB_SOURCES) $(HEADERS) $(LIBLUAW)
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $(LAPP_SOURCES) $(LZ4_SRC) $(LIBLUAW) $(MINGW_CC_LIB) -o $@

$(BUILD)/linux/lrun_blob.c: $(LRUN_SOURCES) $(HEADERS) $(LUA) $(LIBLUA)
	$(CC) $(CC_OPT) $(CC_INC) $(LRUN_SOURCES) $(LZ4_SRC) $(LIBLUA) $(CC_LIB) -o $(dir $@)/lrun
	$(LUA) xxd.lua lrun_linux $(dir $@)/lrun $@

$(BUILD)/win/lrun_blob.c: $(LRUN_SOURCES) $(HEADERS) $(LUA) $(LIBLUAW)
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $(LRUN_SOURCES) $(LZ4_SRC) $(LIBLUAW) $(MINGW_CC_LIB) -o $(dir $@)/lrun.exe
	$(LUA) xxd.lua lrun_windows $(dir $@)/lrun.exe $@
