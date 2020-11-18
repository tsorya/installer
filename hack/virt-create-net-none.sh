sudo virsh net-create ./hack/routed225.xml
sudo virsh net-create ./hack/routed226.xml
echo "Setting iptable rules"
iptables -I FORWARD -i virbr226 -o virbr225 -j ACCEPT
iptables -I FORWARD -i virbr225 -o virbr226 -j ACCEPT
IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -j SNAT --source 192.168.140.0/24 --to-source ${IP}
iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -j SNAT --source 192.168.225.0/24 --to-source ${IP}
