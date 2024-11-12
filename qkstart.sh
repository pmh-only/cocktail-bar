#!/bin/sh

#
# qkstart.sh
# made by Minhyeok Park <pmh_only@pmh.codes>
#
# MIT Licensed. All rights reserved.
#

# load essential variables
ARGS="$@"
SOURCE=$(readlink -f "$0")
SOURCE_ROOT=$(dirname "$SOURCE")

SCRIPT_PATH="$SOURCE_ROOT/_qkstart/scripts"
ASSETS_PATH="$SOURCE_ROOT/_qkstart/assets"

# determine given path is directory
# $1 - absolute path for checking
is_directory() {
  if [[ -d $1 ]]; then
    echo 1
  else
    echo 0
  fi
}

# find suitable target files-or-directories from input
# $1 = base_path
# $2 = input_arg
find_targets() {
  local check_path="$SCRIPT_PATH/$1/$2*"
  for target in $check_path; do
    if [[ $target != *\* ]]; then
      echo $(basename $target)    
    fi
  done
}

# find suitable target files recursively from inputs
# $1 = base_path
# $2 = input_args
find_targets_recursive() {
  if [ ${#2} -lt 1 ]; then
    return 0
  fi

  local input_args=(${@:2})
  if [[ $2 == \-* ]]; then
    find_targets_recursive $1 ${input_args[@]:1}
    return 0
  fi

  local targets=$(find_targets $1 ${input_args[0]})

  if [ ${#targets[@]} -lt 1 ]; then
    return 0
  fi

  for target in $targets; do
    local target_path="$SCRIPT_PATH/$1/$target"
    if [ $(is_directory $target_path) -eq 1 ]; then
      echo $(find_targets_recursive $1/$target ${input_args[@]:1})
    else
      echo $1/$target
    fi
  done
}

# check found target count
# $1 = input_args
# $2 = found_targets
validate_found_targets() {
  found_targets=($2)
  if [ ${#found_targets[@]} -lt 1 ]; then
    echo "Could not found script: $1"
    exit 1
  fi

  if [ ${#found_targets[@]} -gt 1 ]; then
    echo "Ambiguous script: $1, Possible scripts are:"
    for found_target in ${found_targets[@]}; do
      echo $found_target
    done

    exit 1
  fi
}

# prompt before actual running
# $ = script_name
prompt_running() {
  while true; do
    read -p "run: $1 [Y/n] " yn
    case $yn in
      [Yy]* ) break;;
      ""    ) break;;
      [Nn]* ) exit 1;;
      *     ) echo "Please answer yes or no.";;
    esac
  done 
}

# find common files for specific script
# $1 = found_target
find_common_files() {
  dirs=${1//\// }
  for dir in $dirs; do
    if [ -f $SCRIPT_PATH/$dir/_common.sh ]; then
      echo $SCRIPT_PATH/$dir/_common.sh
    fi
  done
}

# run provided scripts
# $1 = scripts
run_scripts() {
  for script in $1; do
    source $(realpath $script) $2
  done
}

array_contains() {
  a=($1)
  for i in "${a[@]}"
  do
    if [ "$i" = "$2" ]; then
      echo 1
      return 0
    fi
  done

  echo 0
}

# entrypoint for qkstart
qkstart() {
  local found_targets=$(find_targets_recursive . "$*")

  validate_found_targets "$*" "$found_targets"

  local found_target=${found_targets[0]}
  local found_commons=$(find_common_files $found_target)

  if [ $(array_contains "$*" "-y") -ne 1 ]; then
    prompt_running "$found_target"; fi

  run_scripts "${found_commons[@]} $SCRIPT_PATH/$found_target" "$*"
}

qkstart $*
