#!/usr/bin/env bash
set -e

if [ ! -f /home/core/done-haproxy.txt ]; then
    echo "Changing iptables"
    iptables -t nat -I OUTPUT  --dst api-int.test-cluster.redhat.com -p tcp --dport 6443 -j REDIRECT --to-ports 6444
    echo "Start dnsmasq"
    echo nameserver 192.168.140.10 > /etc/resolv.conf
    echo "[main]\ndns=none\nrc-manager=unmanaged" >   /etc/NetworkManager/conf.d/aio.conf
    systemctl enable dnsmasq.service --now
    echo "Start haproxy"
    podman run  --net=host -d --privileged --name my-running-haproxy -v /etc/haproxy:/usr/local/etc/haproxy:ro quay.io/itsoiref/haproxy:latest
    echo "Sleeping 20 to give haproxy time to start"
    sleep 20
    echo "Verifying haproxy runs"
    podman ps | grep my-running-haproxy
    echo "Restart kubelet"
    systemctl restart kubelet
    echo "Done" > /home/core/done-haproxy.txt
    echo "Sleeping infinity"
    sleep infinity
fi
echo "Done"

