check_exec jq curl wget

v=$(curl https://api.github.com/repos/derailed/k9s/releases | jq '.[0].name' -r)
a=$(get_arch)

wget https://github.com/derailed/k9s/releases/download/$v/k9s_linux_$a.rpm -O /tmp/k9s.rpm
sudo rpm -i /tmp/k9s.rpm
