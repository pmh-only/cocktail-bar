sudo yum install -y yum-utils && \
  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo && \
  sudo yum -y install terraform

git clone https://github.com/pmh-only/cocktail-bar /tmp/cocktail-bar
mkdir /home/cloudshell-user/cocktail-bar/ 
for f in /tmp/cocktail-bar/*; do
  echo $f
  if [[ "$f" != "/tmp/cocktail-bar/_bar" ]]; then
    ln -sf "$f" /home/cloudshell-user/cocktail-bar/
  fi
done

# ---

export BAR_NAME="${1:-new}"

if [ ! -f /home/cloudshell-user/cocktail-bar/_bar/$BAR_NAME ]; then
  mkdir -p /home/cloudshell-user/cocktail-bar/_bar/$BAR_NAME
fi

mkdir -p /tmp/terraform/$BAR_NAME
ln -sf /tmp/terraform/$BAR_NAME /home/cloudshell-user/cocktail-bar/_bar/$BAR_NAME/.terraform
