#!/bin/bash

# $ curl -O -L https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.6/46.82.202007051540-0/x86_64/rhcos-46.82.202007051540-0-qemu.x86_64.qcow2.gz
# $ mv rhcos-46.82.202007051540-0-qemu.x86_64.qcow2.gz /tmp
# $ sudo gunzip /tmp/rhcos-46.82.202007051540-0-qemu.x86_64.qcow2.gz

IGNITION_CONFIG="/var/lib/libvirt/images/aio.ign"
sudo cp "$1" "${IGNITION_CONFIG}"
sudo chown qemu:qemu "${IGNITION_CONFIG}"
sudo restorecon "${IGNITION_CONFIG}"

VM_INT=${VM_INT:-1}
RHCOS_IMAGE="/tmp/rhcos-46.82.202008181646-0-qemu.x86_64.qcow2"
VM_NAME="aio-test-${VM_INT}"
OS_VARIANT="rhel8.1"
RAM_MB="16384"
DISK_GB="20"
export NETWORK=${NETWORK:-test-net}

virt-install \
    --connect qemu:///system \
    -n "${VM_NAME}" \
    -r "${RAM_MB}" \
    --vcpus=6 \
    --os-variant="${OS_VARIANT}" \
    --import \
    --network=network:${NETWORK},mac=52:54:00:ee:42:e${VM_INT} \
    --graphics=none \
    --disk "size=${DISK_GB},backing_store=${RHCOS_IMAGE}" \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

