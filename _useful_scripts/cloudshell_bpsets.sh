sudo su

wget https://releases.pmh.codes/bpsets-x64 -O /tmp/bpsets
wget https://github.com/openportio/openport-go/releases/download/v2.2.2/openport-amd64 -O /tmp/openport

chmod +x /tmp/openport /tmp/bpsets

/tmp/bpsets &
/tmp/openport 2424
