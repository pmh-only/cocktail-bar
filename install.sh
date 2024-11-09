#!/bin/sh
SOURCE=$(readlink -f "$0")
SOURCE_ROOT=$(dirname "$SOURCE")

ln -sf $SOURCE_ROOT/qkstart.sh /usr/bin/q
chmod 755 /usr/bin/q
chmod 777 -R $SOURCE_ROOT
