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

BUILDS=.build
CACHE=.cache
RELEASE=$BUILDS/release
INDEX=$RELEASE/index.md

set -ex

index()
{
    case "$1" in
        \#*)   echo " "; echo "$1"; echo " ";;
        *)      echo "$1";;
    esac >> $INDEX
}

build()
{
    local LAPP_VERSION="$1"
    local OS="$2"
    local OS_VERSION="$3"
    local BUILD=$BUILDS/$OS/$OS_VERSION
    local ARCHIVE_LINUX=lapp-$LAPP_VERSION-$OS-$OS_VERSION-x86_64.tar.gz

    # fix Archlinux archive name
    ARCHIVE_LINUX=$(echo $ARCHIVE_LINUX | sed 's/archlinux-latest/arch-/')

    index "- $OS $OS_VERSION: [$ARCHIVE_LINUX]($ARCHIVE_LINUX)"

    [ -f $RELEASE/$ARCHIVE_LINUX ] && return

    mkdir -p $BUILD
    mkdir -p $CACHE

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp
    ( cd $CACHE/$LAPP_VERSION/lapp && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    local TAG=$(external/dockgen/dockgen.lua $OS $OS_VERSION)
    docker run                                              \
        --privileged                                        \
        --volume $PWD/$CACHE/$LAPP_VERSION/lapp:/mnt/app    \
        --volume $PWD/$BUILD:/mnt/app/.build                \
        --volume $PWD/$CACHE:/mnt/app/.cache                \
        -e CHECKS=OFF                                       \
        -t -i "$TAG"                                        \
        make linux

    cp $BUILD/linux/$ARCHIVE_LINUX $RELEASE/$ARCHIVE_LINUX
}

build_win()
{
    local LAPP_VERSION="$1"
    local OS="$2"
    local OS_VERSION="$3"
    local BUILD=$BUILDS/$OS/$OS_VERSION
    local ARCHIVE_WINDOWS=lapp-$LAPP_VERSION-win-x86_64.zip

    index "- Windows: [$ARCHIVE_WINDOWS]($ARCHIVE_WINDOWS)"

    [ -f $RELEASE/$ARCHIVE_WINDOWS ] && return

    mkdir -p $BUILD
    mkdir -p $CACHE

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp
    ( cd $CACHE/$LAPP_VERSION/lapp && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    local TAG=$(external/dockgen/dockgen.lua $OS $OS_VERSION)
    docker run                                              \
        --privileged                                        \
        --volume $PWD/$CACHE/$LAPP_VERSION/lapp:/mnt/app    \
        --volume $PWD/$BUILD:/mnt/app/.build                \
        --volume $PWD/$CACHE:/mnt/app/.cache                \
        -e CHECKS=OFF                                       \
        -t -i "$TAG"                                        \
        make windows

    cp $BUILD/win/$ARCHIVE_WINDOWS $RELEASE/$ARCHIVE_WINDOWS
}

build_pi()
{
    local LAPP_VERSION="$1"
    local HOST="$2"
    local OS=$(ssh $HOST "cat /etc/os-release" | awk -F "=" '$1=="ID" {print $2}' | tr -d '"')
    local OS_VERSION=$(ssh $HOST "cat /etc/os-release" | awk -F "=" '$1=="VERSION_ID" {print $2}' | tr -d '"')
    local ARCHIVE_LINUX=lapp-$LAPP_VERSION-$OS-$OS_VERSION-aarch64.tar.gz

    index "- $OS $OS_VERSION: [$ARCHIVE_LINUX]($ARCHIVE_LINUX)"

    [ -f $RELEASE/$ARCHIVE_LINUX ] && return

    mkdir -p $CACHE

    mkdir -p $CACHE/$LAPP_VERSION
    [ -d $CACHE/$LAPP_VERSION/lapp ] || git clone https://github.com/CDSoft/lapp $CACHE/$LAPP_VERSION/lapp
    ( cd $CACHE/$LAPP_VERSION/lapp && git checkout master && git fetch && git rebase && git checkout $LAPP_VERSION && git submodule sync && git submodule update --init --recursive )

    local PI_BUILD=/tmp/lapp_build
    ssh $HOST "rm -rf $PI_BUILD; mkdir $PI_BUILD"
    scp -r $PWD/$CACHE/$LAPP_VERSION/lapp pi:$PI_BUILD
    ssh $HOST "make -C $PI_BUILD/lapp linux"

    scp pi:$PI_BUILD/lapp/.build/linux/$ARCHIVE_LINUX $RELEASE/$ARCHIVE_LINUX
}

mkdir -p $RELEASE
rm -f $INDEX

index "# lapp releases"

for version in 0.6.3
do

    index "## lapp $version"

    index "### Debian"

    build $version debian 9
    build $version debian 10
    build $version debian 11

    index "### Ubuntu"

    build $version ubuntu 18.04    # LTS
    build $version ubuntu 20.04    # LTS
    build $version ubuntu 21.10
    build $version ubuntu 22.04    # LTS

    index "### Fedora"

    build $version fedora 34
    build $version fedora 35
    build $version fedora 36
    #build $version fedora rawhide

    index "### Raspberry Pi OS"

    build_pi $version pi

    index "### Windows"

    build_win $version fedora 36

done

for version in 0.6.4 0.6.5
do

    index "## lapp $version"

    index "### Debian"

    build $version debian 9
    build $version debian 10
    build $version debian 11

    index "### Ubuntu"

    build $version ubuntu 18.04    # LTS
    build $version ubuntu 20.04    # LTS
    build $version ubuntu 21.10
    build $version ubuntu 22.04    # LTS

    index "### Fedora"

    build $version fedora 34
    build $version fedora 35
    build $version fedora 36
    #build $version fedora rawhide

    index "### Archlinux"

    build $version archlinux latest

    index "### Raspberry Pi OS"

    build_pi $version pi

    index "### Windows"

    build_win $version fedora 36

done
