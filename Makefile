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

CC_OPT = -Wall -Wextra -pedantic -g -O3

CC = gcc
LIBLUA = $(BUILD)/linux/lua-$(LUA_VERSION)/src/liblua.a
LAPP = $(BUILD)/linux/lapp
CC_INC = -I$(BUILD)/linux/lua-$(LUA_VERSION)/src
CC_INC += -I$(BUILD)/linux
CC_LIB = -lm -ldl

MINGW_CC = x86_64-w64-mingw32-gcc
LIBLUAW = $(BUILD)/win/lua-$(LUA_VERSION)/src/liblua.a
LAPPW = $(BUILD)/win/lapp.exe
MINGW_CC_INC = -I$(BUILD)/win/lua-$(LUA_VERSION)/src
MINGW_CC_INC += -I$(BUILD)/win
MINGW_CC_LIB = -lm

.PHONY: all test

all: compile_flags.txt
all: $(LIBLUA) $(LIBLUAW)
all: $(LAPP) $(LAPPW)
all: test

clean:
	rm -rf $(BUILD)

install: $(LAPP) $(LAPPW)
	install -T $(LAPP) $(INSTALL_PATH)/$(notdir $(LAPP))
	install -T $(LAPPW) $(INSTALL_PATH)/$(notdir $(LAPPW))

test: test/main.lua test/lib.lua test/expected_result.txt
	@mkdir -p $(BUILD)/test
	# Linux test
	$(LAPP) test/main.lua test/lib.lua -o $(BUILD)/test/lapp_test
	$(BUILD)/test/lapp_test a1 a2 a3 > $(BUILD)/test/lapp_test.res
	diff test/expected_result.txt $(BUILD)/test/lapp_test.res
	# Windows test (with Wine)
	wine $(LAPPW) test/main.lua test/lib.lua -o $(BUILD)/test/lapp_test.exe
	wine $(BUILD)/test/lapp_test.exe a1 a2 a3 > $(BUILD)/test/lapp_test_win.res
	dos2unix $(BUILD)/test/lapp_test_win.res
	diff test/expected_result.txt $(BUILD)/test/lapp_test_win.res

compile_flags.txt: Makefile
	@(	echo "-Wall";							\
		echo "-Wextra";							\
		echo "-pedantic";						\
		echo "-Weverything";					\
		echo "-Wstrict-prototypes";				\
		echo "-Wmissing-field-initializers";	\
		echo "-Wmissing-prototypes";			\
		echo "-Wmissing-declarations";			\
		echo "-Werror=switch-enum";				\
		echo "-Wno-padded";						\
		echo "$(CC_INC)" | tr " " "\n"			\
	) > $@

$(LIBLUA): $(LUA_ARCHIVE)
	@mkdir -p $(BUILD)/linux
	tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/linux
	make -C $(BUILD)/linux/lua-$(LUA_VERSION) linux

$(LIBLUAW): $(LUA_ARCHIVE)
	@mkdir -p $(BUILD)/win
	tar -xzf $(LUA_ARCHIVE) -C $(BUILD)/win
	sed -i "s/^CC=.*/CC=$(MINGW_CC) -std=gnu99/" $(BUILD)/win/lua-$(LUA_VERSION)/src/Makefile
	make -C $(BUILD)/win/lua-$(LUA_VERSION) mingw

$(LUA_ARCHIVE):
	@mkdir -p $(dir $@)
	wget -c $(LUA_URL) -O $(LUA_ARCHIVE)

$(LAPP): lapp.c $(LIBLUA) $(BUILD)/linux/lrun_blob.c
	$(CC) $(CC_OPT) $(CC_INC) $(filter-out %/lrun_blob.c,$^) $(CC_LIB) -o $@

$(LAPPW): lapp.c $(LIBLUAW) $(BUILD)/win/lrun_blob.c
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $(filter-out %/lrun_blob.c,$^) $(MINGW_CC_LIB) -o $@

$(BUILD)/linux/lrun_blob.c: lrun.c
	$(CC) $(CC_OPT) $(CC_INC) $^ $(LIBLUA) $(CC_LIB) -o $(dir $@)/lrun
	xxd -i $(dir $@)/lrun $@
	sed -i 's/_.*linux__//' $@

$(BUILD)/win/lrun_blob.c: lrun.c
	$(MINGW_CC) $(CC_OPT) $(MINGW_CC_INC) $^ $(LIBLUAW) $(MINGW_CC_LIB) -o $(dir $@)/lrun.exe
	xxd -i $(dir $@)/lrun.exe $@
	sed -i -e 's/_.*win__//' -e 's/_exe//' $@
