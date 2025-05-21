cat <<EOF >> ~/.zshrc

alias k="kubectl"
alias ka="kubectl apply -f"
alias kg="kubectl get -f"
alias kd="kubectl describe -f"

alias ti="terraform init"
alias ta="terraform apply --parallelism 100"
alias taa="terraform apply --parallelism 100 --auto-approve"

EOF

source ~/.zshrc
