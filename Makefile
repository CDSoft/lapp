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

all: compile_flags.txt
all: linux
all: windows
all: test

linux: $(BUILD)/lapp_version.h
linux: $(LUA) $(LIBLUA) $(LIBLUAW) $(LAPP)

windows: $(BUILD)/lapp_version.h
windows: $(LUA) $(LIBLUA) $(LIBLUAW) $(LAPPW)

clean:
	rm -rf $(BUILD)

install: $(BUILD)/lapp_version.h $(LAPP) $(LAPPW)
	install -T $(LAPP) $(INSTALL_PATH)/$(notdir $(LAPP))
	install -T $(LAPPW) $(INSTALL_PATH)/$(notdir $(LAPPW))

test: $(LAPP) $(LAPPW) test/main.lua test/lib.lua test/expected_result.txt
	@mkdir -p $(BUILD)/test

	# Linux test
	$(LAPP) test/main.lua test/lib.lua -o $(BUILD)/test/lapp_test
	$(BUILD)/test/lapp_test Lua is great > $(BUILD)/test/lapp_test.res
	diff test/expected_result.txt $(BUILD)/test/lapp_test.res

	# Windows test (cross compilation)
	$(LAPP) test/main.lua test/lib.lua -o $(BUILD)/test/lapp_test.exe
	wine $(BUILD)/test/lapp_test.exe Lua is great > $(BUILD)/test/lapp_test_win.res
	dos2unix $(BUILD)/test/lapp_test_win.res
	diff test/expected_result.txt $(BUILD)/test/lapp_test_win.res

	# Windows test (with Wine)
	wine $(LAPPW) test/main.lua test/lib.lua -o $(BUILD)/test/lapp_wine_test.exe
	wine $(BUILD)/test/lapp_wine_test.exe Lua is great > $(BUILD)/test/lapp_wine_test_win.res
	dos2unix $(BUILD)/test/lapp_wine_test_win.res
	diff test/expected_result.txt $(BUILD)/test/lapp_wine_test_win.res

	# Cross compilation and Wine compilation shall produce the same executable
	diff -b $(BUILD)/test/lapp_test.exe $(BUILD)/test/lapp_wine_test.exe

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

$(LAPP): lapp.c $(LIBLUA) $(BUILD)/linux/lrun_blob.c $(BUILD)/win/lrun_blob.c tools.c
	$(CC) $(CC_OPT) $(CC_INC) $(filter-out %/lrun_blob.c,$^) $(LZ4_SRC) $(CC_LIB) -o $@

$(LAPPW): lapp.c $(LIBLUAW) $(BUILD)/linux/lrun_blob.c $(BUILD)/win/lrun_blob.c tools.c
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $(filter-out %/lrun_blob.c,$^) $(LZ4_SRC) $(MINGW_CC_LIB) -o $@

$(BUILD)/linux/lrun_blob.c: lrun.c tools.c
	$(CC) $(CC_OPT) $(CC_INC) $^ $(LZ4_SRC) $(LIBLUA) $(CC_LIB) -o $(dir $@)/lrun
	$(LUA) xxd.lua lrun_linux $(dir $@)/lrun $@

$(BUILD)/win/lrun_blob.c: lrun.c tools.c
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $^ $(LZ4_SRC) $(LIBLUAW) $(MINGW_CC_LIB) -o $(dir $@)/lrun.exe
	$(LUA) xxd.lua lrun_windows $(dir $@)/lrun.exe $@
