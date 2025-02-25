sudo yum install -y docker
sudo systemctl enable --now docker

sudo docker run --privileged --rm tonistiigi/binfmt --install arm64
sudo usermod -aG docker ec2-user
