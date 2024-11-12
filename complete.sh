#!/bin/sh
SOURCE=$(readlink -f "$0")
SOURCE_ROOT=$(dirname "$SOURCE")

is_directory() {
  if [[ -d $1 ]]; then
    echo 1
  else
    echo 0
  fi
}

SCRIPT_PATH="$SOURCE_ROOT/_qkstart/scripts"

ARGS=($(echo "${COMP_LINE[@]:1}"))
ARGS_S=$(IFS=/; echo "${ARGS[*]}")

TARGET_PATH="$SCRIPT_PATH/$ARGS_S"

if [ $(is_directory $SCRIPT_PATH/$ARGS_S) -eq 1 ]; then
  TARGET_PATH+="/"
fi

TARGET_PATH+="*"


for target in $TARGET_PATH; do
  if [[ $target != *\* ]]; then
    echo $(basename $target .sh)
  fi
done

