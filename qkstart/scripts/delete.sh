rm ~/.
rm -rf $(dirname $(readlink $(which q)))
sudo rm `which q`

sed -i '/qkstart/d' ~/.bash_history
sed -i '/qkstart/d' ~/.zsh_history
