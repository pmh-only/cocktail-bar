check_exec docker
sudo systemctl enable --now docker
sudo usermod -aG docker $(whoami)

cat <<EOT >> ~/.bashrc
source /etc/profile.d/bash_completion.sh
EOT

mkdir -p ~/.local/share/bash-completion/completions
docker completion bash > ~/.local/share/bash-completion/completions/docker

mkdir -p ~/.oh-my-zsh/completions
docker completion zsh > ~/.oh-my-zsh/completions/_docker
