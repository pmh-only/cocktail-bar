#!/bin/sh
SOURCE=$(readlink -f "$0")
SOURCE_ROOT=$(dirname "$SOURCE")

ln -sf $SOURCE_ROOT/qkstart.sh /usr/local/bin/q
chmod 755 /usr/local/bin/q

chmod 777 complete.sh qkstart.sh
chmod 777 -R $SOURCE_ROOT/_qkstart
