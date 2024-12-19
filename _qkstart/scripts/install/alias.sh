cat <<EOF >> ~/.bashrc >> ~/.zshrc
alias ka="kubectl apply -f"
alias kd="kubectl describe -f"
alias kx="kubectl delete -f"
alias kg="kubectl get -f"
alias kns="kubens"
alias t="terraform"
alias ti="terraform init"
alias ta="terraform apply"
alias taa="terraform apply --auto-approve"
alias to="terraform output"
EOF
