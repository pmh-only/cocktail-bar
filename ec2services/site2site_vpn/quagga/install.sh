# for al2023
yum install -y gcc autoconf automake readline-devel autoconf-archive c-ares-devel
wget https://github.com/Quagga/quagga/releases/download/quagga-1.2.4/quagga-1.2.4.tar.gz
tar xvf quagga-1.2.4.tar.gz
cd quagga-1.2.4
autoreconf
./configure --disable-pimd --sysconfdir /etc/quagga

# Patch lib/prefix.h, replace __packed to __attribute__((__packed__))

make
make install

# after install and configure
mkdir /var/log/quagga
zebra -d -u root -g root
bgpd -d -u root -g root

# for al2
amazon-linux-extras install -y epel
yum install -y quagga
