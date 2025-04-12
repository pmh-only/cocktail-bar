while true; do
  if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    break
  fi

  docker run --privileged --rm tonistiigi/binfmt --install arm64
done
