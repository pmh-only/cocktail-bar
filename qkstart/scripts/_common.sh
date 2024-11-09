confirm_continue() {
  while true; do
    read -p "confirm_continue: $* [Y/n] " yn
    case $yn in
      [Yy]* ) break;;
      ""    ) break;;
      [Nn]* ) exit 1;;
      *     ) echo "Please answer yes or no.";;
    esac
  done 
}
