check_exec curl wget

v=$(curl -L -s https://dl.k8s.io/release/stable.txt)
a=$(get_arch)

wget https://dl.k8s.io/release/$v/bin/linux/$a/kubectl -O /tmp/kubectl

sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl

echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

echo 'source <(kubectl completion zsh)' >>~/.zshrc
echo 'alias k=kubectl' >>~/.zshrc
echo "compdef k='kubectl'" >>~/.zshrc

echo "export KUBE_CONFIG_PATH=/home/$USER/.kube/config" >> ~/.zshrc
