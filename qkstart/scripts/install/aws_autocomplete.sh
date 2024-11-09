COMPLETER_PATH=$(which aws_completer)


echo "complete -C '$COMPLETER_PATH' aws" >> ~/.bashrc
cat <<EOF >> ~/.zshrc
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -C '$COMPLETER_PATH' aws
EOF
