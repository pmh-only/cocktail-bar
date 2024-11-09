check_exec curl tar

ARCH=$(get_arch)
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin

echo ". <(eksctl completion bash)" >> ~/.bashrc

mkdir -p ~/.zsh/completion/
eksctl completion zsh > ~/.zsh/completion/_eksctl

echo 'fpath=($fpath ~/.zsh/completion)' >> ~/.zshrc

cat <<EOF >> ~/.zshsrc
autoload -U compinit
compinit
EOF
