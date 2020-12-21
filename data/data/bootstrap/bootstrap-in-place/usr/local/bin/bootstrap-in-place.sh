#!/usr/bin/env bash
set -euoE pipefail ## -E option will cause functions to inherit trap

# This script is executed by bootkube.sh when installing single node with bootstrap in place
CLUSTER_BOOTSTRAP_IMAGE=$1


bootkube_podman_run() {
  # we run all commands in the host-network to prevent IP conflicts with
  # end-user infrastructure.
  podman run --quiet --net=host "${@}"
}

if [ ! -f stop-etcd.done ]; then
  echo "Stop etcd static pod by moving the manifest"
  mv /etc/kubernetes/manifests/etcd-member-pod.yaml /etc/kubernetes

  until ! crictl ps | grep etcd; do
    echo "Waiting for etcd to go down"
    sleep 10
  done

  touch stop-etcd.done
fi

if [ ! -f master-ignition.done ]; then

  echo "Creating master ignition and writing it to disk"
  # Get the master ignition from MCS
  curl -k -H "Accept:'application/vnd.coreos.ignition+json;version=3.1.0, */*;q=0.1'" \
    https://localhost:22623/config/master -o /opt/openshift/master.ign

  echo "Adding  bootstrap control plane to master ignition"
  bootkube_podman_run \
    --rm \
    --privileged \
    --volume "/var/lib/etcd:/var/lib/etcd" \
    --volume "$PWD:/assets:z" \
    --volume "/etc/kubernetes:/etc/kubernetes" \
    "${CLUSTER_BOOTSTRAP_IMAGE}" \
    bootstrap-in-place --asset-dir=/assets --ignition-path=/assets/master.ign

  touch master-ignition.done
fi

if [ ! -f coreos-installer.done ]; then
  # Write image + ignition to disk
  echo "Getting installation disk"
  INSTALL_DISK="$(lsblk | grep disk | awk 'NR==1{print $1}')"
  echo "Executing coreos-installer with installation disk: $INSTALL_DISK"
  coreos-installer install --insecure -i /opt/openshift/master.ign /dev/"$INSTALL_DISK"

  touch coreos-installer.done
fi

if [ ! -f reboot.done ]; then

  echo "Going to reboot"
  shutdown -r +1 "Bootstrap completed, server is going to reboot."
  touch reboot.done
fi
