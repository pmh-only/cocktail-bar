cat <<EOF >> ~/.bashrc >> ~/.zshrc
alias ka="kubectl apply -f"
alias kd="kubectl describe -f"
alias kx="kubectl delete -f"
alias kg="kubectl get -f"
EOF
