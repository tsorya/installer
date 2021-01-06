#!/usr/bin/env bash
set -euoE pipefail ## -E option will cause functions to inherit trap

export KUBECONFIG=/etc/kubernetes/bootstrap-secrets/kubeconfig

function wait_for_api {
  until oc get csr &> /dev/null
  do
      echo "Waiting for api ..."
      sleep 5
  done
}

function restart_kubelet {
  echo "Restarting kubelet"
  until [ "$(oc get pod -n openshift-kube-apiserver-operator --selector='app=kube-apiserver-operator'  -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep -c "True")" -eq 1 ];
  do
    echo "Waiting for kube-apiserver-operator to ready condition to be True"
    sleep 10
  done
  # daemon-reload is required because /etc/systemd/system/kubelet.service.d/20-nodenet.conf is added after kubelet started
  systemctl daemon-reload
  systemctl restart kubelet

  while grep  bootstrap-kube-apiserver /etc/kubernetes/manifests/kube-apiserver-pod.yaml;
  do
    echo "Waiting for kube-apiserver to apply the new static pod configuration"
    sleep 10
  done
  systemctl restart kubelet
}

function approve_csr {
  echo "Approving csrs ..."
  needed_to_approve=false
  until [ "$(oc get nodes --selector='node-role.kubernetes.io/master' -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep -c "True")" -eq 1 ];
  do
      needed_to_approve=true
      echo "Approving csrs ..."
     oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve &> /dev/null || true
     sleep 30
  done
  # Restart kubelet only if node was added
  if $needed_to_approve ; then
    apply_patches pre_kubelet_restart_patches
    restart_kubelet
  fi
}

function pre_kubelet_restart_patches {
    echo "patch etcd to allow etcd-operator to start the etcd cluster without minimum of 3 master nodes"
    oc patch etcd cluster -p='{"spec": {"unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableEtcd": true}}}' --type=merge || return 1

    echo "patch cluster-authentication-operator to allow to deploy OAuthServer without minimum of 3 master nodes"
    oc patch authentications.operator.openshift.io cluster -p='{"spec": {"managementState": "Managed", "unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableOAuthServer": true}}}' --type=merge || return 1

    return 0
}

function post_kubelet_restart_patches {

    echo "patch ingress operator to run a single router pod"
    oc patch -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 1}}' --type=merge || return 1


    if oc get deployment etcd-quorum-guard -n openshift-etcd; then
      echo "mark etcd-quorum-guard as unmanaged"
      oc patch clusterversion/version --type='merge' -p "$(cat <<- EOF
spec:
    overrides:
      - group: apps/v1
        kind: Deployment
        name: etcd-quorum-guard
        namespace: openshift-etcd
        unmanaged: true
EOF
  )" || return 1

      echo "scale down etcd-quorum-guard"
      oc scale --replicas=0 deployment/etcd-quorum-guard -n openshift-etcd || return 1
   fi

   return 0
}

function apply_patches {
  echo "patch needed components"
  while ! $1; do
    echo "Waiting to try again..."
    sleep 10
done
}

function wait_for_cvo {
  echo "Waiting for cvo"
  until [ "$(oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Available")].status}')" == "True" ];
  do
    echo "Still waiting for cvo ..."
    sleep 30
  done
}

function clean {
  if [ -d "/etc/kubernetes/bootstrap-secrets" ]; then
     rm -rf /etc/kubernetes/bootstrap-*
  fi
  systemctl disable bootstrap-in-place-post-reboot.service
}

wait_for_api
approve_csr
apply_patches post_kubelet_restart_patches
wait_for_cvo
clean
