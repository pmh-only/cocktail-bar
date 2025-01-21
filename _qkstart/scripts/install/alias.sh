cat <<EOF >> ~/.bashrc >> ~/.zshrc
alias ka="kubectl apply -f"
alias kd="kubectl describe -f"
alias kx="kubectl delete -f"
alias kg="kubectl get -f"
alias kns="kubens"
alias t="terraform"
alias ti="terraform init"
alias ta="terraform apply --parallelism 100"
alias taa="terraform apply --auto-approve --parallelism 100"
alias to="terraform output"
alias qi="q i"
EOF
