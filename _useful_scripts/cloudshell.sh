sudo su
yum install -y openssh-server
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N ""
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

wget https://github.com/openportio/openport-go/releases/download/v2.2.2/openport-amd64 -O /tmp/openport
chmod +x /tmp/openport

`which sshd` -h /root/.ssh/id_rsa -p 22

cat /root/.ssh/id_rsa
/tmp/openport 22
