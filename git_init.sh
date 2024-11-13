GITEA_TOKEN="U2FsdGVkX18OpYGFbAw/jLhTbX9Y7gh461XlvP9vnnnDkPwk/5945/Z/W6wwYO9pkTbHKs1mYVsq9OY9vXukOA=="
GITEA_TOKEN=$(base64 -d <<<$GITEA_TOKEN | openssl enc -d -aes-256-cbc)

git init

git config credential.helper store
git config user.name "Minhyeok Park"
git config user.email "pmh_only@pmh.codes"

git remote add origin https://pmh_only:$GITEA_TOKEN@src.pmh.codes/pmh_only/cocktail-bar.git

git branch -m main
git fetch origin main
git reset --hard origin/main
