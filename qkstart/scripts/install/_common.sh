check_exec() {
  q=""

  for p in "$@"; do
    which $p 1> /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "[check_exec] queued $p package"
      q="$q$p "
    fi
  done

  if [ ${#q} -gt 0 ]; then
    sudo yum install -y $q
  fi
}

get_arch() {
  arch=""
  case $(uname -m) in
    x86_64) arch="amd64" ;;
    aarch64) arch="arm64" ;;
  esac

  echo $arch
}
