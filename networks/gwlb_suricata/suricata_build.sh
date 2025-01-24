amazon-linux-extras install -y epel && \
  yum -y install iptables-services git automake autoconf libtool gcc libpcap-devel pcre-devel libyaml-devel file-devel \
  zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make \
  libnetfilter_queue-devel lua-devel PyYAML supervisor lz4-devel gzip && \
  curl -ks https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain 1.52.1 --no-modify-path -y && \
  yum clean all && rm -rf /var/cache/yum /var/lib/suricata/rules /etc/cron.*/*

export PATH=$PATH:/root/.cargo/bin

git clone --recursive https://github.com/maxmind/libmaxminddb && cd libmaxminddb && \
  ./bootstrap && ./configure && make && make install && ldconfig && cp /usr/local/lib/libmaxminddb.so.0 /usr/lib64/ && \
  cd ../ && curl -ks https://www.openinfosecfoundation.org/download/suricata-6.0.0.tar.gz -o suricata-6.0.0.tar.gz && \
  tar -zxvf suricata-6.0.0.tar.gz && cd suricata-6.0.0 && \
  ./configure --disable-gccmarch-native --prefix=/ --sysconfdir=/etc/ --localstatedir=/var/ --enable-lua --enable-geoip --enable-nfqueue --enable-rust && \
  make install install-conf && \
  mkdir -p /var/lib/suricata/update/
