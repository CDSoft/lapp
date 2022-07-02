#!/bin/bash

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

CACHE=.cache
RELEASE=release
INDEX=$RELEASE/index.md

set -ex

index()
{
    case "$1" in
        \#*)   echo " "; echo "$1"; echo " ";;
        *)      echo "$1";;
    esac >> $INDEX
}

build_linux()
{
    local LAPP_VERSION="$1"
    local ARCHIVE_LINUX=lapp-$LAPP_VERSION-linux-x86_64.tar.gz

    # fix Archlinux archive name
    ARCHIVE_LINUX=$(echo $ARCHIVE_LINUX | sed 's/archlinux-latest/arch-/')

    index "- Linux: [$ARCHIVE_LINUX]($ARCHIVE_LINUX)"

    [ -f $RELEASE/$ARCHIVE_LINUX ] && return

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp-linux ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp-linux
    ( cd $CACHE/$LAPP_VERSION/lapp-linux && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    ( cd $CACHE/$LAPP_VERSION/lapp-linux && make all linux )

    cp $CACHE/$LAPP_VERSION/lapp-linux/.build/linux/lapp-*.tar.gz $RELEASE/$ARCHIVE_LINUX
}

build_win()
{
    local LAPP_VERSION="$1"
    local ARCHIVE_WINDOWS=lapp-$LAPP_VERSION-win-x86_64.zip

    index "- Windows: [$ARCHIVE_WINDOWS]($ARCHIVE_WINDOWS)"

    [ -f $RELEASE/$ARCHIVE_WINDOWS ] && return

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp-win ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp-win
    ( cd $CACHE/$LAPP_VERSION/lapp-win && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    ( cd $PWD/$CACHE/$LAPP_VERSION/lapp-win && make all windows )

    cp $CACHE/$LAPP_VERSION/lapp-win/.build/win/lapp-*.zip $RELEASE/$ARCHIVE_WINDOWS
}

build_pi()
{
    local LAPP_VERSION="$1"
    local HOST="$2"
    local OS=$(ssh $HOST "cat /etc/os-release" | awk -F "=" '$1=="ID" {print $2}' | tr -d '"')
    local ARCHIVE_LINUX=lapp-$LAPP_VERSION-raspberry-aarch64.tar.gz

    index "- Raspberry Pi: [$ARCHIVE_LINUX]($ARCHIVE_LINUX)"

    [ -f $RELEASE/$ARCHIVE_LINUX ] && return

    mkdir -p $CACHE

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp-pi ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp-pi
    ( cd $CACHE/$LAPP_VERSION/lapp-pi && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    local PI_BUILD=/tmp/lapp_build
    ssh $HOST "rm -rf $PI_BUILD; mkdir $PI_BUILD"
    scp -r $PWD/$CACHE/$LAPP_VERSION/lapp-pi pi:$PI_BUILD
    ssh $HOST "make -C $PI_BUILD/lapp-pi dep"
    ssh $HOST "make -C $PI_BUILD/lapp-pi linux"

    scp pi:$PI_BUILD/lapp-pi/.build/linux/lapp-*.tar.gz $RELEASE/$ARCHIVE_LINUX
}

mkdir -p $RELEASE
rm -f $INDEX

index "# lapp releases"

for version in 0.8 0.8.1
do

    index "## lapp $version"

    build_linux $version
    build_pi $version pi
    build_win $version

done
